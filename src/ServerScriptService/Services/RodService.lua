--!strict
-- Owns the rod Tool. Players hit the NPC angler ProximityPrompt → server
-- builds a Rod Tool and parents it to their Backpack. The rod's LocalScript
-- fires "RequestCast" on Activated.

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

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 4, 0.4)
	handle.Color = Color3.fromRGB(110, 70, 50)
	handle.Material = Enum.Material.Wood
	handle.Shape = Enum.PartType.Cylinder
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	-- Tip glow so the rod reads at distance.
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.2, 0.2, 0.2)
	tip.Shape = Enum.PartType.Ball
	tip.Color = Color3.fromRGB(255, 220, 150)
	tip.Material = Enum.Material.Neon
	tip.CanCollide = false; tip.Massless = true
	tip.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle; weld.Part1 = tip; weld.Parent = handle
	tip.CFrame = handle.CFrame * CFrame.new(0, 2, 0)

	-- Tool LocalScript: forwards Activated → RequestCast remote. Uses Player
	-- mouse target as aim.
	local local_ = Instance.new("LocalScript")
	local_.Name = "PhishRodClient"
	local_.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))
local tool = script.Parent
local player = Players.LocalPlayer
tool.Activated:Connect(function()
    local mouse = player:GetMouse()
    local aim = mouse.Hit and mouse.Hit.Position or Vector3.new()
    RemoteService.FireServer("RequestCast", aim)
end)
]]
	local_.Parent = tool
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
