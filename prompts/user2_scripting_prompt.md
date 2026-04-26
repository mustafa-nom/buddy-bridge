# User 2 — PHISH! Scripting Prompt (Lua + Rojo)

> Paste this entire file into your Claude Code session. You are **User 2**. You own all Lua under `src/`. You do **not** open Roblox Studio to build geometry — that is User 1's job. You and User 1 work in parallel against a shared tag/attribute contract (see below) so that your work merges cleanly.

---

## Mission

Build the entire **PHISH!** Lua codebase. PHISH! is a cozy retro-tropical fishing game where every fish is a digital citizenship moment in disguise (phishing scams, rumors, AI hallucinations, fake mods, kindness). Player spawns at a Lodge, casts into water tiles, picks the right verb (Cast / Verify / Reel / Cut Line / Report / Release) for each fish, sells catches at the sell-shop for **Pearls** (currency), buys better rods/lures at the fisherman shop, unlocks harder colored water zones with rarer fish. A rowboat with hovercraft physics lets the player drive to deeper waters with up to 3 friends.

Your job is everything in `src/`: services, controllers, registries, UIs, remotes, physics, economy. User 1 is building the Studio map in parallel. Your contract with User 1 is the **tag/attribute spec** at the bottom of this prompt. Read tags via `CollectionService`; never reach into specific instance paths except the named anchors User 1 promises to place.

---

## First Action

Run these in parallel before doing anything else:

