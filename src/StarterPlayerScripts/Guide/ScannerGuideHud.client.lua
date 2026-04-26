--!strict
-- Backpack Checkpoint Active Scanner Guide HUD.
--
-- Replaces the old BPC annotation buttons with the PRD's workstation:
--   * X-ray feed of the active belt item (label + scan tags if revealed)
--   * Highlight buttons (Green / Yellow / Red rings)
--   * Lane Unlock toggles (Pack / Ask / Leave)
--   * Scan button with scans-left counter
--   * Veto button (one charge per round)
--   * Wave + Mini-Boss banner
--
-- Only shown for the Guide while the active level is Backpack Checkpoint.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))
local ItemRegistry = require(Modules:WaitForChild("ItemRegistry"))

local UIFolder = script.Parent.Parent:WaitForChild("UI")
local UIBuilder = require(UIFolder:WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local state = {
	Role = RoleTypes.None,
	RoundId = nil :: string?,
	LevelType = nil :: string?,
	WaveIndex = 0,
	ScansAllowed = 0,
	ScansUsed = 0,
	VetoUsed = false,
	VetoActive = false,
	ActiveItem = nil :: { Id: string, Label: string, ScanTags: { string }? }?,
	LaneLocks = {
		[ItemRegistry.Lanes.PackIt] = true,
		[ItemRegistry.Lanes.AskFirst] = true,
		[ItemRegistry.Lanes.LeaveIt] = true,
	},
	HighlightColor = nil :: string?,
	MiniBossActive = false,
	MiniBossInnerIndex = 0,
	MiniBossInnerCount = 0,
}

local panel: Frame? = nil
local refs: { [string]: any } = {}

local function teardown()
	if panel then
		panel:Destroy()
		panel = nil
	end
	refs = {}
end

local LANE_ORDER = { ItemRegistry.Lanes.PackIt, ItemRegistry.Lanes.AskFirst, ItemRegistry.Lanes.LeaveIt }

local function laneColor(lane: string): Color3
	local theme = ItemRegistry.LaneTheme[lane]
	return theme and theme.Color or UIStyle.Palette.Accent
end

local function refresh()
	if not panel or not refs.ItemLabel then return end
	-- X-ray feed.
	if state.MiniBossActive then
		refs.ItemLabel.Text = string.format(
			"⭐ MINI-BOSS — inner %d / %d\n%s",
			state.MiniBossInnerIndex,
			state.MiniBossInnerCount,
			state.ActiveItem and state.ActiveItem.Label or ""
		)
	elseif state.ActiveItem then
		refs.ItemLabel.Text = state.ActiveItem.Label
	else
		refs.ItemLabel.Text = "Belt clear — wait for next item"
	end

	if refs.ScanTagsLabel then
		if state.ActiveItem and state.ActiveItem.ScanTags and #state.ActiveItem.ScanTags > 0 then
			refs.ScanTagsLabel.Text = "🔍 " .. table.concat(state.ActiveItem.ScanTags, " · ")
		else
			refs.ScanTagsLabel.Text = "🔍 (scan to reveal hidden tags)"
		end
	end

	if refs.WaveLabel then
		if state.MiniBossActive then
			refs.WaveLabel.Text = "VIP BAG"
		elseif state.WaveIndex > 0 then
			refs.WaveLabel.Text = string.format("Wave %d", state.WaveIndex)
		else
			refs.WaveLabel.Text = ""
		end
	end

	if refs.ScansLabel then
		refs.ScansLabel.Text = string.format("Scans: %d / %d", state.ScansAllowed - state.ScansUsed, state.ScansAllowed)
	end

	if refs.VetoButton then
		refs.VetoButton.AutoButtonColor = not state.VetoUsed and not state.VetoActive
		refs.VetoButton.Text = state.VetoUsed and "✖ VETO USED" or (state.VetoActive and "⏳ VETO ACTIVE" or "⛔ VETO")
		refs.VetoButton.BackgroundColor3 = (state.VetoUsed or state.VetoActive)
			and UIStyle.Palette.PanelStroke
			or UIStyle.Palette.Risky
	end

	for _, lane in ipairs(LANE_ORDER) do
		local btn = refs.LaneButtons and refs.LaneButtons[lane]
		if btn then
			local locked = state.LaneLocks[lane]
			local theme = ItemRegistry.LaneTheme[lane]
			btn.Text = (locked and "🔒 " or "🔓 ") .. (theme and theme.Label or lane)
			btn.BackgroundColor3 = locked and UIStyle.Palette.PanelStroke or laneColor(lane)
		end
	end

	if refs.HighlightRow then
		for _, color in ipairs({ "Green", "Yellow", "Red" }) do
			local btn = refs.HighlightButtons and refs.HighlightButtons[color]
			if btn then
				btn.AutoButtonColor = state.ActiveItem ~= nil
				if state.HighlightColor == color then
					btn.BackgroundColor3 = UIStyle.Palette.Highlight
				else
					if color == "Green" then btn.BackgroundColor3 = UIStyle.Palette.Safe
					elseif color == "Yellow" then btn.BackgroundColor3 = UIStyle.Palette.AskFirst
					else btn.BackgroundColor3 = UIStyle.Palette.Risky
					end
				end
			end
		end
	end
end

local function buildPanel()
	if state.Role ~= RoleTypes.Guide then teardown() return end
	if state.LevelType ~= LevelTypes.BackpackCheckpoint then teardown() return end
	if panel then return end

	local screen = UIBuilder.GetScreenGui()
	panel = UIStyle.MakePanel({
		Name = "ScannerGuideHud",
		Size = UDim2.new(0, 460, 0, 320),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Parent = screen,
	})
	UIBuilder.PadLayout(panel :: Frame, 12)

	local rootLayout = Instance.new("UIListLayout")
	rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rootLayout.Padding = UDim.new(0, 8)
	rootLayout.Parent = panel

	-- Header row: wave + scans + veto used.
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 28)
	header.BackgroundTransparency = 1
	header.LayoutOrder = 1
	header.Parent = panel
	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.Padding = UDim.new(0, 12)
	headerLayout.Parent = header

	refs.WaveLabel = UIStyle.MakeLabel({
		Size = UDim2.new(0, 110, 1, 0),
		Text = "",
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = UIStyle.Palette.Accent,
	})
	refs.WaveLabel.Parent = header

	refs.ScansLabel = UIStyle.MakeLabel({
		Size = UDim2.new(0, 160, 1, 0),
		Text = "",
		TextSize = UIStyle.TextSize.Body,
	})
	refs.ScansLabel.Parent = header

	-- X-ray feed.
	local feed = UIStyle.MakePanel({
		Size = UDim2.new(1, 0, 0, 96),
		LayoutOrder = 2,
	})
	feed.Parent = panel
	UIBuilder.PadLayout(feed :: Frame, 10)
	local feedLayout = Instance.new("UIListLayout")
	feedLayout.SortOrder = Enum.SortOrder.LayoutOrder
	feedLayout.Padding = UDim.new(0, 4)
	feedLayout.Parent = feed
	refs.ItemLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 36),
		Text = "Belt clear — wait for next item",
		TextSize = UIStyle.TextSize.Heading,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	refs.ItemLabel.Parent = feed
	refs.ScanTagsLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 32),
		Text = "🔍 (scan to reveal hidden tags)",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
		TextWrapped = true,
		LayoutOrder = 2,
	})
	refs.ScanTagsLabel.Parent = feed

	-- Highlight row.
	refs.HighlightRow = Instance.new("Frame")
	refs.HighlightRow.Size = UDim2.new(1, 0, 0, 36)
	refs.HighlightRow.BackgroundTransparency = 1
	refs.HighlightRow.LayoutOrder = 3
	refs.HighlightRow.Parent = panel
	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hLayout.Padding = UDim.new(0, 8)
	hLayout.Parent = refs.HighlightRow
	refs.HighlightButtons = {}
	for _, color in ipairs({ "Green", "Yellow", "Red" }) do
		local btn = UIStyle.MakeButton({
			Size = UDim2.new(0, 130, 1, 0),
			Text = (color == "Green" and "✅ " or color == "Yellow" and "⚠️ " or "⛔ ") .. color,
			TextSize = UIStyle.TextSize.Body,
		})
		btn.Parent = refs.HighlightRow
		refs.HighlightButtons[color] = btn
		btn.Activated:Connect(function()
			if state.ActiveItem then
				RemoteService.FireServer("RequestHighlightItem", state.ActiveItem.Id, color)
			end
		end)
	end

	-- Lane unlock row.
	local laneRow = Instance.new("Frame")
	laneRow.Size = UDim2.new(1, 0, 0, 36)
	laneRow.BackgroundTransparency = 1
	laneRow.LayoutOrder = 4
	laneRow.Parent = panel
	local lLayout = Instance.new("UIListLayout")
	lLayout.FillDirection = Enum.FillDirection.Horizontal
	lLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lLayout.Padding = UDim.new(0, 8)
	lLayout.Parent = laneRow
	refs.LaneButtons = {}
	for _, lane in ipairs(LANE_ORDER) do
		local btn = UIStyle.MakeButton({
			Size = UDim2.new(0, 130, 1, 0),
			Text = lane,
			TextSize = UIStyle.TextSize.Body,
			BackgroundColor3 = laneColor(lane),
		})
		btn.Parent = laneRow
		refs.LaneButtons[lane] = btn
		btn.Activated:Connect(function()
			RemoteService.FireServer("RequestUnlockLane", lane)
		end)
	end

	-- Scan + Veto row.
	local actionRow = Instance.new("Frame")
	actionRow.Size = UDim2.new(1, 0, 0, 40)
	actionRow.BackgroundTransparency = 1
	actionRow.LayoutOrder = 5
	actionRow.Parent = panel
	local aLayout = Instance.new("UIListLayout")
	aLayout.FillDirection = Enum.FillDirection.Horizontal
	aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	aLayout.Padding = UDim.new(0, 8)
	aLayout.Parent = actionRow
	refs.ScanButton = UIStyle.MakeButton({
		Size = UDim2.new(0, 160, 1, 0),
		Text = "🔍 SCAN",
		TextSize = UIStyle.TextSize.Body,
		BackgroundColor3 = UIStyle.Palette.Accent,
	})
	refs.ScanButton.Parent = actionRow
	refs.ScanButton.Activated:Connect(function()
		if state.ActiveItem then
			RemoteService.FireServer("RequestScanItem", state.ActiveItem.Id)
		end
	end)
	refs.VetoButton = UIStyle.MakeButton({
		Size = UDim2.new(0, 160, 1, 0),
		Text = "⛔ VETO",
		TextSize = UIStyle.TextSize.Body,
		BackgroundColor3 = UIStyle.Palette.Risky,
	})
	refs.VetoButton.Parent = actionRow
	refs.VetoButton.Activated:Connect(function()
		if state.VetoUsed or state.VetoActive then return end
		RemoteService.FireServer("RequestVeto")
	end)

	refresh()
