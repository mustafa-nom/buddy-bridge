--!strict
-- Backpack Checkpoint level entry point.
--
-- Thin wrapper around the BackpackCheckpoint/ submodules. Keeps the same
-- Begin / HandleSort / GetActiveItemInfo / GetActiveItemModel / Cleanup
-- surface that LevelService and ExplorerInteractionService already call.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local PlayAreaConfig = require(Modules:WaitForChild("PlayAreaConfig"))
local TagQueries = require(Modules:WaitForChild("TagQueries"))
local ItemRegistry = require(Modules:WaitForChild("ItemRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local BackpackCheckpoint = script.Parent:WaitForChild("BackpackCheckpoint")
local BeltController = require(BackpackCheckpoint:WaitForChild("BeltController"))
local WaveDirector = require(BackpackCheckpoint:WaitForChild("WaveDirector"))
local MiniBossDirector = require(BackpackCheckpoint:WaitForChild("MiniBossDirector"))
local GuideRehydrate = require(BackpackCheckpoint:WaitForChild("GuideRehydrate"))

local DataService = require(script.Parent.Parent:WaitForChild("DataService"))

local BackpackCheckpointLevel = {}

local function getLevelModel(round): Model?
	for _, candidate in ipairs(TagQueries.GetSortedSlots()) do
		if candidate:GetAttribute(PlayAreaConfig.Attributes.SlotIndex) == round.SlotIndex then
			local playArea = candidate:FindFirstChild(Constants.SLOT_PLAY_AREA_FOLDER)
			if not playArea then
				return nil
			end
			for _, child in ipairs(playArea:GetChildren()) do
				if child:IsA("Model") and child:GetAttribute(PlayAreaConfig.Attributes.LevelType) == LevelTypes.BackpackCheckpoint then
					return child
				end
			end
		end
	end
	return nil
end

-- Re-export query helpers so existing callers don't need the submodule path.
BackpackCheckpointLevel.GetActiveItemInfo = BeltController.GetActiveItemInfo
BackpackCheckpointLevel.GetActiveItemModel = BeltController.GetActiveItemModel
BackpackCheckpointLevel.GetLaneLocks = BeltController.GetLaneLocks
BackpackCheckpointLevel.SetLaneLock = BeltController.SetLaneLock
BackpackCheckpointLevel.SetHighlight = BeltController.SetHighlight
BackpackCheckpointLevel.MarkHeld = BeltController.MarkHeld
BackpackCheckpointLevel.GetHeldByPlayer = BeltController.GetHeldByPlayer
BackpackCheckpointLevel.HaltBelt = BeltController.HaltBelt
BackpackCheckpointLevel.ResumeBelt = BeltController.ResumeBelt
BackpackCheckpointLevel.IsHalted = BeltController.IsHalted
BackpackCheckpointLevel.RehydrateForGuide = GuideRehydrate.RehydrateForGuide
BackpackCheckpointLevel.IsMiniBossActive = MiniBossDirector.IsActive

function BackpackCheckpointLevel.HandleSort(round, itemId: string, laneId: string): (boolean, boolean, string?)
	-- Returns (acceptedByServer, wasCorrect, reason).
	-- During Mini-Boss the inner-sort path runs; otherwise the normal
	-- BeltController flow applies. WaveDirector.OnItemResolved is fired by
	-- BeltController via the per-spawn callback whenever the active item
	-- leaves the belt (correct sort or fall-off). Wrong sort bounces back
	-- and stays active in the normal flow; in Mini-Boss flow wrong sort
	-- either ends the round (high combo) or advances the bag.
	if MiniBossDirector.IsActive(round) then
		return MiniBossDirector.HandleInnerSort(round, itemId, laneId)
	end
	return BeltController.HandleSort(round, itemId, laneId)
end

function BackpackCheckpointLevel.Begin(round, scenario)
	local levelModel = getLevelModel(round)
	if not levelModel then
		warn("BackpackCheckpointLevel: level model not in slot")
		return false
	end

	-- Wire bin proximity prompts (drop here).
	for _, bin in ipairs(TagQueries.GetTaggedInside(levelModel, PlayAreaConfig.Tags.BuddyBin)) do
		if bin:IsA("BasePart") then
			local existingPrompt = bin:FindFirstChildOfClass("ProximityPrompt")
			if not existingPrompt then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Drop here"
				local laneId = bin:GetAttribute(PlayAreaConfig.Attributes.LaneId)
				local theme = ItemRegistry.LaneTheme[laneId]
				prompt.ObjectText = theme and theme.Label or "Bin"
				prompt.HoldDuration = 0
				prompt.MaxActivationDistance = Constants.BIN_RADIUS_STUDS
				prompt.RequiresLineOfSight = false
				prompt.Parent = bin
				prompt:SetAttribute("BB_LaneId", laneId)
			end
		end
	end

	-- Pixel Post intro: fire on both screens. Wave 1 spawn is gated until
	-- both clients have dismissed or the timeout fires (P2).
	RemoteService.FirePair(round, "PixelPostIntro", {
		RoundId = round.RoundId,
		Title = "Pixel Post: Outbound Sorting",
		Body = "First shift! Bags coming in. Sort outgoing mail and incoming surprises — talk to your buddy.",
		DurationSeconds = Constants.BACKPACK_PIXEL_POST_INTRO_SECONDS,
		SkippableAfterSeconds = 3,
	})

	-- Push the manual to the Guide before the first wave so the Field Manual
	-- chart is on screen the moment Wave 1 spawns.
	RemoteService.FireClient(round.Guide, "GuideManualUpdated", {
		RoundId = round.RoundId,
		LevelType = LevelTypes.BackpackCheckpoint,
		Manual = scenario.GuideManual,
	})

	-- Field Manual session meta (P2): push the union of encountered items
	-- for the pair so the Guide can see what they've already learned across
	-- earlier rounds in this session.
	local explorerSeen = DataService.GetEncounteredItems(round.Explorer)
	local guideSeen = DataService.GetEncounteredItems(round.Guide)
	local union: { [string]: boolean } = {}
	for k in pairs(explorerSeen) do union[k] = true end
	for k in pairs(guideSeen) do union[k] = true end
	RemoteService.FirePair(round, "FieldManualUpdated", {
		RoundId = round.RoundId,
		Encountered = union,
	})

	-- LevelService handles the round.ActiveScenario assignment and itemsSorted
	-- reset; we just kick off the wave runner once the intro gate is open.
	local Services = script.Parent.Parent
	local LevelService
	local RoundService
	local function onLevelComplete()
		LevelService = LevelService or require(Services:WaitForChild("LevelService"))
		LevelService.CompleteLevel(round, LevelTypes.BackpackCheckpoint)
	end
	local function onMiniBossFail()
		-- Mini-Boss with combo above threshold ends the round outright.
		-- Score screen renders whatever was earned so far. Trust Seeds
		-- policy on a failed run is governed by Open Ambiguity A1 in the
		-- edge-case addendum (lean: partial seeds for participation —
		-- already the default in RewardService since seeds are awarded
		-- by rank, and a low-score run still gets Bronze).
		RoundService = RoundService or require(Services:WaitForChild("RoundService"))
		RoundService.EndRound(round, "MiniBossFail")
	end

	-- Intro gate: resolve when both clients dismiss OR the timeout fires.
	-- Whichever happens first calls WaveDirector.Begin exactly once.
	local levelState = round.LevelState[LevelTypes.BackpackCheckpoint]
	local gateFired = false
	local function fireGate()
		if gateFired then return end
		gateFired = true
		if not round.IsActive then return end
		if round.ActiveScenario ~= scenario then return end
		WaveDirector.Begin(round, scenario, onLevelComplete, onMiniBossFail)
	end
	levelState.IntroGate = fireGate
	-- Timeout fallback so a non-responsive client can't stall the round.
	task.delay(Constants.BACKPACK_INTRO_GATE_TIMEOUT_SECONDS, fireGate)

	-- Guide rehydrate-on-respawn (P2 edge case 4): when the Guide character
	-- is re-added mid-round, re-fire the scanner snapshot to that one
	-- client. Skip if the round already ended.
	local RoundState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RoundState"))
	local guide = round.Guide
	local respawnConn = guide.CharacterAdded:Connect(function(_character)
		task.wait(0.4)
		if not round.IsActive then return end
		if round.ActiveScenario ~= scenario then return end
		GuideRehydrate.RehydrateForGuide(round, guide)
	end)
	RoundState.AddConnection(round, respawnConn)

	-- Drop-not-bin recovery (P2 edge case 6): if the Explorer character
	-- dies while holding an item, clear the Held flag so the model is no
	-- longer "carried" but stays at its last position on the belt. The
	-- existing fall-off timer continues — no additional mistake from the
	-- death itself; only the existing falloff timer can fire as a mistake.
	local function watchExplorerDeaths(character: Model)
		local hum = character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local conn = hum.Died:Connect(function()
			if not round.IsActive then return end
			if BeltController.GetHeldByPlayer(round) == round.Explorer then
				BeltController.MarkHeld(round, nil)
			end
		end)
		RoundState.AddConnection(round, conn)
	end
	if round.Explorer.Character then
		watchExplorerDeaths(round.Explorer.Character)
	end
	local explorerCharConn = round.Explorer.CharacterAdded:Connect(watchExplorerDeaths)
	RoundState.AddConnection(round, explorerCharConn)

	-- Tutorial gating (P2 edge case 29): first time this player sees BPC
	-- as Guide / Explorer in this session, push a one-line tutorial.
	local guideKey = "BackpackCheckpointGuide"
	local explorerKey = "BackpackCheckpointExplorer"
	if not DataService.HasSeenTutorialKey(round.Guide, guideKey) then
		DataService.MarkTutorialSeen(round.Guide, guideKey)
		RemoteService.FireClient(round.Guide, "TutorialPrompt", {
			RoundId = round.RoundId,
			Key = guideKey,
			Title = "You're the X-Ray Guide",
			Body = "Scan, highlight, and unlock a lane. Your buddy can only sort what you unlock.",
		})
	end
	if not DataService.HasSeenTutorialKey(round.Explorer, explorerKey) then
		DataService.MarkTutorialSeen(round.Explorer, explorerKey)
		RemoteService.FireClient(round.Explorer, "TutorialPrompt", {
			RoundId = round.RoundId,
			Key = explorerKey,
			Title = "You're the Sorter",
			Body = "Pick up an item and drop it in the lane your buddy unlocks. Wrong calls bounce back.",
		})
	end
	return true
end

function BackpackCheckpointLevel.Cleanup(round)
	BeltController.Cleanup(round)
end

return BackpackCheckpointLevel
