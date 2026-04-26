--!strict
-- Client init. The other controllers are LocalScripts that auto-start; this
-- bootstrap exists to:
--   * make sure the remote folder is replicated before any controller fires
--   * create the shared ScreenGui parent
--   * acknowledge progression on join

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the remote folder so other controllers don't race.
ReplicatedStorage:WaitForChild("BuddyBridgeRemotes")

-- Shared ScreenGui that every UI controller mounts under.
local screen = playerGui:FindFirstChild("BuddyBridgeUI")
if not screen then
	screen = Instance.new("ScreenGui")
	screen.Name = "BuddyBridgeUI"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
else
	screen.IgnoreGuiInset = false
end

local _ = RemoteService

print("[BuddyBridge] Client bootstrap ready.")