end

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	state.Role = payload and payload.Role or RoleTypes.None
	buildPanel()
end)

RemoteService.OnClientEvent("RoundStarted", function(payload)
	if typeof(payload) ~= "table" then return end
	state.RoundId = payload.RoundId
	state.VetoUsed = false
	state.VetoActive = false
	state.MiniBossActive = false
end)

RemoteService.OnClientEvent("LevelStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.LevelType = payload.LevelType
	state.WaveIndex = 0
	state.ScansAllowed = 0
	state.ScansUsed = 0
	state.ActiveItem = nil
	state.HighlightColor = nil
	buildPanel()
end)

RemoteService.OnClientEvent("WaveStarted", function(payload)
	if payload.RoundId ~= state.RoundId then return end
	state.WaveIndex = payload.WaveIndex or 0
	state.ScansAllowed = payload.ScansAllowed or 0
	state.ScansUsed = 0
	refresh()
end)

RemoteService.OnClientEvent("ConveyorItemSpawned", function(payload)
	if state.Role ~= RoleTypes.Guide then return end
	state.ActiveItem = {
		Id = payload.ItemId,
		Label = payload.DisplayLabel or payload.ItemKey or "?",
		ScanTags = nil,
	}
	state.HighlightColor = nil
	state.LaneLocks[ItemRegistry.Lanes.PackIt] = true
	state.LaneLocks[ItemRegistry.Lanes.AskFirst] = true
	state.LaneLocks[ItemRegistry.Lanes.LeaveIt] = true
	refresh()
end)

