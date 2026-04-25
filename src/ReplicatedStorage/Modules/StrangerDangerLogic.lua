--!strict
-- Stranger Danger shared cue and archetype data.

local StrangerDangerLogic = {}

StrangerDangerLogic.Verdict = {
	Approach = "Approach",
	Avoid = "Avoid",
}

export type Cue = {
	Tag: string,
	Risk: number,
	ExplorerText: string,
	GuideText: string,
}

StrangerDangerLogic.Cues = {
	InsideParkedCar = {
		Tag = "InsideParkedCar",
		Risk = -2,
		ExplorerText = "Sitting inside the parked van, waving at you",
		GuideText = "Calling you over from inside a vehicle",
	},
	OfferingCandy = {
		Tag = "OfferingCandy",
		Risk = -2,
		ExplorerText = "Holding out candy or a free game item",
		GuideText = "Offering candy or 'a secret' to come closer",
	},
	WantsPrivateSpot = {
		Tag = "WantsPrivateSpot",
		Risk = -2,
		ExplorerText = "Pointing toward a quiet alley away from the crowd",
		GuideText = "Wants you somewhere private, away from people",
	},
	HoldingKnife = {
		Tag = "HoldingKnife",
		Risk = -2,
		ExplorerText = "Holding something sharp at their side",
		GuideText = "Visible weapon: sharp object in hand",
	},
	AskingPersonalInfo = {
		Tag = "AskingPersonalInfo",
		Risk = -1,
		ExplorerText = "Asking what your real name is",
		GuideText = "Asking real name, school, or address",
	},
	HoodedAlone = {
		Tag = "HoodedAlone",
		Risk = -1,
		ExplorerText = "Hood pulled up, face shadowed",
		GuideText = "Hood up, face hidden, alone",
	},
	LingeringNoReason = {
		Tag = "LingeringNoReason",
		Risk = -1,
		ExplorerText = "Standing in one spot for a long time, watching",
		GuideText = "Hanging out where adults do not usually stand",
	},
	BehindCounter = {
		Tag = "BehindCounter",
		Risk = 2,
		ExplorerText = "Standing behind a counter with a register",
		GuideText = "Behind a shop counter, working",
	},
	WearingUniform = {
		Tag = "WearingUniform",
		Risk = 2,
		ExplorerText = "Wearing a uniform with a name tag",
		GuideText = "Uniform and visible name tag",
	},
	HelpingMultipleKids = {
		Tag = "HelpingMultipleKids",
		Risk = 1,
		ExplorerText = "Helping a line of kids, not just you",
		GuideText = "Helping many people, not focused on one",
	},
	WithFamily = {
		Tag = "WithFamily",
		Risk = 1,
		ExplorerText = "Pushing a stroller or holding a kid's hand",
		GuideText = "Busy with their own family",
	},
	IgnoringYou = {
		Tag = "IgnoringYou",
		Risk = 1,
		ExplorerText = "Reading on a bench, not looking up at you",
		GuideText = "Doing their own thing, not trying to get you",
	},
	OfficerBadge = {
		Tag = "OfficerBadge",
		Risk = 2,
		ExplorerText = "Park ranger badge on their chest",
		GuideText = "Park ranger or officer badge",
	},
}

export type Silhouette = {
	Headline: string,
	Outline: string,
	AccentColor: { number },
	Stance: string,
}

export type Archetype = {
	Template: string,
	BaseRisk: "Risky" | "Safe" | "Neutral",
	Silhouette: Silhouette,
	CuePool: { string },
	RequiredCues: { string }?,
	Bark: string?,
}

