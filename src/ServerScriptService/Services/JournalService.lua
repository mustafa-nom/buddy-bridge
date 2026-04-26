--!strict
-- Thin wrapper. The actual journal-unlocked map lives in DataService and
-- is updated as a side-effect of CatchResolutionService.finalizeCatch.
-- This service exists so other modules can ask "do they have it?" without
-- knowing about DataService internals.

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

local JournalService = {}

function JournalService.HasUnlocked(player: Player, fishId: string): boolean
	local data = DataService.GetData(player)
	return data.JournalUnlocked[fishId] == true
end

function JournalService.Count(player: Player): number
	local data = DataService.GetData(player)
	local n = 0
	for _ in pairs(data.JournalUnlocked) do
		n += 1
	end
	return n
end

function JournalService.Init() end

return JournalService
