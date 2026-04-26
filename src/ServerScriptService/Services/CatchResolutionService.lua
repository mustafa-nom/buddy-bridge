--!strict
-- Validates the player's chosen verb against the bitten fish's correctAction,
-- delegates the reel mini-game to ReelMinigameService, and resolves the
-- catch with streak + lucky-bobber multipliers. Triggers public
-- AnnouncementService broadcasts on Epic/Legendary catches and on streak
-- milestones.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local Actions = require(Modules:WaitForChild("ReelActionTypes"))
local RodRegistry = require(Modules:WaitForChild("RodRegistry"))
local FishEncounterTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishEncounterTypes"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local CastingService = require(Services:WaitForChild("CastingService"))
local DataService = require(Services:WaitForChild("DataService"))
local RewardService = require(Services:WaitForChild("RewardService"))
local FieldGuideService = require(Services:WaitForChild("FieldGuideService"))
local StreakService = require(Services:WaitForChild("StreakService"))
local AnnouncementService = require(Services:WaitForChild("AnnouncementService"))
local BobberService = require(Services:WaitForChild("BobberService"))
local ReelMinigameService = require(Services:WaitForChild("ReelMinigameService"))

local CatchResolutionService = {}

local cutLineStreak: { [Player]: number } = {}

local function basicGate(player: Player, encounterId: string?, key: string, rateLimitWindow: number)
	if typeof(encounterId) ~= "string" then return nil end
	if not RemoteValidation.RequirePlayer(player) then return nil end
	if not RemoteValidation.RequireRateLimit(player, key, rateLimitWindow) then return nil end
	local enc = CastingService.GetEncounter(player)
	if not enc then return nil end
	if enc.encounterId ~= encounterId then return nil end
	return enc
end

local function maybeUpdateTitle(player: Player)
	local d = DataService.GetData(player)
	local newTitle = d.Title
	for _, entry in ipairs(Constants.TITLES) do
		if d.TotalCorrectCatches >= entry.threshold then
			newTitle = entry.title
		end
	end
	if newTitle ~= d.Title then
		d.Title = newTitle
		RemoteService.FireClient(player, "TitleUnlocked", { Title = newTitle })
	end
end

local function finalizeCatch(player: Player, enc, wasCorrect: boolean, outcome: string, reelQuality: number?)
	local fish = enc.fishId and FishRegistry.GetById(enc.fishId)
	if not fish then return end
	enc.state = FishEncounterTypes.States.Resolved
	enc.resolvedAt = os.clock()

	local streak
	if wasCorrect then
		streak = StreakService.RegisterCorrect(player)
	else
		StreakService.RegisterWrong(player)
		streak = 0
	end

	local streakMult = StreakService.MultiplierFor(streak)
	local luckyMult = enc.luckyBobber and Constants.LUCKY_BOBBER_MULTIPLIER or 1

	if wasCorrect then
		DataService.AddFish(player, fish.id, fish.rarity)
		DataService.UnlockJournal(player, fish.id)
		FieldGuideService.UnlockEntry(player, fish.id)
		maybeUpdateTitle(player)
	end

	local reward = RewardService.GrantCatch(player, fish.id, wasCorrect, enc.zoneTier, {
		streakMultiplier = streakMult,
		luckyMultiplier = luckyMult,
		reelQuality = reelQuality,
	})
	local lessonLine = wasCorrect and fish.lessonLineCorrect or fish.lessonLineWrong

	-- Cut-line streak nudge (separate from the multiplier streak — this one
	-- watches for spam regardless of correctness).
	if outcome == FishEncounterTypes.OutcomeKinds.CorrectCutLine then
		cutLineStreak[player] = (cutLineStreak[player] or 0) + 1
	elseif wasCorrect then
		cutLineStreak[player] = 0
	end
	local nudge = (cutLineStreak[player] or 0) >= Constants.CUT_LINE_STREAK_NUDGE_AT
		and "Lots of cuts in a row — try Verify on the next bite to peek at the Field Guide."
		or nil

	-- Public hype.
	if wasCorrect then
		AnnouncementService.RareCatch(player, fish.displayName, fish.rarity)
		if streak >= Constants.STREAK.PublicAnnounceAt and streak % Constants.STREAK.PublicAnnounceAt == 0 then
			AnnouncementService.StreakMilestone(player, streak)
		end
	end

	BobberService.Despawn(player)

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
		Multipliers = reward.Multipliers,
		AquariumPromptable = wasCorrect and fish.correctAction == Actions.Reel,
		Streak = streak,
		LuckyBobber = enc.luckyBobber == true,
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
	if enc.fishId then
		FieldGuideService.RevealEntry(player, enc.fishId, true)
	end
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
	local fish = enc.fishId and FishRegistry.GetById(enc.fishId)
	if not fish then return end
	enc.state = FishEncounterTypes.States.Reeling

	local rod = RodRegistry.GetById(enc.rodId or "")
	local rodForgiveness = rod and rod.reelForgiveness or 0
	local encounterId = enc.encounterId

	ReelMinigameService.Start(player, encounterId, fish.rarity, rodForgiveness, function(successful)
		local current = CastingService.GetEncounter(player)
		if not current or current.encounterId ~= encounterId then return end
		local correct = successful and (fish.correctAction == Actions.Reel)
		local quality = successful and 1 or 0.4
		local outcome
		if correct then
			outcome = FishEncounterTypes.OutcomeKinds.CorrectReel
		else
			outcome = FishEncounterTypes.OutcomeKinds.WrongAction
		end
		finalizeCatch(player, current, correct, outcome, quality)
	end)
end

local function handleReelInput(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.encounterId) ~= "string" then return end
	if not RemoteValidation.RequireRateLimit(player, "ReelInput", Constants.RATE_LIMIT_REEL_INPUT) then return end
	ReelMinigameService.OnInput(player, payload.encounterId, payload.holding == true)
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
	end)
end

return CatchResolutionService
