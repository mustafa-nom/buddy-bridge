--!strict
-- Scenario shape definitions. Matches docs/TECHNICAL_DESIGN.md "Scenario Shapes".

local ScenarioTypes = {}

export type StrangerDangerSilhouette = {
	Headline: string,
	Outline: string,
	AccentColor: { number },
	Stance: string,
}

export type StrangerDangerFragment = {
	Truthful: boolean,
	Landmark: string,
	Text: string,
}

export type StrangerDangerNpc = {
	Id: string,
	SpawnPointId: string,
	Anchor: string?,
	Archetype: string,             -- NPC template name (HotDogVendor, etc.)
	Role: string,                  -- Risky | Safe
	Silhouette: StrangerDangerSilhouette,  -- Explorer-visible glance
	Cues: { string },              -- Guide-visible cue tags (full info)
	Verdict: string,               -- canonical Approach/AskFirst/Avoid
	Badge: any,
	Fragment: StrangerDangerFragment?,
	Bark: string?,                 -- chat-bubble line
	-- Legacy fields for backwards compatibility with existing renderers:
	Traits: { string },            -- mirrors Cues for older callers
	ClueText: string?,             -- mirrors Fragment.Text for older callers
}

export type StrangerDangerScenario = {
	Type: string,
	Npcs: { StrangerDangerNpc },
	AnswerBadges: { any },
	GuideManual: {
		RiskyTags: { string },
		SafeTags: { string },
	},
}

export type BackpackItem = {
	Id: string,
	ItemKey: string,
	DisplayLabel: string,
	CorrectLane: string,
	Category: string?,
	DifficultyTier: number?,
	ScanTags: { string }?,
}

export type BackpackWave = {
	WaveIndex: number,
	Items: { BackpackItem },
	BeltSpeed: number,
	ScansAllowed: number,
}

export type BackpackCheckpointScenario = {
	Type: string,
	Waves: { BackpackWave },
	GuideManual: {
		Lanes: {
			PackIt: { string },
			AskFirst: { string },
			LeaveIt: { string },
		},
	},
	CurrentWaveIndex: number,
	CurrentItemIndex: number,
	TotalItems: number,
}

ScenarioTypes.NpcRoles = {
	Safe = "Safe",
	Risky = "Risky",
}

function ScenarioTypes.IsValidNpcRole(role: string?): boolean
	return role == ScenarioTypes.NpcRoles.Safe or role == ScenarioTypes.NpcRoles.Risky
end

return ScenarioTypes
