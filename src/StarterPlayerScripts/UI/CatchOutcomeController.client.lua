--!strict
-- Catch resolution panel. Animates pearls/XP counters, color-codes by
-- rarity, surfaces streak + lucky-bobber + multiplier breakdown, and
-- prompts the player to place kindness fish in the aquarium.

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
local activeFrame: Frame? = nil
local activeFishId: string? = nil

local function close()
	if activeFrame then activeFrame:Destroy() end
	activeFrame = nil
	activeFishId = nil
end

local function rarityColor(rarity: string?): Color3
	if rarity == "Legendary" then return Color3.fromRGB(255, 200, 80) end
	if rarity == "Epic" then return Color3.fromRGB(220, 130, 250) end
	if rarity == "Rare" then return Color3.fromRGB(120, 200, 255) end
	return Color3.fromRGB(220, 220, 220)
end

local function animateNumber(label: TextLabel, target: number, prefix: string, suffix: string?, duration: number?)
	local dur = duration or 0.7
	local started = os.clock()
	local startedConn
	startedConn = RunService.Heartbeat:Connect(function()
		if not label or not label.Parent then
			startedConn:Disconnect()
			return
		end
		local elapsed = os.clock() - started
		local t = math.clamp(elapsed / dur, 0, 1)
		local ease = 1 - (1 - t) ^ 3
		local value = math.floor(target * ease)
		label.Text = prefix .. tostring(value) .. (suffix or "")
		if t >= 1 then
			label.Text = prefix .. tostring(target) .. (suffix or "")
			startedConn:Disconnect()
		end
	end)
end

RemoteService.OnClientEvent("CatchResolved", function(payload)
	if typeof(payload) ~= "table" then return end
	close()
	activeFishId = payload.FishId

	local headerColor = payload.WasCorrect
		and (rarityColor(payload.Rarity))
		or UIStyle.Palette.Risky

	local frame = UIStyle.MakePanel({
		Name = "CatchOutcomeFrame",
		Size = UDim2.new(0, 520, 0, 280),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		BackgroundColor3 = UIStyle.Palette.Panel,
		Parent = screen,
	})
	activeFrame = frame

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 70)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = headerColor
	header.BorderSizePixel = 0
	header.Parent = frame
	UIStyle.ApplyCorner(header)

	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 30),
		Position = UDim2.new(0, 8, 0, 6),
		Text = payload.DisplayName or "Fish",
		TextSize = UIStyle.TextSize.Title,
		TextColor3 = Color3.fromRGB(40, 28, 16),
		Parent = header,
	})
	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 38),
		Text = ("%s • %s"):format(tostring(payload.Category), tostring(payload.Rarity)),
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = Color3.fromRGB(50, 36, 22),
		Parent = header,
	})

	UIStyle.MakeLabel({
		Size = UDim2.new(1, -16, 0, 56),
		Position = UDim2.new(0, 8, 0, 80),
		Text = payload.LessonLine or "",
		TextSize = UIStyle.TextSize.Body,
		TextWrapped = true,
		Parent = frame,
	})

	if payload.WasCorrect and payload.Pearls and payload.Pearls > 0 then
		local pearlsLabel = UIStyle.MakeLabel({
			Size = UDim2.new(0, 240, 0, 24),
			Position = UDim2.new(0, 12, 0, 142),
			Text = "+0 pearls",
			TextSize = UIStyle.TextSize.Heading,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})
		animateNumber(pearlsLabel, payload.Pearls, "+", " pearls", 0.7)

		local xpLabel = UIStyle.MakeLabel({
			Size = UDim2.new(0, 220, 0, 24),
			Position = UDim2.new(1, -232, 0, 142),
			Text = "+0 XP",
			TextSize = UIStyle.TextSize.Heading,
			TextColor3 = UIStyle.Palette.Highlight,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = frame,
		})
		animateNumber(xpLabel, payload.Xp or 0, "+", " XP", 0.6)

		local mults = payload.Multipliers or {}
		local breakdown = {}
		if (mults.streak or 1) > 1 then
			table.insert(breakdown, ("streak ×%.1f"):format(mults.streak))
		end
		if (mults.lucky or 1) > 1 then
			table.insert(breakdown, "LUCKY ×2")
		end
		if (mults.reel or 1) > 1.0 then
			table.insert(breakdown, ("reel ×%.2f"):format(mults.reel))
		end
		if #breakdown > 0 then
			UIStyle.MakeLabel({
				Size = UDim2.new(1, -16, 0, 20),
				Position = UDim2.new(0, 8, 0, 168),
				Text = table.concat(breakdown, "  •  "),
				TextSize = UIStyle.TextSize.Caption,
				TextColor3 = UIStyle.Palette.Accent,
				Parent = frame,
			})
		end
	end

	if payload.Streak and payload.Streak >= 3 and payload.WasCorrect then
		local burst = UIStyle.MakeLabel({
			Size = UDim2.new(0, 200, 0, 32),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 196),
			Text = ("STREAK x%d"):format(payload.Streak),
			TextSize = UIStyle.TextSize.Heading,
			TextColor3 = Color3.fromRGB(255, 90, 60),
			Parent = frame,
		})
		burst.TextScaled = false
		TweenService:Create(burst, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 240, 0, 38),
		}):Play()
	end

	if payload.AquariumPromptable then
		local btn = UIStyle.MakeButton({
			Size = UDim2.new(0, 220, 0, 40),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Text = "Place in Aquarium",
			BackgroundColor3 = UIStyle.Palette.Highlight,
			Parent = frame,
		})
		btn.Activated:Connect(function()
			if activeFishId then
				RemoteService.FireServer("RequestPlaceFishInAquarium", { fishId = activeFishId })
			end
			close()
		end)
		task.delay(8, function()
			if activeFrame == frame then close() end
		end)
		return
	end

	if payload.Nudge then
		UIStyle.MakeLabel({
			Size = UDim2.new(1, -16, 0, 22),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Text = payload.Nudge,
			TextSize = UIStyle.TextSize.Caption,
			TextColor3 = UIStyle.Palette.TextMuted,
			Parent = frame,
		})
	end

	task.delay(4, function()
		if activeFrame == frame then close() end
	end)
end)
