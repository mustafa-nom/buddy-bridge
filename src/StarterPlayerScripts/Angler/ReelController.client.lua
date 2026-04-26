--!strict
-- Listens for BiteOccurred → shows a tap prompt + simple progress bar; every
-- LMB/space tap fires RequestReelTap. ReelProgress updates the bar; once the
-- server hits required taps it sends ShowInspectionCard and the bar clears.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIStyle = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStyle"))
local UIBuilder = require(Players.LocalPlayer.PlayerScripts:WaitForChild("UI"):WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()

local active = false
local taps = 0
local required = 3

local function clearBar()
	local old = screen:FindFirstChild("PhishReelBar")
	if old then old:Destroy() end
end

local function showBar()
	clearBar()
	local panel = UIStyle.MakePanel({
		Name = "PhishReelBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.85),
		Size = UDim2.fromOffset(360, 80),
		BackgroundColor3 = UIStyle.Palette.Panel,
	})
	panel.Parent = screen
	local label = UIStyle.MakeLabel({
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 4),
		Text = "TAP to reel! (0 / " .. required .. ")",
		Font = UIStyle.FontBold,
		TextSize = UIStyle.TextSize.Heading,
	})
	label.Parent = panel
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -32, 0, 16)
	barBg.Position = UDim2.fromOffset(16, 44)
	barBg.BackgroundColor3 = UIStyle.Palette.Background
	barBg.BorderSizePixel = 0
	barBg.Parent = panel
	UIStyle.ApplyCorner(barBg, UDim.new(0, 8))
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = UIStyle.Palette.Accent
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	UIStyle.ApplyCorner(fill, UDim.new(0, 8))
end

local function updateBar()
	local panel = screen:FindFirstChild("PhishReelBar")
	if not panel then return end
	local label = panel:FindFirstChild("Label") :: TextLabel?
	local fill = panel:FindFirstChild("BarBg") and panel.BarBg:FindFirstChild("Fill") :: Frame?
	if label then label.Text = string.format("TAP to reel! (%d / %d)", taps, required) end
	if fill then fill.Size = UDim2.fromScale(taps / required, 1) end
end

local function onTap()
	if not active then return end
	RemoteService.FireServer("RequestReelTap")
end

RemoteService.OnClientEvent("BiteOccurred", function(payload)
	required = (payload and payload.tapsRequired) or 3
	taps = 0
	active = true
	showBar()
end)

RemoteService.OnClientEvent("ReelProgress", function(payload)
	if type(payload) ~= "table" then return end
	taps = payload.count or taps
	required = payload.required or required
	updateBar()
end)

RemoteService.OnClientEvent("ReelFailed", function()
	active = false
	clearBar()
	UIBuilder.Toast("Got away! Cast again.", 2, "Error")
end)

RemoteService.OnClientEvent("ShowInspectionCard", function()
	active = false
	clearBar()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.Space then
		onTap()
	end
end)
