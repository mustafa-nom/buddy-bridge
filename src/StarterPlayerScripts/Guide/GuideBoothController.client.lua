--!strict
-- Guide booth slot picker UI for Stranger Danger Park.

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
	Picker = nil :: Frame?,
	SlotIndex = nil :: number?,
	Color = nil :: string?,
	Shape = nil :: string?,
	Display = nil :: Frame?,
	SlotLabels = {} :: { TextLabel },
	AttemptsLabel = nil :: TextLabel?,
}

local function closePicker()
	if state.Picker then
		state.Picker:Destroy()
		state.Picker = nil
	end
	state.SlotIndex = nil
end

local function destroyDisplay()
	if state.Display then
		state.Display:Destroy()
		state.Display = nil
	end
	state.SlotLabels = {}
	state.AttemptsLabel = nil
end

local function ensureDisplay()
	if state.Display then
		return
	end
	state.Display = UIStyle.MakePanel({
		Name = "BoothSlotDisplay",
		Size = UDim2.new(0, 430, 0, 110),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -112),
		Parent = UIBuilder.GetScreenGui(),
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = state.Display
	UIBuilder.PadLayout(state.Display, 8)

	for i = 1, 3 do
		local label = UIStyle.MakeLabel({
			Size = UDim2.new(0, 92, 1, 0),
			Text = ("Slot %d\nEmpty"):format(i),
			TextSize = UIStyle.TextSize.Caption,
			TextWrapped = true,
			BackgroundTransparency = 0,
			BackgroundColor3 = UIStyle.Palette.Panel,
		})
		UIStyle.ApplyCorner(label, UIStyle.SmallCorner)
		UIStyle.ApplyStroke(label)
		label.Parent = state.Display
		state.SlotLabels[i] = label
	end
	state.AttemptsLabel = UIStyle.MakeLabel({
		Size = UDim2.new(0, 96, 1, 0),
		Text = "3 tries\nSubmit pad",
		TextSize = UIStyle.TextSize.Caption,
		TextWrapped = true,
	})
	state.AttemptsLabel.Parent = state.Display
end

local function renderBoothState(payload)
	if state.Role ~= RoleTypes.Guide or state.LevelType ~= LevelTypes.StrangerDangerPark then
		return
	end
	ensureDisplay()
	local boothState = payload.BoothState or {}
	for i = 1, 3 do
		local slot = boothState.Slots and boothState.Slots[i] or {}
		local label = state.SlotLabels[i]
		if label then
			local badge = slot.Color and slot.Shape and (slot.Color .. "\n" .. slot.Shape) or "Empty"
			label.Text = ("Slot %d\n%s"):format(i, badge)
			label.BackgroundColor3 = slot.Status == "Correct" and UIStyle.Palette.Safe
				or slot.Status == "Wrong" and UIStyle.Palette.Risky
				or UIStyle.Palette.Panel
		end
	end
	if state.AttemptsLabel then
		state.AttemptsLabel.Text = ("%d tries\nSubmit pad"):format(payload.AttemptsLeft or 0)
	end
end

local function makeChoice(parent: Frame, label: string, color: Color3?, onClick: () -> ())
	local button = UIStyle.MakeButton({
		Size = UDim2.new(0, 92, 0, 42),
		Text = label,
		TextSize = UIStyle.TextSize.Body,
		BackgroundColor3 = color or UIStyle.Palette.Panel,
	})
	button.Parent = parent
	button.Activated:Connect(onClick)
	return button
end

local function makeRow(parent: Frame, y: number): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -24, 0, 46)
	row.Position = UDim2.new(0, 12, 0, y)
	row.BackgroundTransparency = 1
	row.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.Parent = row
	return row
end

local function openPicker(payload)
	closePicker()
	state.SlotIndex = payload.SlotIndex
	local current = payload.Current or {}
	state.Color = current.Color or BadgeConfig.ColorOrder[1]
	state.Shape = current.Shape or BadgeConfig.ShapeOrder[1]

	state.Picker = UIStyle.MakePanel({
		Name = "BoothSlotPicker",
		Size = UDim2.new(0, 430, 0, 300),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Parent = UIBuilder.GetScreenGui(),
	})

	local title = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 12),
		Text = ("Slot %d Badge"):format(state.SlotIndex or 1),
		TextSize = UIStyle.TextSize.Heading,
	})
	title.Parent = state.Picker

	local colorRow = makeRow(state.Picker :: Frame, 64)
	for _, colorName in ipairs(BadgeConfig.ColorOrder) do
		makeChoice(colorRow, colorName, BadgeConfig.Colors[colorName], function()
			state.Color = colorName
		end)
	end

	local shapeRow = makeRow(state.Picker :: Frame, 126)
	for _, shapeName in ipairs(BadgeConfig.ShapeOrder) do
		makeChoice(shapeRow, shapeName, nil, function()
			state.Shape = shapeName
		end)
	end

	local confirm = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -18, 0, 52),
		Position = UDim2.new(0, 12, 1, -64),
		Text = "Confirm",
		BackgroundColor3 = UIStyle.Palette.Safe,
		Parent = state.Picker,
	})
	confirm.Activated:Connect(function()
		if state.SlotIndex and state.Color and state.Shape then
			RemoteService.FireServer("RequestSetSlotBadge", {
				SlotIndex = state.SlotIndex,
				Color = state.Color,
				Shape = state.Shape,
			})
		end
		closePicker()
	end)

	local cancel = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -18, 0, 52),
		Position = UDim2.new(0.5, 6, 1, -64),
		Text = "Cancel",
		Parent = state.Picker,
	})
	cancel.Activated:Connect(closePicker)
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload.Role or RoleTypes.None
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	state.RoundId = payload.RoundId
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	closePicker()
	if state.LevelType ~= LevelTypes.StrangerDangerPark then
		destroyDisplay()
	end
end)

RemoteService.OnClientEvent("OpenSlotPicker", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	if payload.RoundId ~= state.RoundId then return end
	if state.LevelType ~= LevelTypes.StrangerDangerPark then return end
	openPicker(payload)
end)

RemoteService.OnClientEvent("BoothStateUpdated", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	renderBoothState(payload)
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	closePicker()
	destroyDisplay()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.RoundId = nil
	state.LevelType = nil
	closePicker()
	destroyDisplay()
end)
