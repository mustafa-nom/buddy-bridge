--!strict
-- Sell shop. Computes payouts using fish rarity and current zone tier
-- multiplier (the zone the player is *standing in* when selling — sell-prompt
-- usually lives near the lodge so this defaults to tier 1).

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local FishRegistry = require(Modules:WaitForChild("FishRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local DataService = require(Services:WaitForChild("DataService"))

local SellService = {}

local function payoutForFish(fishId: string): number
	local fish = FishRegistry.GetById(fishId)
	if not fish then return 0 end
	local mult = Constants.SELL_RARITY_MULTIPLIER[fish.rarity] or 1
	return Constants.SELL_BASE_PAYOUT * mult
end

local function quoteFor(player: Player)
	local data = DataService.GetData(player)
	local entries = {}
	local total = 0
	for fishId, stack in pairs(data.FishInventory) do
		local fish = FishRegistry.GetById(fishId)
		if fish then
			local pay = payoutForFish(fishId)
			total += pay * stack.count
			table.insert(entries, {
				FishId = fishId,
				DisplayName = fish.displayName,
				Rarity = fish.rarity,
				Count = stack.count,
				PerUnit = pay,
			})
		end
	end
	table.sort(entries, function(a, b) return a.DisplayName < b.DisplayName end)
	return { Entries = entries, QuickSellTotal = total }
end

local function handleSellOne(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.fishId) ~= "string" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestSellFish", Constants.RATE_LIMIT_SELL) then return end
	local data = DataService.GetData(player)
	local stack = data.FishInventory[payload.fishId]
	if not stack or stack.count <= 0 then
		RemoteService.FireClient(player, "Notify", { Kind = "Info", Text = "You don't have any of those." })
		return
	end
	local pay = payoutForFish(payload.fishId)
	DataService.RemoveFish(player, payload.fishId, 1)
	DataService.GrantPearls(player, pay)
	RemoteService.FireClient(player, "Notify", {
		Kind = "Success",
		Text = ("Sold for %d pearls."):format(pay),
	})
end

local function handleSellAll(player: Player, _payload: any)
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestSellAll", Constants.RATE_LIMIT_SELL) then return end
	local data = DataService.GetData(player)
	local total = 0
	local soldCount = 0
	for fishId, stack in pairs(data.FishInventory) do
		local pay = payoutForFish(fishId)
		total += pay * stack.count
		soldCount += stack.count
	end
	if soldCount == 0 then
		RemoteService.FireClient(player, "Notify", { Kind = "Info", Text = "Nothing to sell." })
		return
	end
	-- Clear inventory.
	for fishId in pairs(data.FishInventory) do
		DataService.RemoveFish(player, fishId)
	end
	DataService.GrantPearls(player, total)
	RemoteService.FireClient(player, "Notify", {
		Kind = "Success",
		Title = "Quick sell",
		Text = ("Sold %d fish for %d pearls."):format(soldCount, total),
	})
end

function SellService.Init()
	RemoteService.OnServerEvent("RequestSellFish", handleSellOne)
	RemoteService.OnServerEvent("RequestSellAll", handleSellAll)
	RemoteService.OnServerInvoke("GetSellQuote", function(player) return quoteFor(player) end)
	Players.PlayerAdded:Connect(function() end)
end

return SellService
