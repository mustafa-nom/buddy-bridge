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
Constants.REEL_MINIGAME_SECONDS = 4.0
Constants.REEL_HIT_WINDOW = 0.18

-- Underpowered-rod feedback cooldown so players don't get spammed.
Constants.UNDERPOWERED_NUDGE_COOLDOWN = 6

-- Anti-spam on Cut Line.
Constants.CUT_LINE_STREAK_NUDGE_AT = 4

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
