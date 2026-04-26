-- build_phish_water.luau
-- Builds the 50x50 biome water grid (tiles only). Run after build_phish_world.luau,
-- then run build_phish_decor.luau for biome flora + scattered islets.
-- Idempotent: wipes PhishWater and rebuilds.
-- Run via: Studio Command Bar (View > Command Bar > paste > Enter), or MCP execute_luau.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local C3 = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new

local map = Workspace:FindFirstChild("PhishMap")
assert(map, "PhishMap missing — run build_phish_world.luau first")

local function mkPart(name, parent, props)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent; return p
end

local oldWater = map:FindFirstChild("PhishWater"); if oldWater then oldWater:Destroy() end
local water = Instance.new("Folder"); water.Name = "PhishWater"; water.Parent = map

-- BIOMES: each maps to a Difficulty + MinRodTier (User 2 contract). Visual
-- color + material differ so biomes are spottable from a distance. `share`
-- is the target fraction of total tiles (enforced via percentile bins).
local BIOMES_ORDER = { "CalmCove", "OpenSea", "MossyMarsh", "StormChannel", "Abyss" }
local BIOME_DEFS = {
	CalmCove =     { color = C3(80, 210, 215),  material = Enum.Material.Glass,         diff = "Beginner",     rod = 1, transparency = 0.20, share = 0.25 },
	OpenSea =      { color = C3(60, 150, 220),  material = Enum.Material.SmoothPlastic, diff = "Beginner",     rod = 1, transparency = 0.15, share = 0.30 },
	MossyMarsh =   { color = C3(80, 170, 130),  material = Enum.Material.Slate,         diff = "Intermediate", rod = 2, transparency = 0.15, share = 0.25 },
	StormChannel = { color = C3(50, 80, 180),   material = Enum.Material.Foil,          diff = "Expert",       rod = 3, transparency = 0.10, share = 0.15 },
	Abyss =        { color = C3(140, 40, 100),  material = Enum.Material.Neon,          diff = "Legendary",    rod = 4, transparency = 0.05, share = 0.05 },
}

local GRID = 50
local TILE = 16
local ISLAND_R = 42
local NOISE_SCALE = 0.011    -- larger = more granular biomes; smaller = bigger biomes

-- Score = noise + distance bias. Noise dominates so biomes form patches;
-- distance bias nudges far tiles toward harder biomes.
local candidates = {}
for r = 0, GRID - 1 do
	for c = 0, GRID - 1 do
		local x = (c - (GRID - 1) / 2) * TILE
		local z = (r - (GRID - 1) / 2) * TILE
		local d = math.sqrt(x * x + z * z)
		if d >= ISLAND_R then
			local n = math.noise(x * NOISE_SCALE, z * NOISE_SCALE, 0)
			local bias = (d - ISLAND_R) / (565 - ISLAND_R)
			local score = n + (bias - 0.5) * 1.4
			table.insert(candidates, { r = r, c = c, x = x, z = z, score = score })
		end
	end
end

table.sort(candidates, function(a, b) return a.score < b.score end)

local n = #candidates
local cuts = {}
local cum = 0
for _, biomeId in ipairs(BIOMES_ORDER) do
	cum = cum + BIOME_DEFS[biomeId].share
	table.insert(cuts, { biome = biomeId, upTo = math.floor(cum * n + 0.5) })
end

local cutIdx = 1
for i, t in ipairs(candidates) do
	while cutIdx < #cuts and i > cuts[cutIdx].upTo do cutIdx = cutIdx + 1 end
	local biomeId = cuts[cutIdx].biome
	local b = BIOME_DEFS[biomeId]
	local tile = mkPart(string.format("Tile_%d_%d", t.r, t.c), water, {
		Size = V3(TILE, 1, TILE),
		Color = b.color,
		Material = b.material,
		CFrame = CF(t.x, 0, t.z),
		CanCollide = false,
		Transparency = b.transparency,
	})
	CollectionService:AddTag(tile, "PhishWaterZone")
	tile:SetAttribute("Difficulty", b.diff)
	tile:SetAttribute("MinRodTier", b.rod)
	tile:SetAttribute("Biome", biomeId)
end

-- Push fog out so far biomes are still visible from the dock.
Lighting.FogEnd = 1100
Lighting.FogStart = 350

print(string.format("[PHISH! WATER] Done. Tiles=%d. Run build_phish_decor.luau next.", n))
return true
