# User 1 — PHISH! Map Builder Prompt (Roblox Studio + MCP)

> Paste this entire file into your Claude Code session. You are **User 1**. You own the Roblox Studio map. You do **not** write Lua under `src/` — that is User 2's job. You and User 2 work in parallel against a shared tag/attribute contract (see below) so that your work merges cleanly.

---

## Mission

Build the entire **PHISH!** map in Roblox Studio using your Roblox MCP. PHISH! is a cozy retro-tropical fishing game where every fish is a digital citizenship moment in disguise (phishing scams, rumors, AI hallucinations, fake mods, kindness). Player spawns at a Lodge on a small island, walks to the dock, casts into the surrounding water, catches fish, sells them at the sell-shop for **Pearls** (currency), and buys better rods/lures at the fisherman shop. Better rods unlock harder colored water zones with rarer fish. A small rowboat near the island lets the player drive out to deeper waters and bring up to 3 friends along.

Your job is everything **visual, spatial, and physical**: terrain, buildings, water tile grid, fish models, boat, props, lighting. User 2 is building all the Lua services in parallel. Your contract with User 2 is the **tag/attribute spec** at the bottom of this prompt. Apply tags exactly as specified and User 2's code will Just Work.

---

## First Action

Run these in parallel before doing anything else:

1. Read `CLAUDE.md`
2. Read `docs/GAMEDESIGN.md`
3. Read `docs/PHISH_CORE_LOOP.md`
4. Read `docs/PHISH_CONTENT.md` (you'll model 12 fish from this)
5. Read `docs/PHISH_MVP_PLAN.md`
6. List `src/` to confirm the existing Buddy Bridge Studio assets (lobby, play arenas, booths) — those will be removed/replaced
7. Open Roblox Studio via your MCP and inspect the current place file

Then enter plan mode, write your build plan to `tasks/user1_map.md`, and only start building once you've sketched the island layout.

---

## Game Loop (so you build the right thing)

1. Player spawns at **Lodge** on the island
2. Walks across sand to the **dock** OR enters the **rowboat**
3. Casts lure into a **water tile** (16×16 stud Part)
4. Bobber wiggles → category cue (color/ripple)
5. Player chooses verb: **Cast / Verify / Reel / Cut Line / Report / Release**
6. Outcome panel → XP + journal + maybe aquarium
7. Walks to **sell-shop** → trades fish for Pearls
8. Walks to **fisherman shop** → buys better rod / lure / sonar
9. Better rod unlocks harder water tiles → rarer fish → loop tightens

---

## Aesthetic Direction

> **Animal Crossing meets early N64.** Chunky low-poly. Warm sunset palette. Cozy.

- **Color palette:** corals, golds, deep teals, soft pinks, warm cream sand. Avoid greys.
- **Lighting:** lock golden hour. `Lighting.ClockTime = 17.5`, `Technology = "Future"` or `"ShadowMap"`, warm orange ambient.
- **Geometry:** chunky, low-poly. Fewer triangles, more silhouette. No PBR realism.
- **Water:** stylized polygonal water (just colored Parts with subtle ripple decals or particle emitters — **NOT** real Roblox water Terrain). CanCollide off so the boat hovers above. See water tile spec below.
- **Lodge:** wooden cabin with slatted roof, warm window glow, lanterns, fishing-net wall decor.
- **Dock:** weathered wooden planks, lantern posts every few studs, bait barrel.
- **Boat:** small rowboat with chunky planks; looks hand-carved, not industrial.
- **Fish models:** chunky, characterful, category-coded. Free Robux Bass should be visibly *gaudy*. Compliment Carp should be visibly *soft and warm*. Don't aim for realism — aim for readable silhouette.
- **Props:** palm trees, tide pools with starfish, lily pads, fireflies (PointLight + small Part), hanging lanterns, beach umbrellas.

What to avoid: realistic shaders, dark/scary tones, modern minimalist UI styling, anything that breaks the "cozy" promise.

---

## Deliverables Checklist

Build in this order. Each block should be playable-testable before moving on.

### Block 1 — Foundation
- [ ] Wipe the prior Buddy Bridge map (lobby, play arena slots, booths) from `Workspace`. **Do not touch any `init.meta.json` files** in the Rojo `src/` folders — those control Rojo behavior and User 2's code depends on them.
- [ ] Set `Lighting.ClockTime = 17.5`, `Technology = "ShadowMap"` (or `"Future"` if not too expensive), `Ambient = warm orange`, `OutdoorAmbient` matching.
- [ ] Set `Workspace.Gravity = 196.2` (default) — boat physics rely on this.
- [ ] Place a `Folder` named `PhishMap` under `Workspace` to hold all map content. Anchor everything inside.

### Block 2 — Island
- [ ] Sand beach (chunky low-poly, warm cream color, ~80×80 studs roughly circular)
- [ ] Grass interior (soft green, slightly raised)
- [ ] 4–6 palm trees (low-poly trunks + chunky frond cluster)
- [ ] Tide pools (small water Parts in beach divots) with starfish/seashell props
- [ ] Stone path from Lodge → dock and Lodge → boat launch
- [ ] Sign at spawn: "Welcome to Phish Cove" (BillboardGui or SurfaceGui — User 2 won't touch decorative GUIs)

### Block 3 — Lodge
- [ ] Wooden cabin building (~16×16 stud footprint, sloped slatted roof)
- [ ] Door opening (no door needed — open archway is fine)
- [ ] Interior: warm wood floor, hanging lanterns (PointLight inside Part), 2–3 wall decorations
- [ ] **Aquarium volume**: a glass-fronted Part inside the Lodge, ~12×6×4 studs. Tag this `PhishAquariumDisplay`. User 2's code will spawn fish models inside this volume.
- [ ] **Spawn point**: SpawnLocation Part inside the Lodge (or just outside the door). Tag `PhishLodgeSpawn`. Set `Neutral = true`, `Enabled = true`.
- [ ] Aquarium origin anchor: an empty Part named `AquariumOrigin` inside the aquarium volume. User 2 references this by path: `workspace.PhishMap.PhishLodge.AquariumOrigin`.

### Block 4 — Dock
- [ ] Wooden dock extending ~24 studs into the water from the beach
- [ ] Lantern posts at intervals
- [ ] **Cast zones**: 2–3 Parts at the dock's water-facing end. Tag each `PhishCastZone`.
- [ ] Cast anchor: a Part named `CastAnchor` at the dock's tip. User 2 references `workspace.PhishMap.PhishDock.CastAnchor` to spawn lure visuals.

### Block 5 — Water Tile Grid (the meat of the map)
The water around the island is a grid of 16×16 stud Parts. CanCollide **off** (boat hovers; player swimming is irrelevant — they fish from dock or boat). Stylized — **NOT** real Roblox Terrain water.

Layout: ~12×12 grid (192×192 studs total) with the island in the center. Most tiles are Beginner; insert harder zones as colored patches.

For every water tile:
- 16×16×1 stud Part
- CanCollide `false`, Anchored `true`, Material `SmoothPlastic` (or `Glass` for sparkle)
- Subtle wave-bob animation via TweenService is nice-to-have (User 2 won't write it; you can use a Studio plugin or skip it for MVP)
- Tag `PhishWaterZone`
- Attribute `Difficulty` (string): `"Beginner"`, `"Intermediate"`, `"Expert"`, or `"Legendary"`
- Attribute `MinRodTier` (number): `1`, `2`, `3`, or `4`
- Name pattern: `Phish_WaterTile_<row>_<col>` (e.g. `Phish_WaterTile_4_7`)

Difficulty distribution + colors:

| Difficulty | Color (Color3) | Coverage | MinRodTier | Notes |
|------------|----------------|----------|-----------|-------|
| Beginner | Turquoise `(64, 200, 200)` | ~70% of tiles | 1 | Default; mostly Common+Rare fish |
| Intermediate | Cobalt `(40, 100, 200)` | ~20% of tiles, in patches near shore | 2 | More Rare, some Epic |
| Expert | Deep Purple `(100, 50, 160)` | ~8% of tiles, isolated patches further out | 3 | Epic-heavy, harder reels |
| Legendary | Crimson Swirl `(180, 40, 60)` | 1–2 tiles only, deepest spot | 4 | Legendary fish only |

Group all water tiles under `Workspace.PhishMap.PhishWater` for easy iteration.

### Block 6 — Rowboat (hovercraft)
- [ ] Small rowboat Model (~8 studs long, 4 wide, 2 tall)
- [ ] Wooden plank texture, chunky
- [ ] PrimaryPart named `Hull` — tag `PhishBoatHull`. CanCollide `true`. Anchored `false`. Mass low (User 2 will tune via VectorForce).
- [ ] **4 Seats** (driver + 3 passengers) — VehicleSeat for driver, regular Seats for passengers
  - Driver Seat: tag `PhishBoatSeat`, attribute `IsDriver = true`
  - Passenger Seats: tag `PhishBoatSeat`, attribute `IsDriver = false`
- [ ] BodyVelocity / VectorForce / AlignOrientation: don't add — User 2 will attach hovercraft physics constraints in Lua
- [ ] Boat starts docked next to the dock at `workspace.PhishMap.PhishBoat`. CFrame the hull just above the water surface (~1.5 studs above tile-top).
- [ ] **Important**: PrimaryPart must be set to `Hull` and the model must be welded to it. User 2 will move the entire model by setting Hull's CFrame.

### Block 7 — Fisherman Shop (Powerups)
- [ ] Small wooden shack on the island (separate from Lodge), beach side
- [ ] NPC fisherman behind a counter (a basic Rig is fine — animation comes later)
- [ ] **Proximity trigger**: Part in front of the counter, ~6×6×6 studs invisible volume
  - Tag `PhishShopTrigger`
  - Attribute `ShopType` (string): `"Powerup"`
- [ ] Add a `ProximityPrompt` to the shop counter Part with `ActionText = "Shop"`, `HoldDuration = 0`, `MaxActivationDistance = 8`. User 2 will hook the prompt; you just need it placed.
- [ ] Sign above shop: "FISHERMAN'S WARES" (SurfaceGui)

### Block 8 — Sell Shop
- [ ] Second small structure (separate from fisherman shop), maybe at the dock end
- [ ] NPC fishmonger or just a counter with a scale
- [ ] **Proximity trigger**: Part in front, same shape as fisherman shop
  - Tag `PhishShopTrigger`
  - Attribute `ShopType` (string): `"Sell"`
- [ ] ProximityPrompt with `ActionText = "Sell Fish"`
- [ ] Sign: "FISH MARKET" (SurfaceGui)

### Block 9 — Fish Models (12 fish per `docs/PHISH_CONTENT.md`)

Place each fish as a Model under `ServerStorage.PhishFishTemplates`.

Each model:
- PrimaryPart set
- Tag `PhishFishTemplate`
- Attribute `FishId` (string) — exactly matches the id in `FishRegistry` (e.g. `"free_robux_bass"`)
- Visual coding: each category should be silhouette-distinct
  - **Scam Bait**: gaudy / glittery / gold / loud
  - **Rumor Fish**: shifting / shimmering / off-color
  - **Mod Imposter**: wears a fake-looking badge or uniform piece
  - **Kindness**: soft glow, warm color, friendly silhouette

The 12 fish (mirror this exactly — User 2's `FishRegistry.lua` will match):

| FishId | Display | Category | Visual hint |
|--------|---------|----------|-------------|
| `free_robux_bass` | Free Robux Bass | ScamBait | Gold body, glitter texture, Robux-shape fin |
| `lottery_lobster` | Lottery Lobster | ScamBait | Confetti-spotted shell, oversized claws |
| `link_shark` | Link Shark | ScamBait | Underline-shaped fin, deep blue |
| `telephone_trout` | Telephone Trout | Rumor | Wobbly translucent body, color shifts |
| `wiki_walleye` | Wiki-Forgery Walleye | Rumor | Page-textured fin, sepia tone |
| `hallucinated_halibut` | Hallucinated Halibut | Rumor | Glitchy / pixelated mesh, semi-transparent |
| `faux_mod_flounder` | Faux-Mod Flounder | ModImposter | Off-blue badge on side |
| `pseudo_support_shark` | Pseudo-Support Shark | ModImposter | "Support" lifebuoy collar |
| `counterfeit_admin_cod` | Counterfeit-Admin Cod | ModImposter | Fake crown |
| `compliment_carp` | Compliment Carp | Kindness | Soft pink glow, gentle silhouette |
| `helpful_hint_herring` | Helpful-Hint Herring | Kindness | Warm yellow body |
| `real_friend_rainbow` | Real-Friend Rainbow | Kindness (Legendary) | Rainbow shimmer, larger size |

If you don't have time to model all 12 unique meshes, **ship simple primitive composites** (sphere body + colored fins + a defining prop). Ugly-but-shipping > pretty-but-incomplete.

### Block 10 — Bobber + Lure Visuals
- [ ] Place 4 bobber Models under `ServerStorage.PhishBobbers`, one per category cue:
  - `Bobber_Glitter` (Scam cue) — gold sparkle Part
  - `Bobber_Shimmer` (Rumor cue) — color-shifting Part
  - `Bobber_Badge` (ModImposter cue) — small badge-shaped Part
  - `Bobber_Glow` (Kindness cue) — soft warm PointLight
- [ ] Lure model under `ServerStorage.PhishLures` — small weighted hook Part

### Block 11 — Tags + Attributes Pass
After everything is built, sweep the place to confirm every required tag/attribute is set. Use Studio's Tag Editor or your MCP's tag tools. The acceptance criteria below has the full checklist.

### Block 12 — Polish
- [ ] Lanterns light up after sunset (hard-locked to golden hour, so mostly aesthetic)
- [ ] Ambient SFX: water lapping (Sound on dock), distant gulls (Sound in island center), wind in palms
- [ ] Particle emitters in tide pools (small bubble particles)
- [ ] Fireflies near Lodge at night (decorative)
- [ ] BillboardGui welcome sign at spawn

---

## Shared Contract (you write the world; User 2 reads it)

This is the **only** place User 1 and User 2 sync. If you change a tag or attribute name, the game breaks. If User 2 wants to change a name, they must Discord you first.

### CollectionService Tags

| Tag | Where | Required attributes |
|-----|-------|---------------------|
| `PhishLodgeSpawn` | SpawnLocation Part | — |
| `PhishCastZone` | Dock-edge Parts (2–3) | — |
| `PhishWaterZone` | Every 16×16 water tile | `Difficulty` (string), `MinRodTier` (number) |
| `PhishFishTemplate` | Each fish Model in `ServerStorage.PhishFishTemplates` | `FishId` (string) |
| `PhishAquariumDisplay` | Aquarium glass volume in Lodge | — |
| `PhishShopTrigger` | Shop proximity volume | `ShopType` (string: "Powerup" or "Sell") |
| `PhishBoatHull` | Boat PrimaryPart | — |
| `PhishBoatSeat` | Each boat seat | `IsDriver` (boolean) |

### Named CFrame Anchors (User 2 references by path)

| Path | What |
|------|------|
| `workspace.PhishMap.PhishLodge.AquariumOrigin` | Origin Part where aquarium fish spawn |
| `workspace.PhishMap.PhishDock.CastAnchor` | Origin Part where lures spawn on cast |
| `workspace.PhishMap.PhishBoat` | Boat Model parent (Hull is PrimaryPart) |

### ServerStorage Layout

```
ServerStorage/
├── PhishFishTemplates/    (12 Models, each with PhishFishTemplate tag + FishId attr)
├── PhishBobbers/          (4 Models)
└── PhishLures/            (1+ Models)
```

User 2's services will `require` from `ReplicatedStorage` and `Clone` from `ServerStorage`. Do not put scripts in your Studio assets — leave scripting to User 2.

---

## File Ownership Rules (no merge conflicts)

| Path | You? | User 2? |
|------|------|---------|
| Roblox place file (via MCP / Studio) | ✅ own | read-only via Rojo sync |
| `src/**/*.lua` | ❌ never edit | ✅ owns |
| `default.project.json`, `selene.toml`, `aftman.toml` | ❌ | ✅ |
| `init.meta.json` files in `src/` | ❌ never delete or edit | ✅ |
| `human_todo.md` | ✅ owns (Studio tasks) | ❌ |
| `tasks/user1_map.md` (your task list — create if missing) | ✅ owns | ❌ |
| `tasks/user2_code.md` | ❌ | ✅ owns |
| `tasks/todo.md` (top-level pointer) | read-only | read-only |
| `tasks/lessons.md` | append-only at end | append-only at end (coordinate via Discord) |
| `CLAUDE.md`, `docs/PHISH_*.md`, `docs/GAMEDESIGN.md` | ❌ locked — ping team if wrong | ❌ locked |
| `prompts/user1_map_prompt.md` (this file) | ❌ | ❌ |

**When in doubt: don't touch what the other user owns. Discord them.**

---

## Workflow

1. **Plan first.** Enter plan mode for any block above. Sketch the island layout in `tasks/user1_map.md` before placing parts.
2. **Use Roblox MCP for everything.** Don't hand-edit place files; let the MCP tools place parts, set properties, apply tags.
3. **`init.meta.json` rule.** If Rojo starts wiping your Studio parts on sync, the cause is almost always a missing `init.meta.json` in a `src/` subfolder. Never delete those files. If you create a new ServerStorage subfolder via MCP, that's fine — it doesn't need an `init.meta.json` (only `src/`-mapped folders do).
4. **Sync with Rojo.** User 2 will be running `rojo serve`; Studio plugin connects, code changes appear. You don't run rojo commands — you just keep Studio open with the plugin connected.
5. **Commit your Studio work.** Save the place file periodically. If your Studio work lives outside `src/` (it does — Workspace + ServerStorage), it doesn't go in git automatically. **Export as `.rbxlx` and commit it** OR if the team has set up a Studio-place git workflow, follow that.
   - If unclear, ask the user where the place file should live. A common pattern: commit `.rbxlx` snapshots in a `studio/` folder.
6. **Test in solo Studio play mode** after each block. Walk around, confirm tiles look right, confirm boat seats work as seats (even without physics).
7. **Discord-coordinate** when:
   - You finish a block (so User 2 knows tags are now placeable for testing)
   - You need a tag name changed
   - You're blocked on a contract decision
8. **Lessons.** If you hit a Studio-MCP gotcha (like "tags don't replicate to clients without RobloxEditableMesh" or whatever), append it to `tasks/lessons.md` at the END of the file. Don't edit User 2's lesson entries.

---

## Acceptance Criteria

You're done when:

- [ ] All 12 deliverable blocks above are checked off
- [ ] Player can walk from spawn → dock and stand at a cast zone
- [ ] Player can sit in the rowboat driver seat (physics from User 2 will make it move)
- [ ] All `PhishWaterZone` tiles have correct `Difficulty` and `MinRodTier` attributes (verify with the Tag Editor or your MCP)
- [ ] All 12 fish models exist in `ServerStorage.PhishFishTemplates` with `FishId` attributes matching the FishRegistry id list above
- [ ] Both shop triggers exist with correct `ShopType` attribute
- [ ] Lighting is locked at golden hour
- [ ] No `init.meta.json` files were deleted
- [ ] `rojo serve` connects without warnings (User 2 will confirm)
- [ ] User 2 can solo-play and see the world they expect

When all of these pass: commit and push your Studio snapshot, post in Discord "User 1 map MVP done", and start on polish (Block 12).

---

## Out of Scope (do not build)

- Multiple ponds beyond the island
- Day/night cycle
- Weather VFX
- Boss-fish-specific arena
- Cosmetics shop UI (User 2 builds; you only need the proximity trigger)
- Tutorial NPCs / dialogue (post-MVP)
- Realistic Roblox Terrain water (use stylized Parts)
