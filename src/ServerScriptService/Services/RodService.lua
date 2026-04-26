--!strict
-- Owns the rod Tool given to players, plus the display Models in
-- ReplicatedStorage.PhishRods that the shop ViewportFrames clone. Tier-aware:
-- when DataService.rodTier changes, RefreshRod rebuilds the player's tool to
-- match the new tier's visuals.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PhishConstants = require(Modules:WaitForChild("PhishConstants"))
local RodCatalog = require(Modules:WaitForChild("RodCatalog"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local RodService = {}

local ROD_TOOL_NAME = "PhishRod"
local TEMPLATES_FOLDER = "PhishRods"

local function rgb(t: { number }): Color3
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- Build the visible rod parts onto a Handle. Used by both Tool (in-hand) and
-- Model (display) builders so the visuals stay in sync.
local function attachAnatomy(handle: Part, parent: Instance, spec: RodCatalog.Rod)
	local function add(name: string, props: { [string]: any }, weldOffset: CFrame): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props) do (p :: any)[k] = v end
		p.Parent = parent
		p.CFrame = handle.CFrame * weldOffset
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle; w.Part1 = p; w.Parent = handle
		return p
	end

	add("GripWrap", {
		Size = Vector3.new(0.46, 1.2, 0.46), Color = rgb(spec.wrapColor),
		Material = Enum.Material.Fabric, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, -1.2, 0))

	add("ReelHousing", {
		Size = Vector3.new(0.7, 0.5, 0.5), Color = rgb(spec.reelColor),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0.3, -0.4, 0))
	add("ReelDisc", {
		Size = Vector3.new(0.15, 0.9, 0.9), Color = rgb(spec.reelColor),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0.6, -0.4, 0))

	add("MidBand", {
		Size = Vector3.new(0.42, 0.3, 0.42), Color = rgb(spec.bandColor),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, 0.6, 0))

	local upperMaterial = Enum.Material[spec.upperShaftMaterial] or Enum.Material.Wood
	add("UpperShaft", {
		Size = Vector3.new(0.22, 2.4, 0.22), Color = rgb(spec.upperShaftColor),
		Material = upperMaterial, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, 2.0, 0))

	add("Tip", {
		Size = Vector3.new(0.28, 0.28, 0.28), Color = rgb(spec.tipColor),
		Material = Enum.Material.Neon, Shape = Enum.PartType.Ball,
	}, CFrame.new(0, 3.4, 0))
	local tipLight = Instance.new("PointLight")
	tipLight.Color = rgb(spec.tipColor)
	tipLight.Range = spec.tipGlowRange; tipLight.Brightness = 1.4
	tipLight.Parent = parent:FindFirstChild("Tip")
end

local function buildHandle(name: string, color: Color3): Part
	local handle = Instance.new("Part")
	handle.Name = name
	handle.Size = Vector3.new(0.4, 4, 0.4)
	handle.Color = color
	handle.Material = Enum.Material.Wood
	handle.Shape = Enum.PartType.Cylinder
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	return handle
end

local function buildTool(spec: RodCatalog.Rod): Tool
	local tool = Instance.new("Tool")
	tool.Name = ROD_TOOL_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = spec.name
	tool.Grip = CFrame.new(0, 0, -1.5)

	local handle = buildHandle("Handle", rgb(spec.handleColor))
	handle.Parent = tool
	attachAnatomy(handle, tool, spec)

	tool:SetAttribute("PhishRod", true)
	tool:SetAttribute("RodId", spec.id)
	tool:SetAttribute("RodTier", spec.tier)
	CollectionService:AddTag(tool, ROD_TOOL_NAME)
	return tool
end

local function buildDisplayModel(spec: RodCatalog.Rod): Model
	local model = Instance.new("Model")
	model.Name = spec.id
	local handle = buildHandle("Handle", rgb(spec.handleColor))
	handle.CFrame = CFrame.new(0, 0, 0)
	handle.Parent = model
	model.PrimaryPart = handle
	attachAnatomy(handle, model, spec)
	model:SetAttribute("RodId", spec.id)
	model:SetAttribute("RodTier", spec.tier)
	return model
end

local function ensureTemplatesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(TEMPLATES_FOLDER)
	if existing then existing:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = TEMPLATES_FOLDER
	folder.Parent = ReplicatedStorage
	return folder
end

local function buildAllTemplates()
	local folder = ensureTemplatesFolder()
	for _, spec in ipairs(RodCatalog.Rods) do
		local model = buildDisplayModel(spec)
		model.Parent = folder
	end
end

local function specForPlayer(player: Player): RodCatalog.Rod
	local profile = DataService.Get(player)
	local spec = RodCatalog.GetByTier(profile.rodTier or 1)
	return spec or RodCatalog.GetByTier(1) :: RodCatalog.Rod
end

-- Removes any existing rod the player has and gives them a fresh one matching
-- their current rodTier. Safe to call multiple times.
function RodService.RefreshRod(player: Player)
	local profile = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in ipairs({ backpack, player.Character }) do
		if container then
			local existing = container:FindFirstChild(ROD_TOOL_NAME)
			if existing then existing:Destroy() end
		end
	end
	if not backpack then return end
	local tool = buildTool(specForPlayer(player))
	tool.Parent = backpack
	profile.rodGiven = true
	RemoteService.FireClient(player, "RodGranted", {
		rodName = ROD_TOOL_NAME, rodId = tool:GetAttribute("RodId"), tier = tool:GetAttribute("RodTier"),
	})
end

local function giveRod(player: Player)
	local profile = DataService.Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	-- If they already have the right rod, no-op. Otherwise refresh.
	local existing = backpack and backpack:FindFirstChild(ROD_TOOL_NAME)
		or (player.Character and player.Character:FindFirstChild(ROD_TOOL_NAME))
	if existing and existing:GetAttribute("RodTier") == profile.rodTier then return end
	RodService.RefreshRod(player)
end

local function bindNpcPrompt(npcModel: Instance)
	local prompt = npcModel:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then return end
	prompt.Triggered:Connect(function(player)
		local ok, _ = RemoteValidation.RunChain({
			function() return RemoteValidation.RequirePlayer(player) end,
			function() return RemoteValidation.RequireRateLimit(player, "Rod", PhishConstants.RATE_LIMIT_ROD) end,
		})
		if not ok then return end
		giveRod(player)
	end)
end

function RodService.Init()
	buildAllTemplates()

	for _, npc in ipairs(CollectionService:GetTagged(PhishConstants.Tags.NpcAngler)) do
		bindNpcPrompt(npc)
	end
	CollectionService:GetInstanceAddedSignal(PhishConstants.Tags.NpcAngler):Connect(bindNpcPrompt)

	RemoteService.OnServerEvent("RequestRod", function(player)
		local ok, _ = RemoteValidation.RunChain({
			function() return RemoteValidation.RequirePlayer(player) end,
			function() return RemoteValidation.RequireRateLimit(player, "Rod", PhishConstants.RATE_LIMIT_ROD) end,
		})
		if not ok then return end
		giveRod(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if DataService.Get(player).rodGiven then giveRod(player) end
		end)
	end)
end

return RodService
