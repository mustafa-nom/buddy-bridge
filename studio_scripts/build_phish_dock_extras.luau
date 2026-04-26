-- build_phish_dock_extras.luau
-- Adds the new PRD-aligned dock fixtures: NPC angler with rod-give prompt, Board of Fame
-- leaderboard, and the offshore PhishermanSpawn point. Depends on Workspace.PhishMap.PhishDock
-- already existing (run build_phish_world.luau first).
-- Idempotent: re-running wipes and rebuilds these specific instances.
-- Run via: Studio Command Bar (View > Command Bar > paste > Enter), or MCP execute_luau.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local C3 = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new

local map = Workspace:FindFirstChild("PhishMap"); assert(map, "PhishMap missing — run build_phish_world.luau first")
local dock = map:FindFirstChild("PhishDock"); assert(dock, "PhishDock missing")

local function mkPart(name, parent, props)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props or {}) do p[k] = v end
	p.Parent = parent; return p
end
local function tag(i, t) CollectionService:AddTag(i, t) end
local function weldTo(primary, others)
	for _, c in ipairs(others) do
		if c:IsA("BasePart") and c ~= primary then
			local w = Instance.new("WeldConstraint"); w.Part0 = primary; w.Part1 = c; w.Parent = primary
		end
	end
end

-- 1) NPC Angler stand-in (low-poly figure, rod prop, rod-give ProximityPrompt).
local oldNpc = dock:FindFirstChild("PhishNpcAngler"); if oldNpc then oldNpc:Destroy() end
local npc = Instance.new("Model"); npc.Name = "PhishNpcAngler"; npc.Parent = dock
local origin = V3(14, 1.6, 0)
local torso = mkPart("Torso", npc, {
	Size = V3(2, 3, 1.2), Color = C3(140, 100, 70), Material = Enum.Material.Fabric,
	CFrame = CF(origin + V3(0, 1.5, 0)),
})
mkPart("Head", npc, {
	Size = V3(1.4, 1.4, 1.4), Color = C3(255, 220, 180),
	Material = Enum.Material.SmoothPlastic, Shape = Enum.PartType.Ball,
	CFrame = CF(origin + V3(0, 3.7, 0)),
})
mkPart("Hat", npc, {
	Size = V3(1.6, 0.4, 1.6), Color = C3(120, 50, 60), Material = Enum.Material.Fabric,
	Shape = Enum.PartType.Cylinder,
	CFrame = CF(origin + V3(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
})
for i, side in ipairs({ -1, 1 }) do
	mkPart("Arm_" .. i, npc, {
		Size = V3(0.6, 2.4, 0.6), Color = C3(255, 220, 180),
		CFrame = CF(origin + V3(side * 1.4, 1.3, 0)),
	})
end
for i, side in ipairs({ -1, 1 }) do
	mkPart("Leg_" .. i, npc, {
		Size = V3(0.7, 2.4, 0.7), Color = C3(60, 60, 100),
		CFrame = CF(origin + V3(side * 0.4, -1, 0)),
	})
end
mkPart("RodProp", npc, {
	Size = V3(0.2, 4, 0.2), Color = C3(110, 70, 50), Material = Enum.Material.Wood,
	CFrame = CF(origin + V3(2, 2, 0.5)) * CFrame.Angles(0, 0, math.rad(-25)),
})
weldTo(torso, npc:GetChildren())
npc.PrimaryPart = torso
tag(npc, "PhishNpcAngler")

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Take a rod"; prompt.ObjectText = "Angler"
prompt.HoldDuration = 0; prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false; prompt.Parent = torso

-- 2) Board of Fame (leaderboard SurfaceGui — User 2 populates content via remote).
local oldBoard = dock:FindFirstChild("PhishBoardOfFame"); if oldBoard then oldBoard:Destroy() end
local boardModel = Instance.new("Model"); boardModel.Name = "PhishBoardOfFame"; boardModel.Parent = dock
local boardPos = V3(10, 4, -4)
mkPart("Post1", boardModel, {
	Size = V3(0.5, 8, 0.5), Color = C3(110, 70, 50), Material = Enum.Material.Wood,
	CFrame = CF(boardPos + V3(-3, 0, 0)),
})
mkPart("Post2", boardModel, {
	Size = V3(0.5, 8, 0.5), Color = C3(110, 70, 50), Material = Enum.Material.Wood,
	CFrame = CF(boardPos + V3(3, 0, 0)),
})
local panel = mkPart("Panel", boardModel, {
	Size = V3(7, 5, 0.3), Color = C3(255, 240, 200), Material = Enum.Material.WoodPlanks,
	CFrame = CF(boardPos + V3(0, 1.5, 0)),
})
boardModel.PrimaryPart = panel
tag(panel, "PhishBoardOfFame")

local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = panel; sg.PixelsPerStud = 50
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.2, 0); title.BackgroundTransparency = 1
title.Text = "🏆 BOARD OF FAME"; title.Font = Enum.Font.Cartoon; title.TextScaled = true
title.TextColor3 = C3(110, 70, 50); title.Parent = sg
local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, 0, 0.8, 0); body.Position = UDim2.new(0, 0, 0.2, 0)
body.BackgroundTransparency = 1
body.Text = "(no one's caught a phish yet)"
body.Font = Enum.Font.Cartoon; body.TextScaled = true
body.TextColor3 = C3(140, 100, 70); body.TextWrapped = true; body.Parent = sg

-- 3) PhishermanSpawn (invisible boss anchor, offshore in deeper water).
local oldSpawn = map:FindFirstChild("PhishermanSpawn"); if oldSpawn then oldSpawn:Destroy() end
local bossSpawn = mkPart("PhishermanSpawn", map, {
	Size = V3(2, 2, 2), Transparency = 1, CanCollide = false,
	CFrame = CF(60, 3, -40),
})
tag(bossSpawn, "PhishermanSpawn")

print("[PHISH! DOCK EXTRAS] Done. NPC + BoardOfFame + PhishermanSpawn placed.")
return true
