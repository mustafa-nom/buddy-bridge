--!strict
-- Left-side session goals panel. 3 goals with progress bars + reward.
-- Auto-collapses when all 3 are complete.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local _ = Players.LocalPlayer
local screen = UIBuilder.GetScreenGui()

local panel = UIStyle.MakePanel({
	Name = "GoalsHud",
	Size = UDim2.new(0, 240, 0, 220),
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Parent = screen,
})

UIStyle.MakeLabel({
	Size = UDim2.new(1, -16, 0, 24),
	Position = UDim2.new(0, 8, 0, 6),
	Text = "Session Goals",
	TextSize = UIStyle.TextSize.Heading,
	Parent = panel,
})

local rowsContainer = Instance.new("Frame")
rowsContainer.Size = UDim2.new(1, -16, 1, -38)
rowsContainer.Position = UDim2.new(0, 8, 0, 32)
rowsContainer.BackgroundTransparency = 1
rowsContainer.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = rowsContainer

local function clearRows()
	for _, child in ipairs(rowsContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function rowFor(goal, layoutOrder: number)
	local row = UIStyle.MakePanel({
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = goal.completed and UIStyle.Palette.Safe or UIStyle.Palette.Background,
		LayoutOrder = layoutOrder,
		Parent = rowsContainer,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -8, 0, 22),
		Position = UDim2.new(0, 4, 0, 4),
		Text = goal.displayName,
		TextSize = UIStyle.TextSize.Caption,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = row,
	})
	local pct = math.clamp(goal.progress / goal.target, 0, 1)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, -8, 0, 8)
	bg.Position = UDim2.new(0, 4, 0, 30)
	bg.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
	bg.BorderSizePixel = 0
	bg.Parent = row
	UIStyle.ApplyCorner(bg, UDim.new(0, 4))

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = goal.completed and Color3.fromRGB(120, 220, 120) or UIStyle.Palette.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bg
	UIStyle.ApplyCorner(fill, UDim.new(0, 4))

	UIStyle.MakeLabel({
		Size = UDim2.new(1, -8, 0, 14),
		Position = UDim2.new(0, 4, 0, 40),
		Text = ("%d/%d  •  +%d pearls"):format(goal.progress, goal.target, goal.reward),
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
end

local function rebuild(goals)
	clearRows()
	for i, goal in ipairs(goals) do
		rowFor(goal, i)
	end
end

RemoteService.OnClientEvent("GoalsUpdated", function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.Goals then rebuild(payload.Goals) end
end)

RemoteService.OnClientEvent("GoalCompleted", function(payload)
	if typeof(payload) ~= "table" then return end
	UIBuilder.Toast(
		("Goal: %s   +%d pearls"):format(payload.DisplayName or "?", payload.Reward or 0),
		4,
		"Success"
	)
	-- Pulse the panel.
	local original = panel.BackgroundColor3
	panel.BackgroundColor3 = UIStyle.Palette.Safe
	TweenService:Create(panel, TweenInfo.new(0.6), { BackgroundColor3 = original }):Play()
end)
