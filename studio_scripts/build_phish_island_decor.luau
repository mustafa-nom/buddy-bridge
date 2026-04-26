-- build_phish_island_decor.luau
-- Lived-in dressing for the main island: back-of-island lookout hill, hammock,
-- picnic table, tiki torches, fishing net, fish crate pile, beach chairs +
-- umbrella, footbridge over tide pools, windmill, sundial, scattered flora
-- (bushes / flowers / grass tufts / mushrooms / stumps / sea grass), and
-- string lights strung between the four corner palms.
-- Depends on Workspace.PhishMap.PhishIsland (run build_phish_world.luau first).
-- Idempotent: wipes PhishIslandDecor and rebuilds.
-- Run via: Studio Command Bar (View > Command Bar > paste > Enter), or MCP execute_luau.

local Workspace = game:GetService("Workspace")

local C3 = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new

local map = Workspace:FindFirstChild("PhishMap"); assert(map, "PhishMap missing")
local old = map:FindFirstChild("PhishIslandDecor"); if old then old:Destroy() end
local decor = Instance.new("Folder"); decor.Name = "PhishIslandDecor"; decor.Parent = map

local function mk(name, props)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false  -- default; structural pieces opt back in
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = decor; return p
end

local rng = Random.new(42)
local function jitter(c, r) return c + rng:NextNumber(-r, r) end

-- Back-of-island hill + lookout deck + telescope (walkable).
mk("BackHill", { Size = V3(38, 4, 22), Color = C3(120, 180, 100),
	Material = Enum.Material.Grass, CFrame = CF(-30, 3, -22), CanCollide = true })
mk("BackHillCap", { Size = V3(28, 1.5, 14), Color = C3(140, 200, 110),
	Material = Enum.Material.Grass, CFrame = CF(-30, 5.5, -22), CanCollide = true })
mk("LookoutDeck", { Size = V3(10, 0.4, 8), Color = C3(110, 75, 50),
	Material = Enum.Material.WoodPlanks, CFrame = CF(-32, 6.5, -22), CanCollide = true })
for _, sp in ipairs({V3(-37, 7, -25), V3(-27, 7, -25), V3(-37, 7, -19), V3(-27, 7, -19)}) do
	mk("LookoutPost", { Size = V3(0.3, 2, 0.3), Color = C3(110, 75, 50),
		Material = Enum.Material.Wood, CFrame = CF(sp.X, sp.Y + 1, sp.Z), CanCollide = true })
end
mk("TelescopeStand", { Size = V3(0.4, 2.5, 0.4), Color = C3(60, 60, 70),
	Material = Enum.Material.Metal, CFrame = CF(-32, 8, -22), CanCollide = true })
mk("TelescopeTube", { Size = V3(0.6, 0.6, 2.5), Color = C3(40, 40, 50),
	Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder,
	CFrame = CF(-32, 9.5, -22) * CFrame.Angles(0, 0, math.rad(20)), CanCollide = true })
for i = 1, 4 do
	mk("HillStep_" .. i, { Size = V3(4, 0.5, 1.5), Color = C3(110, 75, 50),
		Material = Enum.Material.WoodPlanks, CFrame = CF(-22, 2.0 + i * 1.0, -22 + (4 - i) * 0.5),
		CanCollide = true })
end

-- Hammock between two palms.
mk("HammockSling", { Size = V3(7, 0.2, 2.4), Color = C3(220, 180, 80),
	Material = Enum.Material.Fabric, CFrame = CF(-11, 4, -25) * CFrame.Angles(0, math.rad(40), math.rad(8)) })
mk("HammockRope1", { Size = V3(0.1, 2, 0.1), Color = C3(150, 130, 90),
	Material = Enum.Material.Fabric, CFrame = CF(-19, 5.2, -23) })
mk("HammockRope2", { Size = V3(0.1, 2, 0.1), Color = C3(150, 130, 90),
	Material = Enum.Material.Fabric, CFrame = CF(-3, 5.2, -27) })

-- Picnic table near lodge.
local px, pz = -10, 8
mk("PicnicTop", { Size = V3(5, 0.3, 2.5), Color = C3(140, 90, 55),
	Material = Enum.Material.WoodPlanks, CFrame = CF(px, 3.5, pz), CanCollide = true })
mk("PicnicBenchN", { Size = V3(5, 0.25, 0.8), Color = C3(140, 90, 55),
	Material = Enum.Material.WoodPlanks, CFrame = CF(px, 2.6, pz - 1.7), CanCollide = true })
