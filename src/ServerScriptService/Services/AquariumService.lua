--!strict
-- Manages aquarium placement. Stores ordered list of placed fishIds in
-- DataService and replicates to all aquarium display anchors tagged by
-- User 1's map (PhishAquariumDisplay). Display is a simple Billboard
-- listing of placed fish for MVP — the actual swimming-fish art is a
-- Studio-side polish task.

local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local UIStyle = require(Modules:WaitForChild("UIStyle"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local DataService = require(Services:WaitForChild("DataService"))
local GoalsService = require(Services:WaitForChild("GoalsService"))

local AquariumService = {}

local function paintAquariumDisplay(part: BasePart, fishIds: { string })
	local existing = part:FindFirstChild("PhishAquariumGui")
	if existing then existing:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "PhishAquariumGui"
	bb.Adornee = part
	bb.Size = UDim2.new(0, 320, 0, 220)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	local panel = UIStyle.MakePanel({ Size = UDim2.fromScale(1, 1) })
	panel.Parent = bb
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel
	UIStyle.MakeLabel({
		Size = UDim2.new(1, 0, 0, 32),
		Text = "Lodge Aquarium",
		TextSize = UIStyle.TextSize.Heading,
		LayoutOrder = 0,
		Parent = panel,
	})
	for i, fishId in ipairs(fishIds) do
		local fish = FishRegistry.GetById(fishId)
		if fish then
			UIStyle.MakeLabel({
				Size = UDim2.new(1, 0, 0, 22),
				Text = fish.displayName,
				TextSize = UIStyle.TextSize.Body,
				LayoutOrder = i,
				Parent = panel,
			})
		end
	end
	if #fishIds == 0 then
		UIStyle.MakeLabel({
			Size = UDim2.new(1, 0, 0, 22),
			Text = "Catch a kindness fish to fill the tank.",
			TextSize = UIStyle.TextSize.Caption,
			TextColor3 = UIStyle.Palette.TextMuted,
			LayoutOrder = 1,
			Parent = panel,
		})
	end
	bb.Parent = part
end

local function refreshAllDisplays()
	for _, part in ipairs(CollectionService:GetTagged(Constants.TAGS.Aquarium)) do
		if part:IsA("BasePart") then
			-- Show the union of all players' aquariums (server-shared display).
			local seen: { [string]: boolean } = {}
			local list = {}
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local data = DataService.GetData(player)
				for _, fishId in ipairs(data.Aquarium) do
					if not seen[fishId] then
						seen[fishId] = true
						table.insert(list, fishId)
					end
				end
			end
			paintAquariumDisplay(part, list)
		end
	end
end

local function handlePlace(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.fishId) ~= "string" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestPlaceFishInAquarium", Constants.RATE_LIMIT_PLACE_FISH) then return end

	local fish = FishRegistry.GetById(payload.fishId)
	if not fish or fish.correctAction ~= "Reel" then
		RemoteService.FireClient(player, "Notify", {
			Kind = "Info",
			Title = "Aquarium full of fish",
			Text = "Only the kindness catches go in the tank.",
		})
		return
	end
	local data = DataService.GetData(player)
	if not data.JournalUnlocked[fish.id] then
		RemoteService.FireClient(player, "Notify", {
			Kind = "Info",
			Title = "Catch one first",
			Text = "Reel one of these the right way before placing it.",
		})
		return
	end
	local placed = DataService.PlaceInAquarium(player, fish.id)
	if not placed then return end
	GoalsService.RecordAquariumPlace(player)
	refreshAllDisplays()
end

function AquariumService.Init()
	RemoteService.OnServerEvent("RequestPlaceFishInAquarium", handlePlace)
	CollectionService:GetInstanceAddedSignal(Constants.TAGS.Aquarium):Connect(function()
		refreshAllDisplays()
	end)
	game:GetService("Players").PlayerAdded:Connect(function()
		task.wait(2)
		refreshAllDisplays()
	end)
	game:GetService("Players").PlayerRemoving:Connect(function()
		task.delay(1, refreshAllDisplays)
	end)
	task.delay(2, refreshAllDisplays)
end

function AquariumService.Diagnostics(): { [string]: number }
	return { Aquariums = #CollectionService:GetTagged(Constants.TAGS.Aquarium) }
end

return AquariumService
