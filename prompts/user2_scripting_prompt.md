# User 2 — Scripting Prompt (Rojo + Claude Code)

> Paste this prompt into your Claude Code session. You are the **Scripting User**. You write all Lua via Rojo. You do **not** open Roblox Studio to build geometry — that is User 1's job.

---

## Prompt

You are working on **Buddy Bridge: A Two Player Trust Obby**, a 2-player asymmetric co-op Roblox obby for the LAHacks Roblox Civility Challenge.

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
- Wire client controllers to UI built in code (UI is created programmatically in Lua; only the booth's `ControlPanel` SurfaceGui anchor is built by User 1).
- Handle all server logic: pairing, role assignment, round orchestration, room scenarios, scoring, rewards.
- Keep every file under 500 lines.
- Maintain server authority — never trust the client for gameplay truth.

You do **NOT**:
- Open Roblox Studio to build or edit geometry, lobby pads, play arena slots, room templates, or the booth template. User 1 builds those.
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

### Architecture Recap (read the docs for details)

- **Server-authoritative.** Server owns roles, round state, scoring, room correctness, rewards.
- **8 players per server**, up to 4 simultaneous duos.
- **Lobby** is shared. Players pair via capsule pads (`LobbyCapsule` tag, `CapsuleId` + `CapsulePairId` attributes) OR via `ProximityPrompt` "invite to play" on other players.
- **Play arena slots** are pre-built in `Workspace/PlayArenaSlots` (4 slots, each tagged `PlayArenaSlot` with `SlotIndex` 1..4).
- **Room templates** live in `ServerStorage/Rooms`. Clone into a slot's `PlayArea` folder when a round starts.
- **Booth template** lives in `ServerStorage/GuideBooths/DefaultBooth`. Clone into a slot's `Booth` folder, align to `BoothAnchor`.
- **Guide is teleported into the booth** and cannot leave during the round. They communicate with the Runner only via voice / chat / UI signals.
- **Remotes** are all created in `RemoteService.lua` (single source of truth). See `docs/TECHNICAL_DESIGN.md` for the list.

### Implementation Order

Work in this order. Update `tasks/todo.md` as you go — check items off when complete.

#### Milestone 1: Skeleton

1. `RemoteService.lua` — creates and exposes all RemoteEvents / RemoteFunctions.
2. `Modules/Constants.lua`, `Modules/RoleTypes.lua`, `Modules/RoomTypes.lua`.
3. `Modules/PlayAreaConfig.lua` — slot count, room order defaults, etc.
4. `ServerBootstrap.server.lua` — requires every server service in dependency order.
5. `ClientBootstrap.client.lua` — requires every client controller.

After this, `rojo serve` should succeed and the place should run with no errors (just no gameplay yet).

#### Milestone 2: Lobby + Pairing

1. `LobbyService.lua` — capsule occupancy tracking, invite flow, calls `MatchService:CreatePair` when both confirm.
2. `MatchService.lua` — `CreatePair`, `GetPair`, `RemovePair`.
3. Client: `LobbyPairController.client.lua` — listens for `CapsulePairReady` / `InviteReceived`, shows confirm UI, sends responses.
4. Test: 2 players in Studio can pair via capsules and via proximity prompt.

#### Milestone 3: Role + Round Start (no rooms yet)

1. `RoleService.lua` — `AssignRoles`, `GetRole`.
2. `RoundService.lua` — `StartRound`, `EndRound`, timer, room sequence.
3. `PlayAreaService.lua` — slot reservation, clone rooms + booth, teleport players.
4. Client: `RoleSelectController.client.lua`, `RoundHudController.client.lua`.
5. Test: 2 paired players can pick roles and get teleported to a slot. Runner spawns in obby area, Guide spawns in booth and cannot leave.

#### Milestone 4: Button Room

1. `ScenarioRegistry.lua` + `ScenarioService.lua` — generate randomized button scenarios.
2. `RoomService.lua` — load Button Room, attach scenario to cloned buttons (set BillboardGui labels, mark IsSafe server-side).
3. `RunnerInteractionService.lua` — handle `RequestPressButton`, validate, apply consequences.
4. `GuideControlService.lua` — handle `RequestGuideScan` (Guide reveals warning tags for a button).
5. Client: `RunnerController.client.lua`, `GuideManualController.client.lua`, `GuideControlsController.client.lua`.
6. Test end-to-end: Guide can scan, Runner presses safe button, room completes; pressing wrong button increments mistakes.

#### Milestone 5: Bridge Builder

1. Add `BridgeBuilder` scenario logic.
2. Guide activates bridge segments via `RequestActivateBridge`. Server toggles `Transparency` and `CanCollide`.
3. Runner crosses; `RoomExit` trigger fires room completion.

#### Milestone 6: Door Decoder

1. Add `DoorDecoder` scenario logic.
2. Generate door messages; mark one safe server-side.
3. Runner triggers `RequestChooseDoor`; correct door advances, wrong door applies consequence.

#### Milestone 7: Scoring + Score Screen

1. `ScoringConfig.lua`, `ScoringService.lua` — track time / mistakes / trust points / rank.
2. `RewardService.lua` — grant Trust Seeds (session data is fine for MVP).
3. Client: `ScoreScreenController.client.lua` — show results + replay button.

#### Milestone 8: Lobby Progression

1. `DataService.lua` — session-only data store first; persist later if time allows.
2. Client: `LobbyProgressionController.client.lua` — visualize Trust Seeds / treehouse level on the lobby's treehouse area.

#### Milestone 9: Polish

- SFX hookups (User 1 placed placeholder Sounds in `SoundService`).
- UI styling pass (Cartoon font, rounded corners, friendly colors).
- Tutorial prompts (very short — 1 sentence per role).
- Replay flow that returns the duo to the lobby cleanly.

### Verification Before Marking Anything Done

After every milestone:

- [ ] `selene src/` passes (or you've documented known-acceptable warnings).
- [ ] No file in `src/` exceeds 500 lines.
- [ ] All remote handlers validate: player exists, is in active round, has correct role, target id exists.
- [ ] No client-side authoritative state for score / role / room correctness.
- [ ] You tested with 2 players in a Studio local server (or with a 1-player debug toggle in `Constants.lua` if User 1 isn't around).
- [ ] `tasks/todo.md` updated.
- [ ] If you got something wrong and the user corrected you, `tasks/lessons.md` updated.

### Coordination With User 1

- The map (lobby, slots, room templates, booth template) comes from User 1's Studio work. **Do not edit it directly** — only consume the tags and attributes they set.
- If a tag / attribute / Model name is missing or wrong, update `docs/TECHNICAL_DESIGN.md` and `human_todo.md` to reflect what you actually need, then tell User 1.
- Test `rojo serve` early to confirm the place file isn't getting wiped (the `init.meta.json` files prevent this — if it happens, check they are still present in every `src/` subfolder).

### When You Are Done

1. Verify every checkbox in `tasks/todo.md`.
2. Run `selene src/` one final time.
3. Run a clean 2-player Studio test of the full demo route: pair → roles → 3 rooms → score screen → return to lobby → progression visual updates.
4. Make sure the demo flow described in `docs/MVP_SCOPE.md` "Hackathon Demo Script" works end-to-end without intervention.
