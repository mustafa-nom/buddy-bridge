--!strict
-- Promotes Anglers → Coast Guard once they hit accuracy + catch thresholds.
-- Harbor Master rotation is post-MVP; for now we just stamp the role onto the
-- profile and push a HudUpdated so the badge refreshes. Server-wide broadcast
-- + crown cosmetic are future work.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local RoleService = {}

local function maybePromote(player: Player)
	local profile = DataService.Get(player)
	if profile.role ~= "Angler" then return end
	if profile.totalCatches < PhishConstants.COAST_GUARD_MIN_CATCHES then return end
	local accuracy = profile.correctCatches / math.max(1, profile.totalCatches)
	if accuracy < PhishConstants.COAST_GUARD_MIN_ACCURACY then return end
	profile.role = "CoastGuard"
	RemoteService.FireClient(player, "Notify", { kind = "Success", message = "Promoted to Coast Guard!" })
	RemoteService.FireClient(player, "HudUpdated", DataService.Snapshot(player))
end

function RoleService.Init()
	-- Cheap polling: check every 10 seconds. Avoids re-firing on every catch.
	task.spawn(function()
		while true do
			task.wait(10)
			for _, player in ipairs(Players:GetPlayers()) do
				maybePromote(player)
			end
		end
	end)
end

return RoleService
