--!strict
-- After PairAssigned, shows a role-select panel: pick Explorer or Guide,
-- then Start Round. Also exposes "Just TSA" / "Just Strangers" debug
-- buttons that start a round with an override level sequence — useful for
-- 2-player testing of one level at a time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RoleTypes = require(Modules:WaitForChild("RoleTypes"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))

local UIFolder = script.Parent
local UIBuilder = require(UIFolder:WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local panel: Frame? = nil
local locked = false

local function build()
	local screen = UIBuilder.GetScreenGui()
	if panel and panel.Parent then
		panel:Destroy()
	end
	panel = UIStyle.MakePanel({
		Name = "RoleSelect",
		Size = UDim2.new(0, 540, 0, 380),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Parent = screen,
	})
	UIBuilder.PadLayout(panel :: Frame, 16)

	local title = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 36),
		Text = "Pick your role",
		TextSize = UIStyle.TextSize.Title,
	})
	title.Parent = panel

	local subtitle = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 0, 36),
		Text = "Talk before big choices.",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
	})
	subtitle.Parent = panel

	local explorerBtn = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -8, 0, 90),
		Position = UDim2.new(0, 0, 0, 80),
		Text = "🚶 Explorer\n<i>The action player</i>",
		BackgroundColor3 = UIStyle.Palette.Highlight,
	})
	explorerBtn.Parent = panel

	local guideBtn = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -8, 0, 90),
		Position = UDim2.new(0.5, 8, 0, 80),
		Text = "📖 Guide\n<i>The manual reader</i>",
		BackgroundColor3 = UIStyle.Palette.Accent,
	})
	guideBtn.Parent = panel

	local startBtn = UIStyle.MakeButton({
		Size = UDim2.new(1, 0, 0, 56),
		Position = UDim2.new(0, 0, 0, 188),
		Text = "Start Round (both levels)",
		BackgroundColor3 = UIStyle.Palette.Safe,
	})
	startBtn.Parent = panel

	-- Debug / test shortcuts: skip directly to one level. Server validates
	-- the override against LevelTypes.IsValid; bad input falls back to the
	-- default DemoSequence.
	local testLabel = UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 250),
		Text = "Test shortcuts",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
	})
	testLabel.Parent = panel

	local justSdBtn = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -8, 0, 56),
		Position = UDim2.new(0, 0, 0, 272),
		Text = "👀 Just Strangers",
		BackgroundColor3 = UIStyle.Palette.AskFirst,
	})
	justSdBtn.Parent = panel

	local justBpcBtn = UIStyle.MakeButton({
		Size = UDim2.new(0.5, -8, 0, 56),
		Position = UDim2.new(0.5, 8, 0, 272),
		Text = "🧳 Just TSA",
		BackgroundColor3 = UIStyle.Palette.Highlight,
	})
	justBpcBtn.Parent = panel

	explorerBtn.Activated:Connect(function()
		if locked then return end
		RemoteService.FireServer("SelectRole", RoleTypes.Explorer)
	end)
	guideBtn.Activated:Connect(function()
		if locked then return end
		RemoteService.FireServer("SelectRole", RoleTypes.Guide)
	end)
	startBtn.Activated:Connect(function()
		RemoteService.FireServer("StartRound")
	end)
	justSdBtn.Activated:Connect(function()
		RemoteService.FireServer("StartRound", { LevelTypes.StrangerDangerPark })
	end)
	justBpcBtn.Activated:Connect(function()
		RemoteService.FireServer("StartRound", { LevelTypes.BackpackCheckpoint })
	end)
end

local function teardown()
	if panel then
		panel:Destroy()
		panel = nil
	end
	locked = false
end

RemoteService.OnClientEvent("PairAssigned", function(_payload)
	build()
end)

RemoteService.OnClientEvent("PairCleared", function(_payload)
	teardown()
end)

RemoteService.OnClientEvent("RoleAssigned", function(payload)
	locked = true
	if panel then
		local title = panel:FindFirstChildWhichIsA("TextLabel")
		if title then
			title.Text = ("You are the %s"):format(payload.Role or "?")
		end
	end
	UIBuilder.Toast(("Role: %s"):format(payload.Role), 2, "Success")
end)

RemoteService.OnClientEvent("RoundStarted", function(_payload)
	teardown()
end)
