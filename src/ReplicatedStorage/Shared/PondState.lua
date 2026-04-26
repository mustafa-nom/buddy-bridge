--!strict
-- Per-player encounter state. Server writes these; clients only see
-- snapshots via remote payloads.

local FishEncounterTypes = require(script.Parent:WaitForChild("FishEncounterTypes"))

local PondState = {}

export type Encounter = {
	encounterId: string,
	state: string,
	zoneId: string?,
	zoneTier: number,
	rodId: string,
	fishId: string?,
	correctAction: string?,
	bobberCue: { color: Color3, ripple: string }?,
	startedAt: number,
	bitedAt: number?,
	verified: boolean,
	resolvedAt: number?,
}

local _idCounter = 0

function PondState.NewId(): string
	_idCounter += 1
	return string.format("enc_%d_%d", math.floor(os.clock() * 1000), _idCounter)
end

function PondState.New(player: Player, zoneId: string?, zoneTier: number, rodId: string): Encounter
	local _ = player
	return {
		encounterId = PondState.NewId(),
		state = FishEncounterTypes.States.Casting,
		zoneId = zoneId,
		zoneTier = zoneTier,
		rodId = rodId,
		fishId = nil,
		correctAction = nil,
		bobberCue = nil,
		startedAt = os.clock(),
		bitedAt = nil,
		verified = false,
		resolvedAt = nil,
	}
end

function PondState.IsBitePending(enc: Encounter): boolean
	return enc.state == FishEncounterTypes.States.BitePending
		or enc.state == FishEncounterTypes.States.Verifying
end

return PondState
