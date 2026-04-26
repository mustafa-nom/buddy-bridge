--!strict
-- PHISH! reward calculator. Maps a (fish, wasCorrect, zoneTier) tuple to
-- pearls + XP and writes to DataService. Catch-resolution call site, not a
-- run-end call site.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local ZoneTiers = require(Modules:WaitForChild("ZoneTiers"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local RewardService = {}

function RewardService.ComputeCatchReward(fishId: string, wasCorrect: boolean, zoneTier: number): { Pearls: number, Xp: number }
	local fish = FishRegistry.GetById(fishId)
	if not fish then return { Pearls = 0, Xp = 0 } end
	if not wasCorrect then
		return { Pearls = 0, Xp = math.max(1, math.floor(fish.xpReward * 0.25)) }
	end
	local zone = ZoneTiers.Get(zoneTier)
	local mult = zone and zone.payoutMultiplier or 1
	local rarityBonus = Constants.SELL_RARITY_MULTIPLIER[fish.rarity] or 1
	local pearls = math.floor((Constants.SELL_BASE_PAYOUT * 0.4) * rarityBonus * mult)
	local xp = math.floor(fish.xpReward * mult)
	return { Pearls = pearls, Xp = xp }
end

function RewardService.GrantCatch(player: Player, fishId: string, wasCorrect: boolean, zoneTier: number): { Pearls: number, Xp: number }
	local reward = RewardService.ComputeCatchReward(fishId, wasCorrect, zoneTier)
	if reward.Pearls > 0 then
		DataService.GrantPearls(player, reward.Pearls)
	end
	if reward.Xp > 0 then
		DataService.GrantXp(player, reward.Xp)
	end
	return reward
end

function RewardService.Init()
	-- No remotes wired here; catch resolution calls GrantCatch directly.
end

return RewardService
