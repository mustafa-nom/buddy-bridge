--!strict
-- Dialog-style Explorer interaction for Stranger Danger NPCs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local BadgeConfig = require(Modules:WaitForChild("BadgeConfig"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local UIBuilder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local currentRole = RoleTypes.None
local activeRoundId: string? = nil
local dialog: Frame? = nil

local function clearDialog()
	if dialog then
		dialog:Destroy()
	end
	dialog = nil
end

local function addPad(parent: Instance, amount: number)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(amount, 0)
	pad.PaddingBottom = UDim.new(amount, 0)
	pad.PaddingLeft = UDim.new(amount, 0)
	pad.PaddingRight = UDim.new(amount, 0)
	pad.Parent = parent
end

local function makeText(parent: Instance, props): TextLabel
	local label = UIStyle.MakeLabel(props)
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function badgeText(badge): string
	if typeof(badge) ~= "table" then return "Unknown badge" end
	return ("%s %s badge"):format(badge.Color or "Unknown", badge.Shape or "Unknown")
end

local function showDialog(payload)
	clearDialog()
	dialog = UIStyle.MakePanel({
		Name = "NpcDialogPanel",
		Size = UDim2.fromScale(0.42, 0.48),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.97, 0.94),
		Parent = UIBuilder.GetScreenGui(),
	})
	addPad(dialog :: Frame, 0.035)

	makeText(dialog :: Frame, {
		Size = UDim2.fromScale(1, 0.1),
		Text = "Talk",
		TextSize = UIStyle.TextSize.Heading,
		TextColor3 = UIStyle.Palette.TextMuted,
	})

	local speech = UIStyle.MakePanel({
		Size = UDim2.fromScale(1, 0.32),
		Position = UDim2.fromScale(0, 0.13),
		BackgroundColor3 = UIStyle.Palette.Background,
		Parent = dialog,
	})
	makeText(speech, {
		Size = UDim2.fromScale(0.92, 0.86),
		Position = UDim2.fromScale(0.04, 0.07),
		Text = "NPC: " .. (payload.NpcLine or "Hi there."),
		TextSize = UIStyle.TextSize.Body,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local badge = payload.Badge or {}
	local badgePill = UIStyle.MakePanel({
		Size = UDim2.fromScale(1, 0.1),
		Position = UDim2.fromScale(0, 0.48),
		BackgroundColor3 = BadgeConfig.Colors[badge.Color] or UIStyle.Palette.Highlight,
		Parent = dialog,
	})
	makeText(badgePill, {
		Size = UDim2.fromScale(1, 1),
		Text = badgeText(badge),
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = Color3.fromRGB(40, 28, 16),
	})

	local choices = Instance.new("Frame")
	choices.Size = UDim2.fromScale(1, 0.36)
	choices.Position = UDim2.fromScale(0, 0.61)
	choices.BackgroundTransparency = 1
	choices.Parent = dialog
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.06, 0)
	layout.Parent = choices

	for i, choice in ipairs(payload.Choices or {}) do
		local button = UIStyle.MakeButton({
			Size = UDim2.fromScale(1, 0.28),
			Text = choice.Text or "Say hi.",
			TextSize = UIStyle.TextSize.Body,
			TextWrapped = true,
			LayoutOrder = i,
			Parent = choices,
		})
		button.Activated:Connect(function()
			RemoteService.FireServer("RequestNpcDialogChoice", {
				NpcId = payload.NpcId,
				ChoiceId = choice.Id,
			})
			clearDialog()
		end)
	end
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	currentRole = payload.Role or RoleTypes.None
	if currentRole ~= RoleTypes.Explorer then
		clearDialog()
	end
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	activeRoundId = payload.RoundId
end)

RemoteService.OnClientEvent("OpenNpcDialog", function(payload)
	if currentRole ~= RoleTypes.Explorer then return end
	if payload.RoundId ~= activeRoundId then return end
	showDialog(payload)
end)

RemoteService.OnClientEvent("LevelEnded", clearDialog)
RemoteService.OnClientEvent("RoundEnded", function()
	activeRoundId = nil
	clearDialog()
end)
