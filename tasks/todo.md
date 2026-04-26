# PHISH! — TODO

Pivoted from Buddy Bridge on 2026-04-25. Old Buddy Bridge checklist is in `docs/archive/` (via the old PRDs).

## P0 — Pivot housekeeping (this task)

- [x] Tag `pre-phish-pivot` on git
- [x] Move 12 Buddy Bridge docs to `docs/archive/` + write archive README
- [x] Rewrite `CLAUDE.md` for PHISH!
- [x] Write `docs/GAMEDESIGN.md`
- [x] Write `docs/PHISH_CORE_LOOP.md`
- [x] Write `docs/PHISH_CONTENT.md`
- [x] Write `docs/PHISH_MVP_PLAN.md`
- [x] Replace `tasks/todo.md` (this file)
- [x] Replace `human_todo.md`
- [ ] Verify `rojo build` and `selene src/` still pass

## P1 — Code archive pass (DONE)

Buddy Bridge runtime stripped from `src/`. Pre-pivot state preserved at git tag `pre-phish-pivot`.

- [x] Removed Stranger Danger / Backpack Checkpoint runtime modules
- [x] Removed legacy lobby / role / pair / round services
- [x] Disconnected Buddy Bridge registrations in `ServerBootstrap.server.lua`
- [x] `rojo build default.project.json -o build.rbxl` passes
- [x] `selene src/` clean

## P2 — PHISH! core systems (DONE)

### Data + Registry
- [x] `ReplicatedStorage/Modules/FishRegistry.lua` — 12 MVP fish authored
- [x] `ReplicatedStorage/Modules/FishCategoryTypes.lua`
- [x] `ReplicatedStorage/Modules/ReelActionTypes.lua`
- [x] `ReplicatedStorage/Modules/RodRegistry.lua` (3 tiers: Wooden/Bamboo/Reinforced)
- [x] `ReplicatedStorage/Modules/ZoneTiers.lua`
- [x] `ReplicatedStorage/Modules/ShopCatalog.lua`
- [x] `ReplicatedStorage/Shared/PondState.lua`
- [x] `ReplicatedStorage/Shared/FishEncounterTypes.lua`

### Server services
- [x] `PondService` — zone resolution by tagged `PhishCastZone` parts
- [x] `CastingService` — `RequestCast` + per-player encounter registry + underpowered nudge
- [x] `BiteService` — weighted-random fish pick, anti-clumping, decision-window timeout
- [x] `CatchResolutionService` — Verify/Reel/CutLine/Report/Release + reel mini-game
- [x] `FieldGuideService` — entry unlocks
- [x] `JournalService`
- [x] `AquariumService` — global aquarium display via BillboardGui
- [x] `RewardService` — pearls + XP from rarity × zone-tier
- [x] `ShopService` — rod purchase + equip
- [x] `SellService` — sell one + sell all
- [x] `RowboatService` — XZ-plane hovercraft physics
- [x] Extended `DataService` — pearls / rods / fish inventory / journal / aquarium
- [x] Remotes added to `RemoteService.lua` (see ENGINEERING_HANDOFF_USER2.md)

### Client controllers
- [x] `AnglerController` — F-to-cast charge + zone HUD
- [x] `BiteHudController` — cue + 5 decision buttons
- [x] `ReelMinigameController` — tap-3-times mini-game
- [x] `FieldGuideController` — entry overlay (B to toggle)
- [x] `JournalController` — fish list (J to toggle)
- [x] `AquariumViewController` — handled in CatchOutcomeController prompt
- [x] `CatchOutcomeController` — post-catch panel + aquarium prompt
- [x] `ShopController` — E near `PhishShopPrompt`
- [x] `SellController` — E near `PhishSellPrompt`
- [x] `RowboatController` — E to drive, WASD/arrows, Shift to exit
- [x] `HudController` — pearls / xp / equipped rod top bar
- [x] `NotificationController` (kept; toast renderer)

### Verification
- [x] `selene src/` clean (0 errors / 0 warnings)
- [x] `rojo build default.project.json -o build.rbxl` passes
- [x] All `src/*.lua` under 500 lines (largest: FishRegistry.lua at 228)
- [x] Server-side validation on every remote (RequirePlayer + per-key rate limit)
- [x] Startup tag-count diagnostics in `[PHISH!] Map diagnostics:` block
- [ ] In-Studio playtest with User 1's tagged map (HUMAN — see "Smoke test recipe" in ENGINEERING_HANDOFF_USER2.md)

## P3 — Content + polish

- [ ] Final lesson-line copy edit on all 12 fish (read aloud as if to a 9-year-old)
- [ ] SFX: cast, splash, bite (4 category variants), reel, success, sad-trombone
- [ ] Water shader or ripple decals
- [ ] Fish swim animations in aquarium
- [ ] Cartoon-font Field Guide pages
- [ ] Tutorial nudge on first cast
- [ ] Pre-populated demo profile (aquarium has 1 fish on first load)
- [ ] Demo script (90 sec, written and rehearsed)
- [ ] `tasks/lessons.md` sweep — port any Buddy Bridge rules still applicable; archive the rest

## P4 — Stretch (only if MVP locks early)

- [ ] 6 stretch fish from `docs/PHISH_CONTENT.md`
- [ ] Boss Phisher encounter
- [ ] Buddy Mode (reuse Buddy Bridge plumbing — second player coaches via Field Guide)
- [ ] DataStore persistence
- [ ] Cosmetics (rod skins, lure colors)
- [ ] Foggy Cove time-of-day variant

## Notes for Future Agents

- Read `CLAUDE.md` first.
- Check `docs/PHISH_MVP_PLAN.md` before adding any feature — if it's not on the checklist, it's cut.
- Engineering rules (server authority, no file >500 lines, `init.meta.json` per `src/` folder, `Enum.Font.Cartoon`, RemoteService discipline) are from `CLAUDE.md` and non-negotiable.
- The Buddy Bridge Lua under `src/` is **legacy** until P1 archives it. Don't extend it. Read it for patterns to reuse.
- The git tag `pre-phish-pivot` recovers full Buddy Bridge state if needed.
