--!strict
-- Pixel Post intro slide. Shows a centered overlay on level start with the
-- title + body from the server-fired `PixelPostIntro` event, fades after
-- DurationSeconds. P0 is non-gating: Wave 1 has already started server-side.
-- The P2 gated version will wait on a `RequestDismissIntro` from both clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIFolder = script.Parent
local UIBuilder = require(UIFolder:WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local activeOverlay: Frame? = nil
local activeToken = 0

local function teardown()
	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
	end
end

local function show(payload)
	teardown()
	local screen = UIBuilder.GetScreenGui()
	local overlay = Instance.new("Frame")
	overlay.Name = "PixelPostIntro"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 200
	overlay.Parent = screen
	activeOverlay = overlay

	local card = UIStyle.MakePanel({
		Name = "Card",
		Size = UDim2.new(0, 540, 0, 260),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = overlay,
	})
	card.ZIndex = 201
	UIBuilder.PadLayout(card, 18)

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = card

	local stamp = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 24),
		Text = "✉ PIXEL POST",
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = UIStyle.Palette.Highlight,
		LayoutOrder = 1,
	})
	stamp.ZIndex = 202
	stamp.Parent = card

	local title = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 36),
		Text = payload.Title or "Pixel Post: Outbound Sorting",
		TextSize = UIStyle.TextSize.Heading,
		LayoutOrder = 2,
	})
	title.ZIndex = 202
	title.Parent = card

	local body = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 80),
		Text = payload.Body or "First shift! Talk to your buddy.",
		TextSize = UIStyle.TextSize.Body,
		TextWrapped = true,
		LayoutOrder = 3,
	})
	body.ZIndex = 202
	body.Parent = card

	-- Continue button — appears after SkippableAfterSeconds. Firing
	-- RequestDismissIntro lets the server lift the Wave-1 gate as soon as
	-- both players click.
	local continueBtn = UIStyle.MakeButton({
		Size = UDim2.new(0, 220, 0, 40),
		Text = "Continue",
		TextSize = UIStyle.TextSize.Body,
		LayoutOrder = 4,
		Visible = false,
		BackgroundColor3 = UIStyle.Palette.Accent,
	})
	continueBtn.ZIndex = 202
	continueBtn.Parent = card
	local clicked = false
	continueBtn.Activated:Connect(function()
		if clicked then return end
		clicked = true
		RemoteService.FireServer("RequestDismissIntro")
		continueBtn.Text = "Waiting for buddy…"
		continueBtn.AutoButtonColor = false
	end)

	activeToken += 1
	local token = activeToken
	local skippableAfter = tonumber(payload.SkippableAfterSeconds) or 3
	task.delay(skippableAfter, function()
		if token ~= activeToken then return end
		if continueBtn and continueBtn.Parent then
			continueBtn.Visible = true
		end
	end)
	-- Auto-dismiss safety net so the slide doesn't sit forever; the server
	-- has its own gate timeout that starts Wave 1 regardless.
	local duration = tonumber(payload.DurationSeconds) or 5
	local autoFadeAfter = math.max(duration, skippableAfter + 25)
	task.delay(autoFadeAfter, function()
		if token ~= activeToken then return end
		if not activeOverlay or not activeOverlay.Parent then return end
		local fadeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(activeOverlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		task.delay(0.4, function()
			if token ~= activeToken then return end
			teardown()
		end)
	end)
end

RemoteService.OnClientEvent("PixelPostIntro", function(payload)
	if typeof(payload) ~= "table" then return end
	show(payload)
end)

-- Wave 1 starting means the gate has been satisfied. Tear down the overlay
-- immediately so the player isn't staring at a slide while items spawn.
RemoteService.OnClientEvent("WaveStarted", function(payload)
	if typeof(payload) == "table" and payload.WaveIndex == 1 then
		teardown()
	end
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	teardown()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	teardown()
end)
