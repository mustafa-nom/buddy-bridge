--!strict
-- Picks the next fish for an active encounter (server-authoritative weighted
-- random) and schedules the BiteOccurred event. Anti-clumping: avoids
-- repeating the most recent fish twice in a row when possible.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local FishEncounterTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishEncounterTypes"))
local _PondStateModule = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PondState"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local CastingService = require(Services:WaitForChild("CastingService"))
local BobberService = require(Services:WaitForChild("BobberService"))
local StreakService = require(Services:WaitForChild("StreakService"))
local BossEventService = require(Services:WaitForChild("BossEventService"))

local BiteService = {}

local recentFishByPlayer: { [Player]: string } = {}

local function pickFish(zoneTier: number, recentId: string?)
	local pool = FishRegistry.PoolForZoneTier(zoneTier)
	if #pool == 0 then return nil end
	local total = 0
	for _, f in ipairs(pool) do
		local w = f.spawnWeight
		if recentId and f.id == recentId then w = w * 0.4 end
		total += w
	end
	if total <= 0 then return pool[1] end
	local roll = math.random() * total
	for _, f in ipairs(pool) do
		local w = f.spawnWeight
		if recentId and f.id == recentId then w = w * 0.4 end
		if roll <= w then return f end
		roll -= w
	end
	return pool[#pool]
end

local function scheduleBite(player: Player, enc)
	local wait = Constants.BITE_WAIT_MIN + math.random() * (Constants.BITE_WAIT_MAX - Constants.BITE_WAIT_MIN)
	task.delay(wait, function()
		if not player.Parent then return end
		local current = CastingService.GetEncounter(player)
		if current ~= enc then return end
		if enc.state ~= FishEncounterTypes.States.Waiting then return end

		-- Boss event override: if a global boss is open, this player claims it.
		local bossFish = BossEventService.TryClaim(player)
		local fish = bossFish or pickFish(enc.zoneTier, recentFishByPlayer[player])
		if not fish then return end
		recentFishByPlayer[player] = fish.id

		enc.fishId = fish.id
		enc.correctAction = fish.correctAction
		enc.bobberCue = fish.bobberCue
		enc.isBoss = bossFish ~= nil
		enc.bitedAt = os.clock()
		enc.state = FishEncounterTypes.States.BitePending

		BobberService.SetCue(player, fish.bobberCue.color, fish.bobberCue.ripple)
		RemoteService.FireClient(player, "BiteOccurred", {
			EncounterId = enc.encounterId,
			BobberColor = fish.bobberCue.color,
			Ripple = fish.bobberCue.ripple,
			Rarity = fish.rarity,
			Category = fish.category,
			DecisionWindowSec = Constants.DECISION_WINDOW_SECONDS,
			ZoneTier = enc.zoneTier,
			LuckyBobber = enc.luckyBobber == true,
			Boss = enc.isBoss == true,
		})

		-- Decision-window expiry: fish escapes if no action.
		task.delay(Constants.DECISION_WINDOW_SECONDS, function()
			if not player.Parent then return end
			local stillCurrent = CastingService.GetEncounter(player)
			if stillCurrent ~= enc then return end
			if enc.state == FishEncounterTypes.States.BitePending then
				enc.state = FishEncounterTypes.States.Resolved
				enc.resolvedAt = os.clock()
				CastingService.SetEncounter(player, nil)
				BobberService.Despawn(player)
				StreakService.RegisterWrong(player)
				RemoteService.FireClient(player, "CatchResolved", {
					EncounterId = enc.encounterId,
					FishId = fish.id,
					DisplayName = fish.displayName,
					Category = fish.category,
					Rarity = fish.rarity,
					WasCorrect = false,
					Outcome = FishEncounterTypes.OutcomeKinds.Escaped,
					LessonLine = "It slipped away. Set the hook quicker next time.",
					Pearls = 0,
					Xp = 0,
					Streak = 0,
				})
			end
		end)
	end)
end

function BiteService.Init()
	CastingService.SetBiteScheduler(scheduleBite)
	Players.PlayerRemoving:Connect(function(player)
		recentFishByPlayer[player] = nil
	end)
end

return BiteService
