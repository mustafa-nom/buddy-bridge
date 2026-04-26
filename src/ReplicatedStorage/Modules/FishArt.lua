--!strict
-- Maps PhishDex species ids to uploaded Roblox image asset ids. Used by the
-- Fish Index tile previews and the top-right NEW! / MASTERED! popup so both
-- surfaces stay in sync.
--
-- HOW TO POPULATE
-- 1. Rename each generated PNG in `~/.cursor/projects/.../assets/` to
--    `<speciesId>.png` (e.g. `UrgencyEel.png`).
-- 2. Upload via Roblox Creator Dashboard (Decals/Images) or Studio's
--    Asset Manager. The decal asset id is what shows up in the URL.
-- 3. Replace the matching `0` below with the asset id (just the numeric id).
--    The module will auto-format it to `rbxassetid://<id>` at lookup time.
--
-- A value of `0` means "not uploaded yet" — callers should treat that as
-- missing art and fall back gracefully (silhouette / 3D viewport / etc).

local FishArt = {}

-- Species id -> Roblox decal asset id. Keep keys in lockstep with
-- PhishDex.Species so missing entries are obvious during code review.
FishArt.AssetIds = {
	UrgencyEel = 122080947863879,
	AuthorityAnglerfish = 72199304450308,
	RewardTuna = 126535665555655,
	CuriosityCatfish = 118560370656209,
	FearBass = 134921327440322,
	FamiliarityFlounder = 139736494783419,
	RumorRay = 86990468338920,
	ModImposter = 119086778049894,
	HallucinationJelly = 134970686865505,
	PlainCarp = 112829865528883,
	HonestHerring = 79548634185779,
	KindnessKoi = 94157840945824,
} :: { [string]: number }

function FishArt.Get(speciesId: string): string?
	local id = FishArt.AssetIds[speciesId]
	if not id or id == 0 then
		return nil
	end
	return string.format("rbxassetid://%d", id)
end

function FishArt.Has(speciesId: string): boolean
	local id = FishArt.AssetIds[speciesId]
	return id ~= nil and id ~= 0
end

return FishArt
