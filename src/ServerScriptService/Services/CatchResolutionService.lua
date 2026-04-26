--!strict
-- Validates the player's chosen verb against the bitten fish's correctAction,
-- runs the (optional) reel mini-game, and resolves the catch. Grants
-- pearls/XP/journal/inventory deltas through DataService and RewardService.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local Actions = require(Modules:WaitForChild("ReelActionTypes"))
local FishEncounterTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishEncounterTypes"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local CastingService = require(Services:WaitForChild("CastingService"))
local DataService = require(Services:WaitForChild("DataService"))
local RewardService = require(Services:WaitForChild("RewardService"))
local FieldGuideService = require(Services:WaitForChild("FieldGuideService"))

local CatchResolutionService = {}

local cutLineStreak: { [Player]: number } = {}
local activeReelTokens: { [Player]: number } = {}
local reelInputCount: { [Player]: number } = {}

local function basicGate(player: Player, encounterId: string?, key: string, rateLimitWindow: number)
	if typeof(encounterId) ~= "string" then return nil end
	if not RemoteValidation.RequirePlayer(player) then return nil end
	if not RemoteValidation.RequireRateLimit(player, key, rateLimitWindow) then return nil end
	local enc = CastingService.GetEncounter(player)
	if not enc then return nil end
	if enc.encounterId ~= encounterId then return nil end
	return enc
end

local function finalizeCatch(player: Player, enc, wasCorrect: boolean, outcome: string)
	local fish = enc.fishId and FishRegistry.GetById(enc.fishId)
	if not fish then return end
	enc.state = FishEncounterTypes.States.Resolved
	enc.resolvedAt = os.clock()

	if wasCorrect then
		DataService.AddFish(player, fish.id, fish.rarity)
		DataService.UnlockJournal(player, fish.id)
		FieldGuideService.UnlockEntry(player, fish.id)
	end
	local reward = RewardService.GrantCatch(player, fish.id, wasCorrect, enc.zoneTier)
	local lessonLine = wasCorrect and fish.lessonLineCorrect or fish.lessonLineWrong

	-- Cut-line streak nudge for spammers.
	if outcome == FishEncounterTypes.OutcomeKinds.CorrectCutLine then
		cutLineStreak[player] = (cutLineStreak[player] or 0) + 1
	elseif wasCorrect then
		cutLineStreak[player] = 0
	end
	local streak = cutLineStreak[player] or 0
	local nudge = streak >= Constants.CUT_LINE_STREAK_NUDGE_AT
		and "Lots of cuts in a row — try Verify on the next bite to peek at the Field Guide."
		or nil

	RemoteService.FireClient(player, "CatchResolved", {
		EncounterId = enc.encounterId,
		FishId = fish.id,
		DisplayName = fish.displayName,
		Category = fish.category,
		Rarity = fish.rarity,
		WasCorrect = wasCorrect,
		Outcome = outcome,
		LessonLine = lessonLine,
		Pearls = reward.Pearls,
		Xp = reward.Xp,
		AquariumPromptable = wasCorrect and fish.correctAction == Actions.Reel,
		Nudge = nudge,
	})

	CastingService.SetEncounter(player, nil)
end

