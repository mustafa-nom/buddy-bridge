--!strict
-- Client-side rod input. Watches every Tool the server hands the player and
-- — if it's tagged "PhishRod" — binds tool.Activated → RequestCast. We keep
-- this on the client because Roblox no longer permits the server to inject
-- a LocalScript with a custom Source at runtime.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local ROD_TAG = "PhishRod"

local boundTools: { [Tool]: boolean } = {}

local function bindTool(tool: Tool)
	if boundTools[tool] then return end
	boundTools[tool] = true
	tool.Activated:Connect(function()
		local aim = (mouse and mouse.Hit and mouse.Hit.Position) or Vector3.new()
		RemoteService.FireServer("RequestCast", aim)
	end)
	tool.AncestryChanged:Connect(function(_, parent)
		if not parent then boundTools[tool] = nil end
	end)
end

local function tryBindInstance(instance: Instance)
	if instance:IsA("Tool") and (CollectionService:HasTag(instance, ROD_TAG) or instance:GetAttribute("PhishRod")) then
		bindTool(instance)
	end
end

-- Bind any rods already in the backpack/character (e.g., on respawn).
local function scanContainer(container: Instance?)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		tryBindInstance(child)
	end
	container.ChildAdded:Connect(tryBindInstance)
end

local backpack = player:WaitForChild("Backpack", 10)
scanContainer(backpack)

local function onCharacter(character: Model)
	scanContainer(character)
end

if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)

-- Catch tools the server tags after they're already in the world.
CollectionService:GetInstanceAddedSignal(ROD_TAG):Connect(function(instance)
	if instance:IsA("Tool") then bindTool(instance) end
end)
for _, tagged in ipairs(CollectionService:GetTagged(ROD_TAG)) do
	if tagged:IsA("Tool") then bindTool(tagged) end
end
