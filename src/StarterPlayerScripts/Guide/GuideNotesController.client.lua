--!strict
-- Compact Guide-side list of server-owned Explorer dialog notes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local BadgeConfig = require(Modules:WaitForChild("BadgeConfig"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))

local UIBuilder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	LevelType = nil :: string?,
	Panel = nil :: Frame?,
	Notes = {} :: { any },
}

local function destroyPanel()
	if state.Panel then
		state.Panel:Destroy()
	end
	state.Panel = nil
end

local function makeLabel(parent: Instance, props): TextLabel
	local label = UIStyle.MakeLabel(props)
	label.TextScaled = true
	label.Parent = parent
	return label
end

local function badgeName(badge): string
	if typeof(badge) ~= "table" then return "Unknown" end
	return ("%s %s"):format(badge.Color or "Unknown", badge.Shape or "Unknown")
end

local function cueText(note): string
	return table.concat(note.CueLines or {}, "\n")
end

local function makeNoteRow(parent: Frame, note, order: number)
	local row = UIStyle.MakePanel({
		Size = UDim2.fromScale(1, 0.2),
		BackgroundColor3 = UIStyle.Palette.Background,
		LayoutOrder = order,
		Parent = parent,
	})
	local badge = note.Badge or {}
	local badgeBlock = UIStyle.MakePanel({
		Size = UDim2.fromScale(0.3, 0.86),
		Position = UDim2.fromScale(0.02, 0.07),
		BackgroundColor3 = BadgeConfig.Colors[badge.Color] or UIStyle.Palette.Highlight,
		Parent = row,
	})
	makeLabel(badgeBlock, {
		Size = UDim2.fromScale(1, 1),
		Text = badgeName(badge),
		TextSize = UIStyle.TextSize.Caption,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(40, 28, 16),
	})
	makeLabel(row, {
		Size = UDim2.fromScale(0.64, 0.9),
		Position = UDim2.fromScale(0.34, 0.05),
		Text = cueText(note),
		TextSize = UIStyle.TextSize.Caption,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function render()
	destroyPanel()
	if state.Role ~= RoleTypes.Guide or state.LevelType ~= LevelTypes.StrangerDangerPark then return end
	state.Panel = UIStyle.MakePanel({
		Name = "GuideExplorerNotes",
		Size = UDim2.fromScale(0.3, 0.42),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.19),
		Parent = UIBuilder.GetScreenGui(),
	})
	makeLabel(state.Panel, {
		Size = UDim2.fromScale(1, 0.12),
		Text = "Explorer Notes",
		TextSize = UIStyle.TextSize.Heading,
	})
	local list = Instance.new("Frame")
	list.Size = UDim2.fromScale(0.94, 0.82)
	list.Position = UDim2.fromScale(0.03, 0.16)
	list.BackgroundTransparency = 1
	list.Parent = state.Panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.035, 0)
	layout.Parent = list
	if #state.Notes == 0 then
		makeLabel(list, {
			Size = UDim2.fromScale(1, 0.2),
			Text = "Talked-to NPC notes will appear here.",
			TextSize = UIStyle.TextSize.Body,
			TextWrapped = true,
			TextColor3 = UIStyle.Palette.TextMuted,
		})
		return
	end
	for i = 1, math.min(#state.Notes, 4) do
		makeNoteRow(list, state.Notes[i], i)
	end
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
	if state.Role ~= RoleTypes.Guide then
		destroyPanel()
	end
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	state.RoundId = payload.RoundId
	state.Notes = {}
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	state.Notes = {}
	render()
end)

RemoteService.OnClientEvent("NpcDialogNoteAdded", function(payload)
	if state.Role ~= RoleTypes.Guide or payload.RoundId ~= state.RoundId then return end
	state.Notes = payload.Notes or {}
	render()
end)

RemoteService.OnClientEvent("LevelEnded", function()
	state.LevelType = nil
	state.Notes = {}
	destroyPanel()
end)

RemoteService.OnClientEvent("RoundEnded", function()
	state.RoundId = nil
	state.LevelType = nil
	state.Notes = {}
	destroyPanel()
end)