RemoteService.OnClientEvent("ScannerOverlayUpdated", function(payload)
	if state.ActiveItem and payload.ItemId == state.ActiveItem.Id then
		state.ActiveItem.ScanTags = payload.Tags
	end
	state.ScansUsed = payload.ScansUsedThisWave or state.ScansUsed
	state.ScansAllowed = payload.ScansAllowedThisWave or state.ScansAllowed
	refresh()
end)

RemoteService.OnClientEvent("HighlightUpdated", function(payload)
	if state.ActiveItem and payload.ItemId == state.ActiveItem.Id then
		state.HighlightColor = payload.Color
	elseif not payload.ItemId then
		state.HighlightColor = nil
	end
	refresh()
end)

RemoteService.OnClientEvent("LaneLockUpdated", function(payload)
	if typeof(payload.LaneLocks) == "table" then
		for k, v in pairs(payload.LaneLocks) do
			state.LaneLocks[k] = v == true
		end
	end
	refresh()
end)

RemoteService.OnClientEvent("VetoActivated", function(_payload)
	state.VetoUsed = true
	state.VetoActive = true
	refresh()
end)

RemoteService.OnClientEvent("VetoEnded", function(_payload)
	state.VetoActive = false
	refresh()
end)

RemoteService.OnClientEvent("MiniBossStarted", function(payload)
	state.MiniBossActive = true
	state.MiniBossInnerIndex = 0
	state.MiniBossInnerCount = payload and payload.InnerCount or 0
	refresh()
end)

RemoteService.OnClientEvent("MiniBossInnerActivated", function(payload)
	state.MiniBossInnerIndex = payload and payload.InnerIndex or state.MiniBossInnerIndex
	refresh()
end)

RemoteService.OnClientEvent("MiniBossEnded", function(_payload)
	state.MiniBossActive = false
	state.MiniBossInnerIndex = 0
	state.MiniBossInnerCount = 0
	refresh()
end)

RemoteService.OnClientEvent("LevelEnded", function(_payload)
	state.LevelType = nil
	state.ActiveItem = nil
	teardown()
end)

RemoteService.OnClientEvent("RoundEnded", function(_payload)
	state.Role = RoleTypes.None
	state.RoundId = nil
	state.LevelType = nil
	state.ActiveItem = nil
	teardown()
end)