1. Read `CLAUDE.md`
2. Read `docs/GAMEDESIGN.md`
3. Read `docs/PHISH_CORE_LOOP.md` (this is your engineering bible — sequence diagram, remote list, state machine all here)
4. Read `docs/PHISH_CONTENT.md` (FishRegistry data spec)
5. Read `docs/PHISH_MVP_PLAN.md`
6. List `src/` to see the current Buddy Bridge code that needs archiving (P1)
7. Read existing reusable modules: `src/StarterPlayerScripts/Guide/BookView.lua` (you'll repurpose for Field Guide), `src/ServerScriptService/Services/Levels/BackpackCheckpoint/BeltController.lua` (timing pattern for reel mini-game), `src/ReplicatedStorage/RemoteService.lua` (extend for PHISH! remotes), `src/ReplicatedStorage/Modules/RateLimiter.lua`, `src/ReplicatedStorage/Modules/UIStyle.lua`

Then enter plan mode, write your build plan to `tasks/user2_code.md`, and only start coding once you have a P1 → P2 → P3 sequence with smoke-test checkpoints.

---

## Game Loop (so you build the right systems)

1. Player spawns at **Lodge** (`PhishLodgeSpawn` tag → SpawnLocation)
2. Walks to dock (cast zone via `PhishCastZone` tag) OR enters rowboat (`PhishBoatHull` + `PhishBoatSeat`)
3. Player presses cast → `RequestCast` → server picks fish from active water tile's spawn pool → `BiteOccurred`
4. Player chooses verb in decision window
5. If Reel → mini-game → `CatchResolved`
6. Outcome → XP + journal entry + (Kindness only) aquarium offer
7. Walks to sell-shop (`PhishShopTrigger` with `ShopType="Sell"`) → `RequestSellFish` → Pearls
8. Walks to fisherman shop (`PhishShopTrigger` with `ShopType="Powerup"`) → `RequestPurchaseUpgrade` → unlocks gear
9. Better rod tier (1→4) gates which `PhishWaterZone` Difficulty levels can spawn fish for them

---

## Deliverables Checklist

Build in dependency order. Smoke-test after each block.

### P1 — Code Archive Pass (do first)
Buddy Bridge Lua under `src/` still wires up Stranger Danger and Backpack Checkpoint. Archive the SD-only files; keep BPC files for pattern reference.

- [ ] Create `src/_archive/` (note the underscore — keeps it sorted last; outside Rojo project mapping so it's harmless). Add a one-line README explaining the move.
- [ ] **Confirm `src/_archive/` is NOT mapped in `default.project.json`.** If you put it under a mapped folder you must add an `init.meta.json` with `{"ignoreUnknownInstances": true}` to it.
- [ ] Move these files (preserve relative path structure under `_archive/`):
  - `ReplicatedStorage/Modules/StrangerDangerLogic.lua`
  - `ReplicatedStorage/Modules/NpcRegistry.lua`
  - `ServerScriptService/Services/Levels/StrangerDangerLevel.lua`
  - `ServerScriptService/Services/Scenarios/StrangerDangerScenario.lua`
  - `ServerScriptService/Services/GuideControlService.lua` (entirely Stranger-Danger-coupled)
  - `StarterPlayerScripts/Explorer/NpcDescriptionCardController.client.lua`
  - `StarterPlayerScripts/Explorer/StrangerDangerFxController.client.lua`
  - `StarterPlayerScripts/Explorer/NpcBarkController.client.lua` (if it has no PHISH! relevance)
  - `StarterPlayerScripts/Guide/GuideAnnotationController.client.lua`
  - `StarterPlayerScripts/Guide/Manuals/StrangerDangerManual.lua`
  - `StarterPlayerScripts/Guide/Manuals/StrangerDangerBookContent.lua`
  - `StarterPlayerScripts/Guide/GuideBoothController.client.lua` (BB-only)
  - `StarterPlayerScripts/Guide/GuideNotesController.client.lua` (BB-only)
- [ ] **Keep BPC files** for now — `BeltController.lua`, `WaveDirector.lua`, `MiniBossDirector.lua`, `GuideRehydrate.lua`, `BackpackCheckpointLevel.lua`, `BackpackCheckpointScenario.lua`, `BackpackCheckpointManual.lua`, `ScannerService.lua`, `ScannerGuideHud.client.lua`. You'll repurpose patterns from them in P2.
- [ ] Disconnect Stranger Danger registrations in `ServerBootstrap.server.lua` and any client bootstrap. Comment out (don't delete) the `LevelService` BPC/SD wiring — you'll replace with PHISH! wiring in P2.
- [ ] Run `rojo build default.project.json -o build.rbxl` and `selene src/` — both must pass before moving on.

### P2 — PHISH! Core Systems

#### Data + Shared
- [ ] `ReplicatedStorage/Modules/FishRegistry.lua` — author all 12 MVP fish per `docs/PHISH_CONTENT.md`. Data-driven; no logic, just a record per fish.
- [ ] `ReplicatedStorage/Modules/FishCategoryTypes.lua` — enum: `ScamBait`, `Rumor`, `ModImposter`, `Kindness`
- [ ] `ReplicatedStorage/Modules/ReelActionTypes.lua` — enum: `Cast`, `Wait`, `Verify`, `Reel`, `CutLine`, `Report`, `Release`
- [ ] `ReplicatedStorage/Modules/RarityTypes.lua` — enum: `Common`, `Rare`, `Epic`, `Legendary`
- [ ] `ReplicatedStorage/Modules/WaterDifficultyTypes.lua` — enum: `Beginner`, `Intermediate`, `Expert`, `Legendary`
- [ ] `ReplicatedStorage/Modules/PowerupCatalog.lua` — rod tiers + lures + sonar (data-driven; see Economy below)
- [ ] `ReplicatedStorage/Shared/PondState.lua` — server-side per-player state machine (Idle, Casting, Waiting, BitePending, Verifying, Reeling, Resolving)
- [ ] `ReplicatedStorage/Shared/FishEncounterTypes.lua` — payload shapes
- [ ] Extend `ReplicatedStorage/RemoteService.lua` with all remotes from §RemoteService Additions below

#### Server services (`ServerScriptService/Services/`)
- [ ] `PondService` — owns active water-tile spawn pools; reads `PhishWaterZone` tags + attributes via CollectionService; gates spawns by `MinRodTier`
- [ ] `CastingService` — handles `RequestCast`; validates rod tier vs target tile difficulty; spawns lure visual at `workspace.PhishMap.PhishDock.CastAnchor` or boat hull
- [ ] `BiteService` — picks fish weighted-random from pond pool, schedules `BiteOccurred` after randomized 2–6 sec wait, owns the bobber category-cue payload
- [ ] `CatchResolutionService` — server-authoritative validation of verb-vs-fish; grants XP, journal unlock, optional aquarium offer
- [ ] `FieldGuideService` — manages per-player Field Guide unlocks; exposes `RequestVerify`
- [ ] `JournalService` — per-player caught-fish journal
- [ ] `AquariumService` — places Kindness fish models in `PhishAquariumDisplay` volume; manages slot capacity (4–6 fish)
- [ ] `EconomyService` — Pearls currency, sell prices, purchase validation
- [ ] `BoatService` — hovercraft physics: VectorForce + AlignOrientation on boat Hull; reads driver input via `PhishBoatSeat` `IsDriver=true` seat; clamps to water-grid bounds
- [ ] `ShopService` — handles `RequestPurchaseUpgrade` and `RequestSellFish`; reads `PhishShopTrigger` ShopType
- [ ] Update `ServerBootstrap.server.lua` — wire all new services in startup order
- [ ] Extend existing `ScoringService`, `RewardService`, `DataService` (or replace if BB shape doesn't fit)

#### Client controllers (`StarterPlayerScripts/`)
- [ ] `Angler/AnglerController.client.lua` — main rod input loop, decision window UI (4 verb buttons)
- [ ] `Angler/CastingController.client.lua` — cast charge bar, lure visual
- [ ] `Angler/ReelMinigameController.client.lua` — repurpose BeltController timing pattern (do not fork the file; build new module that uses the pattern)
- [ ] `Angler/BoatDriverController.client.lua` — handles WASD input when seated as driver, sends to BoatService
- [ ] `UI/FieldGuideController.client.lua` — repurpose `BookView.lua` pattern; one page per fish entry
- [ ] `UI/JournalController.client.lua` — list of caught fish, opens to Field Guide page on click
- [ ] `UI/AquariumViewController.client.lua` — third-person camera framing of aquarium volume on prompt
- [ ] `UI/PowerupShopController.client.lua` — opens on `PhishShopTrigger ShopType=Powerup` proximity prompt; lists rods/lures/sonar with prices; uses `UIStyle.lua` Cartoon font; warm cozy palette to match map aesthetic
- [ ] `UI/SellShopController.client.lua` — opens on `ShopType=Sell` prompt; lists current inventory of caught fish with sell prices; sell-individual + sell-all
- [ ] `UI/HudController.client.lua` — Pearls counter, current rod tier, current XP, decision-window timer
- [ ] `UI/NotificationController.client.lua` — toast for XP grants, journal unlocks, lesson lines
- [ ] `ClientBootstrap.client.lua` — wire all new controllers

### P3 — Content + Polish
- [ ] Final lesson-line copy on all 12 fish (test by reading aloud as if to a 9-year-old)
- [ ] SFX hooks: cast, splash, bite (4 category variants), reel-success, sad-trombone, shop-buy, shop-sell, boat-engine
- [ ] Field Guide page styling (warm parchment background)
- [ ] Tutorial nudge on first cast (one-time)
- [ ] Pre-populated demo profile so a fresh spawn already has 1 Compliment Carp in the aquarium for the demo
- [ ] Append demo script (90 sec) to `docs/PHISH_MVP_PLAN.md` if missing details
- [ ] Sweep `tasks/lessons.md` and add anything you learned

### P4 — Stretch (only if MVP locks early)
- [ ] 6 stretch fish from `docs/PHISH_CONTENT.md`
- [ ] Boss Phisher Legendary encounter
- [ ] DataStore persistence for Pearls + journal + aquarium
- [ ] Buddy Mode (second player coaches via Field Guide UI)
- [ ] Sonar powerup that reveals fish category before bite

---

## RemoteService Additions

Declare all remotes in `RemoteService.lua` with comments explaining purpose. Server-validate every payload. Rate-limit every player-triggered remote (use existing `RateLimiter.lua`).

| Remote | Direction | Payload | Purpose |
|--------|-----------|---------|---------|
| `RequestCast` | C→S | `{aimDirection, chargePower, sourceWaterTile}` | Player throws lure |
| `BiteOccurred` | S→C | `{encounterId, bobberCue, rippleCue, decisionWindowSec}` | Notify of bite |
| `RequestVerify` | C→S | `{encounterId}` | Open Field Guide for encounter |
| `FieldGuideEntryUnlocked` | S→C | `{fishId, entryText}` | Reveal/unlock entry |
| `RequestReel` | C→S | `{encounterId}` | Commit to reel |
| `RequestCutLine` | C→S | `{encounterId}` | Refuse catch |
| `RequestReport` | C→S | `{encounterId}` | Report imposter |
| `CatchResolved` | S→C | `{fishId, category, rarity, xpDelta, lessonLine, wasCorrect, addedToInventory}` | Final result |
| `JournalUpdated` | S→C | `{fishId}` | Add to journal |
| `RequestPlaceFishInAquarium` | C→S | `{fishId}` | Display in aquarium |
| `AquariumUpdated` | S→C | `{fishId, slot}` | Aquarium changed |
| `XpGranted` | S→C | `{amount, total}` | XP UI update |
| `PearlsGranted` | S→C | `{amount, total}` | Currency UI update |
| `RequestSellFish` | C→S | `{fishId, quantity}` | Sell from inventory |
| `RequestPurchaseUpgrade` | C→S | `{powerupId}` | Buy powerup |
| `InventoryUpdated` | S→C | `{inventory}` | Caught-fish inventory changed |
| `PowerupUnlocked` | S→C | `{powerupId, currentRodTier}` | Powerup grant |
| `RequestEnterShop` | C→S | `{shopType}` | Open shop UI (server validates proximity) |
| `RequestBoatThrottle` | C→S | `{throttle, steer}` | Boat driver input |
| `BoatStateUpdated` | S→C | `{position, velocity}` | Optional, for passenger UI |
| `Notify` | S→C | `{message, severity}` | Generic toast |

---

## Economy Spec (you implement; user said "you figure it out")

### Currency
- **Pearls** — single currency, server-authoritative

### Rod Tiers (Powerup Shop catalog)

| RodId | Tier | Display | Price (Pearls) | Unlocks Difficulty |
|-------|------|---------|---------------|---------------------|
| `rod_wooden` | 1 | Wooden Rod | 0 (starter) | Beginner |
| `rod_iron` | 2 | Iron Rod | 50 | + Intermediate |
| `rod_crystal` | 3 | Crystal Rod | 200 | + Expert |
| `rod_lighthouse` | 4 | Lighthouse Rod | 800 | + Legendary |

### Other Powerups

| PowerupId | Display | Price | Effect |
|-----------|---------|-------|--------|
| `lure_verifier` | Verifier Lens | 30 | Verify takes 1.5 sec instead of 3 sec |
| `lure_patience` | Patience Charm | 40 | Decision window extended by 50% |
| `sonar_basic` | Basic Sonar | 100 | Reveals true category 30% of bites |
| `sonar_advanced` | Advanced Sonar | 300 | Reveals true category 80% of bites (post-MVP) |
| `boat_tune` | Boat Engine Tune | 80 | Boat 50% faster |

### Sell Prices (Sell Shop)

Reward correct verbs; make wrong-verb catches near-worthless. Tension: kid wants money, kid catches a Kindness fish, do they sell it (small money) or aquarium it (no money but completion)?

| Fish handling result | Pearls per fish |
|----------------------|-----------------|
| Kindness Common, correct verb | 5 |
| Kindness Rare, correct verb | 25 |
| Kindness Epic, correct verb | 100 |
| Kindness Legendary, correct verb | 500 |
| Scam/Rumor/ModImposter, correct verb (refused) | 0 — you didn't catch anything to sell |
| ANY fish, wrong verb | 1 (junk fish — symbolic; tells player "this wasn't valuable") |

### XP Rewards (separate from Pearls)

XP doesn't buy anything in MVP — it's just a progress counter for the demo's "feels like progression" beat. Keep XP grants small (5–50 per catch) so the bar visibly fills during a 90-sec demo.

---

## Boat Physics Spec (hovercraft, simple)

The map's water has CanCollide off, so the boat won't naturally float. Implement hover via constraints:

- **VectorForce** on Hull pointing +Y, magnitude `Hull.AssemblyMass * workspace.Gravity` plus a small bouyancy nudge (10%); applied in world space; `RelativeTo = "World"`
- **AlignOrientation** on Hull, target orientation = `CFrame.Angles(0, currentHeading, 0)` — keeps boat upright; updates from driver input
- **LinearVelocity** for forward thrust based on driver's WASD throttle (clamp ~30 studs/sec base, 45 with `boat_tune`)
- Server is authoritative on the Hull's CFrame. Driver client sends throttle/steer via `RequestBoatThrottle`; server applies forces.
- Clamp position to within the water grid bounds (`workspace.PhishMap.PhishWater` BoundingBox) — bounce off invisible walls if player tries to drive off the map
- Passengers `:Sit()` into Seats; the Welds Roblox creates handle them riding along

---

## Shared Contract (User 1 builds the world; you read it)

**This is the only sync point with User 1.** Read tags via `CollectionService:GetTagged(...)`. Read attributes via `:GetAttribute(...)`. Reference named anchors by exact path.

### Tags You Will Read

| Tag | Where User 1 puts it | Required attributes |
|-----|----------------------|---------------------|
| `PhishLodgeSpawn` | SpawnLocation Part | — |
| `PhishCastZone` | Dock Parts | — |
| `PhishWaterZone` | Each 16×16 water tile | `Difficulty` (string), `MinRodTier` (number) |
| `PhishFishTemplate` | Each fish Model in `ServerStorage.PhishFishTemplates` | `FishId` (string) |
| `PhishAquariumDisplay` | Aquarium volume in Lodge | — |
| `PhishShopTrigger` | Shop proximity volume | `ShopType` ("Powerup" or "Sell") |
| `PhishBoatHull` | Boat PrimaryPart | — |
| `PhishBoatSeat` | Each boat seat | `IsDriver` (boolean) |

### Named Paths You Can Reference

| Path | What |
|------|------|
| `workspace.PhishMap.PhishLodge.AquariumOrigin` | Aquarium fish spawn anchor |
| `workspace.PhishMap.PhishDock.CastAnchor` | Cast lure spawn anchor |
| `workspace.PhishMap.PhishBoat` | Boat Model parent (PrimaryPart is `Hull`) |
| `ServerStorage.PhishFishTemplates` | All fish models |
| `ServerStorage.PhishBobbers` | All bobber visual variants |
| `ServerStorage.PhishLures` | Lure visuals |

**Resolution order on game start:**
1. `task.wait()` for one frame, then check `CollectionService:GetTagged("PhishLodgeSpawn")` returns ≥ 1 instance
2. If empty after 5 sec, log a warning ("User 1's map not loaded yet?") and gracefully wait
3. Never assume an instance exists by path without checking — User 1 may not have built it yet

If a tag/attribute name needs to change: **Discord User 1 first.** Don't change it unilaterally and don't just rename their tag — they'll have placed dozens of instances with it.

---

## File Ownership Rules (no merge conflicts)

| Path | You? | User 1? |
|------|------|---------|
| `src/**/*.lua` | ✅ own | ❌ never edit |
| `default.project.json`, `selene.toml`, `aftman.toml` | ✅ own | ❌ |
| `init.meta.json` files in `src/` | ✅ own (preserve all existing; add for new subfolders) | ❌ never delete |
| Roblox place file (Studio assets) | ❌ don't edit Studio | ✅ owns |
| `human_todo.md` | ❌ | ✅ owns (Studio tasks) |
| `tasks/user2_code.md` (your task list — create if missing) | ✅ owns | ❌ |
| `tasks/user1_map.md` | ❌ | ✅ owns |
| `tasks/todo.md` (top-level pointer) | read-only | read-only |
| `tasks/lessons.md` | append-only at end (coordinate via Discord) | append-only at end |
| `CLAUDE.md`, `docs/PHISH_*.md`, `docs/GAMEDESIGN.md` | ❌ locked — ping team if wrong | ❌ locked |
| `prompts/user2_scripting_prompt.md` (this file) | ❌ | ❌ |

**When in doubt: don't touch what User 1 owns. Discord them.**

---

## Workflow

1. **Plan first.** Enter plan mode for any non-trivial block. Write your plan to `tasks/user2_code.md` with checkable items. For each P2 system, sketch the remote payloads + server state transitions before writing code.
2. **Server authority always.** Never trust a client value for: catch identity, verb correctness, XP grants, Pearls grants, journal unlocks, aquarium contents, current rod tier, water-tile difficulty.
3. **One service, one responsibility.** Don't put boat physics in `BiteService`. Don't let `EconomyService` decide which fish bit. Keep the seams clean.
4. **Files under 500 lines.** Hard rule. Split if you approach. The two existing files near the limit (`BookView.lua` 472, `BeltController.lua` 466) must not get fatter when you repurpose patterns from them — build new modules instead.
5. **Rojo + Selene clean before every commit.**
   ```bash
   rojo build default.project.json -o build.rbxl
   selene src/
   ```
6. **`init.meta.json` rule.** Every `src/` subfolder mapped by Rojo must contain `{"ignoreUnknownInstances": true}` so Studio-built content (User 1's map) doesn't get wiped on sync. Never delete an existing one. Add one to any new mapped subfolder you create.
7. **Smoke test after each P2 block.** A real solo Studio play session — even an ugly one — beats reasoning about correctness. Cast → bite → cut line → resolve. Then add Verify. Then add Reel. Then add Shop. Then Boat.
8. **Discord-coordinate** when:
   - You finish a service that depends on a new tag (so User 1 knows to apply it)
   - You hit a missing instance (`PhishWaterZone` tags return empty) — ping User 1
   - You want to change a tag name or add an attribute (User 1 must agree)
   - You finish P2 (so User 1 can do final integration testing with you)
9. **Lessons.** Append to `tasks/lessons.md` at the END of the file. Don't edit User 1's lesson entries. Things worth recording: Rojo gotchas, remote validation patterns, hovercraft tuning numbers, sonar drop rates that felt right.

---

## Acceptance Criteria

You're done with MVP when, in a solo Studio play test:

- [ ] `rojo build` succeeds; `selene src/` is clean; no file exceeds 500 lines
- [ ] All P1 archive moves committed; no Stranger Danger code in active load path
- [ ] Player spawns at `PhishLodgeSpawn`, sees aquarium with at least one Compliment Carp
- [ ] Walks to dock cast zone, presses cast → lure spawns at `CastAnchor`
- [ ] Bobber appears within 6 sec, decision window opens, 4 verb buttons render
- [ ] Cut Line → resolves, no penalty, no inventory entry
- [ ] Verify → Field Guide opens (using BookView pattern), shows fish entry, then resumes decision window
- [ ] Reel on a Kindness fish → mini-game succeeds → outcome panel → "Place in aquarium?" prompt → fish appears in aquarium
- [ ] Reel on a Scam fish → outcome panel with friendly buzzer + lesson line; junk fish in inventory worth 1 Pearl
- [ ] Walks to sell-shop, opens UI, sells the junk fish, sees Pearls counter increment
- [ ] Walks to fisherman shop, opens UI, buys Iron Rod (50 Pearls), rod tier ticks 1→2
- [ ] Tries to cast at an Intermediate water tile with Tier 1 rod → blocked with friendly message; with Tier 2 rod → succeeds
- [ ] Sits in boat driver seat → WASD moves boat → boat hovers over water tiles, can't leave grid bounds
- [ ] Casts from boat → cast spawns from Hull, not dock CastAnchor
- [ ] Journal opens (some HUD button), lists caught fish, click opens that fish's Field Guide page

When all of these pass: commit and push, post in Discord "User 2 code MVP done", and sweep `tasks/lessons.md`.

---

## Out of Scope (do not build)

- Roblox Studio map content (User 1)
- Multiple maps / ponds / locations
- Buddy Mode coordinator UI (post-MVP)
- DataStore persistence (post-MVP — session-only is fine for demo)
- Trading between players
- Voice chat / chat moderation
- Cosmetics shop (rod skins) — only the 4 functional rod tiers in MVP
- Boss fish encounter
- Daily quests / leaderboards
- Anti-exploit beyond basic server validation