mk("PicnicBenchS", { Size = V3(5, 0.25, 0.8), Color = C3(140, 90, 55),
	Material = Enum.Material.WoodPlanks, CFrame = CF(px, 2.6, pz + 1.7), CanCollide = true })
for _, p in ipairs({V3(px - 2, 1.5, pz - 1.4), V3(px + 2, 1.5, pz - 1.4),
	V3(px - 2, 1.5, pz + 1.4), V3(px + 2, 1.5, pz + 1.4)}) do
	mk("PicnicLeg", { Size = V3(0.3, 2.5, 0.3), Color = C3(100, 65, 40),
		Material = Enum.Material.Wood, CFrame = CF(p), CanCollide = true })
end

-- Tiki torches lining the path to the dock.
for _, x in ipairs({8, 14, 20, 26}) do
	for _, side in ipairs({-3, 3}) do
		mk("TikiPole", { Size = V3(0.25, 4, 0.25), Color = C3(80, 50, 30),
			Material = Enum.Material.Wood, CFrame = CF(x, 3.6, side), CanCollide = true })
		local flame = mk("TikiFlame", { Size = V3(0.5, 0.7, 0.5), Color = C3(255, 150, 50),
			Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CFrame = CF(x, 5.8, side) })
		local pl = Instance.new("PointLight"); pl.Color = C3(255, 150, 50); pl.Range = 12; pl.Brightness = 1.8; pl.Parent = flame
	end
end

-- Hanging fishing net + drying fish near the sell shop.
mk("NetPost1", { Size = V3(0.4, 5, 0.4), Color = C3(100, 65, 40),
	Material = Enum.Material.Wood, CFrame = CF(14, 4, -18), CanCollide = true })
mk("NetPost2", { Size = V3(0.4, 5, 0.4), Color = C3(100, 65, 40),
	Material = Enum.Material.Wood, CFrame = CF(22, 4, -18), CanCollide = true })
mk("FishingNet", { Size = V3(8, 3, 0.1), Color = C3(220, 200, 150),
	Material = Enum.Material.Fabric, Transparency = 0.4,
	CFrame = CF(18, 5, -18) * CFrame.Angles(0, 0, math.rad(-3)) })
for i = 1, 3 do
	mk("DryingFish", { Size = V3(0.5, 0.2, 0.8), Color = C3(180, 150, 100),
		Material = Enum.Material.SmoothPlastic, CFrame = CF(15 + i * 2, 4.4, -18) })
end

-- Fish crate pile near the sell shop.
mk("Crate1", { Size = V3(2, 1.4, 2), Color = C3(140, 100, 65),
	Material = Enum.Material.WoodPlanks, CFrame = CF(24, 1.4, -16), CanCollide = true })
mk("Crate2", { Size = V3(2, 1.4, 2), Color = C3(150, 110, 70),
	Material = Enum.Material.WoodPlanks, CFrame = CF(26, 1.4, -15.5), CanCollide = true })
mk("Crate3", { Size = V3(2, 1.4, 2), Color = C3(135, 95, 60),
	Material = Enum.Material.WoodPlanks, CFrame = CF(25, 2.8, -16) * CFrame.Angles(0, math.rad(15), 0), CanCollide = true })

-- Beach umbrella + chairs on the south beach.
mk("UmbrellaPole", { Size = V3(0.2, 5, 0.2), Color = C3(100, 65, 40),
	Material = Enum.Material.Wood, CFrame = CF(8, 3.5, 28), CanCollide = true })
mk("UmbrellaCanopy", { Size = V3(6, 0.3, 6), Color = C3(220, 80, 80),
	Material = Enum.Material.Fabric, Shape = Enum.PartType.Cylinder,
	CFrame = CF(8, 6.0, 28) * CFrame.Angles(0, 0, math.rad(90)) })
for i, off in ipairs({V3(-1.5, 0, 0), V3(1.5, 0, 0)}) do
	mk("ChairSeat_" .. i, { Size = V3(1.5, 0.2, 1.5), Color = C3(180, 220, 240),
		Material = Enum.Material.Fabric, CFrame = CF(8 + off.X, 1.3, 28 + 1.5), CanCollide = true })
	mk("ChairBack_" .. i, { Size = V3(1.5, 1.4, 0.2), Color = C3(180, 220, 240),
		Material = Enum.Material.Fabric, CFrame = CF(8 + off.X, 2.0, 28 + 2.2), CanCollide = true })
