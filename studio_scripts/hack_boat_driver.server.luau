-- HACK_BoatDriver.server.lua  (lives inside Workspace.PhishMap.PhishBoat as a Script.)
-- HACKATHON FALLBACK: simple WASD boat steering until User 2 swaps in real hovercraft physics.
-- Reads the DriverSeat's ThrottleFloat/SteerFloat and CFrame-translates the anchored Hull
-- each frame. WeldConstraints carry every other part along.
-- DELETE THIS SCRIPT once User 2's boat physics service lands.
-- Source mirrored at studio_scripts/hack_boat_driver.server.luau so it can be reinstalled.

local RunService = game:GetService("RunService")
local boat = script.Parent
local hull = boat:WaitForChild("Hull")
local driver = boat:WaitForChild("DriverSeat")

local SPEED = 24    -- studs/sec at full throttle
local TURN = 1.4    -- rad/sec at full steer

RunService.Heartbeat:Connect(function(dt)
	local throttle = driver.ThrottleFloat or 0
	local steer = driver.SteerFloat or 0
	if throttle == 0 and steer == 0 then return end
	-- Bow is +X relative to Hull center, so the boat's "forward" is RightVector.
	local fwd = hull.CFrame.RightVector * (throttle * SPEED * dt)
	local rot = CFrame.fromEulerAnglesYXZ(0, -steer * TURN * dt, 0)
	hull.CFrame = (hull.CFrame + fwd) * rot
end)
