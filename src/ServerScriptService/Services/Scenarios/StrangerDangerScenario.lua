--!strict
-- Generates Stranger Danger Park NPCs for the booth-submit redesign.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local TagQueries = require(Modules:WaitForChild("TagQueries"))
local LevelTypes = require(Modules:WaitForChild("LevelTypes"))
local PlayAreaConfig = require(Modules:WaitForChild("PlayAreaConfig"))
local StrangerDangerLogic = require(Modules:WaitForChild("StrangerDangerLogic"))
local BadgeConfig = require(Modules:WaitForChild("BadgeConfig"))
local ScenarioTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ScenarioTypes"))

local StrangerDangerScenario = {}

local SAFE_ARCHETYPES = { "HotDogVendor", "Ranger", "ParentWithKid", "CasualParkGoer" }
local RISKY_ARCHETYPES = { "VehicleLeaner", "HoodedAdult", "KnifeArchetype" }

local ANCHOR_FAVORITES = {
	HotdogShop = { Safe = "HotDogVendor" },
	GeneralStore = { Safe = "Ranger" },
	WhiteVan = { Risky = "VehicleLeaner" },
	AlleyMouth = { Risky = "KnifeArchetype" },
	NorthSidewalk = { Safe = "ParentWithKid" },
	SouthSidewalk = { Safe = "CasualParkGoer" },
	EastSidewalk = { Safe = "ParentWithKid", Risky = "HoodedAdult" },
	WestSidewalk = { Safe = "CasualParkGoer", Risky = "HoodedAdult" },
}

local ANCHOR_RISK_BIAS = {
	HotdogShop = 0,
	GeneralStore = 0,
	WhiteVan = 6,
	AlleyMouth = 6,
	NorthSidewalk = 1,
	SouthSidewalk = 1,
	EastSidewalk = 2,
	WestSidewalk = 2,
}

local function shuffle<T>(list: { T }): { T }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = math.random(i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

local function pickFromList<T>(list: { T }): T
	return list[math.random(#list)]
end

local function gatherSpawnPoints(levelModel: Model)
	local result = {}
	for _, part in ipairs(TagQueries.GetTaggedInside(levelModel, PlayAreaConfig.Tags.BuddyNpcSpawn)) do
		if part:IsA("BasePart") then
			local id = part:GetAttribute(PlayAreaConfig.Attributes.NpcSpawnId)
			if typeof(id) ~= "string" then
				id = part:GetFullName()
			end
			local anchor = part:GetAttribute(PlayAreaConfig.Attributes.Anchor)
			if typeof(anchor) ~= "string" then
				anchor = nil
			end
			table.insert(result, { Spawn = part, Id = id, Anchor = anchor })
		end
	end
	return result
end

local function assignRoles(spawns)
	local scored = {}
	for i, spawn in ipairs(spawns) do
		local bias = spawn.Anchor and ANCHOR_RISK_BIAS[spawn.Anchor] or 1
		table.insert(scored, {
			Index = i,
			Score = bias + math.random(),
		})
	end
	table.sort(scored, function(a, b)
		return a.Score > b.Score
	end)

	local roles = table.create(#spawns, ScenarioTypes.NpcRoles.Safe)
	for i = 1, math.min(Constants.STRANGER_DANGER_RISKY_COUNT, #scored) do
		roles[scored[i].Index] = ScenarioTypes.NpcRoles.Risky
	end
	return roles
end

local function pickArchetype(role: string, anchor: string?): string
	local riskKey = role == ScenarioTypes.NpcRoles.Risky and "Risky" or "Safe"
	if anchor then
		local favorite = ANCHOR_FAVORITES[anchor]
		if favorite and favorite[riskKey] then
			return favorite[riskKey]
		end
	end
	local pool = role == ScenarioTypes.NpcRoles.Risky and RISKY_ARCHETYPES or SAFE_ARCHETYPES
	return pickFromList(pool)
end

local function pickCue(archetype: string): string
	local cues = StrangerDangerLogic.PickCues(archetype, 3)
	return cues[1] or "LingeringNoReason"
end

function StrangerDangerScenario.Generate(levelModel: Model): any?
	local spawns = gatherSpawnPoints(levelModel)
	if #spawns < Constants.STRANGER_DANGER_RISKY_COUNT then
		warn("StrangerDangerScenario: fewer than 3 BuddyNpcSpawn parts in level")
		return nil
	end
	local allBadges = BadgeConfig.AllBadges()
	if #spawns > #allBadges then
		warn("StrangerDangerScenario: more NPCs than unique badge pairs")
		return nil
	end

	local roles = assignRoles(spawns)
	local badges = shuffle(allBadges)
	local npcs = {}
	local answerBadges = {}

	for i, spawn in ipairs(spawns) do
		local role = roles[i]
		local archetype = pickArchetype(role, spawn.Anchor)
		local archetypeData = StrangerDangerLogic.Archetypes[archetype]
		local cue = pickCue(archetype)
		local badge = badges[i]
		local silhouette = archetypeData and archetypeData.Silhouette or {
			Headline = "Someone in the park",
			Outline = "Person",
			AccentColor = { 200, 200, 200 },
			Stance = "Standing",
		}

		if role == ScenarioTypes.NpcRoles.Risky then
			table.insert(answerBadges, badge)
		end

		table.insert(npcs, {
			Id = string.format("npc_%d", i),
			SpawnPointId = spawn.Id,
			Anchor = spawn.Anchor,
			Archetype = archetype,
			Role = role,
			Silhouette = silhouette,
			Cue = cue,
			Badge = badge,
			Cues = { cue },
			Verdict = role == ScenarioTypes.NpcRoles.Risky
				and StrangerDangerLogic.Verdict.Avoid
				or StrangerDangerLogic.Verdict.Approach,
			Bark = archetypeData and archetypeData.Bark,
			Traits = { cue },
		})
	end

	local riskyTags, safeTags = {}, {}
	for tag, cue in pairs(StrangerDangerLogic.Cues) do
		if cue.Risk < 0 then
			table.insert(riskyTags, tag)
		else
			table.insert(safeTags, tag)
		end
	end

	return {
		Type = LevelTypes.StrangerDangerPark,
		Npcs = npcs,
		AnswerBadges = answerBadges,
		GuideManual = {
			RiskyTags = riskyTags,
			SafeTags = safeTags,
		},
	}
end

return StrangerDangerScenario
