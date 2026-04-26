# TODO

## Current Priority

Build a polished MVP of Buddy Bridge with **2 levels**: Stranger Danger Park and Backpack Checkpoint.

## Setup

- [ ] `aftman install` — verify Rojo 7.7.0-rc4 + Selene 0.27.1 (HUMAN — not yet installed locally)
- [ ] `rojo serve` connects to Studio (HUMAN)
- [x] Confirm `init.meta.json` exists in every `src/` subfolder
- [x] Create base service skeletons

## Core Modules

- [x] `RemoteService.lua`
- [x] `Modules/Constants.lua`
- [x] `Modules/RoleTypes.lua`
- [x] `Modules/LevelTypes.lua`
- [x] `Modules/PlayAreaConfig.lua`
- [x] `Modules/ScenarioRegistry.lua`
- [x] `Modules/NpcRegistry.lua` — NPC trait pool for Stranger Danger
- [x] `Modules/ItemRegistry.lua` — item pool + lane mapping for Backpack Checkpoint
- [x] `Modules/ScoringConfig.lua`
- [x] `Modules/UIStyle.lua`
- [x] `Modules/RateLimiter.lua` (helper)
- [x] `Modules/TagQueries.lua` (helper)
- [x] `Modules/NumberFormatter.lua` (helper)
- [x] `Shared/RoundState.lua`
- [x] `Shared/ScenarioTypes.lua`

## Bootstrap

- [x] `ServerBootstrap.server.lua` requires all server services
- [x] `ClientBootstrap.client.lua` initializes ScreenGui and pulls progression

## Lobby + Pairing

- [x] `LobbyService.lua` — capsule pad detection, invite flow, PlayerRemoving cleanup
- [x] `MatchService.lua` — pair create/get/remove with OnPairCreated callback
- [x] `RoleService.lua` — role assignment with auto-assign timeout
- [x] `LobbyPairController.client.lua` — confirm pair UI + invite UI + Invite-to-Play prompt
- [x] `RoleSelectController.client.lua` — pick Explorer / Guide
- [ ] Test: 2 players can pair via capsule and via proximity prompt (HUMAN — needs Studio)

## Round + Slot Management

- [x] `PlayAreaService.lua` — slot pool, clone level templates, clone booth, teleport players, lock booth (invisible wall + heartbeat-based bounding box check), respawn re-teleport
- [x] `RoundService.lua` — start/end round, level sequence, timer, PlayerRemoving handling
- [x] `LevelService.lua` — start/complete/cleanup the active level
- [x] `Helpers/RoundContext.lua` — player→round registry
- [x] `Helpers/RemoteValidation.lua` — canonical validation chain
- [x] `Helpers/SignalTracker.lua` — connection tracking against round lifetime
- [ ] Test: paired duo gets teleported to a slot; Explorer in level, Guide in booth (HUMAN — needs Studio)

## Stranger Danger Park

- [x] `Scenarios/StrangerDangerScenario.lua` — generate exactly 3 Risky NPCs with unique `(Color, Shape)` badges
- [x] `Levels/StrangerDangerLevel.lua` — clone NPCs, attach badge SurfaceGuis, wire booth slots and submit pad
- [x] `ExplorerInteractionService.lua` — `RequestInspectNpc` opens server-owned dialog; `RequestNpcDialogChoice` records notes
- [x] `GuideControlService.lua` — `RequestSetSlotBadge` + `RequestSubmitAccusation` validators
- [x] `ExplorerController.client.lua` — handle proximity-based NPC talk prompt
- [x] `NpcDescriptionCardController.client.lua` — dialog-style NPC interaction instead of flat inspect card
- [x] `GuideNotesController.client.lua` — compact Explorer Notes panel for badge + cue lines
- [x] `GuideManualController.client.lua` — render trait/risk manual and highlight note cues
- [x] `GuideBoothController.client.lua` — slot picker UI + per-slot display from `BoothStateUpdated`
- [x] Visual: NPC badge SurfaceGui + booth slot/attempt SurfaceGuis
- [x] Submit loop: green slots lock, red slots stay editable, 3 failed submits ends round
- [ ] Test: full level playthrough with 2 players (HUMAN — needs Studio)

