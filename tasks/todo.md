# TODO

## Current Priority

Build a polished MVP of Buddy Bridge with **2 levels**: Stranger Danger Park and Backpack Checkpoint.

## Setup

- [ ] `aftman install` — verify Rojo 7.7.0-rc4 + Selene 0.27.1
- [ ] `rojo serve` connects to Studio
- [ ] Confirm `init.meta.json` exists in every `src/` subfolder
- [ ] Create base service skeletons

## Core Modules

- [ ] `RemoteService.lua`
- [ ] `Modules/Constants.lua`
- [ ] `Modules/RoleTypes.lua`
- [ ] `Modules/LevelTypes.lua`
- [ ] `Modules/PlayAreaConfig.lua`
- [ ] `Modules/ScenarioRegistry.lua`
- [ ] `Modules/NpcRegistry.lua` — NPC trait pool for Stranger Danger
- [ ] `Modules/ItemRegistry.lua` — item pool + lane mapping for Backpack Checkpoint
- [ ] `Modules/ScoringConfig.lua`
- [ ] `Modules/UIStyle.lua`

## Bootstrap

- [ ] `ServerBootstrap.server.lua` requires all server services
- [ ] `ClientBootstrap.client.lua` requires all client controllers

## Lobby + Pairing

- [ ] `LobbyService.lua` — capsule pad detection, invite flow
- [ ] `MatchService.lua` — pair create/get/remove
- [ ] `RoleService.lua` — role assignment
- [ ] `LobbyPairController.client.lua` — confirm pair UI + invite UI
- [ ] `RoleSelectController.client.lua` — pick Explorer / Guide
- [ ] Test: 2 players can pair via capsule and via proximity prompt

## Round + Slot Management

- [ ] `PlayAreaService.lua` — slot pool, clone level templates, clone booth, teleport players, lock booth
- [ ] `RoundService.lua` — start/end round, level sequence, timer
- [ ] `LevelService.lua` — start/complete/cleanup the active level
- [ ] Test: paired duo gets teleported to a slot; Explorer in level, Guide in booth

## Stranger Danger Park

- [ ] `ScenarioService.lua` — generate randomized NPC scenario
- [ ] Wire up `LevelService` to attach scenario to cloned NPCs at level start
- [ ] `ExplorerInteractionService.lua` — `RequestInspectNpc`, `RequestTalkToNpc`
- [ ] `GuideControlService.lua` — `RequestAnnotateNpc`
- [ ] `ExplorerController.client.lua` — handle proximity-based NPC inspect
- [ ] `NpcDescriptionCardController.client.lua` — show trait card to Explorer
- [ ] `GuideManualController.client.lua` — render trait/risk manual on booth SurfaceGui
- [ ] `GuideAnnotationController.client.lua` — annotation buttons
- [ ] Visual: colored ring around NPC when Guide annotates
- [ ] Quest: 3 clues → puppy spawn → level exit
- [ ] Test: full level playthrough with 2 players

## Backpack Checkpoint

- [ ] Generate randomized item rotation server-side
- [ ] Conveyor logic — spawn item, advance after sort
- [ ] `ExplorerInteractionService` — `RequestPickupItem`, `RequestPlaceItemInLane`
- [ ] `GuideControlService` — `RequestAnnotateItem`
- [ ] Bin SFX / VFX on correct vs. wrong sort
- [ ] Manual UI shows the chart (Pack It / Ask First / Leave It rules)
- [ ] N items per round → level complete
- [ ] Test: full level playthrough with 2 players

## Round Transition + Scoring

- [ ] Portal between Stranger Danger and Backpack Checkpoint inside the slot
- [ ] `ScoringService.lua` — track time, mistakes, trust points
- [ ] `RewardService.lua` — grant Trust Seeds (session-only data is fine)
- [ ] `ScoreScreenController.client.lua` — final score UI + replay
- [ ] `RoundHudController.client.lua` — timer + objective + mistakes
- [ ] Return-to-lobby flow

## Lobby Progression

- [ ] `DataService.lua` — session-only data
- [ ] `LobbyProgressionController.client.lua` — visualize Trust Seeds / treehouse level

## Polish

- [ ] SFX hookups (button press, wrong sort, level complete, round complete)
- [ ] Cartoon font + friendly UI styling pass
- [ ] Short tutorial prompts on first run
- [ ] Replay flow tested end-to-end
- [ ] Demo route timed under 5 minutes

## Verification

- [ ] `selene src/` passes
- [ ] All files in `src/` under 500 lines
- [ ] All remotes validate input + role
- [ ] No client-side authoritative gameplay state
- [ ] Tested with 2 players in Studio local server
- [ ] Tested 4 simultaneous duos do not cross-talk
- [ ] `tasks/todo.md` updated
- [ ] `tasks/lessons.md` updated if any pattern was corrected
