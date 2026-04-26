--!strict
-- Routes Explorer ProximityPrompts:
--  * NPC inspect prompt → RequestInspectNpc
--  * Bin drop prompt → RequestPlaceItemInLane (after pickup)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local localPlayer = Players.LocalPlayer
local currentRole = RoleTypes.None
local activeRoundId: string? = nil
local activeLevelType: string? = nil
local activeItemId: string? = nil
local heldItemId: string? = nil

local function isExplorer(): boolean
	return currentRole == RoleTypes.Explorer
end

-- Listen for ProximityPrompt triggers globally; route NPC inspect prompts
-- to the inspect remote.
local promptService = game:GetService("ProximityPromptService")
promptService.PromptTriggered:Connect(function(prompt, player)
	if player ~= localPlayer then return end
	if not isExplorer() then return end
	if not activeRoundId then return end

	local npcId = prompt:GetAttribute("BB_NpcId")
	if typeof(npcId) == "string" then
		RemoteService.FireServer("RequestInspectNpc", npcId)
		return
	end

	local laneId = prompt:GetAttribute("BB_LaneId")
	if typeof(laneId) == "string" and activeLevelType == LevelTypes.BackpackCheckpoint then
		if heldItemId then
			RemoteService.FireServer("RequestPlaceItemInLane", heldItemId, laneId)
			heldItemId = nil
		else
			-- Stand-in: also let the Explorer drop the active belt item
			-- without explicit pickup for MVP simplicity.
			if activeItemId then
				RemoteService.FireServer("RequestPlaceItemInLane", activeItemId, laneId)
			end
		end
		return
	end
end)

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	currentRole = payload.Role or RoleTypes.None
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	activeRoundId = payload.RoundId
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= activeRoundId then return end
	activeLevelType = payload.LevelType
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	activeRoundId = nil
	activeLevelType = nil
	activeItemId = nil
	heldItemId = nil
end)

RemoteService.OnClientEvent("ConveyorItemSpawned", function(payload)
	if payload.RoundId ~= activeRoundId then return end
	activeItemId = payload.ItemId
	heldItemId = nil
end)

RemoteService.OnClientEvent("ItemSortResult", function(payload)
	if payload.RoundId ~= activeRoundId then return end
	if payload.Correct then
		heldItemId = nil
	end
end)
