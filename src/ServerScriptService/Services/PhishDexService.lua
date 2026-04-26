--!strict
-- Tracks species unlocks per player. Fires SpeciesUnlocked when a species
-- crosses the catchesToUnlock threshold for the first time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhishDex = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PhishDex"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))

-- Flip to false to silence the dev-time fire logs once we've confirmed
-- the SpeciesFound / SpeciesUnlocked pipeline is healthy.
local DEBUG = true

local PhishDexService = {}

function PhishDexService.Init()
	-- Whole dex (with unlock counts) for the client dex screen.
	RemoteService.OnServerInvoke("GetPhishDex", function(player)
		local profile = DataService.Get(player)
		local out = {}
		for _, s in ipairs(PhishDex.Species) do
			local count = profile.unlockedSpecies[s.id] or 0
			local found = profile.foundSpecies[s.id] == true or count > 0
			local unlocked = count >= s.catchesToUnlock
			table.insert(out, {
				id = s.id,
				displayName = s.displayName,
				rarity = s.rarity,
				isLegit = s.isLegit,
				count = count,
				catchesToUnlock = s.catchesToUnlock,
				found = found,
				unlocked = unlocked,
				description = found and s.description or nil,
				realPatternName = found and s.realPatternName or nil,
				realWorldInfo = unlocked and s.realWorldInfo or nil,
				redFlags = unlocked and s.redFlags or nil,
				defenseStrategy = unlocked and s.defenseStrategy or nil,
			})
		end
		return out
	end)
end

function PhishDexService.RecordFound(player: Player, speciesId: string)
	local species = PhishDex.Get(speciesId)
	if not species then return end

	local profile = DataService.Get(player)
	if profile.foundSpecies[speciesId] then return end
	profile.foundSpecies[speciesId] = true

	if DEBUG then
		print(string.format(
			"[PhishDex] SpeciesFound fired for %s -> %s",
			player.Name, speciesId
		))
	end

	-- One-shot popup the first time a player ever sees this species.
	RemoteService.FireClient(player, "SpeciesFound", {
		id = species.id,
		displayName = species.displayName,
		rarity = species.rarity,
		isLegit = species.isLegit,
	})
end

-- Called after a correct catch. `speciesId` matches a PhishDex.Species.id.
function PhishDexService.RecordCatch(player: Player, speciesId: string)
	local species = PhishDex.Get(speciesId)
	if not species then return end

	-- Track whether this is the player's first time on this species so we
	-- can pick the right popup variant (Found vs Caught) below.
	local profile = DataService.Get(player)
	local wasFirstCatch = not profile.foundSpecies[speciesId]

	-- Funnel the "first encounter" bookkeeping through RecordFound so the
	-- SpeciesFound popup fires exactly once per profile.
	PhishDexService.RecordFound(player, speciesId)

	local prev = profile.unlockedSpecies[speciesId] or 0
	local next_ = prev + 1
	profile.unlockedSpecies[speciesId] = next_

	local crossedMastery = prev < species.catchesToUnlock and next_ >= species.catchesToUnlock
	if crossedMastery then
		RemoteService.FireClient(player, "SpeciesUnlocked", {
			id = species.id,
			displayName = species.displayName,
			rarity = species.rarity,
			realPatternName = species.realPatternName,
			realWorldInfo = species.realWorldInfo,
			defenseStrategy = species.defenseStrategy,
		})
	elseif not wasFirstCatch then
		-- Routine catch (not first, not mastery): fire the lighter "CAUGHT"
		-- popup so the player gets feedback every time.
		RemoteService.FireClient(player, "SpeciesCaught", {
			id = species.id,
			displayName = species.displayName,
			rarity = species.rarity,
			count = next_,
			catchesToUnlock = species.catchesToUnlock,
		})
	end
end

return PhishDexService
