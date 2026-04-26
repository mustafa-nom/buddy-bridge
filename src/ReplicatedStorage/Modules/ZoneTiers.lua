--!strict
-- Tier metadata for the cast zones. Geometry/anchors come from User 1's map.
-- This module defines the *meaning* of each tier (label, color, payout boost).

local ZoneTiers = {}

export type ZoneTierInfo = {
	tier: number,
	displayName: string,
	color: Color3,
	payoutMultiplier: number,
	requiredRodTier: number,
}

local tiers: { ZoneTierInfo } = {
	{
		tier = 1,
		displayName = "Calm Cove",
		color = Color3.fromRGB(120, 180, 220),
		payoutMultiplier = 1,
		requiredRodTier = 1,
	},
	{
		tier = 2,
		displayName = "Murky Channel",
		color = Color3.fromRGB(80, 130, 110),
		payoutMultiplier = 1.6,
		requiredRodTier = 2,
	},
	{
		tier = 3,
		displayName = "Phisher's Trench",
		color = Color3.fromRGB(60, 60, 110),
		payoutMultiplier = 2.4,
		requiredRodTier = 3,
	},
}

local byTier: { [number]: ZoneTierInfo } = {}
for _, t in ipairs(tiers) do
	byTier[t.tier] = t
end

function ZoneTiers.Get(tier: number): ZoneTierInfo?
	return byTier[tier]
end

function ZoneTiers.All(): { ZoneTierInfo }
	return tiers
end

function ZoneTiers.MaxTier(): number
	local m = 0
	for _, t in ipairs(tiers) do
		if t.tier > m then m = t.tier end
	end
	return m
end

return ZoneTiers
