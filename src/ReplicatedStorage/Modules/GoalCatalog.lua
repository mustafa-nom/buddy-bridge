--!strict
-- Pool of session goal templates. GoalsService picks 3 at random per
-- player on join. Each goal has a stable id, a target progress value, a
-- pearl reward, a kind (drives the event hook in GoalsService.RecordEvent),
-- and an optional filter (e.g. category for ModImposter goals).

local FishCategoryTypes = require(script.Parent:WaitForChild("FishCategoryTypes"))
local Actions = require(script.Parent:WaitForChild("ReelActionTypes"))

local GoalCatalog = {}

export type Goal = {
	id: string,
	displayName: string,
	target: number,
	reward: number,
	kind: string,           -- "CategoryCorrect" | "ActionCorrect" | "Streak" | "EarnPearls" | "AquariumPlace" | "RarityCatch"
	filter: { [string]: any }?,
}

local goals: { Goal } = {
	{
		id = "mod_imposter_3",
		displayName = "Report 3 Mod Imposters",
		target = 3,
		reward = 60,
		kind = "CategoryCorrect",
		filter = { category = FishCategoryTypes.ModImposter },
	},
	{
		id = "scam_3",
		displayName = "Cut 3 scam lines",
		target = 3,
		reward = 50,
		kind = "ActionCorrect",
		filter = { action = Actions.CutLine },
	},
	{
		id = "verify_3",
		displayName = "Verify 3 fish before reeling",
		target = 3,
		reward = 40,
		kind = "VerifyUse",
	},
	{
		id = "kindness_2",
		displayName = "Reel 2 kindness fish",
		target = 2,
		reward = 70,
		kind = "CategoryCorrect",
		filter = { category = FishCategoryTypes.Kindness },
	},
	{
		id = "streak_5",
		displayName = "Hit a 5-catch streak",
		target = 5,
		reward = 80,
		kind = "Streak",
	},
	{
		id = "rare_or_better",
		displayName = "Catch a Rare or better fish",
		target = 1,
		reward = 50,
		kind = "RarityCatch",
		filter = { minRarity = "Rare" },
	},
	{
		id = "aquarium_1",
		displayName = "Place 1 fish in the aquarium",
		target = 1,
		reward = 30,
		kind = "AquariumPlace",
	},
	{
		id = "earn_200",
		displayName = "Earn 200 pearls this session",
		target = 200,
		reward = 60,
		kind = "EarnPearls",
	},
}

function GoalCatalog.All(): { Goal }
	return goals
end

function GoalCatalog.Pick(n: number): { Goal }
	local pool = table.clone(goals)
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local picked = {}
	for i = 1, math.min(n, #pool) do
		table.insert(picked, pool[i])
	end
	return picked
end

return GoalCatalog
