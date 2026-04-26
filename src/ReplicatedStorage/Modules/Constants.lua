--!strict
-- Shared PHISH! constants. Single source for tunables touched by both server and client.

local Constants = {}

-- Server limits
Constants.MAX_PLAYERS_PER_SERVER = 8

-- Folder name for the runtime-created remote folder.
Constants.REMOTE_FOLDER_NAME = "PhishRemotes"

-- Client ScreenGui name.
Constants.SCREEN_GUI_NAME = "PhishUI"

-- Cast / bite / decision timing (seconds)
Constants.CAST_CHARGE_MIN = 0.2
Constants.CAST_CHARGE_MAX = 1.6
Constants.CAST_COOLDOWN_SECONDS = 0.6
Constants.BITE_WAIT_MIN = 1.6
Constants.BITE_WAIT_MAX = 3.8
Constants.DECISION_WINDOW_SECONDS = 4.5
Constants.VERIFY_PAUSE_SECONDS = 2.5
Constants.REEL_MINIGAME_SECONDS = 7.5
Constants.REEL_HIT_WINDOW = 0.18

-- Tension-bar mini-game (Stardew-style). All values are 0..1 fractions of
-- the bar height unless noted.
Constants.REEL = {
	BarHeight = 1,
	CursorStart = 0.5,
	-- Catch zone size by rarity. Smaller = harder.
	CatchZoneSize = {
		Common = 0.34,
		Rare = 0.26,
		Epic = 0.18,
		Legendary = 0.14,
	},
	-- How often the catch zone changes direction (seconds between flips).
	CatchZonePeriod = {
		Common = 1.6,
		Rare = 1.2,
		Epic = 0.9,
		Legendary = 0.7,
	},
	CatchZoneSpeed = 0.28,         -- bar-fractions per second
	-- Cursor physics.
	Gravity = 0.8,                  -- bar-fractions per second^2 when not pressing
	RiseAccel = 1.7,                -- bar-fractions per second^2 when holding input
	MaxRiseSpeed = 1.1,
	MaxFallSpeed = 0.9,
	-- Progress meter.
	ProgressFillRate = 0.27,        -- per second when cursor inside catch zone
	ProgressEmptyRate = 0.18,       -- per second when outside
	ProgressStart = 0.4,
	-- Server tick rate for the reel simulation.
	ServerTickHz = 20,
	ClientTickRemoteHz = 18,        -- rate-limit guard for inputs
	-- Catch threshold (>= this fraction wins).
	CatchThreshold = 1.0,
	-- Lose threshold (<= this fraction loses early).
	LoseThreshold = 0.0,
}

-- Underpowered-rod feedback cooldown so players don't get spammed.
Constants.UNDERPOWERED_NUDGE_COOLDOWN = 6

-- Anti-spam on Cut Line.
Constants.CUT_LINE_STREAK_NUDGE_AT = 4

-- Streak / combo system.
Constants.STREAK = {
	-- Multiplier applied to pearls + xp at each streak count. Indexed by streak.
	-- Streak counts above the table cap stay at the highest tier.
	-- (1=neutral, 3=+25%, 5=+50%, 7=+100%, 10=+150%)
	Multiplier = { 1.0, 1.0, 1.25, 1.25, 1.5, 1.5, 2.0, 2.0, 2.0, 2.5 },
	-- Public announcement broadcast on streak >= this value.
	PublicAnnounceAt = 5,
}

-- Lucky bobber: a small chance the cast surfaces a glittery lure that
-- doubles the next catch's payout. Visually distinct so players know.
Constants.LUCKY_BOBBER_CHANCE = 0.07
Constants.LUCKY_BOBBER_MULTIPLIER = 2.0

-- Title progression by total correct catches.
Constants.TITLES = {
	{ threshold = 0,   title = "Tadpole" },
	{ threshold = 5,   title = "Angler" },
	{ threshold = 15,  title = "Captain" },
	{ threshold = 35,  title = "Lighthouse Keeper" },
	{ threshold = 70,  title = "Lodge Legend" },
}

-- Bobber world part defaults.
Constants.BOBBER = {
	ForwardOffset = 7.5,
	UpOffset = 0.4,
	IdleBobAmplitude = 0.25,
	IdleBobPeriod = 1.4,
	BiteDipDepth = 1.4,
	BiteDipReturnTime = 0.35,
}

-- Rate limits (seconds between requests; player-keyed).
Constants.RATE_LIMIT_CAST = 0.6
Constants.RATE_LIMIT_DECISION = 0.25
Constants.RATE_LIMIT_VERIFY = 0.5
Constants.RATE_LIMIT_REEL_INPUT = 0.05
Constants.RATE_LIMIT_PLACE_FISH = 0.5
Constants.RATE_LIMIT_SHOP = 0.5
Constants.RATE_LIMIT_SELL = 0.4
Constants.RATE_LIMIT_BOAT_INPUT = 0.05

-- Currency
Constants.STARTING_PEARLS = 25
Constants.SELL_RARITY_MULTIPLIER = {
	Common = 1,
	Rare = 2,
	Epic = 4,
	Legendary = 10,
}
Constants.SELL_BASE_PAYOUT = 5

-- XP
Constants.XP_TOAST_DURATION = 2

-- Tags expected from User 1's map (see docs/INTEGRATION_CONTRACT_USER2.md).
Constants.TAGS = {
	CastZone = "PhishCastZone",
	LodgeSpawn = "PhishLodgeSpawn",
	Aquarium = "PhishAquariumDisplay",
	ShopPrompt = "PhishShopPrompt",
	SellPrompt = "PhishSellPrompt",
	Rowboat = "PhishRowboat",
	RowboatSeat = "PhishRowboatSeat",
	FishTemplate = "PhishFishTemplate",
}

Constants.ATTRS = {
	ZoneTier = "ZoneTier",
	ZoneId = "ZoneId",
	FishId = "FishId",
	BoatId = "BoatId",
	BoatSpeed = "BoatSpeed",
	BoatTurnRate = "BoatTurnRate",
}

return Constants
