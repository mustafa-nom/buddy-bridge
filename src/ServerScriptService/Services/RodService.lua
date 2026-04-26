--!strict
-- Owns the rod Tool. Players hit the NPC angler ProximityPrompt → server
-- builds a Rod Tool and parents it to their Backpack. Cast input is bound
-- on the *client* side (StarterPlayerScripts/Angler/RodInputController.client.lua)
-- by listening for tools tagged "PhishRod" — Roblox no longer lets us write
-- LocalScript.Source from a server script.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local RodService = {}

local ROD_TOOL_NAME = "PhishRod"

local function buildRod(): Tool
	local tool = Instance.new("Tool")
	tool.Name = ROD_TOOL_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Cast at the water"
	tool.Grip = CFrame.new(0, 0, -1.5)

	-- Handle: the gripped section. Tool grip math expects a single Handle Part,
	-- so this stays cylindrical and unwelded; everything else welds onto it.
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 4, 0.4)
	handle.Color = Color3.fromRGB(80, 50, 35)
	handle.Material = Enum.Material.Wood
	handle.Shape = Enum.PartType.Cylinder
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	local function add(name: string, props: { [string]: any }, weldOffset: CFrame): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = false
		p.CanCollide = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props) do (p :: any)[k] = v end
		p.Parent = tool
		p.CFrame = handle.CFrame * weldOffset
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle; w.Part1 = p; w.Parent = handle
		return p
	end

	-- Grip wrap: black band at the bottom for that taped-handle look.
	add("GripWrap", {
		Size = Vector3.new(0.46, 1.2, 0.46), Color = Color3.fromRGB(30, 30, 35),
		Material = Enum.Material.Fabric, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, -1.2, 0))

	-- Reel: small horizontal cylinder + side disc for the spinning-reel look.
	add("ReelHousing", {
		Size = Vector3.new(0.7, 0.5, 0.5), Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0.3, -0.4, 0))
	add("ReelDisc", {
		Size = Vector3.new(0.15, 0.9, 0.9), Color = Color3.fromRGB(180, 60, 60),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0.6, -0.4, 0))

	-- Mid-rod sleeve: brass-ish band where the rod tapers.
	add("MidBand", {
		Size = Vector3.new(0.42, 0.3, 0.42), Color = Color3.fromRGB(200, 150, 70),
		Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, 0.6, 0))

	-- Tapered upper shaft: thinner cylinder above the handle.
	add("UpperShaft", {
		Size = Vector3.new(0.22, 2.4, 0.22), Color = Color3.fromRGB(60, 40, 30),
		Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder,
	}, CFrame.new(0, 2.0, 0))

	-- Tip glow: bright neon bead at the very top so the rod reads at distance.
	add("Tip", {
		Size = Vector3.new(0.28, 0.28, 0.28), Color = Color3.fromRGB(255, 220, 150),
		Material = Enum.Material.Neon, Shape = Enum.PartType.Ball,
	}, CFrame.new(0, 3.4, 0))
	-- Soft halo on the tip so it pops in golden-hour shots.
	local tipLight = Instance.new("PointLight")
	tipLight.Color = Color3.fromRGB(255, 220, 150)
	tipLight.Range = 8; tipLight.Brightness = 1.4
	tipLight.Parent = tool:FindFirstChild("Tip")

	-- Tag + attribute so the client-side input controller picks it up. We
	-- can no longer inject a LocalScript.Source at runtime (Roblox sandbox).
	tool:SetAttribute("PhishRod", true)
	CollectionService:AddTag(tool, ROD_TOOL_NAME)
	return tool
end

local function giveRod(player: Player)
	local profile = DataService.Get(player)
	-- Idempotent: if the player already has a rod somewhere, don't re-grant.
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(ROD_TOOL_NAME) then return end
	local char = player.Character
	if char and char:FindFirstChild(ROD_TOOL_NAME) then return end
	if not backpack then return end

	local tool = buildRod()
	tool.Parent = backpack
	profile.rodGiven = true
	RemoteService.FireClient(player, "RodGranted", { rodName = ROD_TOOL_NAME })
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
	for _, npc in ipairs(CollectionService:GetTagged(PhishConstants.Tags.NpcAngler)) do
		bindNpcPrompt(npc)
	end
	CollectionService:GetInstanceAddedSignal(PhishConstants.Tags.NpcAngler):Connect(bindNpcPrompt)

	-- Direct request (useful for clients that bypass the prompt — keep
	-- the same rate limit so it can't be spammed).
	RemoteService.OnServerEvent("RequestRod", function(player)
		local ok, _ = RemoteValidation.RunChain({
			function() return RemoteValidation.RequirePlayer(player) end,
			function() return RemoteValidation.RequireRateLimit(player, "Rod", PhishConstants.RATE_LIMIT_ROD) end,
		})
		if not ok then return end
		giveRod(player)
	end)

	-- Re-give rod on respawn so the player can keep playing.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if DataService.Get(player).rodGiven then giveRod(player) end
		end)
	end)
end

return RodService