## Backpack Checkpoint

- [x] Generate randomized item rotation server-side (`Scenarios/BackpackCheckpointScenario.lua`)
- [x] Conveyor logic in `Levels/BackpackCheckpointLevel.lua` — spawn item, advance after sort
- [x] `ExplorerInteractionService` — `RequestPickupItem`, `RequestPlaceItemInLane`
- [x] `ScannerService` / Guide scanner HUD — `RequestScanItem`, `RequestHighlightItem`, `RequestUnlockLane`
- [x] Bin SFX / VFX hookups (placeholder; SFX files come from User 1 + M8 polish pass)
- [x] Manual UI shows the chart (Pack It / Ask First / Leave It rules)
- [x] N items per round → level complete
- [ ] Test: full level playthrough with 2 players (HUMAN — needs Studio)

## Round Transition + Scoring

- [x] BuddyPortal between levels (handled implicitly: completion of Stranger Danger triggers Backpack Checkpoint via LevelService)
- [x] `ScoringService.lua` — track time, mistakes, trust points
- [x] `RewardService.lua` — grant Trust Seeds (session-only via DataService)
- [x] `ScoreScreenController.client.lua` — final score UI + replay
- [x] `RoundHudController.client.lua` — timer + objective + mistakes
- [x] Return-to-lobby flow

## Lobby Progression

- [x] `DataService.lua` — session-only data
- [x] `LobbyProgressionController.client.lua` — visualize Trust Seeds / treehouse level

## Polish

- [ ] SFX hookups (button press, wrong sort, level complete, round complete) — wired via `ExplorerFeedback` + `ItemSortResult` events; needs SFX files in SoundService (User 1)
- [x] Cartoon font + friendly UI styling (UIStyle module + UIBuilder)
- [ ] Short tutorial prompts on first run (gated by DataService.HasSeenTutorial — DEFERRED)
- [ ] Replay flow tested end-to-end (HUMAN — needs Studio)
- [ ] Demo route timed under 5 minutes (HUMAN)

## Verification

- [x] `rojo build default.project.json -o build.rbxl` passes
- [x] `selene src/` passes
- [x] All files in `src/` under 500 lines (max: 472, BookView.lua, untouched)
- [x] All remotes validate input + role (canonical chain in Helpers/RemoteValidation)
- [x] No client-side authoritative gameplay state
- [x] Retired Stranger Danger/annotation remotes removed from runtime `src/`
- [ ] Tested with 2 players in Studio local server (HUMAN)
- [ ] Tested 4 simultaneous duos do not cross-talk (HUMAN — dialog notes and booth state live on the round; all FireClient is scoped via FirePair)
- [x] `tasks/todo.md` updated
- [x] `tasks/lessons.md` updated

## Backpack Checkpoint V1 — P0 / P1 (shipped)

Per `docs/BACKPACK_CHECKPOINT_DECISION.md` + V1 PRD + edge-case addendum.

### P0 (waves, belt, basic Guide tools)

- [x] 3 waves of 6 / 8 / 10 items, tier-gated (Tier 3 only in Wave 3).
- [x] BeltController split into `Levels/BackpackCheckpoint/{BeltController, WaveDirector}.lua`.
- [x] Bounce-back on wrong sort (–25% belt length, lanes re-arm).
- [x] Fall-off timer → `AddMistake("Fallthrough")` + combo break.
- [x] Per-item lane locks. Locked-lane sort attempts rejected with soft buzzer.
- [x] ScannerService remotes: `RequestScanItem` (per-wave cap, cooldown, cached), `RequestHighlightItem` (last-write-wins), `RequestUnlockLane` (mutually exclusive).
- [x] Annotation system removed from BPC: scanner/highlight/unlock remotes own the flow.
- [x] Pixel Post intro slide (non-gating P0 — fades after 5s).

### P1 (combo, Veto, Mini-Boss, Scanner Guide HUD)

