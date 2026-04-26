--!strict
-- Explorer-side remote handlers: NPC dialog, item pickup/place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local PlayAreaConfig = require(Modules:WaitForChild("PlayAreaConfig"))
local TagQueries = require(Modules:WaitForChild("TagQueries"))
local StrangerDangerLogic = require(Modules:WaitForChild("StrangerDangerLogic"))
local ScoringConfig = require(Modules:WaitForChild("ScoringConfig"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local ScoringService = require(Services:WaitForChild("ScoringService"))
local PlayAreaService = require(Services:WaitForChild("PlayAreaService"))
local BackpackCheckpointLevel = require(Services:WaitForChild("Levels"):WaitForChild("BackpackCheckpointLevel"))

local ExplorerInteractionService = {}

local DEFAULT_SAFE_CHOICES = {
	{ Id = "ask_role", Text = "Are you working here?" },
	{ Id = "say_thanks", Text = "Thanks for helping." },
}

local DEFAULT_RISKY_CHOICES = {
	{ Id = "ask_buddy", Text = "I should ask my buddy first." },
	{ Id = "no_thanks", Text = "No thanks." },
	{ Id = "ask_reason", Text = "What are you doing here?" },
}

local ARCHETYPE_CHOICES = {
	HotDogVendor = {
		{ Id = "ask_stand", Text = "Is this your hot dog stand?" },
		{ Id = "say_thanks", Text = "Thanks!" },
	},
	Ranger = {
		{ Id = "ask_help", Text = "Can you help me find my buddy?" },
		{ Id = "notice_badge", Text = "I see your ranger badge." },
	},
}

local function findNpcInScenario(scenario, npcId: string)
	if not scenario or not scenario.Npcs then return nil end
	for _, npc in ipairs(scenario.Npcs) do
		if npc.Id == npcId then
			return npc
		end
	end
	return nil
end

local function findNpcModel(round, npcId: string): Model?
	local levelState = round.LevelState[LevelTypes.StrangerDangerPark]
	return levelState and levelState.NpcModels and levelState.NpcModels[npcId] or nil
end

local function getNpcRoot(model: Model?): BasePart?
	if not model then return nil end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	return root and root:IsA("BasePart") and root or nil
end

local function getNpcLine(npcInfo): string
	if typeof(npcInfo.Bark) == "string" and npcInfo.Bark ~= "" then
		return npcInfo.Bark
	end
	return "Hi there."
end

local function getDialogChoices(npcInfo)
	local archetypeChoices = ARCHETYPE_CHOICES[npcInfo.Archetype]
	if archetypeChoices then
		return archetypeChoices
	end
	if npcInfo.Verdict == StrangerDangerLogic.Verdict.Avoid then
		return DEFAULT_RISKY_CHOICES
	end
	return DEFAULT_SAFE_CHOICES
end

local function cueLinesForNote(npcInfo): { string }
	local lines = {}
	for _, tag in ipairs(npcInfo.Cues or { npcInfo.Cue }) do
		local cue = StrangerDangerLogic.Cues[tag]
		if cue then
			table.insert(lines, cue.GuideText)
		end
	end
	return lines
end

local function upsertNote(round, note)
	round.ExplorerNotes = round.ExplorerNotes or {}
	for i = #round.ExplorerNotes, 1, -1 do
		if round.ExplorerNotes[i].NpcId == note.NpcId then
			table.remove(round.ExplorerNotes, i)
		end
	end
	table.insert(round.ExplorerNotes, 1, note)
	while #round.ExplorerNotes > 8 do
		table.remove(round.ExplorerNotes)
	end
end

local function handleInspectNpc(player: Player, npcId: string)
	if typeof(npcId) ~= "string" then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	if not RemoteValidation.RequireExplorer(player) then return end
	if not RemoteValidation.RequireLevelType(round, LevelTypes.StrangerDangerPark) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestInspectNpc", Constants.RATE_LIMIT_INSPECT) then return end

	local npcInfo = findNpcInScenario(round.ActiveScenario, npcId)
	if not npcInfo then return end
	local root = getNpcRoot(findNpcModel(round, npcId))
	if not root or not RemoteValidation.RequireProximity(player, root, Constants.INSPECT_RADIUS_STUDS) then return end

	round.NpcDialogSessions = round.NpcDialogSessions or {}
	round.NpcDialogSessions[player.UserId] = { NpcId = npcId, StartedAt = os.clock() }
	RemoteService.FireClient(player, "OpenNpcDialog", {
		RoundId = round.RoundId,
		NpcId = npcId,
		Archetype = npcInfo.Archetype,
		Silhouette = npcInfo.Silhouette,
		Badge = npcInfo.Badge,
		NpcLine = getNpcLine(npcInfo),
		Choices = getDialogChoices(npcInfo),
	})
end

local function handleNpcDialogChoice(player: Player, payload)
	if typeof(payload) ~= "table" then return end
	local npcId, choiceId = payload.NpcId, payload.ChoiceId
	if typeof(npcId) ~= "string" or typeof(choiceId) ~= "string" then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	if not RemoteValidation.RequireExplorer(player) then return end
	if not RemoteValidation.RequireLevelType(round, LevelTypes.StrangerDangerPark) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestNpcDialogChoice", Constants.RATE_LIMIT_TALK) then return end

	local session = round.NpcDialogSessions and round.NpcDialogSessions[player.UserId]
	if not session or session.NpcId ~= npcId then return end
	local npcInfo = findNpcInScenario(round.ActiveScenario, npcId)
	if not npcInfo then return end
	local root = getNpcRoot(findNpcModel(round, npcId))
	if not root or not RemoteValidation.RequireProximity(player, root, Constants.INSPECT_RADIUS_STUDS) then return end

	local validChoice = false
	for _, choice in ipairs(getDialogChoices(npcInfo)) do
		if choice.Id == choiceId then
			validChoice = true
			break
		end
	end
	if not validChoice then return end
	round.NpcDialogSessions[player.UserId] = nil

	local note = {
		NpcId = npcId,
		Archetype = npcInfo.Archetype,
		Headline = npcInfo.Silhouette and npcInfo.Silhouette.Headline or "Someone in the park",
		Badge = npcInfo.Badge,
		CueTags = npcInfo.Cues or { npcInfo.Cue },
		CueLines = cueLinesForNote(npcInfo),
		Quote = getNpcLine(npcInfo),
		ChoiceId = choiceId,
		UpdatedAt = os.clock(),
	}
	upsertNote(round, note)
	RemoteService.FirePair(round, "NpcDialogNoteAdded", {
		RoundId = round.RoundId,
		Note = note,
		Notes = round.ExplorerNotes,
	})
end

local function handlePickupItem(player: Player, itemId: string)
	if typeof(itemId) ~= "string" then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	if not RemoteValidation.RequireExplorer(player) then return end
	if not RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestPickupItem", Constants.RATE_LIMIT_PICKUP) then return end
	if itemId ~= round.ActiveItemId then return end
	local model = BackpackCheckpointLevel.GetActiveItemModel(round)
	if not model then return end
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not root or not root:IsA("BasePart") then return end
	if RemoteValidation.RequireProximity(player, root, Constants.ITEM_PICKUP_RADIUS_STUDS) then
		BackpackCheckpointLevel.MarkHeld(round, player)
	end
end

local function handlePlaceItemInLane(player: Player, itemId: string, laneId: string)
	if typeof(itemId) ~= "string" or typeof(laneId) ~= "string" then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	if not RemoteValidation.RequireExplorer(player) then return end
	if not RemoteValidation.RequireLevelType(round, LevelTypes.BackpackCheckpoint) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestPlaceItemInLane", Constants.RATE_LIMIT_PLACE) then return end

	local slot = PlayAreaService.GetSlotForRound(round)
	local playArea = slot and slot:FindFirstChild("PlayArea")
	if not playArea then return end
	local levelModel: Model? = nil
	for _, child in ipairs(playArea:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute(PlayAreaConfig.Attributes.LevelType) == LevelTypes.BackpackCheckpoint then
			levelModel = child
			break
		end
	end
	local bin = levelModel and TagQueries.GetBinByLane(levelModel, laneId)
	if not bin or not RemoteValidation.RequireProximity(player, bin, Constants.BIN_RADIUS_STUDS) then return end

	local accepted, correct, reason = BackpackCheckpointLevel.HandleSort(round, itemId, laneId)
	if accepted and correct then
		round.ItemsSorted += 1
		local multiplier = ScoringConfig.GetComboMultiplier((round.Streak or 0) + 1)
		ScoringService.AddTrustPoints(round, Constants.TRUST_POINTS_PER_CORRECT_SORT, "Sort", multiplier)
	elseif reason == "WrongLane" then
		ScoringService.AddMistake(round, "WrongLane")
	end
end

function ExplorerInteractionService.Init()
	RemoteService.OnServerEvent("RequestInspectNpc", handleInspectNpc)
	RemoteService.OnServerEvent("RequestNpcDialogChoice", handleNpcDialogChoice)
	RemoteService.OnServerEvent("RequestPickupItem", handlePickupItem)
	RemoteService.OnServerEvent("RequestPlaceItemInLane", handlePlaceItemInLane)
end

return ExplorerInteractionService
