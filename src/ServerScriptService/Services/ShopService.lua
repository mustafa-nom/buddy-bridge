--!strict
-- Validates rod purchases. Server is authoritative on coins + rodTier; the
-- client only fires RequestPurchaseRod with a rodId. Server checks the catalog,
-- the player's coins, and that the rod is actually an upgrade, then deducts
-- the cost and refreshes the player's in-hand rod.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PhishConstants = require(Modules:WaitForChild("PhishConstants"))
local RodCatalog = require(Modules:WaitForChild("RodCatalog"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local DataService = require(Services:WaitForChild("DataService"))
local RodService = require(Services:WaitForChild("RodService"))
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))

local ShopService = {}

local function reply(player: Player, ok: boolean, message: string, rodId: string?)
	local profile = DataService.Get(player)
	RemoteService.FireClient(player, "PurchaseResult", {
		ok = ok, message = message, rodId = rodId,
		newCoins = profile.coins, newRodTier = profile.rodTier,
	})
end

local function onPurchase(player: Player, payload: any)
	local ok, _ = RemoteValidation.RunChain({
		function() return RemoteValidation.RequirePlayer(player) end,
		function() return RemoteValidation.RequireRateLimit(player, "Purchase", 0.5) end,
	})
	if not ok then return end

	if type(payload) ~= "table" or type(payload.rodId) ~= "string" then
		return reply(player, false, "Bad request.")
	end

	local rod = RodCatalog.GetById(payload.rodId)
	if not rod then return reply(player, false, "That rod doesn't exist.", payload.rodId) end

	local profile = DataService.Get(player)
	if rod.tier <= (profile.rodTier or 1) then
		return reply(player, false, "You already have this rod or better.", rod.id)
	end
	if profile.coins < rod.price then
		return reply(player, false, string.format("Not enough pearls — need %d.", rod.price), rod.id)
	end

	profile.coins -= rod.price
	profile.rodTier = rod.tier
	RodService.RefreshRod(player)

	-- Push HUD so coin counter + rod tier refresh immediately.
	RemoteService.FireClient(player, "HudUpdated", DataService.Snapshot(player))
	reply(player, true, string.format("Purchased %s!", rod.name), rod.id)
end

function ShopService.Init()
	-- Suppress "unused" warning on the constants import; future shop tunings
	-- (rate limits, restock timers) will pull from there.
	local _ = PhishConstants
	RemoteService.OnServerEvent("RequestPurchaseRod", onPurchase)
end

return ShopService
