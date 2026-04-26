--!strict
-- Renders the inspection card on ShowInspectionCard. Two big buttons: KEEP
-- (legit) and CUT BAIT (phish). Submitting fires SubmitDecision; the card
-- stays up briefly after submit so the result panel can take over.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local UIStyle = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStyle"))
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()

local function clearOld()
	local old = screen:FindFirstChild("PhishInspectionCard")
	if old then old:Destroy() end
end

local function colorAvatar(color: Color3?): Color3
	return color or Color3.fromRGB(120, 120, 120)
end

local function renderCard(card: any)
	clearOld()
	if type(card) ~= "table" then return end

	local panel = UIStyle.MakePanel({
		Name = "PhishInspectionCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(560, 540),
		BackgroundColor3 = UIStyle.Palette.Background,
	})
	panel.Parent = screen

	-- Sender row
	local senderRow = Instance.new("Frame")
	senderRow.Size = UDim2.new(1, -32, 0, 56)
	senderRow.Position = UDim2.fromOffset(16, 16)
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

	-- Subject
	local subjectLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, -32, 0, 32),
		Position = UDim2.fromOffset(16, 84),
		Text = card.subject or "",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Heading,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	subjectLabel.Parent = panel

	-- Body
	local bodyFrame = UIStyle.MakePanel({
		Size = UDim2.new(1, -32, 0, 240),
		Position = UDim2.fromOffset(16, 124),
		BackgroundColor3 = UIStyle.Palette.Panel,
	})
	bodyFrame.Parent = panel
	local bodyLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, -24, 1, -24),
		Position = UDim2.fromOffset(12, 12),
		Text = card.body or "",
		Font = Enum.Font.RobotoMono,
		TextSize = UIStyle.TextSize.Body,
		TextColor3 = UIStyle.Palette.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})
	bodyLabel.Parent = bodyFrame

	-- Links
	local linksY = 372
	if card.links and #card.links > 0 then
		for _, link in ipairs(card.links) do
			local linkPanel = UIStyle.MakePanel({
				Size = UDim2.new(1, -32, 0, 36),
				Position = UDim2.fromOffset(16, linksY),
				BackgroundColor3 = UIStyle.Palette.Highlight,
			})
			linkPanel.Parent = panel
			local linkLabel = UIStyle.MakeLabel({
				Size = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				Text = string.format("🔗 %s  →  %s", link.displayText or "(link)", link.trueUrl or ""),
				TextSize = UIStyle.TextSize.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = false,
			})
			linkLabel.Parent = linkPanel
			linksY += 40
		end
	end

	-- Decision buttons
	local btnY = 460
	local function submit(decision: string, button: TextButton)
		button.Active = false
		button.Text = "..."
		RemoteService.FireServer("SubmitDecision", { decision = decision })
	end

	local keepBtn = UIStyle.MakeButton({
		Name = "KeepBtn",
		Size = UDim2.new(0.5, -24, 0, 56),
		Position = UDim2.fromOffset(16, btnY),
		Text = "✅ KEEP",
		BackgroundColor3 = UIStyle.Palette.Safe,
	})
	keepBtn.Parent = panel
	keepBtn.MouseButton1Click:Connect(function() submit("KEEP", keepBtn) end)

	local cutBtn = UIStyle.MakeButton({
		Name = "CutBtn",
		Size = UDim2.new(0.5, -24, 0, 56),
		Position = UDim2.new(0.5, 8, 0, btnY),
		Text = "✂️ CUT BAIT",
		BackgroundColor3 = UIStyle.Palette.Risky,
	})
	cutBtn.Parent = panel
	cutBtn.MouseButton1Click:Connect(function() submit("CUT_BAIT", cutBtn) end)
end

RemoteService.OnClientEvent("ShowInspectionCard", renderCard)

-- When result lands, the result panel takes over; clear the card so the
-- screen isn't double-stacked.
RemoteService.OnClientEvent("DecisionResult", function()
	task.delay(0.2, clearOld)
end)
