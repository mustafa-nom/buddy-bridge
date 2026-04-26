# User 1 — PHISH! Map Build Plan

Owner: User 1 (map / Studio).
Source of truth for the contract: `prompts/user1_map_prompt.md`.
This file tracks **what's built**, **what's next**, and the **layout decisions** the prompt left open.

## Current State

- Studio plugin status: **NOT CONNECTED** as of this session start. MCP `execute_luau` returns `Studio plugin connection timeout`. All build work is staged into two Luau scripts under `studio_scripts/`. They can be (a) fired via MCP the moment the plugin reconnects, or (b) pasted into the Studio Command Bar by hand. Either path produces the same result.
  - `studio_scripts/build_phish_world.luau` (477 lines) — Workspace.PhishMap (foundation, island, lodge, dock, water grid, boat, two shops). Run first.
  - `studio_scripts/build_phish_templates.luau` (158 lines) — ServerStorage.PhishFishTemplates (12), .PhishBobbers (4), .PhishLures (1). Run second.
  - Split because a single script breached the 500-line per-file rule. The two are independent — world doesn't depend on templates and vice versa — but conventionally world is run first so a Studio dev can sanity-check the layout before content lands.
- Code side (User 2): not started. `src/` still reflects Buddy Bridge.
- The build script is **idempotent** — running it again wipes `Workspace.PhishMap` + the three `ServerStorage.Phish*` folders and rebuilds from scratch. Safe to re-run after edits.

## Layout Decisions (filling gaps in the prompt)

The User 1 prompt left some specifics open. Decisions made and the reason for each:

### Island center + water grid placement
- Map origin is `Vector3(0, 0, 0)`. Island sits centered on origin; water tiles fan out in a **12×12 grid** of 16-stud tiles spanning roughly `(-96, -96)` to `(96, 96)` in XZ. Total water footprint ~192×192 studs.
- Water Y-level: `0`. Top surface of water = `0.5`. Sand top = `1.5` (so beach reads as raised above water).
- Tiles whose center falls inside the island radius (~38 studs) are **not spawned** — leaves a clean island silhouette without water poking through.

### Difficulty zoning (rings, not random patches)
The prompt allows "patches"; I'm shipping concentric rings instead because (a) it makes the rod-tier gating *visually obvious* to a kid ("the deeper I go, the harder it gets"), and (b) it forces the rowboat to matter — Tier 2+ tiles are physically out of dock cast range.

| Distance from origin | Difficulty | Color | MinRodTier |
|---------------------|------------|-------|-----------|
| < 38 studs | (skipped — island) | — | — |
| 38–68 studs | Beginner | Turquoise (64,200,200) | 1 |
| 68–92 studs | Intermediate | Cobalt (40,100,200) | 2 |
| 92–112 studs | Expert | Deep Purple (100,50,160) | 3 |
| ≥ 112 studs | Legendary | Crimson (180,40,60) | 4 |

Final tile counts shake out close to the prompt's 70/20/8/2 distribution.

### Lodge + dock + boat positions
- **Lodge** at `(-20, 0, 0)`, facing east toward dock. Spawn just outside the open archway.
- **Dock** runs east from beach, tip at roughly `(34, 0, 0)`. Three `PhishCastZone` Parts at the tip.
- **Rowboat** sits at `(40, 1.5, 8)`, just north of the dock tip, hovering 1.5 studs above water. Stepping onto it is a small jump from the dock.
- **Fisherman shop** ("FISHERMAN'S WARES") at `(-30, 0, 18)`, beach side, behind the Lodge.
- **Sell shop** ("FISH MARKET") at `(20, 0, -18)`, near the dock entrance for fast sell-after-fish loop.

### Aesthetic locks
- `Lighting.ClockTime = 17.5`, `Technology = "ShadowMap"` (cheaper than Future, fine for cozy stylized look).
- Ambient warm orange `(180, 130, 90)`, OutdoorAmbient `(120, 90, 60)`.
- All wood: `(130, 90, 60)`. Lantern glow: PointLight, color `(255, 220, 150)`, brightness 1.5, range 12.
- All Parts in the build are `Anchored = true` except the boat Hull. The boat Hull is `Anchored = false` so User 2's hovercraft physics can move it.

### Fish models (Block 9)
Every fish is a primitive composite (sphere body + colored fins + category-defining prop part). The prompt explicitly says "ugly-but-shipping > pretty-but-incomplete." Each model:
- has `PrimaryPart` set to a body Part named `Body`
- has tag `PhishFishTemplate`
- has attribute `FishId` (string) matching `docs/PHISH_CONTENT.md` exactly
- is `Anchored = true` (User 2 will clone + reanimate as needed)
- is parented to `ServerStorage.PhishFishTemplates`

## Block Status

