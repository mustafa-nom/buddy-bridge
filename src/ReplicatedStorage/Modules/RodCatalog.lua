--!strict
-- Rod data: id, display name, tier, price, description, and how to color the
-- model. Server reads it to validate purchases + build the templates into
-- ReplicatedStorage.PhishRods. Client reads it to render the shop list.

export type Rod = {
	id: string,
	name: string,
	tier: number,                -- 1..4
	price: number,               -- pearls
	description: string,
	-- Visual styling: every rod uses the same anatomy as RodService.buildRod
	-- but with these tier-specific colors / accents.
	handleColor: { number },
	wrapColor: { number },
	reelColor: { number },
	bandColor: { number },
	upperShaftColor: { number },
	tipColor: { number },
	upperShaftMaterial: string,  -- "Wood" | "Marble" | "Neon"
	tipGlowRange: number,
}

local RodCatalog = {}

RodCatalog.Rods = {
	{
		id = "wooden_rod", name = "Wooden Rod", tier = 1, price = 0,
		description = "The starter rod. Cuts through Beginner waters cleanly.",
		handleColor = {80, 50, 35}, wrapColor = {30, 30, 35},
		reelColor = {40, 40, 45}, bandColor = {200, 150, 70},
		upperShaftColor = {60, 40, 30}, tipColor = {255, 220, 150},
		upperShaftMaterial = "Wood", tipGlowRange = 6,
	},
	{
		id = "cedar_rod", name = "Cedar Rod", tier = 2, price = 50,
		description = "Sturdier cedar. Reaches Intermediate (Mossy Marsh) waters.",
		handleColor = {120, 70, 50}, wrapColor = {30, 30, 35},
		reelColor = {60, 60, 70}, bandColor = {220, 180, 90},
		upperShaftColor = {80, 50, 35}, tipColor = {255, 200, 120},
		upperShaftMaterial = "Wood", tipGlowRange = 8,
	},
	{
		id = "mariner_rod", name = "Mariner Rod", tier = 3, price = 200,
		description = "Brass-fitted deep-sea rod. Pulls Expert (Storm Channel) catches.",
		handleColor = {50, 35, 25}, wrapColor = {20, 20, 30},
		reelColor = {220, 180, 80}, bandColor = {255, 220, 120},
		upperShaftColor = {35, 25, 20}, tipColor = {120, 220, 255},
		upperShaftMaterial = "Wood", tipGlowRange = 12,
	},
	{
		id = "astral_rod", name = "Astral Rod", tier = 4, price = 800,
		description = "Tuned to the Abyss. Catches what others can't see.",
		handleColor = {30, 20, 50}, wrapColor = {15, 10, 30},
		reelColor = {180, 80, 220}, bandColor = {220, 80, 220},
		upperShaftColor = {40, 30, 70}, tipColor = {255, 100, 220},
		upperShaftMaterial = "Neon", tipGlowRange = 18,
	},
}

local byId: { [string]: Rod } = {}
local byTier: { [number]: Rod } = {}
for _, r in ipairs(RodCatalog.Rods) do byId[r.id] = r; byTier[r.tier] = r end

function RodCatalog.GetById(id: string): Rod?
	return byId[id]
end

function RodCatalog.GetByTier(tier: number): Rod?
	return byTier[tier]
end

return RodCatalog
