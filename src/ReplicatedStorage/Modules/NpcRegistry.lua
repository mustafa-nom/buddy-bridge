--!strict
-- NPC trait display fallback for the Stranger Danger manual.

local NpcRegistry = {}

NpcRegistry.Risk = {
	Risky = "Risky",
	Safe = "Safe",
	Neutral = "Neutral",
}

NpcRegistry.Traits = {
	InsideParkedCar = {
		Risk = "Risky",
		DisplayText = "Calling you over from inside a white van",
	},
	HoldingKnife = {
		Risk = "Risky",
		DisplayText = "Holding a knife in the alley behind the shop",
	},
	AskingPersonalInfo = {
		Risk = "Risky",
		DisplayText = "Asking your real name and school",
	},
	OfferingCandy = {
		Risk = "Risky",
		DisplayText = "Offering candy or game items to come with them",
	},
	WantsToGoSomewherePrivate = {
		Risk = "Risky",
		DisplayText = "Wants you to come somewhere private, out of the crowd",
	},
	AloneInBackAlley = {
		Risk = "Risky",
		DisplayText = "Standing alone in a place adults do not usually hang out",
	},
	BehindHotdogStand = {
		Risk = "Safe",
		DisplayText = "Behind the counter at the hot dog stand, wearing an apron",
	},
	WearingApron = {
		Risk = "Safe",
		DisplayText = "Wearing a uniform and helping multiple customers",
	},
	WithKidsAtPlayground = {
		Risk = "Safe",
		DisplayText = "With their kids in the playground",
	},
	PoliceUniform = {
		Risk = "Safe",
		DisplayText = "A police officer or park ranger in uniform",
	},
	ReadingOnBench = {
		Risk = "Safe",
		DisplayText = "Sitting on a public bench reading a book, ignoring you",
	},
}

NpcRegistry.AnchorBias = {
	WhiteVan = { Risky = 5, Safe = 0 },
	AlleyBehindShop = { Risky = 5, Safe = 0 },
	HotdogStand = { Risky = 0, Safe = 5 },
	RangerBooth = { Risky = 0, Safe = 5 },
	Playground = { Risky = 1, Safe = 4 },
	Bench = { Risky = 1, Safe = 4 },
	Fountain = { Risky = 1, Safe = 3 },
}

NpcRegistry.AnchorRequiredTraits = {
	WhiteVan = { Risky = { "InsideParkedCar" } },
	AlleyBehindShop = { Risky = { "HoldingKnife", "AloneInBackAlley" } },
	HotdogStand = { Safe = { "BehindHotdogStand", "WearingApron" } },
	RangerBooth = { Safe = { "PoliceUniform" } },
	Playground = { Safe = { "WithKidsAtPlayground" } },
	Bench = { Safe = { "ReadingOnBench" } },
}

function NpcRegistry.GetTagsByRisk(risk: string): { string }
	local result = {}
	for tag, info in pairs(NpcRegistry.Traits) do
		if info.Risk == risk then
			table.insert(result, tag)
		end
	end
	return result
end

return NpcRegistry
