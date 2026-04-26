--!strict
-- Validation chain for every remote handler. Strip-down for PHISH! — no
-- rounds, no roles, just player presence + proximity + rate-limit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RateLimiter = require(Modules:WaitForChild("RateLimiter"))

local RemoteValidation = {}

local serverLimiter = RateLimiter.GetServer()

function RemoteValidation.RequirePlayer(player: Player?): (boolean, string?)
	if not player or not player.Parent then
		return false, "NoPlayer"
	end
	return true, nil
end

function RemoteValidation.RequireProximity(player: Player, target: BasePart?, maxStuds: number): (boolean, string?)
	if not target then return false, "TargetMissing" end
	local character = player.Character
	if not character then return false, "NoCharacter" end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return false, "NoRoot" end
	local distance = (root.Position - target.Position).Magnitude
	if distance > maxStuds then return false, "TooFar" end
	return true, nil
end

function RemoteValidation.RequireRateLimit(player: Player, key: string, windowSeconds: number): (boolean, string?)
	if serverLimiter:Check(player, key, windowSeconds) then
		return true, nil
	end
	return false, "RateLimited"
end

return RemoteValidation
