--!strict
-- Tutorial overlay shown the first time a player plays BPC as Guide or
-- Explorer in their session. Server-gated by DataService.HasSeenTutorial
-- (sub-tabled). Auto-fades after 8s; player can also click Got It to
-- dismiss early.

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
	local card = UIStyle.MakePanel({
		Name = "TutorialPrompt",
		Size = UDim2.new(0, 460, 0, 160),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Parent = screen,
	})
	card.ZIndex = 180
	UIBuilder.PadLayout(card, 14)
	activeOverlay = card

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = card

	local title = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 28),
		Text = payload.Title or "Tutorial",
		TextSize = UIStyle.TextSize.Heading,
		LayoutOrder = 1,
	})
	title.ZIndex = 181
	title.Parent = card

	local body = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 60),
		Text = payload.Body or "",
		TextSize = UIStyle.TextSize.Body,
		TextWrapped = true,
		LayoutOrder = 2,
	})
	body.ZIndex = 181
	body.Parent = card

	local btn = UIStyle.MakeButton({
		Size = UDim2.new(0, 160, 0, 32),
		Text = "Got it",
		TextSize = UIStyle.TextSize.Body,
		LayoutOrder = 3,
		BackgroundColor3 = UIStyle.Palette.Accent,
	})
	btn.ZIndex = 181
	btn.Parent = card
	btn.Activated:Connect(function()
		teardown()
	end)

	activeToken += 1
	local token = activeToken
	task.delay(8, function()
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

RemoteService.OnClientEvent("TutorialPrompt", function(payload)
	if typeof(payload) ~= "table" then return end
	show(payload)
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	teardown()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	teardown()
end)
