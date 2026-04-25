# User 2 — Scripting Prompt (Rojo + Claude Code)

> Paste this prompt into your Claude Code session. You are the **Scripting User**. You write all Lua via Rojo. You do **not** open Roblox Studio to build geometry — that is User 1's job.

---

## Prompt

You are working on **Buddy Bridge: A Two Player Trust Game**, a 2-player asymmetric co-op safety game for the LAHacks Roblox Civility Challenge. The team is targeting Roblox's **"Learn and Explore"** sort.

Before doing anything, read these files in this order and treat them as authoritative:

1. `CLAUDE.md`
2. `docs/PRD.md`
3. `docs/GAME_DESIGN.md`
4. `docs/TECHNICAL_DESIGN.md`
5. `docs/MVP_SCOPE.md`
6. `docs/JUDGING_STRATEGY.md`
7. `tasks/todo.md`
8. `tasks/lessons.md`
9. `human_todo.md`
10. `prompts/user1_map_prompt.md` (so you know exactly what tags / attributes / model names to expect from the map)

Then read this prompt to understand your scope.

### Your Role

You are the **Scripting User**. Your scope:

- Implement every Lua module under `src/` to make Buddy Bridge playable end-to-end.
- Define and create all `RemoteEvent` / `RemoteFunction` instances at runtime via `RemoteService.lua`.
- Wire client controllers to UI built in code.
- Handle all server logic: pairing, role assignment, round orchestration, level scenarios, scoring, rewards.
- Keep every file under 500 lines.
- Maintain server authority — never trust the client for gameplay truth.

You do **NOT**:
- Open Roblox Studio to build or edit geometry, lobby pads, play arena slots, level templates, NPC templates, item templates, or the booth template. User 1 builds those.
- Add scripts directly inside Studio — everything goes through Rojo from `src/`.
- Modify CollectionService tags or Instance attributes that User 1 set on the map. If you need a new tag or attribute, update `docs/TECHNICAL_DESIGN.md` and `human_todo.md` and tell User 1.

### Toolchain

- Project file: `default.project.json`
- Aftman: `aftman.toml` provides Rojo `7.7.0-rc4` and Selene `0.27.1`. Run `aftman install` if not already done.
- Rojo serve: `rojo serve default.project.json`
- Lint: `selene src/`
- Build for Studio: `rojo build default.project.json -o build.rbxl`

### Critical Rojo Convention

Every folder under `src/` already contains an `init.meta.json` with `{ "ignoreUnknownInstances": true }`. **Do not delete these.** They prevent Rojo from wiping Studio-built map content on sync. If you create a new subfolder under `src/`, create the same `init.meta.json` inside it.

### Game Design Recap

Two polished levels:

1. **Stranger Danger Park** — 6–8 NPCs in a park with randomized roles (safe-with-clue / safe-no-clue / risky) and randomized traits. Explorer inspects → traits revealed → Guide checks manual → Explorer talks. Goal: collect 3 clues to find a lost puppy.
2. **Backpack Checkpoint** — TSA-style sorting. Items come down a conveyor; Explorer drops them in Pack It / Ask First / Leave It bins based on the Guide's chart.

Players: 8/server, duos of 2, up to 4 simultaneous duos. Each duo plays in its own instanced slot. The round plays both levels back-to-back inside one slot, linked by a `BuddyPortal`.

### Architecture Recap (read the docs for details)

- **Server-authoritative.** Server owns roles, round state, scoring, NPC role assignments, item correctness, rewards.
- **Lobby** is shared. Players pair via capsule pads (`LobbyCapsule` tag, `CapsuleId` + `CapsulePairId` attributes) OR via `ProximityPrompt` "invite to play" on other players.
- **Play arena slots** are pre-built in `Workspace/PlayArenaSlots` (4 slots, each tagged `PlayArenaSlot`).
- **Level templates** live in `ServerStorage/Levels`. Clone into a slot's `PlayArea` folder when a round starts.
- **NPC templates** live in `ServerStorage/NpcTemplates`. `ScenarioService` picks one per spawn point at level start, applies traits and role.
- **Item templates** live in `ServerStorage/ItemTemplates`. `ScenarioService` picks the rotation for Backpack Checkpoint.
- **Booth template** lives in `ServerStorage/GuideBooths/DefaultBooth`. Clone into a slot's `Booth` folder, align to `BoothAnchor`.
- **Guide is teleported into the booth** and cannot leave during the round.
- **Remotes** are all created in `RemoteService.lua` (single source of truth). See `docs/TECHNICAL_DESIGN.md` for the full list.

