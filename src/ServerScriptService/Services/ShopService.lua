--!strict
-- Fisherman shop. Exposes a catalog snapshot via GetShopCatalog and handles
-- purchase / equip flow. Server validates pearls, owned-rod, equipped-rod
-- transitions before mutating DataService.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local ShopCatalog = require(Modules:WaitForChild("ShopCatalog"))
local RodRegistry = require(Modules:WaitForChild("RodRegistry"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local Services = script.Parent
local Helpers = Services:WaitForChild("Helpers")
local RemoteValidation = require(Helpers:WaitForChild("RemoteValidation"))
local DataService = require(Services:WaitForChild("DataService"))

local ShopService = {}

local function snapshotForPlayer(player: Player)
	local data = DataService.GetData(player)
	local entries = {}
	for _, e in ipairs(ShopCatalog.All()) do
		local owned = false
		if e.kind == "Rod" and e.payload.rodId and data.OwnedRods[e.payload.rodId] then
			owned = true
		end
		table.insert(entries, {
			Id = e.id,
			Kind = e.kind,
			DisplayName = e.displayName,
			Price = e.price,
			Description = e.description,
			Owned = owned,
			Payload = e.payload,
		})
	end
	return {
		Pearls = data.Pearls,
		EquippedRodId = data.EquippedRodId,
		Entries = entries,
		Rods = RodRegistry.All(),
	}
end

local function handlePurchase(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.entryId) ~= "string" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestPurchase", Constants.RATE_LIMIT_SHOP) then return end

	local entry = ShopCatalog.GetById(payload.entryId)
	if not entry then
		RemoteService.FireClient(player, "Notify", { Kind = "Error", Text = "That item isn't on the shelf." })
		return
	end
	local data = DataService.GetData(player)
	if entry.kind == "Rod" then
		local rodId = entry.payload.rodId
		if data.OwnedRods[rodId] then
			RemoteService.FireClient(player, "Notify", { Kind = "Info", Text = "You already own this rod." })
			RemoteService.FireClient(player, "ShopUpdated", snapshotForPlayer(player))
			return
		end
	end
	if data.Pearls < entry.price then
		RemoteService.FireClient(player, "Notify", { Kind = "Error", Text = "Not enough pearls. Sell some fish." })
		return
	end
	local ok = DataService.SpendPearls(player, entry.price)
	if not ok then return end
	if entry.kind == "Rod" then
		DataService.GrantRod(player, entry.payload.rodId)
		DataService.SetEquippedRod(player, entry.payload.rodId)
		RemoteService.FireClient(player, "Notify", {
			Kind = "Success",
			Title = "New rod equipped",
			Text = ("You bought %s."):format(entry.displayName),
		})
	end
	RemoteService.FireClient(player, "ShopUpdated", snapshotForPlayer(player))
end

local function handleEquip(player: Player, payload: any)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.rodId) ~= "string" then return end
	if not RemoteValidation.RequirePlayer(player) then return end
	if not RemoteValidation.RequireRateLimit(player, "RequestEquipRod", Constants.RATE_LIMIT_SHOP) then return end
	local data = DataService.GetData(player)
	if not data.OwnedRods[payload.rodId] then
		RemoteService.FireClient(player, "Notify", { Kind = "Error", Text = "You don't own that rod." })
		return
	end
	DataService.SetEquippedRod(player, payload.rodId)
	RemoteService.FireClient(player, "ShopUpdated", snapshotForPlayer(player))
end

function ShopService.Init()
	RemoteService.OnServerEvent("RequestPurchase", handlePurchase)
	RemoteService.OnServerEvent("RequestEquipRod", handleEquip)
	RemoteService.OnServerInvoke("GetShopCatalog", function(player)
		return snapshotForPlayer(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		task.wait(3)
		if player.Parent then
			RemoteService.FireClient(player, "ShopUpdated", snapshotForPlayer(player))
		end
	end)
end

return ShopService
