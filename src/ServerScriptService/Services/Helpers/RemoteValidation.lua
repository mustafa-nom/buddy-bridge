--!strict
-- Lightweight validation chain for PHISH remote handlers. Every C->S handler
-- runs the relevant subset before applying gameplay logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RateLimiter = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RateLimiter"))

local RemoteValidation = {}
local serverLimiter = RateLimiter.GetServer()

function RemoteValidation.RequirePlayer(player: Player?): (boolean, string?)
	if not player or not player.Parent then
		return false, "NoPlayer"
	end
	return true, nil
end

function RemoteValidation.RequireRateLimit(player: Player, key: string, windowSeconds: number): (boolean, string?)
	if serverLimiter:Check(player, key, windowSeconds) then
		return true, nil
	end
	return false, "RateLimited"
end

function RemoteValidation.RequireProximity(player: Player, target: BasePart?, maxStuds: number): (boolean, string?)
	if not target then return false, "TargetMissing" end
	local character = player.Character
	if not character then return false, "NoCharacter" end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return false, "NoRoot" end
	if (root.Position - target.Position).Magnitude > maxStuds then
		return false, "TooFar"
	end
	return true, nil
end

function RemoteValidation.RunChain(steps: { () -> (boolean, string?) }): (boolean, string?)
	for _, step in ipairs(steps) do
		local ok, reason = step()
		if not ok then return false, reason end
	end
	return true, nil
end

return RemoteValidation
