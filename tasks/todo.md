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

## P1 — Code archive pass (next task)

The `src/` Lua tree still reflects Buddy Bridge. Moving Stranger-Danger-only files out keeps the build clean for new agents.

- [ ] Create `src/archive/` outside the Rojo mapping (or with `init.meta.json` if mapped)
- [ ] Move Stranger-Danger-only files to `src/archive/StrangerDanger/`:
  - `ReplicatedStorage/Modules/StrangerDangerLogic.lua`
  - `ReplicatedStorage/Modules/NpcRegistry.lua`
  - `ServerScriptService/Services/Levels/StrangerDangerLevel.lua`
  - `ServerScriptService/Services/Scenarios/StrangerDangerScenario.lua`
  - `StarterPlayerScripts/Explorer/NpcDescriptionCardController.client.lua`
  - `StarterPlayerScripts/Explorer/StrangerDangerFxController.client.lua`
  - `StarterPlayerScripts/Guide/GuideAnnotationController.client.lua`
  - `StarterPlayerScripts/Guide/Manuals/StrangerDangerManual.lua`
  - `StarterPlayerScripts/Guide/Manuals/StrangerDangerBookContent.lua`
- [ ] **Keep Backpack Checkpoint code** for reference until P2 — patterns (BeltController, BookView, ScannerService, manuals) will be repurposed
- [ ] Disconnect Stranger Danger registrations in `ServerBootstrap.server.lua`
- [ ] Verify `rojo build` and `selene src/` still pass

## P2 — PHISH! core systems

Build in dependency order. Smoke-test after each block.

### Data + Registry
- [ ] `ReplicatedStorage/Modules/FishRegistry.lua` — author the 12 MVP fish per `docs/PHISH_CONTENT.md`
- [ ] `ReplicatedStorage/Modules/FishCategoryTypes.lua` — enum constants
- [ ] `ReplicatedStorage/Modules/ReelActionTypes.lua` — verb constants
- [ ] `ReplicatedStorage/Shared/PondState.lua` — server-side state machine
- [ ] `ReplicatedStorage/Shared/FishEncounterTypes.lua`

### Server services
- [ ] `PondService` — pond active state, spawn weights, time-of-day
- [ ] `CastingService` — `RequestCast` handling, lure state
- [ ] `BiteService` — picks fish weighted-random, schedules `BiteOccurred`
- [ ] `CatchResolutionService` — validates verb, grants XP/journal
- [ ] `FieldGuideService` — entry unlocks
- [ ] `JournalService`
- [ ] `AquariumService`
- [ ] Extend `ScoringService`, `RewardService`, `DataService`
- [ ] Add new remotes to `RemoteService.lua`

### Client controllers
- [ ] `AnglerController.client.lua` — rod input, cast charge, decision window
- [ ] `CastingController.client.lua` — lure visuals
- [ ] `ReelMinigameController.client.lua` — repurpose `BeltController` timing pattern
- [ ] `FieldGuideController.client.lua` — reuses `BookView.lua`
- [ ] `JournalController.client.lua`
- [ ] `AquariumViewController.client.lua`
- [ ] Adapt `HudController`, `NotificationController` for angler context

### Smoke tests
- [ ] One pond, one fish, full round-trip: Cast → Bite → CutLine → Resolve
- [ ] Verify flow opens Field Guide and resumes correctly
- [ ] Reel mini-game succeeds and grants XP
- [ ] Journal updates on each new fish
- [ ] Aquarium displays placed fish

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
