--!strict
-- Phish-Dex species catalog. Mirrors docs/PHISH_PHISH_DEX.md.
-- The fish models in ServerStorage.PhishFishTemplates have a FishId attribute
-- that matches `id` here (and the `species` field on a ScamCard).

export type Species = {
	id: string,
	displayName: string,
	realPatternName: string,
	rarity: string,
	description: string,
	realWorldInfo: string,
	redFlags: { string },
	defenseStrategy: string,
	catchesToUnlock: number,
	isLegit: boolean,
}

local PhishDex = {}

PhishDex.Species = {
	{
		id = "UrgencyEel",
		displayName = "Urgency Eel",
		realPatternName = "Urgency-based phishing",
		rarity = "Common",
		description = "Slippery and fast. Rushes you into bad decisions before you can think.",
		realWorldInfo = "Scammers create fake time pressure to bypass critical thinking. Real companies almost never require action within hours.",
		redFlags = {
			"Time-based threats (24 hours, immediately)",
			"All-caps subject lines",
			"Threats of account closure or loss",
		},
		defenseStrategy = "Pause. Real urgent issues can be resolved by calling the company directly using the number on their official website.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	{
		id = "AuthorityAnglerfish",
		displayName = "Authority Anglerfish",
		realPatternName = "Authority impersonation",
		rarity = "Uncommon",
		description = "Wears a glowing fake badge. Pretends to be someone in charge.",
		realWorldInfo = "Scammers impersonate IRS, banks, police, school admins, or employers. Real institutions rarely email about urgent action.",
		redFlags = {
			"Domain doesn't match the real institution",
			"Threats of legal/financial consequence",
			"Asks for verification info you wouldn't volunteer",
		},
		defenseStrategy = "Look up the institution's real number on their official site and call them.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	{
		id = "RewardTuna",
		displayName = "Reward Tuna",
		realPatternName = "Too-good-to-be-true reward",
		rarity = "Common",
		description = "Glittery and gold. Promises something for nothing.",
		realWorldInfo = "\"You won!\" emails for contests you never entered are universally scams.",
		redFlags = {
			"You didn't enter a contest",
			"\"Free [expensive item]\"",
			"Asks for shipping fee or verification payment",
		},
		defenseStrategy = "If you didn't enter, you didn't win. Delete.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	{
		id = "CuriosityCatfish",
		displayName = "Curiosity Catfish",
		realPatternName = "Clickbait / curiosity scam",
		rarity = "Common",
		description = "Wide eyes, wider mouth. Wants you to click before you read.",
		realWorldInfo = "Scammers exploit curiosity (\"Is this you in this video?\") to get clicks on malware or credential-stealing pages.",
		redFlags = {
			"Vague subject line designed to make you ask \"what?\"",
			"No personal context",
			"Single big \"view\" or \"open\" link",
		},
		defenseStrategy = "Real shared content has context. If the email is just bait + a link, it's bait.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	{
		id = "FearBass",
		displayName = "Fear Bass",
		realPatternName = "Threat / fear-based phishing",
		rarity = "Uncommon",
		description = "Spiky and dark. Scares you into clicking before you check.",
		realWorldInfo = "\"Suspicious login detected\" / \"Your photos leaked\" — scammers weaponize fear to short-circuit verification habits.",
		redFlags = {
			"Threat with tight deadline",
			"Claims of leaked data or compromised account",
			"Geographic scare",
		},
		defenseStrategy = "Don't click the email's link. Open a new tab and sign in directly to the real site.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	{
		id = "FamiliarityFlounder",
		displayName = "Familiarity Flounder",
		realPatternName = "Social engineering via familiarity",
		rarity = "Rare",
		description = "Looks like someone you know. Feels off when you read it twice.",
		realWorldInfo = "Scammers spoof friends' or family members' accounts to ask for gift cards, money transfers, or personal info.",
		redFlags = {
			"Out-of-character request (gift cards, urgent transfer)",
			"Won't talk on a phone call",
			"Sender address subtly different from the real person's",
		},
		defenseStrategy = "Call the person on a number you already have.",
		catchesToUnlock = 3,
		isLegit = false,
	},
	-- Legit fish: visual flavor for the cards that should be KEPT.
	{
		id = "PlainCarp",
		displayName = "Plain Carp",
		realPatternName = "Legitimate routine notice",
		rarity = "Common",
		description = "Clean and ordinary. The \"this is fine\" fish.",
		realWorldInfo = "Real notifications from services you use are usually short, calm, and don't ask for credentials.",
		redFlags = {},
		defenseStrategy = "Keep it.",
		catchesToUnlock = 3,
		isLegit = true,
	},
	{
		id = "HonestHerring",
		displayName = "Honest Herring",
		realPatternName = "Legitimate transactional email",
		rarity = "Common",
		description = "Silver, clean fins, gentle silhouette.",
		realWorldInfo = "Receipts, statements, and 2FA codes from real services are usually safe and useful.",
		redFlags = {},
		defenseStrategy = "Keep it.",
		catchesToUnlock = 3,
		isLegit = true,
	},
}

local byId: { [string]: Species } = {}
for _, s in ipairs(PhishDex.Species) do byId[s.id] = s end

function PhishDex.Get(id: string): Species?
	return byId[id]
end

function PhishDex.IsLegitSpecies(id: string): boolean
	local s = byId[id]
	return s ~= nil and s.isLegit
end

return PhishDex
