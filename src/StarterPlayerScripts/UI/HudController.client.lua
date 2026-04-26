--!strict
-- Top HUD: coins, accuracy %, role badge. Listens to HudUpdated.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIStyle = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIStyle"))
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local screen = UIBuilder.GetScreenGui()

local existing = screen:FindFirstChild("PhishHud")
if existing then existing:Destroy() end

local hud = Instance.new("Frame")
hud.Name = "PhishHud"
hud.Size = UDim2.new(1, 0, 0, 56)
hud.Position = UDim2.fromScale(0, 0)
hud.BackgroundTransparency = 1
hud.Parent = screen

local function chip(name: string, color: Color3, anchor: Vector2, pos: UDim2): TextLabel
	local frame = UIStyle.MakePanel({
		Name = name,
		Size = UDim2.new(0, 200, 0, 40),
		AnchorPoint = anchor,
		Position = pos,
		BackgroundColor3 = color,
	})
	frame.Parent = hud
	local label = UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 1),
		Text = "—",
		TextSize = UIStyle.TextSize.Heading,
		TextColor3 = UIStyle.Palette.TextPrimary,
	})
	label.Parent = frame
	return label
end

local coinsLabel = chip("CoinsChip", UIStyle.Palette.AskFirst, Vector2.new(0, 0), UDim2.new(0, 16, 0, 8))
local accuracyLabel = chip("AccuracyChip", UIStyle.Palette.Highlight, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8))
local roleLabel = chip("RoleChip", UIStyle.Palette.Safe, Vector2.new(1, 0), UDim2.new(1, -16, 0, 8))

local function render(snapshot: any)
	if not snapshot then return end
	coinsLabel.Text = string.format("🪙 %d", snapshot.coins or 0)
	local acc = snapshot.accuracy or 0
	accuracyLabel.Text = string.format("🎯 %d%%", math.floor(acc * 100))
	roleLabel.Text = snapshot.role or "Angler"
end

RemoteService.OnClientEvent("HudUpdated", render)

-- Warm initial state from the server.
task.spawn(function()
	local ok, snapshot = pcall(function() return RemoteService.InvokeServer("GetPlayerSnapshot") end)
	if ok then render(snapshot) end
end)

-- Generic notify toasts.
RemoteService.OnClientEvent("Notify", function(payload)
	if type(payload) ~= "table" then return end
	UIBuilder.Toast(payload.message or "", payload.duration, payload.kind)
end)

-- Species unlock toast.
RemoteService.OnClientEvent("SpeciesUnlocked", function(payload)
	if type(payload) ~= "table" then return end
	UIBuilder.Toast("New dex entry: " .. (payload.displayName or ""), 5, "Success")
end)
