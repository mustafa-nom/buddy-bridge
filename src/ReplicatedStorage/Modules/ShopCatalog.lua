--!strict
-- The fisherman's shop. Currently just rods, but structured so consumables
-- can be added later by appending to `entries`.

local RodRegistry = require(script.Parent:WaitForChild("RodRegistry"))

local ShopCatalog = {}

export type ShopEntry = {
	id: string,
	kind: string,             -- "Rod" | "Consumable"
	displayName: string,
	price: number,
	description: string,
	payload: { [string]: any },
}

local entries: { ShopEntry } = {}

for _, rod in ipairs(RodRegistry.All()) do
	if rod.price > 0 then
		table.insert(entries, {
			id = "rod_" .. rod.id,
			kind = "Rod",
			displayName = rod.displayName,
			price = rod.price,
			description = rod.description,
			payload = { rodId = rod.id },
		})
	end
end

local byId: { [string]: ShopEntry } = {}
for _, e in ipairs(entries) do
	byId[e.id] = e
end

function ShopCatalog.All(): { ShopEntry }
	return entries
end

function ShopCatalog.GetById(id: string): ShopEntry?
	return byId[id]
end

return ShopCatalog