end

-- Footbridge between the two tide pools.
mk("BridgePlanks", { Size = V3(8, 0.3, 1.6), Color = C3(120, 80, 50),
	Material = Enum.Material.WoodPlanks, CFrame = CF(-1, 1.9, -1) * CFrame.Angles(0, math.rad(-12), 0), CanCollide = true })
for i = 1, 3 do
	mk("BridgeRail_" .. i, { Size = V3(0.2, 0.6, 0.2), Color = C3(120, 80, 50),
		Material = Enum.Material.Wood, CFrame = CF(-3 + i * 2, 2.5, -1.5) })
end

-- Windmill at the back of the island.
mk("WindmillPole", { Size = V3(0.4, 7, 0.4), Color = C3(100, 65, 40),
	Material = Enum.Material.Wood, CFrame = CF(-12, 5.5, 14), CanCollide = true })
mk("WindmillHub", { Size = V3(0.6, 0.6, 0.6), Color = C3(60, 60, 60),
	Material = Enum.Material.Metal, Shape = Enum.PartType.Ball, CFrame = CF(-12, 8.5, 14) })
for i = 1, 4 do
	local angle = (i - 1) * (math.pi / 2)
	mk("WindmillBlade_" .. i, { Size = V3(0.2, 3, 0.6), Color = C3(220, 220, 230),
		Material = Enum.Material.Fabric,
		CFrame = CF(-12, 8.5, 14) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 1.7, 0) })
end

-- Sundial pedestal in the grass.
mk("SundialBase", { Size = V3(2.2, 1, 2.2), Color = C3(170, 170, 165),
	Material = Enum.Material.Slate, Shape = Enum.PartType.Cylinder,
	CFrame = CF(6, 2.2, 12) * CFrame.Angles(0, 0, math.rad(90)), CanCollide = true })
mk("SundialFace", { Size = V3(1.8, 0.1, 1.8), Color = C3(220, 200, 160),
	Material = Enum.Material.Sand, Shape = Enum.PartType.Cylinder,
	CFrame = CF(6, 2.8, 12) * CFrame.Angles(0, 0, math.rad(90)) })
mk("SundialGnomon", { Size = V3(0.2, 1.6, 1.6), Color = C3(60, 60, 60),
	Material = Enum.Material.Metal, CFrame = CF(6, 3.6, 12) * CFrame.Angles(0, 0, math.rad(-25)) })

-- Organic flora scatter on the grass interior. Avoids lodge / paths / hill.
local function inGrass(x, z)
	if math.abs(x) > 24 or math.abs(z) > 24 then return false end
	if x > -28 and x < -12 and z > -8 and z < 8 then return false end                 -- lodge
	if x > 5 and math.abs(z) < 2 then return false end                                 -- dock path
	if math.abs(x - 20) < 2 and z > 5 and z < 19 then return false end                 -- boat path
	if x > -49 and x < -11 and z > -33 and z < -11 then return false end               -- back hill
	return true
end
local function tryScatter(count, place)
	local placed = 0
	for _ = 1, count * 4 do
		if placed >= count then break end
		local x = rng:NextNumber(-25, 25); local z = rng:NextNumber(-25, 25)
		if inGrass(x, z) then place(x, z); placed = placed + 1 end
	end
end

tryScatter(12, function(x, z)
	local r = rng:NextNumber(1.4, 2.2)
	mk("Bush", { Size = V3(r * 2, r * 1.4, r * 2), Color = C3(60, 140, 75),
		Material = Enum.Material.Grass, Shape = Enum.PartType.Ball,
		CFrame = CF(x, 2.0 + r * 0.3, z) })
end)
local FLOWER_COLORS = { C3(255, 100, 130), C3(255, 220, 100), C3(255, 140, 200), C3(180, 120, 240), C3(255, 180, 80) }
tryScatter(28, function(x, z)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	for _ = 1, rng:NextInteger(2, 4) do
		mk("Flower", { Size = V3(0.5, 0.1, 0.5), Color = color,
			Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder,
			CFrame = CF(jitter(x, 0.7), 2.05, jitter(z, 0.7)) * CFrame.Angles(0, 0, math.rad(90)) })
		mk("FlowerStem", { Size = V3(0.06, 0.5, 0.06), Color = C3(70, 130, 70),
			Material = Enum.Material.Grass, CFrame = CF(jitter(x, 0.7), 1.8, jitter(z, 0.7)) })
	end
end)
tryScatter(20, function(x, z)
	for _ = 1, rng:NextInteger(3, 5) do
		local h = rng:NextNumber(0.7, 1.4)
		mk("GrassTuft", { Size = V3(0.12, h, 0.12), Color = C3(120, 200, 110),
			Material = Enum.Material.Grass,
			CFrame = CF(jitter(x, 0.4), 2.0 + h / 2, jitter(z, 0.4))
				* CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), 0, math.rad(rng:NextNumber(-10, 10))) })
	end
