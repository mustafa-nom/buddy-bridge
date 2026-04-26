--!strict
-- Session-only player data store for PHISH!. No DataStore in MVP scope.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local RodRegistry = require(Modules:WaitForChild("RodRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local DataService = {}

export type FishStack = {
	id: string,
	count: number,
	bestRarity: string,
}

export type PlayerData = {
	Pearls: number,
	Xp: number,
	OwnedRods: { [string]: boolean },
	EquippedRodId: string,
	FishInventory: { [string]: FishStack },
	JournalUnlocked: { [string]: boolean },
	Aquarium: { string },          -- ordered list of fishIds placed
	HasSeenTutorial: { [string]: boolean },
	Streak: number,
	BestStreak: number,
	TotalCorrectCatches: number,
	Title: string,
}

local data: { [Player]: PlayerData } = {}

local function defaults(): PlayerData
	local rodId = RodRegistry.DefaultRodId()
	return {
		Pearls = Constants.STARTING_PEARLS,
		Xp = 0,
		OwnedRods = { [rodId] = true },
		EquippedRodId = rodId,
		FishInventory = {},
		JournalUnlocked = {},
		Aquarium = {},
		HasSeenTutorial = {},
		Streak = 0,
		BestStreak = 0,
		TotalCorrectCatches = 0,
		Title = (Constants.TITLES[1] and Constants.TITLES[1].title) or "Tadpole",
	}
end

local function pushSnapshot(player: Player)
	local d = data[player]
	if not d then return end
	RemoteService.FireClient(player, "InventoryUpdated", {
		Pearls = d.Pearls,
		Xp = d.Xp,
		OwnedRods = d.OwnedRods,
		EquippedRodId = d.EquippedRodId,
		FishInventory = d.FishInventory,
		JournalUnlocked = d.JournalUnlocked,
		Aquarium = d.Aquarium,
		Streak = d.Streak,
		BestStreak = d.BestStreak,
		TotalCorrectCatches = d.TotalCorrectCatches,
		Title = d.Title,
	})
end

function DataService.GetData(player: Player): PlayerData
	if not data[player] then
		data[player] = defaults()
	end
	return data[player]
end

function DataService.GrantPearls(player: Player, amount: number): number
	local d = DataService.GetData(player)
	d.Pearls = math.max(0, d.Pearls + amount)
	RemoteService.FireClient(player, "PearlsGranted", { Amount = amount, Total = d.Pearls })
	pushSnapshot(player)
	return d.Pearls
end

function DataService.SpendPearls(player: Player, amount: number): boolean
	local d = DataService.GetData(player)
	if d.Pearls < amount then return false end
	d.Pearls -= amount
	RemoteService.FireClient(player, "PearlsGranted", { Amount = -amount, Total = d.Pearls })
	pushSnapshot(player)
	return true
end

function DataService.GrantXp(player: Player, amount: number): number
	local d = DataService.GetData(player)
	d.Xp += amount
	RemoteService.FireClient(player, "XpGranted", { Amount = amount, Total = d.Xp })
	return d.Xp
end

function DataService.AddFish(player: Player, fishId: string, rarity: string)
	local d = DataService.GetData(player)
	local stack = d.FishInventory[fishId]
	if stack then
		stack.count += 1
	else
		d.FishInventory[fishId] = { id = fishId, count = 1, bestRarity = rarity }
	end
	pushSnapshot(player)
end

function DataService.RemoveFish(player: Player, fishId: string, count: number?): number
	local d = DataService.GetData(player)
	local stack = d.FishInventory[fishId]
	if not stack then return 0 end
	local toRemove = math.min(stack.count, count or stack.count)
	stack.count -= toRemove
	if stack.count <= 0 then
		d.FishInventory[fishId] = nil
	end
	pushSnapshot(player)
	return toRemove
end

function DataService.UnlockJournal(player: Player, fishId: string): boolean
	local d = DataService.GetData(player)
	if d.JournalUnlocked[fishId] then return false end
	d.JournalUnlocked[fishId] = true
	RemoteService.FireClient(player, "JournalUpdated", { FishId = fishId, Total = (function()
		local n = 0
		for _ in pairs(d.JournalUnlocked) do n += 1 end
		return n
	end)() })
	pushSnapshot(player)
	return true
end

function DataService.PlaceInAquarium(player: Player, fishId: string): boolean
	local d = DataService.GetData(player)
	for _, existing in ipairs(d.Aquarium) do
		if existing == fishId then return false end
	end
	table.insert(d.Aquarium, fishId)
	RemoteService.FireClient(player, "AquariumUpdated", { Aquarium = d.Aquarium, Added = fishId })
	pushSnapshot(player)
	return true
end

function DataService.OwnsRod(player: Player, rodId: string): boolean
	local d = DataService.GetData(player)
	return d.OwnedRods[rodId] == true
end

function DataService.GrantRod(player: Player, rodId: string): boolean
	if not RodRegistry.GetById(rodId) then return false end
	local d = DataService.GetData(player)
	if d.OwnedRods[rodId] then return false end
	d.OwnedRods[rodId] = true
	pushSnapshot(player)
	return true
end

function DataService.SetEquippedRod(player: Player, rodId: string): boolean
	local d = DataService.GetData(player)
	if not d.OwnedRods[rodId] then return false end
	d.EquippedRodId = rodId
	pushSnapshot(player)
	return true
end

function DataService.GetEquippedRodTier(player: Player): number
	local d = DataService.GetData(player)
	local rod = RodRegistry.GetById(d.EquippedRodId)
	return rod and rod.tier or 1
end

function DataService.MarkTutorialSeen(player: Player, key: string)
	local d = DataService.GetData(player)
	d.HasSeenTutorial[key] = true
end

function DataService.HasSeenTutorial(player: Player, key: string): boolean
	local d = DataService.GetData(player)
	return d.HasSeenTutorial[key] == true
end

function DataService.Init()
	Players.PlayerAdded:Connect(function(player)
		data[player] = defaults()
		task.wait(1)
		if player.Parent then
			pushSnapshot(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		data[player] = nil
	end)

	RemoteService.OnServerInvoke("GetSnapshot", function(player)
		local d = DataService.GetData(player)
		return {
			Pearls = d.Pearls,
			Xp = d.Xp,
			OwnedRods = d.OwnedRods,
			EquippedRodId = d.EquippedRodId,
			FishInventory = d.FishInventory,
			JournalUnlocked = d.JournalUnlocked,
			Aquarium = d.Aquarium,
			Streak = d.Streak,
			BestStreak = d.BestStreak,
			TotalCorrectCatches = d.TotalCorrectCatches,
			Title = d.Title,
		}
	end)
end

return DataService
