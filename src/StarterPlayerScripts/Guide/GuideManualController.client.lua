--!strict
-- Default-closed Guide manual with an on-screen toggle button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local UIBuilder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle
local Manuals = script.Parent:WaitForChild("Manuals")
local StrangerDangerManual = require(Manuals:WaitForChild("StrangerDangerManual"))
local BackpackCheckpointManual = require(Manuals:WaitForChild("BackpackCheckpointManual"))

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	LevelType = nil :: string?,
	ManualPayload = nil :: any?,
	Open = false,
	Manual = nil :: any?,
	Panel = nil :: Frame?,
	Toggle = nil :: TextButton?,
}

local function destroyManual()
	if state.Manual then
		state.Manual:Destroy()
		state.Manual = nil
	end
	if state.Panel then
		state.Panel:Destroy()
		state.Panel = nil
	end
end

local function updateToggle()
	if state.Toggle then
		state.Toggle.Text = state.Open and "Close Manual" or "Open Manual"
		state.Toggle.Visible = state.Role == RoleTypes.Guide and state.LevelType ~= nil
	end
end

local function renderManual()
	destroyManual()
	if not state.Open or state.Role ~= RoleTypes.Guide or not state.LevelType or not state.ManualPayload then
		updateToggle()
		return
	end
	state.Panel = UIStyle.MakePanel({
		Name = "GuideManualPanel",
		Size = UDim2.new(0, 380, 0, 460),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Parent = UIBuilder.GetScreenGui(),
	})
	if state.LevelType == LevelTypes.StrangerDangerPark then
		state.Manual = StrangerDangerManual.Build(state.Panel, state.ManualPayload)
	elseif state.LevelType == LevelTypes.BackpackCheckpoint then
		state.Manual = BackpackCheckpointManual.Build(state.Panel, state.ManualPayload)
	end
	updateToggle()
end

local function ensureToggle()
	if state.Toggle then
		updateToggle()
		return
	end
	state.Toggle = UIStyle.MakeButton({
		Name = "GuideManualToggle",
		Size = UDim2.new(0, 180, 0, 46),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.new(0, 16, 0, 88),
		Text = "Open Manual",
		TextSize = UIStyle.TextSize.Body,
		Parent = UIBuilder.GetScreenGui(),
	})
	state.Toggle.Activated:Connect(function()
		state.Open = not state.Open
		renderManual()
	end)
	updateToggle()
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
	ensureToggle()
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	state.RoundId = payload.RoundId
	ensureToggle()
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	state.ManualPayload = nil
	state.Open = false
	destroyManual()
	ensureToggle()
end)

RemoteService.OnClientEvent("GuideManualUpdated", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	state.ManualPayload = payload.Manual
	state.LevelType = payload.LevelType
	state.Open = false
	renderManual()
end)

RemoteService.OnClientEvent("NpcDescriptionShown", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.Audience ~= "Guide" then return end
	if state.Manual then
		state.Manual:Highlight(payload.Cues or {})
	end
end)

RemoteService.OnClientEvent("ConveyorItemSpawned", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	if state.Manual and state.LevelType == LevelTypes.BackpackCheckpoint then
		state.Manual:Highlight(payload.ItemKey)
	end
end)

RemoteService.OnClientEvent("LevelEnded", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = nil
	state.ManualPayload = nil
	state.Open = false
	destroyManual()
	updateToggle()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.RoundId = nil
	state.LevelType = nil
	state.ManualPayload = nil
	state.Open = false
	destroyManual()
	if state.Toggle then
		state.Toggle:Destroy()
		state.Toggle = nil
	end
end)
