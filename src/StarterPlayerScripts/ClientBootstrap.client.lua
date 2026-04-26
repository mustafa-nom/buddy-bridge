--!strict
-- PHISH client init. Ensures the remote folder + ScreenGui exist before any
-- controller mounts, then warms the player snapshot so HUD has data on join.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Constants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Constants"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME)

local screen = playerGui:FindFirstChild(Constants.SCREEN_GUI_NAME)
if not screen then
	screen = Instance.new("ScreenGui")
	screen.Name = Constants.SCREEN_GUI_NAME
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
end

-- Touch the remote so it loads in the cache; controllers will reuse it.
local _ = RemoteService

-- WindShake: per-client foliage shake. Watches CollectionService for parts
-- tagged "WindShake" and animates them via CFrame each Heartbeat. Client-
-- side so it costs no network bandwidth. Tag pond reeds, palms, dock
-- banners, etc. in Studio to bring them to life.
local WindShake = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("WindShake"))
WindShake:Init()

print("[PHISH] Client bootstrap ready.")
