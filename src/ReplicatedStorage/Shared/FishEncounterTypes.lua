--!strict
-- Shared encounter-state vocabulary. Both server (PondState) and client
-- (BiteHudController) read these so the wire format is canonical.

local FishEncounterTypes = {}

FishEncounterTypes.States = {
	Idle = "Idle",
	Casting = "Casting",
	Waiting = "Waiting",
	BitePending = "BitePending",
	Verifying = "Verifying",
	Reeling = "Reeling",
	Resolved = "Resolved",
}

FishEncounterTypes.OutcomeKinds = {
	CorrectCutLine = "CorrectCutLine",
	CorrectVerifyRelease = "CorrectVerifyRelease",
	CorrectReel = "CorrectReel",
	CorrectReport = "CorrectReport",
	WrongAction = "WrongAction",
	Escaped = "Escaped",  -- decision window expired
}

return FishEncounterTypes
