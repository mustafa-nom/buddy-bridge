--!strict
-- Top-right streak/multiplier widget. Pulses when streak ticks up; pulses
-- red briefly on a wrong action. Shows current title beneath the streak.

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
	Name = "PhishStreakHud",
	Size = UDim2.new(0, 220, 0, 96),
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 12),
	Parent = screen,
})

local streakLabel = UIStyle.MakeLabel({
	Size = UDim2.new(1, -16, 0, 28),
	Position = UDim2.new(0, 8, 0, 6),
	Text = "Streak 0",
	TextSize = UIStyle.TextSize.Heading,
	Parent = panel,
})

local multLabel = UIStyle.MakeLabel({
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 36),
	Text = "Bonus ×1.0",
	TextSize = UIStyle.TextSize.Body,
	TextColor3 = UIStyle.Palette.TextMuted,
	Parent = panel,
})

local titleLabel = UIStyle.MakeLabel({
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 62),
	Text = "Tadpole",
	TextSize = UIStyle.TextSize.Caption,
	TextColor3 = UIStyle.Palette.Accent,
	Parent = panel,
})

local function pulse(color: Color3)
	local original = panel.BackgroundColor3
	panel.BackgroundColor3 = color
	TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundColor3 = original }):Play()
end

local function applySnapshot(payload)
	if typeof(payload) ~= "table" then return end
	if payload.Streak then
		streakLabel.Text = ("Streak %d"):format(payload.Streak)
	end
	if payload.Multiplier then
		multLabel.Text = ("Bonus ×%.1f"):format(payload.Multiplier)
		if payload.Multiplier > 1.0 then
			multLabel.TextColor3 = UIStyle.Palette.Safe
		else
			multLabel.TextColor3 = UIStyle.Palette.TextMuted
		end
	end
	if payload.Delta and payload.Delta > 0 then
		pulse(UIStyle.Palette.Safe)
	elseif payload.Delta and payload.Delta < 0 then
		pulse(UIStyle.Palette.Risky)
	end
end

RemoteService.OnClientEvent("StreakUpdated", applySnapshot)

RemoteService.OnClientEvent("InventoryUpdated", function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.Title then titleLabel.Text = payload.Title end
end)

RemoteService.OnClientEvent("TitleUnlocked", function(payload)
	if typeof(payload) ~= "table" or typeof(payload.Title) ~= "string" then return end
	titleLabel.Text = payload.Title
	pulse(UIStyle.Palette.Highlight)
	UIBuilder.Toast(("New title unlocked: %s"):format(payload.Title), 4, "Success")
end)

task.spawn(function()
	local ok, snap = pcall(function()
		return RemoteService.InvokeServer("GetSnapshot")
	end)
	if ok and snap then
		applySnapshot({ Streak = snap.Streak, Multiplier = 1.0 })
		if snap.Title then titleLabel.Text = snap.Title end
	end
end)