local function handleVerify(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	local enc = basicGate(player, payload.encounterId, "RequestVerify", Constants.RATE_LIMIT_VERIFY)
	if not enc then return end
	if enc.state ~= FishEncounterTypes.States.BitePending then return end
	enc.state = FishEncounterTypes.States.Verifying
	enc.verified = true
	local fishId = enc.fishId
	if fishId then
		FieldGuideService.RevealEntry(player, fishId, true)
	end
	-- Resume bite-pending after pause.
	task.delay(Constants.VERIFY_PAUSE_SECONDS, function()
		local current = CastingService.GetEncounter(player)
		if current ~= enc then return end
		if enc.state == FishEncounterTypes.States.Verifying then
			enc.state = FishEncounterTypes.States.BitePending
		end
	end)
end

local function handleCutLine(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	local enc = basicGate(player, payload.encounterId, "RequestCutLine", Constants.RATE_LIMIT_DECISION)
	if not enc then return end
	if enc.state ~= FishEncounterTypes.States.BitePending then return end
	local correct = enc.correctAction == Actions.CutLine
	finalizeCatch(player, enc, correct,
		correct and FishEncounterTypes.OutcomeKinds.CorrectCutLine
			or FishEncounterTypes.OutcomeKinds.WrongAction)
end

local function handleReport(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	local enc = basicGate(player, payload.encounterId, "RequestReport", Constants.RATE_LIMIT_DECISION)
	if not enc then return end
	if enc.state ~= FishEncounterTypes.States.BitePending then return end
	local correct = enc.correctAction == Actions.Report
	finalizeCatch(player, enc, correct,
		correct and FishEncounterTypes.OutcomeKinds.CorrectReport
			or FishEncounterTypes.OutcomeKinds.WrongAction)
end

local function handleRelease(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	local enc = basicGate(player, payload.encounterId, "RequestRelease", Constants.RATE_LIMIT_DECISION)
	if not enc then return end
	if enc.state ~= FishEncounterTypes.States.BitePending then return end
	local correct = enc.correctAction == Actions.Release
	finalizeCatch(player, enc, correct,
		correct and FishEncounterTypes.OutcomeKinds.CorrectVerifyRelease
			or FishEncounterTypes.OutcomeKinds.WrongAction)
end

local function handleReel(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	local enc = basicGate(player, payload.encounterId, "RequestReel", Constants.RATE_LIMIT_DECISION)
	if not enc then return end
	if enc.state ~= FishEncounterTypes.States.BitePending then return end

	enc.state = FishEncounterTypes.States.Reeling
	local token = (activeReelTokens[player] or 0) + 1
	activeReelTokens[player] = token
	reelInputCount[player] = 0
	RemoteService.FireClient(player, "ReelMinigameStarted", {
		EncounterId = enc.encounterId,
		DurationSec = Constants.REEL_MINIGAME_SECONDS,
		HitWindow = Constants.REEL_HIT_WINDOW,
	})

	task.delay(Constants.REEL_MINIGAME_SECONDS, function()
		if activeReelTokens[player] ~= token then return end
		local current = CastingService.GetEncounter(player)
		if current ~= enc then return end
		local successful = (reelInputCount[player] or 0) >= 3
		local correct = enc.correctAction == Actions.Reel and successful
		local outcome
		if correct then
			outcome = FishEncounterTypes.OutcomeKinds.CorrectReel
		else
			outcome = FishEncounterTypes.OutcomeKinds.WrongAction
		end
		RemoteService.FireClient(player, "ReelMinigameResolved", {
			EncounterId = enc.encounterId,
			Successful = successful,
		})
		finalizeCatch(player, enc, correct, outcome)
	end)
end

local function handleReelInput(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.encounterId) ~= "string" then return end
	if not RemoteValidation.RequireRateLimit(player, "ReelInput", Constants.RATE_LIMIT_REEL_INPUT) then return end
	local enc = CastingService.GetEncounter(player)
	if not enc or enc.encounterId ~= payload.encounterId then return end
	if enc.state ~= FishEncounterTypes.States.Reeling then return end
	reelInputCount[player] = (reelInputCount[player] or 0) + 1
	RemoteService.FireClient(player, "ReelMinigameTick", {
		EncounterId = enc.encounterId,
		Count = reelInputCount[player],
	})
end

function CatchResolutionService.Init()
	RemoteService.OnServerEvent("RequestVerify", handleVerify)
	RemoteService.OnServerEvent("RequestCutLine", handleCutLine)
	RemoteService.OnServerEvent("RequestReport", handleReport)
	RemoteService.OnServerEvent("RequestRelease", handleRelease)
	RemoteService.OnServerEvent("RequestReel", handleReel)
	RemoteService.OnServerEvent("RequestReelInput", handleReelInput)

	Players.PlayerRemoving:Connect(function(player)
		cutLineStreak[player] = nil
		activeReelTokens[player] = nil
		reelInputCount[player] = nil
	end)
end

return CatchResolutionService