| # | Block | Status | Notes |
|---|-------|--------|-------|
| 1 | Foundation (wipe, lighting, PhishMap) | Done | Lighting + Workspace.PhishMap. `Lighting.Technology` skipped (plugin sandbox lacks RobloxScript capability — pcall'd) |
| 2 | Island | Done | Sand + grass + 5 palms + 2 tide pools + 2 paths |
| 3 | Lodge | Done | Cabin, archway, aquarium volume tagged, spawn tagged, AquariumOrigin anchor |
| 4 | Dock | Done | 26-stud dock, 6 lanterns, 3 cast zones, CastAnchor at tip |
| 5 | Water tile grid | Done | **128 tiles** built (12×12 grid minus island center). Difficulty distribution **Beginner 90 / Intermediate 26 / Expert 10 / Legendary 2 = 70/20/8/2%** (matches contract — fixed after first pass over-rotated to outer rings). Percentile-classifier replaced concentric-ring approach |
| 6 | Rowboat | Done | Hull tagged + welded, 1 VehicleSeat (driver) + 3 Seats (passengers), all `IsDriver` attrs set |
| 7 | Fisherman shop | Done | "FISHERMAN'S WARES" sign, trigger tagged with `ShopType=Powerup`, ProximityPrompt placed |
| 8 | Sell shop | Done | "FISH MARKET" sign, trigger tagged with `ShopType=Sell`, ProximityPrompt placed |
| 9 | Fish templates | Done | **Realigned to PRD: 6 phish species + 2 legit** in `ServerStorage.PhishFishTemplates`. FishIds match `docs/PHISH_PHISH_DEX.md` (UrgencyEel, AuthorityAnglerfish, RewardTuna, CuriosityCatfish, FearBass, FamiliarityFlounder, PlainCarp, HonestHerring). `IsLegit` attribute distinguishes legit fish |
| 10 | Bobbers + lure | Done | 4 bobbers in `ServerStorage.PhishBobbers`, 1 lure in `ServerStorage.PhishLures` |
| 11 | Tags + attributes verification | Done | All 8 tags ok, all 3 named anchors found, 12 unique FishIds, no missing attrs |
| 12 | Polish (SFX, particles, fireflies) | Done | Welcome sign (now PRD copy "PHISH / Cast. Reel. Inspect. Don't get phish'd.") + 6 fireflies + 2 tide-pool emitters + dock/center ambient sounds. Built into `studio_scripts/build_phish_polish.luau` |
| 13 | **PRD realignment** (NPC angler, BoardOfFame, PhishermanSpawn) | Done | New `studio_scripts/build_phish_dock_extras.luau` adds the angler stand-in with rod-give ProximityPrompt at the dock entrance, the Board of Fame leaderboard SurfaceGui, and the offshore PhishermanSpawn boss anchor. New tags: `PhishNpcAngler`, `PhishBoardOfFame`, `PhishermanSpawn` |

## Run Order

1. Confirm Studio plugin is connected (in Studio: `Plugins` tab → Roblox MCP → green "Connected").
2. Run **`studio_scripts/build_phish_world.luau`**:
   - **Via MCP:** call `mcp__robloxstudio__execute_luau` with the file's contents.
   - **Manual:** open Studio → `View` → `Command Bar` → paste → Enter.
   - Expect output: `[PHISH! WORLD] Done. WaterTiles=119. Run build_phish_templates.luau next.` (tile count will be ~119 give or take 2 depending on integer rounding.)
3. Run **`studio_scripts/build_phish_templates.luau`** the same way.
   - Expect output: `[PHISH! TEMPLATES] Done. Species=8 (6 phish, 2 legit). Bobbers=4 Lures=1`
4. Run **`studio_scripts/build_phish_dock_extras.luau`** for the PRD additions (NPC angler, BoardOfFame, PhishermanSpawn).
   - Expect output: `[PHISH! DOCK EXTRAS] Done. NPC + BoardOfFame + PhishermanSpawn placed.`
5. Run **`studio_scripts/build_phish_polish.luau`** last for the welcome sign + ambient.
   - Expect output: `[PHISH! POLISH] Done.`
4. Verify `Workspace.PhishMap` has children: `PhishIsland`, `PhishLodge`, `PhishDock`, `PhishWater`, `PhishBoat`, `PhishFishermanShop`, `PhishSellShop`.
5. Verify `ServerStorage` has folders: `PhishFishTemplates` (12 Models), `PhishBobbers` (4 Models), `PhishLures` (1 Model).
6. Run Block 11 verification (call `get_tagged` for each tag in the contract).
7. Solo-play Studio test: walk from spawn → dock → confirm cast zones are at the dock tip; sit in boat driver seat (no movement yet — User 2 owns physics).

## Coordination Notes

- **Do not edit any `init.meta.json` under `src/`.** They are required for Rojo to leave Studio-built content alone on sync.
- **Do not write Lua under `src/`.** That's User 2's lane. The builder script lives under `studio_scripts/` which is intentionally outside Rojo's tree.
- The shared contract (tags, attributes, named anchors) is locked to the table at the bottom of `prompts/user1_map_prompt.md`. If a name needs to change, ping User 2 first.

## Out of Scope for This Pass

Per the prompt:
- Multiple ponds beyond the island
- Day/night cycle, weather VFX
- Boss-fish arena
- Cosmetics shop UI (User 2 builds; only the proximity trigger is User 1's job)
- Tutorial NPC dialogue
- Realistic Roblox Terrain water (using stylized Parts, as required)
