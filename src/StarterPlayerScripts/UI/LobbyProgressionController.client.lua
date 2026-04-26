--!strict
-- Tiny lobby HUD that shows the local player's Trust Seeds + treehouse
-- level. Also toggles visibility on placeholder treehouse stages User 1
-- placed in the lobby (named "TreehouseStage1", "TreehouseStage2", etc.)
-- inside `Workspace.Lobby.Treehouse` if present.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local UIFolder = script.Parent
local UIBuilder = require(UIFolder:WaitForChild("UIBuilder"))
local UIStyle = UIBuilder.UIStyle

local panel: Frame? = nil
local seedsLabel: TextLabel? = nil
local treehouseLabel: TextLabel? = nil

local function build()
	if panel and panel.Parent then return end
	local screen = UIBuilder.GetScreenGui()
	panel = UIStyle.MakePanel({
		Name = "LobbyProgression",
		Size = UDim2.fromScale(0.22, 0.08),
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.02, 0.1),
		Parent = screen,
	})
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0.05, 0)
	pad.PaddingRight = UDim.new(0.05, 0)
	pad.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.04, 0)
	layout.Parent = panel

	seedsLabel = UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 0.48),
		Text = "🌱 0 Trust Seeds",
		TextSize = UIStyle.TextSize.Body,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	seedsLabel.Parent = panel

	treehouseLabel = UIStyle.MakeLabel({
		Size = UDim2.fromScale(1, 0.4),
		Text = "Treehouse: stage 1",
		TextSize = UIStyle.TextSize.Caption,
		TextColor3 = UIStyle.Palette.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	treehouseLabel.Parent = panel
end

local function updateTreehouseVisuals(treehouseLevel: number)
	local lobby = Workspace:FindFirstChild("Lobby")
	if not lobby then return end
	local treehouse = lobby:FindFirstChild("Treehouse")
	if not treehouse then return end
	for _, child in ipairs(treehouse:GetChildren()) do
		local stage = string.match(child.Name, "TreehouseStage(%d+)")
		if stage then
			local stageNum = tonumber(stage)
			if stageNum then
				if child:IsA("Model") then
					for _, descendant in ipairs(child:GetDescendants()) do
						if descendant:IsA("BasePart") then
							descendant.Transparency = (stageNum == treehouseLevel) and 0 or 1
							descendant.CanCollide = stageNum == treehouseLevel
						end
					end
				elseif child:IsA("BasePart") then
					child.Transparency = (stageNum == treehouseLevel) and 0 or 1
					child.CanCollide = stageNum == treehouseLevel
				end
			end
		end
	end
end

local function applyProgression(p)
	if seedsLabel then
		seedsLabel.Text = ("🌱 %d Trust Seeds"):format(p.TrustSeeds or 0)
	end
	if treehouseLabel then
		treehouseLabel.Text = ("Treehouse: stage %d"):format(p.TreehouseLevel or 1)
	end
	updateTreehouseVisuals(p.TreehouseLevel or 1)
end

build()

task.spawn(function()
	local ok, progression = pcall(RemoteService.InvokeServer, "GetProgression")
	if ok and progression then
		applyProgression(progression)
	end
end)

RemoteService.OnClientEvent("ProgressionUpdated", function(payload)
	if typeof(payload) ~= "table" then return end
	applyProgression(payload)
end)