end)
tryScatter(6, function(x, z)
	for _ = 1, rng:NextInteger(2, 4) do
		local jx = jitter(x, 0.6); local jz = jitter(z, 0.6)
		mk("MushroomStem", { Size = V3(0.2, 0.4, 0.2), Color = C3(245, 235, 220),
			Material = Enum.Material.SmoothPlastic, CFrame = CF(jx, 2.2, jz) })
		mk("MushroomCap", { Size = V3(0.55, 0.25, 0.55), Color = C3(220, 60, 60),
			Material = Enum.Material.SmoothPlastic, Shape = Enum.PartType.Ball,
			CFrame = CF(jx, 2.55, jz) })
	end
end)
tryScatter(3, function(x, z)
	mk("Stump", { Size = V3(1.4, 1.0, 1.4), Color = C3(110, 75, 50),
		Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder,
		CFrame = CF(x, 2.5, z) * CFrame.Angles(0, 0, math.rad(90)), CanCollide = true })
	mk("StumpRings", { Size = V3(1.42, 0.05, 1.42), Color = C3(150, 110, 80),
		Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder,
		CFrame = CF(x, 3.03, z) * CFrame.Angles(0, 0, math.rad(90)) })
end)

-- Sea grass at the beach edges where sand meets water.
local beachEdges = {
	V3(-32, 0, 12), V3(-32, 0, -12), V3(32, 0, 12), V3(32, 0, -12),
	V3(-12, 0, 32), V3(12, 0, 32), V3(-12, 0, -32), V3(12, 0, -32),
}
for _, b in ipairs(beachEdges) do
	for _ = 1, rng:NextInteger(4, 8) do
		local h = rng:NextNumber(0.6, 1.2)
		mk("SeaGrass", { Size = V3(0.1, h, 0.1), Color = C3(180, 200, 100),
			Material = Enum.Material.Grass,
			CFrame = CF(jitter(b.X, 4), 1.0 + h / 2, jitter(b.Z, 4))
				* CFrame.Angles(math.rad(rng:NextNumber(-15, 15)), 0, math.rad(rng:NextNumber(-15, 15))) })
	end
end

-- String lights between corner palms (decorative + ambient lighting).
local strings = {
	{V3(-22, 14, -22), V3(22, 14, -22)},
	{V3(22, 14, -22), V3(22, 14, 22)},
	{V3(22, 14, 22), V3(-22, 14, 22)},
	{V3(-22, 14, 22), V3(-22, 14, -22)},
}
for _, pair in ipairs(strings) do
	local a, b = pair[1], pair[2]
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	mk("StringRope", { Size = V3(length, 0.05, 0.05), Color = C3(60, 50, 40),
		Material = Enum.Material.Fabric,
		CFrame = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0) })
	local bulbs = math.floor(length / 4)
	for i = 1, bulbs do
		local t = i / (bulbs + 1)
		local pos = a:Lerp(b, t)
		local droop = math.sin(t * math.pi) * 0.6
		local bulb = mk("StringBulb", { Size = V3(0.4, 0.4, 0.4),
			Color = ({ C3(255, 220, 130), C3(255, 150, 130), C3(180, 220, 255), C3(220, 180, 255) })[((i - 1) % 4) + 1],
			Material = Enum.Material.Neon, Shape = Enum.PartType.Ball,
			CFrame = CF(pos.X, pos.Y - droop, pos.Z) })
		local pl = Instance.new("PointLight"); pl.Color = bulb.Color; pl.Range = 6; pl.Brightness = 1.0; pl.Parent = bulb
	end
end

print(string.format("[PHISH! ISLAND DECOR] Done. Pieces=%d", #decor:GetDescendants()))
return true
