--!strict
-- Guide-side remote handlers.
--
-- BPC item annotation moved to ScannerService (RequestScanItem /
-- RequestHighlightItem / RequestUnlockLane). This module now only handles
-- Stranger Danger NPC annotation; the SD redesign branch will eventually
-- remove that too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local ScenarioTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ScenarioTypes"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local GuideControlService = {}

local function findNpcInScenario(scenario, npcId: string)
	if not scenario or not scenario.Npcs then
		return nil
	end
	for _, npc in ipairs(scenario.Npcs) do
		if npc.Id == npcId then
			return npc
		end
	end
	return nil
end

local function handleAnnotateNpc(player: Player, npcId: string, marker: string)
	if typeof(npcId) ~= "string" or typeof(marker) ~= "string" then return end
	if not ScenarioTypes.IsValidAnnotationMarker(marker) then return end
	local okPlayer = RemoteValidation.RequirePlayer(player)
	if not okPlayer then return end
	local okRound, _, round = RemoteValidation.RequireRound(player)
	if not okRound or not round then return end
	local okRole = RemoteValidation.RequireGuide(player)
	if not okRole then return end
	local okLevel = RemoteValidation.RequireLevelType(round, LevelTypes.StrangerDangerPark)
	if not okLevel then return end
	local okRate = RemoteValidation.RequireRateLimit(player, "RequestAnnotateNpc:" .. npcId, Constants.RATE_LIMIT_ANNOTATE)
	if not okRate then return end

	local scenario = round.ActiveScenario
	if not findNpcInScenario(scenario, npcId) then return end

	scenario.Annotations[npcId] = marker
	RemoteService.FirePair(round, "NpcAnnotationUpdated", {
		RoundId = round.RoundId,
		NpcId = npcId,
		Marker = marker,
	})
end

function GuideControlService.Init()
	RemoteService.OnServerEvent("RequestAnnotateNpc", handleAnnotateNpc)
end

return GuideControlService
