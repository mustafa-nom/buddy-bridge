--!strict
-- Tension-bar reel mini-game UI. Server simulates; client renders cursor +
-- catch zone + progress meter and forwards the player's hold/release input.
-- Hold Space (or LMB) to push the cursor up; release to let it fall under
-- gravity. Keep the cursor inside the green zone to fill the catch meter.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIFolder = script.Parent.Parent:WaitForChild("UI")
local UIBuilder = require(UIFolder:WaitForChild("UIBuilder"))

local _ = Players.LocalPlayer
local screen = UIBuilder.GetScreenGui()

local state = {
	encounterId = nil :: string?,
	frame = nil :: Frame?,
	bar = nil :: Frame?,
	cursor = nil :: Frame?,
	zone = nil :: Frame?,
	progressFill = nil :: Frame?,
	progressLabel = nil :: TextLabel?,
	timerLabel = nil :: TextLabel?,
	rarityLabel = nil :: TextLabel?,
	holding = false,
	lastSent = 0,
}

local function destroy()
	if state.frame then state.frame:Destroy() end
	state.frame = nil
	state.bar = nil
	state.cursor = nil
	state.zone = nil
	state.progressFill = nil
	state.progressLabel = nil
	state.timerLabel = nil
	state.rarityLabel = nil
end

local function rarityColor(rarity: string?): Color3
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 80) end
	if rarity == "Epic" then return Color3.fromRGB(220, 130, 250) end
	if rarity == "Rare" then return Color3.fromRGB(120, 200, 255) end
	return Color3.fromRGB(220, 220, 220)
end

local function build(payload)
	destroy()
	local frame = UIStyle.MakePanel({
		Name = "ReelTensionFrame",
		Size = UDim2.new(0, 360, 0, 460),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Parent = screen,
	})
	state.frame = frame

	UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 8),
		Text = "REEL!",
		TextSize = UIStyle.TextSize.Title,
		Parent = frame,
	})
	state.rarityLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 42),
		Text = ("%s catch — keep cursor in green"):format(tostring(payload.Rarity)),
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = rarityColor(payload.Rarity),
		Parent = frame,
	})

	-- The vertical tension bar.
	local bar = Instance.new("Frame")
	bar.Name = "TensionBar"
	bar.Size = UDim2.new(0, 76, 0, 320)
	bar.AnchorPoint = Vector2.new(0, 0)
	bar.Position = UDim2.new(0, 32, 0, 76)
	bar.BackgroundColor3 = Color3.fromRGB(40, 28, 16)
	bar.BorderSizePixel = 0
	bar.Parent = frame
	UIStyle.ApplyCorner(bar, UDim.new(0, 8))
	state.bar = bar

	-- Catch zone (green band that floats up/down).
	local zone = Instance.new("Frame")
	zone.Name = "CatchZone"
	zone.AnchorPoint = Vector2.new(0.5, 0.5)
	zone.Size = UDim2.new(1, -8, (payload.ZoneSize or 0.3), 0)
	zone.Position = UDim2.new(0.5, 0, 1 - (payload.ZoneCenter or 0.5), 0)
	zone.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
	zone.BorderSizePixel = 0
	zone.BackgroundTransparency = 0.15
	zone.Parent = bar
	UIStyle.ApplyCorner(zone, UDim.new(0, 6))
	state.zone = zone

	-- Cursor (the rod's pull line).
	local cursor = Instance.new("Frame")
	cursor.Name = "Cursor"
	cursor.AnchorPoint = Vector2.new(0.5, 0.5)
	cursor.Size = UDim2.new(1, 12, 0, 8)
	cursor.Position = UDim2.new(0.5, 0, 0.5, 0)
	cursor.BackgroundColor3 = Color3.fromRGB(255, 153, 84)
	cursor.BorderSizePixel = 0
	cursor.Parent = bar
	UIStyle.ApplyCorner(cursor, UDim.new(0, 4))
	UIStyle.ApplyStroke(cursor, Color3.fromRGB(80, 40, 10), 2)
	state.cursor = cursor

	-- Progress meter on the right side of the panel.
	local meterBg = Instance.new("Frame")
	meterBg.Size = UDim2.new(0, 28, 0, 320)
	meterBg.Position = UDim2.new(0, 132, 0, 76)
	meterBg.BackgroundColor3 = Color3.fromRGB(40, 28, 16)
	meterBg.BorderSizePixel = 0
	meterBg.Parent = frame
	UIStyle.ApplyCorner(meterBg, UDim.new(0, 6))

	local fill = Instance.new("Frame")
	fill.Name = "ProgressFill"
	fill.Size = UDim2.new(1, 0, payload.Progress or 0.4, 0)
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(120, 220, 120)
	fill.BorderSizePixel = 0
	fill.Parent = meterBg
	UIStyle.ApplyCorner(fill, UDim.new(0, 6))
	state.progressFill = fill

	-- Right-side instructions.
	UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 0, 26),
		Position = UDim2.new(0, 180, 0, 76),
		Text = "Hold SPACE",
		TextSize = UIStyle.TextSize.Heading,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 0, 22),
		Position = UDim2.new(0, 180, 0, 104),
		Text = "to lift the line.",
		TextSize = UIStyle.TextSize.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = UIStyle.Palette.TextMuted,
		Parent = frame,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 0, 22),
		Position = UDim2.new(0, 180, 0, 132),
		Text = "Release to drop.",
		TextSize = UIStyle.TextSize.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = UIStyle.Palette.TextMuted,
		Parent = frame,
	})
	state.progressLabel = UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 0, 22),
		Position = UDim2.new(0, 180, 0, 200),
		Text = "Progress 40%",
		TextSize = UIStyle.TextSize.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	state.timerLabel = UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 0, 22),
		Position = UDim2.new(0, 180, 0, 226),
		Text = "Time 7.5s",
		TextSize = UIStyle.TextSize.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 1, -32),
		Text = "Don't lose the line.",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
		Parent = frame,
	})
