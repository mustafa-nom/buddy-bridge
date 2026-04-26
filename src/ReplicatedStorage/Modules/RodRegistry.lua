--!strict
-- Rod tiers. Higher-tier rods unlock higher-tier zones and add reel forgiveness.
-- The Wooden Rod is granted free at session start.

local RodRegistry = {}

export type Rod = {
	id: string,
	displayName: string,
	tier: number,
	price: number,
	reelForgiveness: number,  -- extra hit window in seconds
	description: string,
}

local rods: { Rod } = {
	{
		id = "wooden_rod",
		displayName = "Wooden Rod",
		tier = 1,
		price = 0,
		reelForgiveness = 0,
		description = "Splintery but reliable. Tier 1 waters only.",
	},
	{
		id = "bamboo_rod",
		displayName = "Bamboo Rod",
		tier = 2,
		price = 60,
		reelForgiveness = 0.05,
		description = "Bendy and patient. Reaches Tier 2 fish.",
	},
	{
		id = "reinforced_rod",
		displayName = "Reinforced Rod",
		tier = 3,
		price = 220,
		reelForgiveness = 0.12,
		description = "Strong line, deep cast. Reaches Tier 3 fish.",
	},
}

local byId: { [string]: Rod } = {}
for _, r in ipairs(rods) do
	byId[r.id] = r
end

function RodRegistry.GetById(id: string): Rod?
	return byId[id]
end

function RodRegistry.All(): { Rod }
	return rods
end

function RodRegistry.DefaultRodId(): string
	return "wooden_rod"
end

function RodRegistry.MaxTier(): number
	local m = 0
	for _, r in ipairs(rods) do
		if r.tier > m then m = r.tier end
	end
	return m
end

return RodRegistry
