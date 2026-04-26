--!strict
-- Listens to RareCatchAnnouncement (broadcast to all clients) and surfaces
-- a styled banner toast. Solo-fed players still feel "the lodge is alive".

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local _ = Players.LocalPlayer
local screen = UIBuilder.GetScreenGui()

local function rarityColor(rarity: string?): Color3
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 80) end
	if rarity == "Epic" then return Color3.fromRGB(220, 130, 250) end
	return UIStyle.Palette.Accent
end

local function showRareCatch(payload)
	local frame = UIStyle.MakePanel({
		Name = "AnnouncementToast",
		Size = UDim2.new(0, 380, 0, 56),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -64),
		BackgroundColor3 = rarityColor(payload.Rarity),
		Parent = screen,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 1, -8),
		Position = UDim2.new(0, 8, 0, 4),
		Text = ("%s caught a %s %s!"):format(
			payload.PlayerName or "Someone",
			payload.Rarity or "Rare",
			payload.FishName or "fish"
		),
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = Color3.fromRGB(40, 28, 16),
		Parent = frame,
	})
	TweenService:Create(frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 80) }):Play()
	task.delay(4, function()
		if not frame.Parent then return end
		TweenService:Create(frame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -64) }):Play()
		task.wait(0.45)
		frame:Destroy()
	end)
end

local function showStreak(payload)
	UIBuilder.Toast(
		("%s is on a %d-catch streak!"):format(payload.PlayerName or "Someone", payload.Streak or 0),
		3,
		"Success"
	)
end

RemoteService.OnClientEvent("RareCatchAnnouncement", function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.Kind == "RareCatch" then
		showRareCatch(payload)
	elseif payload.Kind == "StreakMilestone" then
		showStreak(payload)
	end
end)
