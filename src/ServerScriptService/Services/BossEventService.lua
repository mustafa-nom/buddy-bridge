--!strict
-- Server-wide boss event. Every Constants.BOSS.IntervalSeconds, picks a
-- random eligible boss fish and broadcasts a window. The first player to
-- cast during the window has their next bite *forced* to the boss fish.
-- Boss catches award Constants.BOSS.RewardMultiplier on top of the normal
-- pearl payout and broadcast a hype banner to every player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local BossEventService = {}

type Event = {
	fishId: string,
	displayName: string,
	rarity: string,
	startedAt: number,
	endsAt: number,
	claimedBy: Player?,
}

local current: Event? = nil
local nextEventAt: number = 0

local function pickBossFish()
	local pool = {}
	for _, id in ipairs(Constants.BOSS.BossFishIds) do
		local fish = FishRegistry.GetById(id)
		if fish then table.insert(pool, fish) end
	end
	if #pool == 0 then return nil end
	return pool[math.random(#pool)]
end

local function scheduleNext()
	nextEventAt = os.clock() + Constants.BOSS.IntervalSeconds
end

local function startEvent()
	local fish = pickBossFish()
	if not fish then
		scheduleNext()
		return
	end
	current = {
		fishId = fish.id,
		displayName = fish.displayName,
		rarity = fish.rarity,
		startedAt = os.clock(),
		endsAt = os.clock() + Constants.BOSS.WindowSeconds,
		claimedBy = nil,
	}
	RemoteService.FireAllClients("BossEventStarted", {
		FishId = fish.id,
		DisplayName = fish.displayName,
		Rarity = fish.rarity,
		WindowSec = Constants.BOSS.WindowSeconds,
	})
end

local function endEvent(reason: string)
	if not current then return end
	RemoteService.FireAllClients("BossEventEnded", {
		Reason = reason,
		ClaimedBy = current.claimedBy and (current.claimedBy.DisplayName or current.claimedBy.Name) or nil,
		FishId = current.fishId,
	})
	current = nil
	scheduleNext()
end

-- Called by BiteService.scheduleBite right before it picks a fish.
-- If a boss event is active and unclaimed, claim it for this player and
-- return the forced boss fish. Otherwise returns nil so BiteService falls
-- back to its weighted random.
function BossEventService.TryClaim(player: Player)
	if not current then return nil end
	if current.claimedBy then return nil end
	if os.clock() > current.endsAt then return nil end
	current.claimedBy = player
	local fish = FishRegistry.GetById(current.fishId)
	if not fish then return nil end
	RemoteService.FireAllClients("BossEventClaimed", {
		ClaimerName = player.DisplayName or player.Name,
		FishId = fish.id,
		DisplayName = fish.displayName,
		Rarity = fish.rarity,
	})
	return fish
end

function BossEventService.IsActive(): boolean
	return current ~= nil
end

function BossEventService.IsBossFishForPlayer(player: Player, fishId: string): boolean
	return current ~= nil
		and current.claimedBy == player
		and current.fishId == fishId
end

function BossEventService.RewardMultiplier(): number
	return Constants.BOSS.RewardMultiplier
end

-- Called by CatchResolutionService once a boss catch resolves so we can
-- close the event window.
function BossEventService.NoteResolution(player: Player, fishId: string, wasCorrect: boolean)
	if not current then return end
	if current.claimedBy ~= player then return end
	if current.fishId ~= fishId then return end
	endEvent(wasCorrect and "Claimed" or "MissedClaim")
end

local lastTick = 0
local function tick()
	local now = os.clock()
	if (now - lastTick) < 1 then return end
	lastTick = now
	if current then
		if now > current.endsAt and not current.claimedBy then
			endEvent("Expired")
		end
	else
		if now >= nextEventAt then
			startEvent()
		end
	end
end

function BossEventService.Init()
	nextEventAt = os.clock() + Constants.BOSS.StartupGraceSeconds
	game:GetService("RunService").Heartbeat:Connect(tick)
end

return BossEventService