### Implementation Order

Work in this order. Update `tasks/todo.md` as you go.

#### Milestone 1: Skeleton

1. `RemoteService.lua` — creates and exposes all RemoteEvents / RemoteFunctions.
2. `Modules/Constants.lua`, `Modules/RoleTypes.lua`, `Modules/LevelTypes.lua`.
3. `Modules/PlayAreaConfig.lua`, `Modules/NpcRegistry.lua`, `Modules/ItemRegistry.lua`.
4. `ServerBootstrap.server.lua` — requires every server service in dependency order.
5. `ClientBootstrap.client.lua` — requires every client controller.

After this, `rojo serve` should succeed and the place should run with no errors.

#### Milestone 2: Lobby + Pairing

1. `LobbyService.lua` — capsule occupancy tracking via `LobbyCapsule`-tagged parts and `Touched` events. Pair-ready broadcast when both pads of a `CapsulePairId` are occupied. Invite flow via proximity prompt on other players.
2. `MatchService.lua` — `CreatePair`, `GetPair`, `RemovePair`.
3. Client: `LobbyPairController.client.lua` — listens for `CapsulePairReady` / `InviteReceived`, shows confirm UI, sends responses.
4. Test: 2 players in Studio can pair via capsule and via proximity prompt.

#### Milestone 3: Role + Round Start

1. `RoleService.lua` — `AssignRoles`, `GetRole`. Auto-assign on timeout.
2. `RoundService.lua` — `StartRound`, `EndRound`, timer, level sequence (`{"StrangerDangerPark", "BackpackCheckpoint"}`).
3. `PlayAreaService.lua` — slot reservation, clone level templates, clone booth, align via `BoothAnchor`, teleport players, lock booth (invisible wall + return-on-exit).
4. `LevelService.lua` — start / complete / cleanup the active level. Handle the `BuddyPortal` between levels.
5. Client: `RoleSelectController.client.lua`, `RoundHudController.client.lua`.
6. Test: paired duo can pick roles and get teleported to a slot. Explorer in level entry, Guide in booth, booth sealed.

#### Milestone 4: Stranger Danger Park (the headline level)

This is the most important level. Spend more time here than anywhere else.

1. `ScenarioService.lua` — `GenerateStrangerDangerScenario(slot)`:
    - Pick which 3 of 6–8 NPC spawn points get `SafeWithClue` role.
    - Pick 2 spawns for `SafeNoClue`, 2–3 for `Risky`.
    - For each NPC, draw 1–3 traits from the appropriate pool in `NpcRegistry` (risky NPCs draw from risky tags + maybe one neutral; safe NPCs draw from safe tags).
    - Pick a `PuppySpawn`. Distribute clue fragments such that the 3 safe-with-clue NPCs reveal hints leading to it.
    - Construct the `GuideManual` payload (full risky / safe trait reference list).
2. `LevelService` integrates the scenario:
    - For each `BuddyNpcSpawn` part, clone an NPC template into it (random visual).
    - Set the NPC's `BillboardGui.TraitCard` text via attribute (or via remote at inspect time — your call).
    - Add `ProximityPrompt` to each NPC for "Take a closer look" → fires `RequestInspectNpc`.
3. `ExplorerInteractionService.lua`:
    - `RequestInspectNpc` — validate proximity and active level. Send `NpcDescriptionShown` to Explorer (full trait list as visible to Explorer) and to Guide (with risk cross-reference).
    - `RequestTalkToNpc` — second prompt that appears after inspect. Apply outcome:
        - Safe with clue → fire `ClueCollected` + add trust points.
        - Safe no clue → friendly small talk notification, no penalty.
        - Risky → consequence (teleport Explorer to level entry / brief slowdown / play funny SFX), `ScoringService:AddMistake`.
4. `GuideControlService.lua`:
    - `RequestAnnotateNpc(npcId, marker)` — validate Guide role, broadcast `NpcAnnotationUpdated` to the duo so the Explorer's HUD can draw a colored ring around that NPC.
5. Client controllers:
    - `ExplorerController.client.lua` — proximity-prompt routing, talk confirmations.
    - `NpcDescriptionCardController.client.lua` — render the small trait card UI for the Explorer.
    - `GuideController.client.lua` — top-level routing on Guide side.
    - `GuideManualController.client.lua` — render the full manual on the booth's `ControlPanel` SurfaceGui. Highlight matching trait rows when the Guide sees a description.
    - `GuideAnnotationController.client.lua` — annotation buttons (✅/🚩/⚠️/Clear) targeting the most recently inspected NPC.