end

local function applyTick(payload)
	if not state.frame then return end
	if state.zone and payload.ZoneCenter and payload.ZoneSize then
		state.zone.Position = UDim2.new(0.5, 0, 1 - payload.ZoneCenter, 0)
		state.zone.Size = UDim2.new(1, -8, payload.ZoneSize, 0)
	end
	if state.cursor and payload.Cursor then
		-- Smoothly tween cursor for visual polish.
		TweenService:Create(state.cursor,
			TweenInfo.new(0.06, Enum.EasingStyle.Linear),
			{ Position = UDim2.new(0.5, 0, 1 - payload.Cursor, 0) }):Play()
	end
	if state.progressFill and payload.Progress then
		state.progressFill.Size = UDim2.new(1, 0, payload.Progress, 0)
		local p = payload.Progress
		local color
		if p > 0.66 then
			color = Color3.fromRGB(120, 220, 120)
		elseif p > 0.33 then
			color = Color3.fromRGB(245, 210, 90)
		else
			color = Color3.fromRGB(220, 92, 92)
		end
		state.progressFill.BackgroundColor3 = color
	end
	if state.progressLabel and payload.Progress then
		state.progressLabel.Text = ("Progress %d%%"):format(math.floor(payload.Progress * 100))
	end
	if state.timerLabel and payload.Remaining then
		state.timerLabel.Text = ("Time %.1fs"):format(payload.Remaining)
	end
end

local function setHolding(holding: boolean)
	if not state.encounterId then return end
	state.holding = holding
	-- Send immediately on edge; heartbeat re-sends at low rate.
	state.lastSent = 0
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not state.encounterId then return end
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setHolding(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		setHolding(false)
	end
end)

RemoteService.OnClientEvent("ReelMinigameStarted", function(payload)
	if typeof(payload) ~= "table" then return end
	state.encounterId = payload.EncounterId
	state.holding = false
	build(payload)
end)

RemoteService.OnClientEvent("ReelMinigameTick", function(payload)
	if typeof(payload) ~= "table" then return end
	if state.encounterId ~= payload.EncounterId then return end
	applyTick(payload)
end)

RemoteService.OnClientEvent("ReelMinigameResolved", function(payload)
	if typeof(payload) ~= "table" then return end
	if state.encounterId ~= payload.EncounterId then return end
	state.encounterId = nil
	state.holding = false
end)

RemoteService.OnClientEvent("CatchResolved", function()
	state.encounterId = nil
	state.holding = false
	destroy()
end)

RunService.Heartbeat:Connect(function(_dt)
	if not state.encounterId then return end
	local now = os.clock()
	if (now - state.lastSent) >= 0.06 then
		state.lastSent = now
		RemoteService.FireServer("RequestReelInput", {
			encounterId = state.encounterId,
			holding = state.holding,
		})
	end
end)