- [x] Combo multipliers in `ScoringConfig` — 3 → ×1.5, 5 → ×2.0; multiplier applies only to per-sort base trust points; level/perfect bonuses unaffected.
- [x] `ScoringService.AddTrustPoints(round, amount, reason, multiplier)` accepts an optional multiplier; `ScoringService.ReduceStreak(round, divisor)` for Veto cost.
- [x] Veto: `RequestVeto` remote, one charge per round, 3s belt freeze (re-locks all lanes, pauses fall-off timer), halves combo; allowed during Mini-Boss; HUD reflects used/active state.
- [x] Mini-Boss `MiniBossDirector.lua`: triggered after Wave 3 drains, 3 inner items sequential, belt halted, all 3 inner labels+tags revealed at start, fail-on-high-combo (≥5) → `EndRound("MiniBossFail")`, below threshold → AddMistake + bag continues, success → `MiniBossSuccessBonus`.
- [x] `ScannerGuideHud.client.lua`: X-ray feed (label + scan tags), Highlight (G/Y/R), Lane Unlock (Pack/Ask/Leave), Scan w/ counter, Veto button. Reflects wave + Mini-Boss state.
- [x] All round-scoped state on `round.LevelState[BackpackCheckpoint]`; no module-level mutable BPC state.

### P1 manual smoke test (HUMAN — 2-player Studio)

- [ ] Wave 1 happy path: Pixel Post intro plays both screens; first item spawns; Guide scans/highlights/unlocks; Explorer sorts; combo bar ticks.
- [ ] Wrong sort with Streak <3: combo resets, item bounces back to belt –25%, mistake counter increments.
- [ ] Reach Streak ≥3: next correct sort awards ×1.5 trust points (Notify shows Multiplier=1.5).
- [ ] Reach Streak ≥5: next correct sort awards ×2.0.
- [ ] Veto: press Veto button mid-item; lanes re-lock; 3s freeze countdown; combo halves; button disables for rest of round.
- [ ] Mini-Boss: complete all 3 waves; bag arrives; sort all 3 inner items correctly → success bonus + level complete.
- [ ] Mini-Boss fail: build Streak ≥5, then deliberately wrong-sort an inner item → round ends with `MiniBossFail`, kid-friendly toast appears, score screen still renders.
- [ ] Mini-Boss below threshold: with Streak <5, wrong-sort an inner item → AddMistake, bag continues with next inner.
- [ ] **SD regression smoke**: play one Stranger Danger round; verify Explorer dialog notes populate for Guide and booth slot submission works.
- [ ] PartnerLeft cleanup: have one player close their client mid-wave or mid-Mini-Boss; verify the round ends cleanly, no orphaned models, slot is released.

### P2 (shipped)

- [x] Gated Pixel Post intro: server tracks `IntroDismissedBy`; Wave 1 spawn waits until both dismiss OR `BACKPACK_INTRO_GATE_TIMEOUT_SECONDS` (30s). Continue button surfaces after 3s on the slide.
- [x] Field Manual session meta: `DataService.EncounteredItems` per player. `BeltController.SpawnItem` calls `MarkItemEncountered`; `BackpackCheckpointLevel.Begin` pushes the union via `FieldManualUpdated`. `BackpackCheckpointManual` adds `MarkSeen` / `MarkAllSeen`; `GuideManualController` listens.
- [x] Rehydrate on Guide respawn: `GuideRehydrate.lua` re-fires `WaveStarted` / `ConveyorItemSpawned` / `ScannerOverlayUpdated` / `LaneLockUpdated` / `HighlightUpdated` / `VetoActivated+Ended` / `MiniBoss*` / `FieldManualUpdated` to the one client.
- [x] Drop-not-bin recovery: Explorer Humanoid.Died handler clears `HeldByPlayer`. The fall-off timer is unchanged so a benign drop still risks a fall-off mistake (P2 polish to skip the fall-off on death is deferred).
- [x] Tutorial gating: `DataService.HasSeenTutorial` is sub-tabled by key (`BackpackCheckpointGuide` / `BackpackCheckpointExplorer`). Server fires `TutorialPrompt` on first BPC level start per role per session. Client overlay in `TutorialPromptController.client.lua` auto-fades after 8s.

See `docs/BACKPACK_CHECKPOINT_P1P2.md` for the full Studio test checklist and out-of-scope list.
