--!strict
-- Server-wide boss event banner. When BossEventStarted fires, slides a
-- pulsing banner in at the top center with a countdown. Closes/replaces
-- on BossEventClaimed and BossEventEnded.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local _ = Players.LocalPlayer
local screen = UIBuilder.GetScreenGui()

local state = {
	frame = nil :: Frame?,
	endsAt = nil :: number?,
	timerLabel = nil :: TextLabel?,
}

local function close()
	if state.frame then state.frame:Destroy() end
	state.frame = nil
	state.endsAt = nil
	state.timerLabel = nil
end

local function show(payload)
	close()
	local frame = UIStyle.MakePanel({
		Name = "BossBanner",
		Size = UDim2.new(0, 460, 0, 78),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -90),
		BackgroundColor3 = Color3.fromRGB(60, 30, 90),
		Parent = screen,
	})
	state.frame = frame

	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 26),
		Position = UDim2.new(0, 8, 0, 6),
		Text = ("⚠ BOSS PHISHER — %s"):format(payload.DisplayName or "?"),
		TextSize = UIStyle.TextSize.Heading,
		TextColor3 = Color3.fromRGB(255, 220, 110),
		Parent = frame,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 32),
		Text = ("First to cast hooks it. Pick the right verb to land 3× pearls."):format(),
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = Color3.fromRGB(220, 220, 240),
		Parent = frame,
	})
	state.timerLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 1, -28),
		Text = ("Window: %ds"):format(payload.WindowSec or 90),
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = frame,
	})

	state.endsAt = os.clock() + (payload.WindowSec or 90)

	TweenService:Create(frame,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 168) }):Play()
end

RunService.RenderStepped:Connect(function()
	if state.endsAt and state.timerLabel then
		local remaining = math.max(0, math.floor(state.endsAt - os.clock()))
		state.timerLabel.Text = ("Window: %ds"):format(remaining)
	end
end)

RemoteService.OnClientEvent("BossEventStarted", function(payload)
	if typeof(payload) ~= "table" then return end
	show(payload)
end)

RemoteService.OnClientEvent("BossEventClaimed", function(payload)
	if typeof(payload) ~= "table" then return end
	if state.frame and state.timerLabel then
		state.timerLabel.Text = ("%s hooked it!"):format(payload.ClaimerName or "Someone")
		state.timerLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	end
end)

RemoteService.OnClientEvent("BossEventEnded", function(payload)
	if typeof(payload) ~= "table" then return end
	if state.frame then
		if payload.ClaimedBy then
			UIBuilder.Toast(("%s landed the boss!"):format(payload.ClaimedBy), 4, "Success")
		end
		local frame = state.frame
		TweenService:Create(frame,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, 0, 0, -90) }):Play()
		task.delay(0.45, function()
			if state.frame == frame then close() end
		end)
	end
end)