6. World feedback:
    - When the 3rd clue is collected, spawn a sparkle trail toward the puppy.
    - Activate `LevelExit` near the chosen `PuppySpawn`.
7. Test the full slice end-to-end with 2 players.

#### Milestone 5: Backpack Checkpoint

1. `ScenarioService:GenerateBackpackCheckpointScenario(slot)`:
    - Pick N items (default 6) from `ItemRegistry` with a balance across lanes.
    - Build the sequence and the `GuideManual` payload (full chart).
2. Conveyor logic in `LevelService` (or a small helper module):
    - Spawn item template at `BeltStart`.
    - Tween / move it toward `BeltEnd` (or just spawn at the Explorer's reach — keep it simple for MVP).
    - Wait for either pickup or auto-advance after a timeout.
3. `ExplorerInteractionService`:
    - `RequestPickupItem(itemId)` — validate it's the active item. Mark it as held by the Explorer.
    - `RequestPlaceItemInLane(itemId, laneId)` — validate, fire `ItemSortResult`. Correct → trust points + advance. Wrong → bounce-back animation, mistake counter.
4. `GuideControlService`:
    - `RequestAnnotateItem(itemId, lane)` — broadcast annotation.
5. Client:
    - Extend `ExplorerController` for pickup / drop input. Use ProximityPrompts on bins.
    - Extend `GuideManualController` to render the chart for this level.
    - Extend `GuideAnnotationController` for item-mode annotation buttons.
6. After N items, fire `LevelExit` and route through `RoundFinishZone` → score screen.

#### Milestone 6: Scoring + Score Screen

1. `Modules/ScoringConfig.lua` — point values for level completion, time bonus, mistake penalty, trust streak.
2. `ScoringService.lua` — track time / mistakes / trust points / rank.
3. `RewardService.lua` — grant Trust Seeds (session data is fine for MVP).
4. Client: `ScoreScreenController.client.lua` — show breakdown + replay / return-to-lobby buttons.

#### Milestone 7: Lobby Progression

1. `DataService.lua` — session-only data.
2. Client: `LobbyProgressionController.client.lua` — visualize Trust Seeds + treehouse level on the lobby's treehouse area (toggle visibility on placeholder visual stages User 1 placed).

#### Milestone 8: Polish

- SFX hookups (User 1 placed Sounds in `SoundService` — wire each to the right server/client event).
- UI styling pass: Cartoon font, rounded corners, friendly colors. Use `Modules/UIStyle.lua` as the single source of truth.
- 2-line tutorial prompts on first-ever pair / first-ever role select.
- Replay flow that returns the duo to the lobby cleanly and re-enables their capsules.
- Test the demo route end-to-end. Time it. Should be under 5 minutes.

### Verification Before Marking Anything Done

After every milestone:

- [ ] `selene src/` passes (or you've documented known-acceptable warnings).
- [ ] No file in `src/` exceeds 500 lines.
- [ ] All remote handlers validate: player exists, is in active round, has correct role, target id exists.
- [ ] No client-side authoritative state for score / role / NPC role / item correctness.
- [ ] Tested with 2 players in a Studio local server (or 1-player + `DEBUG_SOLO` flag in `Constants.lua` if alone).
- [ ] `tasks/todo.md` updated.
- [ ] If you got something wrong and the user corrected you, `tasks/lessons.md` updated.

### Coordination With User 1

- The map (lobby, slots, level templates, NPC/item templates, booth template) comes from User 1's Studio work. **Do not edit it directly** — only consume the tags and attributes they set.
- If a tag / attribute / Model name is missing or wrong, update `docs/TECHNICAL_DESIGN.md` and `human_todo.md` to reflect what you actually need, then tell User 1.
- Test `rojo serve` early to confirm the place file isn't getting wiped (the `init.meta.json` files prevent this — if it happens, check they are still present in every `src/` subfolder).

### When You Are Done

1. Verify every checkbox in `tasks/todo.md`.
2. Run `selene src/` one final time.
3. Run a clean 2-player Studio test of the full demo route: pair → roles → Stranger Danger Park → Backpack Checkpoint → score screen → return to lobby → progression visual updates.
4. Make sure the demo flow described in `docs/MVP_SCOPE.md` "Hackathon Demo Script" works end-to-end without intervention.
