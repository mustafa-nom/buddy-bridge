--!strict
-- Explorer-side card for inspected Stranger Danger NPCs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))
local StrangerDangerLogic = require(Modules:WaitForChild("StrangerDangerLogic"))

local UIBuilder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local currentRole = RoleTypes.None
local activeRoundId: string? = nil
local card: Frame? = nil

local function clearCard()
	if card then
		card:Destroy()
		card = nil
	end
end

local function makeLine(parent: Frame, text: string, y: number, height: number, size: number, color: Color3?)
	local label = UIStyle.MakeLabel({
		Size = UDim2.new(1, -24, 0, height),
		Position = UDim2.new(0, 12, 0, y),
		Text = text,
		TextSize = size,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = color or UIStyle.Palette.TextPrimary,
	})
	label.Parent = parent
	return label
end

local function showCard(payload)
	clearCard()
	local screen = UIBuilder.GetScreenGui()
	card = UIStyle.MakePanel({
		Name = "NpcDescriptionCard",
		Size = UDim2.new(0, 360, 0, 260),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Parent = screen,
	})

	local cue = StrangerDangerLogic.Cues[payload.Cue]
	local cueText = cue and cue.ExplorerText or "A behavior detail"
	local badge = payload.Badge or {}
	local badgeText = ("%s %s badge"):format(badge.Color or "Unknown", badge.Shape or "Unknown")
	local headline = payload.Silhouette and payload.Silhouette.Headline or "Someone in the park"

	makeLine(card :: Frame, "WHAT YOU SEE", 14, 24, UIStyle.TextSize.Caption, UIStyle.Palette.TextMuted)
	makeLine(card :: Frame, headline, 42, 54, UIStyle.TextSize.Body, nil)
	makeLine(card :: Frame, "Behavior: " .. cueText, 108, 54, UIStyle.TextSize.Body, UIStyle.Palette.Risky)
	makeLine(card :: Frame, "Badge: " .. badgeText, 174, 34, UIStyle.TextSize.Heading, UIStyle.Palette.Highlight)
	makeLine(card :: Frame, "Tell your Guide which behavior looks risky and which badge it has.", 214, 34, 14, UIStyle.Palette.TextMuted)

	task.delay(12, clearCard)
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	currentRole = payload.Role or RoleTypes.None
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	activeRoundId = payload.RoundId
end)

RemoteService.OnClientEvent("NpcDescriptionShown", function(payload)
	if currentRole ~= RoleTypes.Explorer then return end
	if payload.RoundId ~= activeRoundId then return end
	if payload.Audience ~= "Explorer" then return end
	showCard(payload)
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	clearCard()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	activeRoundId = nil
	clearCard()
end)
