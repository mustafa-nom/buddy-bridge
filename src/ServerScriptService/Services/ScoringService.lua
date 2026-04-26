--!strict
-- Scoring + reward logic. Mutates Profile. Triggers HudUpdated remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishConstants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local ScoringService = {}

local function pushHud(player: Player)
	RemoteService.FireClient(player, "HudUpdated", DataService.Snapshot(player))
end

function ScoringService.Init() end

-- Called by DecisionService after every catch resolution.
-- `wasCorrect` tracks accuracy. `card` provides reward base; difficulty bumps it.
function ScoringService.GrantCatchReward(player: Player, wasCorrect: boolean, card: any): { coinsDelta: number, xpDelta: number }
	local profile = DataService.Get(player)
	profile.totalCatches += 1

	local coinsDelta = 0
	local xpDelta = 0
	if wasCorrect then
		profile.correctCatches += 1
		local baseCoins = (card.reward and card.reward.coins) or PhishConstants.REWARD_CORRECT_COINS
		local baseXp = (card.reward and card.reward.xp) or PhishConstants.REWARD_CORRECT_XP
		local diffBonus = math.max(0, (card.difficulty or 1) - 1) * PhishConstants.REWARD_DIFFICULTY_BONUS
		coinsDelta = baseCoins + diffBonus
		xpDelta = baseXp + diffBonus
		profile.coins += coinsDelta
		profile.xp += xpDelta
	else
		-- Soft penalty: tiny coin loss only if they have coins; never negative.
		coinsDelta = -math.min(profile.coins, 1)
		profile.coins += coinsDelta
	end

	pushHud(player)
	return { coinsDelta = coinsDelta, xpDelta = xpDelta }
end

function ScoringService.PushHud(player: Player)
	pushHud(player)
end

return ScoringService
