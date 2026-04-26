--!strict
-- Stardew-style tension-bar mini-game, server-simulated.
--
-- Shape:
--   * cursor moves up while the player holds input, falls under "gravity"
--     when not holding.
--   * catch zone bobs up and down on the bar with rarity-scaled speed/size.
--   * progress meter fills while cursor is inside catch zone, empties
--     while outside. Hit 1.0 → success. Hit 0.0 or timeout → fail.
--
-- Per-player session state lives in `active[player]`. Inputs come from the
-- client at <= ClientTickRemoteHz. The simulation tick runs at ServerTickHz
-- and emits ReelMinigameTick to the client.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local ReelMinigameService = {}

type Session = {
	player: Player,
	encounterId: string,
	startedAt: number,
	endsAt: number,
	cursor: number,
	cursorVel: number,
	zoneCenter: number,
	zoneVel: number,
	zoneSize: number,
	progress: number,
	holding: boolean,
	rarity: string,
	resolved: boolean,
	onResolve: ((boolean) -> ())?,
	-- Audit: how often the cursor was inside.
	hitTime: number,
	totalTime: number,
	rodForgiveness: number,
}

local active: { [Player]: Session } = {}
local lastClientInputAt: { [Player]: number } = {}

local function clamp(v: number, lo: number, hi: number): number
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

local function emitTick(s: Session)
	RemoteService.FireClient(s.player, "ReelMinigameTick", {
		EncounterId = s.encounterId,
		Cursor = s.cursor,
		ZoneCenter = s.zoneCenter,
		ZoneSize = s.zoneSize,
		Progress = s.progress,
		Remaining = math.max(0, s.endsAt - os.clock()),
	})
end

local function finish(player: Player, successful: boolean)
	local s = active[player]
	if not s or s.resolved then return end
	s.resolved = true
	active[player] = nil
	RemoteService.FireClient(player, "ReelMinigameResolved", {
		EncounterId = s.encounterId,
		Successful = successful,
		Progress = s.progress,
	})
	if s.onResolve then
		task.spawn(s.onResolve, successful)
	end
end

local function step(s: Session, dt: number)
	-- Cursor physics.
	local accel
	if s.holding then
		accel = Constants.REEL.RiseAccel
	else
		accel = -Constants.REEL.Gravity
	end
	s.cursorVel = clamp(s.cursorVel + accel * dt, -Constants.REEL.MaxFallSpeed, Constants.REEL.MaxRiseSpeed)
	s.cursor += s.cursorVel * dt
	if s.cursor < 0 then
		s.cursor = 0
		s.cursorVel = 0
	elseif s.cursor > 1 then
		s.cursor = 1
		s.cursorVel = 0
	end

	-- Catch zone bobs.
	s.zoneCenter += s.zoneVel * dt
	local halfZone = s.zoneSize * 0.5
	if s.zoneCenter - halfZone < 0 then
		s.zoneCenter = halfZone
		s.zoneVel = math.abs(s.zoneVel)
	elseif s.zoneCenter + halfZone > 1 then
		s.zoneCenter = 1 - halfZone
		s.zoneVel = -math.abs(s.zoneVel)
	end

	-- Progress.
	local inZone = s.cursor >= s.zoneCenter - halfZone - s.rodForgiveness
		and s.cursor <= s.zoneCenter + halfZone + s.rodForgiveness
	s.totalTime += dt
	if inZone then
		s.hitTime += dt
		s.progress = clamp(s.progress + Constants.REEL.ProgressFillRate * dt, 0, 1)
	else
		s.progress = clamp(s.progress - Constants.REEL.ProgressEmptyRate * dt, 0, 1)
	end
end

local accumulator = 0
local tickInterval = 1 / Constants.REEL.ServerTickHz
local function heartbeat(dt: number)
	accumulator += dt
	while accumulator >= tickInterval do
		accumulator -= tickInterval
		local now = os.clock()
		for player, s in pairs(active) do
			if not player.Parent then
				active[player] = nil
				continue
			end
			step(s, tickInterval)
			emitTick(s)
			if s.progress >= Constants.REEL.CatchThreshold then
				finish(player, true)
			elseif s.progress <= Constants.REEL.LoseThreshold then
				finish(player, false)
			elseif now >= s.endsAt then
				finish(player, s.progress >= 0.5)
			end
		end
	end
end

function ReelMinigameService.Start(
	player: Player,
	encounterId: string,
	rarity: string,
	rodForgiveness: number,
	onResolve: ((boolean) -> ())?
)
	local zoneSize = Constants.REEL.CatchZoneSize[rarity] or Constants.REEL.CatchZoneSize.Common
	local periodSec = Constants.REEL.CatchZonePeriod[rarity] or Constants.REEL.CatchZonePeriod.Common
	-- pick an initial direction; speed = bar-fractions/sec from period & travel range.
	local travelRange = 1 - zoneSize
	local zoneSpeed = (travelRange / periodSec)
	if math.random() > 0.5 then zoneSpeed = -zoneSpeed end
	local s: Session = {
		player = player,
		encounterId = encounterId,
		startedAt = os.clock(),
		endsAt = os.clock() + Constants.REEL_MINIGAME_SECONDS,
		cursor = Constants.REEL.CursorStart,
		cursorVel = 0,
		zoneCenter = math.random() * (1 - zoneSize) + zoneSize * 0.5,
		zoneVel = zoneSpeed,
		zoneSize = zoneSize,
		progress = Constants.REEL.ProgressStart,
		holding = false,
		rarity = rarity,
		resolved = false,
		onResolve = onResolve,
		hitTime = 0,
		totalTime = 0,
		rodForgiveness = rodForgiveness,
	}
	active[player] = s
	RemoteService.FireClient(player, "ReelMinigameStarted", {
		EncounterId = encounterId,
		DurationSec = Constants.REEL_MINIGAME_SECONDS,
		ZoneSize = zoneSize,
		ZoneCenter = s.zoneCenter,
		Cursor = s.cursor,
		Progress = s.progress,
		Rarity = rarity,
	})
end

function ReelMinigameService.OnInput(player: Player, encounterId: string, holding: boolean)
	local s = active[player]
	if not s then return end
	if s.encounterId ~= encounterId then return end
	-- Light client-side rate guard.
	local now = os.clock()
	local last = lastClientInputAt[player] or 0
	if (now - last) < (1 / Constants.REEL.ClientTickRemoteHz) then return end
	lastClientInputAt[player] = now
	s.holding = holding == true
end

function ReelMinigameService.Cancel(player: Player)
	local s = active[player]
	if not s then return end
	finish(player, false)
end

function ReelMinigameService.Init()
	RunService.Heartbeat:Connect(heartbeat)
	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
		lastClientInputAt[player] = nil
	end)
end

return ReelMinigameService
