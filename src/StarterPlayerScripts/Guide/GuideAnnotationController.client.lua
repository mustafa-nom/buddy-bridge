--!strict
-- Backpack Checkpoint item hint buttons for the Guide.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local UIBuilder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	LevelType = nil :: string?,
	ItemId = nil :: string?,
}

local panel: Frame? = nil

local function teardown()
	if panel then
		panel:Destroy()
		panel = nil
	end
end

local function makeButton(label: string, color: Color3, lane: string)
	local btn = UIStyle.MakeButton({
		Size = UDim2.new(0, 76, 1, 0),
		Text = label,
		BackgroundColor3 = color,
		TextSize = UIStyle.TextSize.Body,
	})
	btn.Parent = panel
	btn.Activated:Connect(function()
		if state.ItemId then
			RemoteService.FireServer("RequestAnnotateItem", state.ItemId, lane)
		end
	end)
end

local function buildButtons()
	if state.Role ~= RoleTypes.Guide or state.LevelType ~= LevelTypes.BackpackCheckpoint then
		teardown()
		return
	end
	teardown()
	panel = UIStyle.MakePanel({
		Name = "GuideItemAnnotation",
		Size = UDim2.new(0, 360, 0, 80),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Parent = UIBuilder.GetScreenGui(),
	})
	UIBuilder.PadLayout(panel :: Frame, 8)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = panel

	makeButton("Pack", UIStyle.Palette.Safe, "PackIt")
	makeButton("Ask", UIStyle.Palette.AskFirst, "AskFirst")
	makeButton("Leave", UIStyle.Palette.Risky, "LeaveIt")
	makeButton("Clear", UIStyle.Palette.PanelStroke, "Clear")
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
	buildButtons()
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	state.RoundId = payload.RoundId
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	state.ItemId = nil
	buildButtons()
end)

RemoteService.OnClientEvent("ConveyorItemSpawned", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	state.ItemId = payload.ItemId
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	state.LevelType = nil
	teardown()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.Role = RoleTypes.None
	state.RoundId = nil
	state.LevelType = nil
	state.ItemId = nil
	teardown()
end)
