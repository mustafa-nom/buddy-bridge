--!strict
-- Owns Field Guide entry unlock state. Verify-on-bite reveals the entry
-- through `RevealEntry`; first correct catch unlocks it permanently via
-- `UnlockEntry` (called from CatchResolutionService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishRegistry = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local FieldGuideService = {}

function FieldGuideService.RevealEntry(player: Player, fishId: string, openOnClient: boolean)
	local fish = FishRegistry.GetById(fishId)
	if not fish then return end
	RemoteService.FireClient(player, "FieldGuideEntryUnlocked", {
		FishId = fish.id,
		DisplayName = fish.displayName,
		Category = fish.category,
		Rarity = fish.rarity,
		Entry = fish.fieldGuideEntry,
		CorrectAction = fish.correctAction,
		OpenOnClient = openOnClient == true,
	})
end

function FieldGuideService.UnlockEntry(player: Player, fishId: string)
	FieldGuideService.RevealEntry(player, fishId, false)
end

function FieldGuideService.Init() end

return FieldGuideService
