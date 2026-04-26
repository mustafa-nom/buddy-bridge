--!strict
-- Resolves which cast zone (and therefore zone tier) a player is currently
-- standing in. Uses CollectionService tags applied by User 1's map. Fails
-- gracefully if the map doesn't have any tagged zones (cast simply
-- defaults to tier 1).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Constants = require(Modules:WaitForChild("Constants"))
local ZoneTiers = require(Modules:WaitForChild("ZoneTiers"))
local RemoteService = require(ReplicatedStorage:WaitForChild("RemoteService"))

local PondService = {}

local activeZoneByPlayer: { [Player]: { zoneId: string, tier: number, part: BasePart } } = {}

local function tierForPart(part: BasePart): number
	local tier = part:GetAttribute(Constants.ATTRS.ZoneTier)
	if typeof(tier) == "number" and tier >= 1 and tier <= ZoneTiers.MaxTier() then
		return math.floor(tier)
	end
	return 1
end

local function zoneIdForPart(part: BasePart): string
	local id = part:GetAttribute(Constants.ATTRS.ZoneId)
	if typeof(id) == "string" and id ~= "" then return id end
	return part:GetFullName()
end

local function notifyEnter(player: Player, part: BasePart)
	local tier = tierForPart(part)
	local id = zoneIdForPart(part)
	activeZoneByPlayer[player] = { zoneId = id, tier = tier, part = part }
	local meta = ZoneTiers.Get(tier)
	RemoteService.FireClient(player, "ZoneEntered", {
		ZoneId = id,
		Tier = tier,
		DisplayName = meta and meta.displayName or "Cast Zone",
		RequiredRodTier = meta and meta.requiredRodTier or 1,
		Color = meta and meta.color or Color3.fromRGB(180, 200, 220),
	})
end

local function notifyLeave(player: Player)
	local cur = activeZoneByPlayer[player]
	if not cur then return end
	activeZoneByPlayer[player] = nil
	RemoteService.FireClient(player, "ZoneLeft", { ZoneId = cur.zoneId })
end

local function attachZone(part: BasePart)
	if not part:IsA("BasePart") then return end
	part.Touched:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then return end
		local cur = activeZoneByPlayer[player]
		if cur and cur.part == part then return end
		notifyEnter(player, part)
	end)
	part.TouchEnded:Connect(function(other)
		local character = other:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then return end
		local cur = activeZoneByPlayer[player]
		if not cur or cur.part ~= part then return end
		-- Defer leave by a short tick to avoid touch-flicker on stair edges.
		task.delay(0.4, function()
			local stillCurrent = activeZoneByPlayer[player]
			if stillCurrent and stillCurrent.part == part then
				-- Re-test occupancy via overlap query.
				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { part }
				local hits = workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.new(0.5, 0.5, 0.5), params)
				local stillTouching = false
				for _, hit in ipairs(hits) do
					if hit:IsDescendantOf(player.Character or Instance.new("Model")) then
						stillTouching = true
						break
					end
				end
				if not stillTouching then notifyLeave(player) end
			end
		end)
	end)
end

function PondService.GetActiveZone(player: Player): { zoneId: string, tier: number, part: BasePart }?
	return activeZoneByPlayer[player]
end

function PondService.ResolveZoneFor(player: Player): { zoneId: string, tier: number }
	local cur = activeZoneByPlayer[player]
	if cur then return { zoneId = cur.zoneId, tier = cur.tier } end
	return { zoneId = "default", tier = 1 }
end

function PondService.Init()
	for _, p in ipairs(CollectionService:GetTagged(Constants.TAGS.CastZone)) do
		if p:IsA("BasePart") then attachZone(p) end
	end
	CollectionService:GetInstanceAddedSignal(Constants.TAGS.CastZone):Connect(function(p)
		if p:IsA("BasePart") then attachZone(p) end
	end)
	Players.PlayerRemoving:Connect(function(player)
		activeZoneByPlayer[player] = nil
	end)
end

function PondService.Diagnostics(): { [string]: number }
	local counts = {}
	counts.CastZones = #CollectionService:GetTagged(Constants.TAGS.CastZone)
	return counts
end

return PondService
