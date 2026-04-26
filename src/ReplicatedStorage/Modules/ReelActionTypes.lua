--!strict
-- The verbs the player can perform during a bite. Each verb is *also* a
-- digital-safety lesson the player practices through play.

local ReelActionTypes = {}

ReelActionTypes.Cast = "Cast"            -- start the encounter
ReelActionTypes.Verify = "Verify"        -- pause + open Field Guide (fact-check)
ReelActionTypes.Reel = "Reel"            -- commit to catch (accept genuine)
ReelActionTypes.CutLine = "CutLine"      -- refuse the lure (refuse phishing)
ReelActionTypes.Report = "Report"        -- flag a Mod Imposter
ReelActionTypes.Release = "Release"      -- catch but throw back (unfollow / mute)

ReelActionTypes.Decision = {
	ReelActionTypes.Verify,
	ReelActionTypes.Reel,
	ReelActionTypes.CutLine,
	ReelActionTypes.Report,
	ReelActionTypes.Release,
}

function ReelActionTypes.IsDecisionAction(value: string?): boolean
	if typeof(value) ~= "string" then return false end
	for _, v in ipairs(ReelActionTypes.Decision) do
		if v == value then return true end
	end
	return false
end

return ReelActionTypes