StrangerDangerLogic.Archetypes = {
	HotDogVendor = {
		Template = "HotDogVendor",
		BaseRisk = "Safe",
		Silhouette = {
			Headline = "Cheery vendor in a red apron behind a hot dog counter",
			Outline = "Apron and paper hat",
			AccentColor = { 220, 90, 78 },
			Stance = "Behind counter, smiling",
		},
		CuePool = { "BehindCounter", "WearingUniform", "HelpingMultipleKids" },
		RequiredCues = { "BehindCounter" },
		Bark = "Fresh dogs! Come get one!",
	},
	Ranger = {
		Template = "Ranger",
		BaseRisk = "Safe",
		Silhouette = {
			Headline = "Park ranger in a green uniform with a shiny badge",
			Outline = "Ranger hat and badge",
			AccentColor = { 78, 132, 88 },
			Stance = "On patrol, scanning the park",
		},
		CuePool = { "OfficerBadge", "WearingUniform", "HelpingMultipleKids" },
		RequiredCues = { "OfficerBadge" },
		Bark = "Stay safe out there, kiddo!",
	},
	ParentWithKid = {
		Template = "ParentWithKid",
		BaseRisk = "Safe",
		Silhouette = {
			Headline = "Adult pushing a stroller, holding a small kid's hand",
			Outline = "Stroller and kid",
			AccentColor = { 132, 200, 255 },
			Stance = "Walking with family",
		},
		CuePool = { "WithFamily", "HelpingMultipleKids", "IgnoringYou" },
		RequiredCues = { "WithFamily" },
		Bark = "Hold my hand sweetie, careful crossing!",
	},
	CasualParkGoer = {
		Template = "CasualParkGoer",
		BaseRisk = "Safe",
		Silhouette = {
			Headline = "Person on a bench reading, sunglasses on",
			Outline = "Sunglasses and book",
			AccentColor = { 180, 232, 140 },
			Stance = "Sitting, reading",
		},
		CuePool = { "IgnoringYou", "WithFamily" },
		Bark = "...",
	},
	HoodedAdult = {
		Template = "HoodedAdult",
		BaseRisk = "Risky",
		Silhouette = {
			Headline = "Tall figure with a black hood up, face shadowed",
			Outline = "Hood and dark cloak",
			AccentColor = { 60, 60, 64 },
			Stance = "Standing alone, hands hidden",
		},
		CuePool = { "HoodedAlone", "LingeringNoReason", "WantsPrivateSpot" },
		RequiredCues = { "HoodedAlone" },
		Bark = "Hey kid... come over here a sec.",
	},
	VehicleLeaner = {
		Template = "VehicleLeaner",
		BaseRisk = "Risky",
		Silhouette = {
			Headline = "Adult leaning out of a parked white van's open door",
			Outline = "Sunglasses and van",
			AccentColor = { 236, 110, 110 },
			Stance = "Leaning out a vehicle",
		},
		CuePool = { "InsideParkedCar", "OfferingCandy", "AskingPersonalInfo" },
		RequiredCues = { "InsideParkedCar" },
		Bark = "Want some candy? Hop in!",
	},
	KnifeArchetype = {
		Template = "KnifeArchetype",
		BaseRisk = "Risky",
		Silhouette = {
			Headline = "Tense figure in a dark hood holding something at their side",
			Outline = "Hood and something sharp",
			AccentColor = { 40, 40, 48 },
			Stance = "Tense, weapon visible",
		},
		CuePool = { "HoldingKnife", "HoodedAlone", "WantsPrivateSpot", "LingeringNoReason" },
		RequiredCues = { "HoldingKnife" },
		Bark = "...",
	},
}

local function shuffleInPlace<T>(list: { T })
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

function StrangerDangerLogic.PickCues(archetypeName: string, count: number): { string }
	local archetype = StrangerDangerLogic.Archetypes[archetypeName]
	if not archetype then return {} end
	local result: { string } = {}
	local seen: { [string]: boolean } = {}
	if archetype.RequiredCues then
		for _, tag in ipairs(archetype.RequiredCues) do
			if not seen[tag] and StrangerDangerLogic.Cues[tag] then
				table.insert(result, tag)
				seen[tag] = true
			end
		end
	end
	local pool = table.clone(archetype.CuePool)
	shuffleInPlace(pool)
	for _, tag in ipairs(pool) do
		if #result >= count then break end
		if not seen[tag] then
			table.insert(result, tag)
			seen[tag] = true
		end
	end
	return result
end

return StrangerDangerLogic
