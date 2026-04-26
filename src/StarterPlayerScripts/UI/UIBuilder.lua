--!strict
-- Shared UI scaffolding used by every controller. Wraps UIStyle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIStyle = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStyle"))

local UIBuilder = {}

UIBuilder.UIStyle = UIStyle

function UIBuilder.GetScreenGui(): ScreenGui
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local screen = playerGui:WaitForChild("PhishUI", 5)
	if screen and screen:IsA("ScreenGui") then
		return screen :: ScreenGui
	end
	local newScreen = Instance.new("ScreenGui")
	newScreen.Name = "PhishUI"
	newScreen.ResetOnSpawn = false
	newScreen.IgnoreGuiInset = false
	newScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	newScreen.Parent = playerGui
	return newScreen
end

function UIBuilder.NamedFrame(name: string, parent: Instance?): Frame
	local existing = parent and parent:FindFirstChild(name)
	if existing and existing:IsA("Frame") then
		return existing
	end
	local frame = UIStyle.MakePanel({ Name = name, AnchorPoint = Vector2.new(0.5, 0.5) })
	if parent then
		frame.Parent = parent
	end
	return frame
end

function UIBuilder.Toast(message: string, durationSeconds: number?, kind: string?)
	local screen = UIBuilder.GetScreenGui()
	local container = screen:FindFirstChild("ToastContainer")
	if not container then
		container = Instance.new("Frame")
		container.Name = "ToastContainer"
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.fromScale(0.5, 0.1)
		-- Width fixed, height auto-grows with stacked toasts.
		container.Size = UDim2.new(0, 360, 0, 0)
		container.AutomaticSize = Enum.AutomaticSize.Y
		container.BackgroundTransparency = 1
		container.ZIndex = 50
		container.Parent = screen
		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		layout.Parent = container
	end
	local toast = UIStyle.MakePanel({
		-- Width = container width; height grows to fit wrapped text.
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = (kind == "Error" and UIStyle.Palette.Risky)
			or (kind == "Success" and UIStyle.Palette.Safe)
			or UIStyle.Palette.Panel,
	})
	-- 12px padding so the wrapped text never butts up against the rim.
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = toast

	local label = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = message,
		TextSize = UIStyle.TextSize.Body,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	label.Parent = toast
	toast.Parent = container

	task.delay(durationSeconds or 3, function()
		if toast and toast.Parent then
			toast:Destroy()
		end
	end)
end

function UIBuilder.PadLayout(parent: Instance, padding: number?): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, padding or 12)
	p.PaddingBottom = UDim.new(0, padding or 12)
	p.PaddingLeft = UDim.new(0, padding or 12)
	p.PaddingRight = UDim.new(0, padding or 12)
	p.Parent = parent
	return p
end

return UIBuilder
