--!strict
-- PHISH! reward calculator. Maps a catch outcome to pearls + XP and writes
-- to DataService. Accepts streak/lucky multipliers that the resolution
-- service computes per encounter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local ZoneTiers = require(Modules:WaitForChild("ZoneTiers"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local RewardService = {}

export type CatchModifiers = {
	streakMultiplier: number?,
	luckyMultiplier: number?,
	reelQuality: number?,    -- 0..1, fraction of reel time spent in the catch zone
}

function RewardService.ComputeCatchReward(
	fishId: string,
	wasCorrect: boolean,
	zoneTier: number,
	modifiers: CatchModifiers?
): { Pearls: number, Xp: number, Multipliers: { [string]: number } }
	local fish = FishRegistry.GetById(fishId)
	if not fish then return { Pearls = 0, Xp = 0, Multipliers = {} } end
	local m = modifiers or {}
	local streakM = m.streakMultiplier or 1
	local luckyM = m.luckyMultiplier or 1
	local reelQ = m.reelQuality or 1
	if not wasCorrect then
		return {
			Pearls = 0,
			Xp = math.max(1, math.floor(fish.xpReward * 0.25)),
			Multipliers = { streak = 1, lucky = 1, reel = 1 },
		}
	end
	local zone = ZoneTiers.Get(zoneTier)
	local zoneM = zone and zone.payoutMultiplier or 1
	local rarityBonus = Constants.SELL_RARITY_MULTIPLIER[fish.rarity] or 1
	-- Reel quality bonus: 0.85x at 0% in-zone, up to 1.4x at 100%.
	local reelM = 0.85 + reelQ * 0.55
	local total = zoneM * rarityBonus * streakM * luckyM * reelM
	local pearls = math.max(1, math.floor((Constants.SELL_BASE_PAYOUT * 0.5) * total))
	local xp = math.max(1, math.floor(fish.xpReward * (zoneM * streakM * luckyM)))
	return {
		Pearls = pearls,
		Xp = xp,
		Multipliers = {
			zone = zoneM,
			rarity = rarityBonus,
			streak = streakM,
			lucky = luckyM,
			reel = reelM,
		},
	}
end

function RewardService.GrantCatch(
	player: Player,
	fishId: string,
	wasCorrect: boolean,
	zoneTier: number,
	modifiers: CatchModifiers?
)
	local reward = RewardService.ComputeCatchReward(fishId, wasCorrect, zoneTier, modifiers)
	if reward.Pearls > 0 then
		DataService.GrantPearls(player, reward.Pearls)
	end
	if reward.Xp > 0 then
		DataService.GrantXp(player, reward.Xp)
	end
	return reward
end

function RewardService.Init() end

return RewardService
