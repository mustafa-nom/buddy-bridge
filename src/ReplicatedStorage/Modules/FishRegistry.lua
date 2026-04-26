--!strict
-- Authored fish catalog. Keep in sync with docs/PHISH_CONTENT.md.
-- Fields per fish: id, displayName, category, rarity, zoneTierMin,
-- bobberCue (color + ripple style), correctAction, fieldGuideEntry,
-- lessonLineCorrect, lessonLineWrong, xpReward, spawnWeight.

local Categories = require(script.Parent:WaitForChild("FishCategoryTypes"))
local Actions = require(script.Parent:WaitForChild("ReelActionTypes"))

local FishRegistry = {}

export type Fish = {
	id: string,
	displayName: string,
	category: string,
	rarity: string,
	zoneTierMin: number,
	bobberCue: { color: Color3, ripple: string },
	correctAction: string,
	fieldGuideEntry: string,
	lessonLineCorrect: string,
	lessonLineWrong: string,
	xpReward: number,
	spawnWeight: number,
}

local fish: { Fish } = {
	-- ============ Scam Bait (3) ============
	{
		id = "free_robux_bass",
		displayName = "Free Robux Bass",
		category = Categories.ScamBait,
		rarity = "Common",
		zoneTierMin = 1,
		bobberCue = { color = Color3.fromRGB(255, 215, 0), ripple = "GlitterSplash" },
		correctAction = Actions.CutLine,
		fieldGuideEntry = "Glittery and fast, but the gold dust is fake. The promise of free Robux is the lure.",
		lessonLineCorrect = "Smart move. Free in-game stuff for nothing is the bait.",
		lessonLineWrong = "Free Robux is never free. The bait took your XP.",
		xpReward = 10,
		spawnWeight = 30,
	},
	{
		id = "lottery_lobster",
		displayName = "Lottery Lobster",
		category = Categories.ScamBait,
		rarity = "Rare",
		zoneTierMin = 2,
		bobberCue = { color = Color3.fromRGB(240, 100, 230), ripple = "ConfettiSplash" },
		correctAction = Actions.CutLine,
		fieldGuideEntry = "A loud claw waving a prize you didn't enter. The 'win' is the trap.",
		lessonLineCorrect = "You can't win something you didn't enter. Cut the line.",
		lessonLineWrong = "If you didn't enter, you didn't win. That's how the lobster gets you.",
		xpReward = 18,
		spawnWeight = 14,
	},
	{
		id = "link_shark",
		displayName = "Link Shark",
		category = Categories.ScamBait,
		rarity = "Epic",
		zoneTierMin = 2,
		bobberCue = { color = Color3.fromRGB(70, 130, 240), ripple = "UnderlineRipple" },
		correctAction = Actions.CutLine,
		fieldGuideEntry = "Slick blue body, sharp teeth, hides links from strangers under its fin.",
		lessonLineCorrect = "Mystery links from strangers belong under the water.",
		lessonLineWrong = "Following a stranger's link is how the Link Shark feeds.",
		xpReward = 28,
		spawnWeight = 8,
	},

	-- ============ Rumor Fish (3) ============
	{
		id = "telephone_trout",
		displayName = "Telephone Trout",
		category = Categories.Rumor,
		rarity = "Common",
		zoneTierMin = 1,
		bobberCue = { color = Color3.fromRGB(180, 200, 255), ripple = "WobbleRipple" },
		correctAction = Actions.Release,
		fieldGuideEntry = "Tells you a story it heard from a friend who heard it from a friend.",
		lessonLineCorrect = "Stories that travel get warped. Toss it back.",
		lessonLineWrong = "Spreading what you heard is how the trout multiplies.",
		xpReward = 12,
		spawnWeight = 26,
	},
	{
		id = "wiki_walleye",
		displayName = "Wiki-Forgery Walleye",
		category = Categories.Rumor,
		rarity = "Rare",
		zoneTierMin = 2,
		bobberCue = { color = Color3.fromRGB(220, 220, 255), ripple = "PageFlutter" },
		correctAction = Actions.Release,
		fieldGuideEntry = "Looks well-sourced until you realize anyone can write the source.",
		lessonLineCorrect = "Check more than one source. Then back into the water.",
		lessonLineWrong = "One source isn't a source. The walleye loved that.",
		xpReward = 20,
		spawnWeight = 12,
	},
	{
		id = "hallucinated_halibut",
		displayName = "Hallucinated Halibut",
		category = Categories.Rumor,
		rarity = "Epic",
		zoneTierMin = 3,
		bobberCue = { color = Color3.fromRGB(180, 255, 220), ripple = "PixelGlitch" },
		correctAction = Actions.Release,
		fieldGuideEntry = "Confidently makes things up. AI can do that. Verify it.",
		lessonLineCorrect = "Confidence isn't truth. Always verify.",
		lessonLineWrong = "It sounded sure, but it was making it up.",
		xpReward = 32,
		spawnWeight = 6,
	},

	-- ============ Mod Imposters (3) ============
	{
		id = "faux_mod_flounder",
		displayName = "Faux-Mod Flounder",
		category = Categories.ModImposter,
		rarity = "Common",
		zoneTierMin = 1,
		bobberCue = { color = Color3.fromRGB(80, 130, 220), ripple = "FakeBadge" },
		correctAction = Actions.Report,
		fieldGuideEntry = "Wears a badge that's slightly off. Real mods never DM for your password.",
		lessonLineCorrect = "Reported. Real mods don't DM for passwords.",
		lessonLineWrong = "That badge was painted on. Always report fake mods.",
		xpReward = 14,
		spawnWeight = 22,
	},
	{
		id = "pseudo_support_shark",
		displayName = "Pseudo-Support Shark",
		category = Categories.ModImposter,
		rarity = "Rare",
		zoneTierMin = 2,
		bobberCue = { color = Color3.fromRGB(120, 180, 230), ripple = "LifebuoyHook" },
		correctAction = Actions.Report,
		fieldGuideEntry = "Offers help if you 'just share your account real quick.' Don't.",
		lessonLineCorrect = "Real support never asks you to share your account.",
		lessonLineWrong = "Sharing your account is how the shark eats. Report next time.",
		xpReward = 22,
		spawnWeight = 11,
	},
	{
		id = "counterfeit_admin_cod",
		displayName = "Counterfeit-Admin Cod",
		category = Categories.ModImposter,
		rarity = "Epic",
		zoneTierMin = 3,
		bobberCue = { color = Color3.fromRGB(255, 215, 100), ripple = "CrownGlint" },
		correctAction = Actions.Report,
		fieldGuideEntry = "Crown looks real until you notice the missing detail. Urgency is the giveaway.",
		lessonLineCorrect = "If 'an admin' threatens you, it's fake. Report.",
		lessonLineWrong = "Urgency is the tell. The real admins don't pressure you.",
		xpReward = 34,
		spawnWeight = 5,
	},

	-- ============ Kindness Fish (3) ============
	{
		id = "compliment_carp",
		displayName = "Compliment Carp",
		category = Categories.Kindness,
		rarity = "Common",
		zoneTierMin = 1,
		bobberCue = { color = Color3.fromRGB(255, 180, 200), ripple = "SoftGlow" },
		correctAction = Actions.Reel,
		fieldGuideEntry = "Pink and gentle. Carries kind words home with it.",
		lessonLineCorrect = "Kind words are real treasure. Keep them.",
		lessonLineWrong = "That was a real one. You let kindness slip.",
		xpReward = 16,
		spawnWeight = 24,
	},
	{
		id = "helpful_hint_herring",
		displayName = "Helpful-Hint Herring",
		category = Categories.Kindness,
		rarity = "Rare",
		zoneTierMin = 2,
		bobberCue = { color = Color3.fromRGB(255, 235, 130), ripple = "WarmGlow" },
		correctAction = Actions.Reel,
		fieldGuideEntry = "Calm and clear. Genuine help looks like this.",
		lessonLineCorrect = "Genuine help is calm and clear. Reel it in.",
		lessonLineWrong = "That was real help. Try Reel next time.",
		xpReward = 24,
		spawnWeight = 10,
	},
	{
		id = "real_friend_rainbow",
		displayName = "Real-Friend Rainbow",
		category = Categories.Kindness,
		rarity = "Legendary",
		zoneTierMin = 3,
		bobberCue = { color = Color3.fromRGB(180, 240, 255), ripple = "RainbowShimmer" },
		correctAction = Actions.Reel,
		fieldGuideEntry = "Slow shimmer, music sting, rare. Real friends show up steady.",
		lessonLineCorrect = "Real friends show up steady. Treasure this one.",
		lessonLineWrong = "You let a Real-Friend Rainbow get away. They show up again, but rarely.",
		xpReward = 60,
		spawnWeight = 3,
	},
}

local byId: { [string]: Fish } = {}
for _, f in ipairs(fish) do
	byId[f.id] = f
end

function FishRegistry.GetById(id: string): Fish?
	return byId[id]
end

function FishRegistry.All(): { Fish }
	return fish
end

function FishRegistry.PoolForZoneTier(zoneTier: number): { Fish }
	local pool = {}
	for _, f in ipairs(fish) do
		if f.zoneTierMin <= zoneTier then
			table.insert(pool, f)
		end
	end
	return pool
end

return FishRegistry
