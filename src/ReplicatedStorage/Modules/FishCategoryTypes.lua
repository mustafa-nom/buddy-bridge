--!strict
-- Enum of the four fish categories. Each maps to a real online-safety
-- archetype the player learns to recognize.

local FishCategoryTypes = {}

FishCategoryTypes.ScamBait = "ScamBait"
FishCategoryTypes.Rumor = "Rumor"
FishCategoryTypes.ModImposter = "ModImposter"
FishCategoryTypes.Kindness = "Kindness"

FishCategoryTypes.All = {
	FishCategoryTypes.ScamBait,
	FishCategoryTypes.Rumor,
	FishCategoryTypes.ModImposter,
	FishCategoryTypes.Kindness,
}

function FishCategoryTypes.IsValid(value: string?): boolean
	if typeof(value) ~= "string" then return false end
	for _, c in ipairs(FishCategoryTypes.All) do
		if c == value then return true end
	end
	return false
end

return FishCategoryTypes
