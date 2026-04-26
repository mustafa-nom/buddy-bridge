--!strict
-- Renders the inspection card on ShowInspectionCard. Two big buttons: KEEP
-- (legit) and CUT BAIT (phish). Submitting fires SubmitDecision; the card
-- stays up briefly after submit so the result panel can take over.
--
-- Layout is scale-based + anchored so the buttons stay glued to the bottom
-- edge of the card on any screen aspect ratio. Body content scrolls if the
-- email is longer than the visible area.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local UIStyle = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStyle"))
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()
local guiParent = screen.Parent  -- PlayerGui — the card lives here, not in PhishUI

-- Roblox's Backpack hotbar lives in CoreGui and renders above custom GUIs;
-- on shorter screens its tool slots overlap the bottom of the inspection
-- card and intercept clicks on KEEP / CUT BAIT. Hide it while the card is
-- up and restore it when the decision result clears.
local function setBackpackHidden(hidden: boolean)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, not hidden)
	end)
end

local function clearOld()
	local old = guiParent and guiParent:FindFirstChild("PhishInspectionCard")
	if old then old:Destroy() end
end

local function colorAvatar(color: Color3?): Color3
	return color or Color3.fromRGB(120, 120, 120)
end

local CARD_WIDTH_FRACTION = 0.46     -- of screen width
local CARD_HEIGHT_FRACTION = 0.78    -- of screen height
local CARD_MIN_WIDTH = 460
local CARD_MIN_HEIGHT = 460

local function renderCard(card: any)
	clearOld()
	if type(card) ~= "table" then return end

	-- Use a dedicated ScreenGui above the regular HUD so nothing can cover it.
	local cardGui = Instance.new("ScreenGui")
	cardGui.Name = "PhishInspectionCard"
	cardGui.ResetOnSpawn = false
	cardGui.IgnoreGuiInset = true
	cardGui.DisplayOrder = 50
	cardGui.Parent = screen.Parent
	setBackpackHidden(true)

	local panel = UIStyle.MakePanel({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(CARD_WIDTH_FRACTION, CARD_HEIGHT_FRACTION),
		BackgroundColor3 = UIStyle.Palette.Background,
	})
	-- Clamp to a sensible minimum so the card stays usable on small screens.
	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(CARD_MIN_WIDTH, CARD_MIN_HEIGHT)
	sizeConstraint.MaxSize = Vector2.new(640, 720)
	sizeConstraint.Parent = panel
	panel.Parent = cardGui

	-- Header row: avatar + sender name + sender address.
	local senderRow = Instance.new("Frame")
	senderRow.Name = "Sender"
	senderRow.Size = UDim2.new(1, -32, 0, 56)
	senderRow.Position = UDim2.fromOffset(16, 12)
	senderRow.BackgroundTransparency = 1
	senderRow.Parent = panel

	local avatar = Instance.new("Frame")
	avatar.Size = UDim2.fromOffset(48, 48)
	avatar.Position = UDim2.fromOffset(0, 4)
	avatar.BackgroundColor3 = colorAvatar(card.sender and card.sender.avatarColor)
	avatar.BorderSizePixel = 0
	avatar.Parent = senderRow
	UIStyle.ApplyCorner(avatar, UDim.new(1, 0))

	local senderName = UIStyle.MakeLabel({
		Size = UDim2.new(1, -64, 0, 24),
		Position = UDim2.fromOffset(64, 0),
		Text = (card.sender and card.sender.name) or "(unknown)",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Heading,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	senderName.Parent = senderRow

	local senderAddr = UIStyle.MakeLabel({
		Size = UDim2.new(1, -64, 0, 18),
		Position = UDim2.fromOffset(64, 26),
		Text = (card.sender and card.sender.address) or "",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	senderAddr.Parent = senderRow

	-- Subject below the header.
	local subjectLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, -32, 0, 32),
		Position = UDim2.fromOffset(16, 76),
		Text = card.subject or "",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Heading,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	subjectLabel.Parent = panel

	-- Scrollable body + links. Bottom is reserved for the decision buttons
	-- via the AnchorPoint trick below.
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "BodyScroll"
	scroll.AnchorPoint = Vector2.new(0, 0)
	scroll.Position = UDim2.new(0, 16, 0, 116)
	scroll.Size = UDim2.new(1, -32, 1, -116 - 96)   -- leave 96px at bottom for buttons
	scroll.BackgroundColor3 = UIStyle.Palette.Panel
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel
	UIStyle.ApplyCorner(scroll, UDim.new(0, 12))

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = scroll

	local bodyLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 0),     -- height grows with AutomaticSize
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = card.body or "",
		Font = Enum.Font.RobotoMono,
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = UIStyle.Palette.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 1,
	})
	bodyLabel.Parent = scroll

	if card.links and #card.links > 0 then
		for i, link in ipairs(card.links) do
			local linkPanel = UIStyle.MakePanel({
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = UIStyle.Palette.Highlight,
				LayoutOrder = 1 + i,
			})
			linkPanel.Parent = scroll
			local linkLabel = UIStyle.MakeLabel({
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				Text = string.format("link: %s  →  %s", link.displayText or "(link)", link.trueUrl or ""),
				TextSize = UIStyle.TextSize.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = false,
			})
			linkLabel.Parent = linkPanel
		end
	end

	-- Decision buttons — anchored to the bottom edge of the card so they're
	-- always visible regardless of body length.
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.AnchorPoint = Vector2.new(0.5, 1)
	buttonRow.Position = UDim2.new(0.5, 0, 1, -16)
	buttonRow.Size = UDim2.new(1, -32, 0, 64)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = panel

	local function submit(decision: string, btn: TextButton, twin: TextButton)
		btn.Active = false
		btn.AutoButtonColor = false
		btn.Text = "..."
		twin.Active = false
		RemoteService.FireServer("SubmitDecision", { decision = decision })
	end

	local keepBtn = UIStyle.MakeButton({
		Name = "KeepBtn",
		Size = UDim2.new(0.5, -8, 1, 0),
		Position = UDim2.fromScale(0, 0),
		Text = "KEEP",
		TextSize = UIStyle.TextSize.Title,
		BackgroundColor3 = UIStyle.Palette.Safe,
	})
	keepBtn.Parent = buttonRow

	local cutBtn = UIStyle.MakeButton({
		Name = "CutBtn",
		Size = UDim2.new(0.5, -8, 1, 0),
		Position = UDim2.new(0.5, 8, 0, 0),
		Text = "CUT BAIT",
		TextSize = UIStyle.TextSize.Title,
		BackgroundColor3 = UIStyle.Palette.Risky,
	})
	cutBtn.Parent = buttonRow

	keepBtn.MouseButton1Click:Connect(function() submit("KEEP", keepBtn, cutBtn) end)
	cutBtn.MouseButton1Click:Connect(function() submit("CUT_BAIT", cutBtn, keepBtn) end)

	print("[PHISH] Inspection card opened:", card.cardId or "(no id)")
end

RemoteService.OnClientEvent("ShowInspectionCard", renderCard)

-- When result lands, the result panel takes over; clear the card so the
-- screen isn't double-stacked, and bring the rod hotbar back so the player
-- can cast again.
RemoteService.OnClientEvent("DecisionResult", function()
	task.delay(0.2, function()
		clearOld()
		setBackpackHidden(false)
	end)
end)

-- Defensive: if the player respawns mid-inspection, restore the hotbar so
-- they aren't stuck without a rod tray.
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
localPlayer.CharacterAdded:Connect(function()
	setBackpackHidden(false)
end)
