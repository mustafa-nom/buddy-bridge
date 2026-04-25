# User 1 — Map Builder Prompt (Roblox MCP / Studio)

> Paste this prompt into your Claude Code session. You are the **Map User**. You have the Roblox MCP attached and you build everything in Roblox Studio. You do **not** write Lua scripts — that is User 2's job.

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

Then read this prompt to understand your scope.

### Your Role

You are the **Map User**. Your scope:

- Build the **lobby**, **play arena slots**, **room templates**, and **booth template** in Roblox Studio using the Roblox MCP.
- Place all CollectionService tags and Instance attributes the scripting user needs.
- Set up `Workspace`, `ServerStorage`, and any geometry-only parts of `ReplicatedStorage` (no scripts).
- Apply visual polish — colors, materials, signage, themed decoration, simple SFX placeholders.

You do **NOT**:
- Write Lua scripts (that is User 2's responsibility, working from `src/` via Rojo).
- Modify files in `src/ReplicatedStorage`, `src/ServerScriptService`, `src/ServerStorage`, or `src/StarterPlayerScripts` on disk.
- Create RemoteEvents / RemoteFunctions / BindableEvents — those are managed by `RemoteService.lua` (User 2).

### Server Capacity

- Max 8 players per server, up to 4 simultaneous duos (2 players each).
- The lobby is shared. Each duo plays in its own instanced **play arena slot**.

### Build Plan

Build in this order. After each section, save the place file and confirm in-Studio that it looks right.

#### 1. Place Settings

- Set **Max Players** in Game Settings to **8**.
- Make sure `Workspace.FilteringEnabled = true`.
- Enable HttpService if needed for analytics.

#### 2. Lobby

Build a single shared lobby hub where all 8 players spawn.

- Create a `Lobby` model in `Workspace`.
- Add a friendly themed area: bright colors, soft materials, signage like "Welcome to Buddy Bridge — find a buddy and start a run".
- Place a `SpawnLocation` so all players spawn here on join.
- Add a small **Treehouse / Garden** decorative area visible from spawn — this is where progression visuals will eventually grow.

Add **4 capsule pad pairs** (8 pads total) around the lobby:

- Each pad is a small cylinder or hex part (~6 studs wide, ~1 stud tall), brightly colored.
- Each pad has a CollectionService tag `LobbyCapsule`.
- Each pad has Instance attributes:
    - `CapsuleId` — unique string, e.g. `"capsule_1a"`, `"capsule_1b"`, `"capsule_2a"`, `"capsule_2b"`, etc.
    - `CapsulePairId` — shared between the two pads of a pair, e.g. `"pair_1"`, `"pair_2"`, ...
- Pads in a pair should sit visibly next to each other (e.g. ~6 studs apart) with a small archway or sign indicating "Buddy Pair 1", "Buddy Pair 2", etc.
- Add a `BillboardGui` over each pad with text "Step here to find a buddy".

Do **not** add any scripts or remote events to capsules. User 2's `LobbyService` handles all logic and uses the tags / attributes you set.

#### 3. Play Arena Slots

Build **4 play arena slots** in a hidden region of the workspace (e.g. y = -500 below the lobby). Players will be teleported here when a round starts.

For each slot:

- Create a `Model` named `Slot1`, `Slot2`, `Slot3`, `Slot4`, all under a `Workspace/PlayArenaSlots` folder.
- Tag the root model with `PlayArenaSlot`.
- Set attribute `SlotIndex` = 1, 2, 3, 4 respectively.
- Position the slots far apart (e.g. 500 studs between each) so cloned rooms don't overlap.

Inside each slot:

- A `RunnerSpawn` part (small invisible part). Tag: `RunnerSpawn`.
- A `BoothAnchor` part — this is a reference part where the booth template's `PrimaryPart` will be aligned. Place it ~30 studs to the side of where the obby will load, with a clear sightline to the obby area.
- An empty `Folder` named `PlayArea` — rooms get cloned into here.
- An empty `Folder` named `Booth` — the booth template gets cloned into here.

A simple "ground plane" baseplate under each slot is fine for visual reference, but everything else is empty until rooms clone in at runtime.

#### 4. Room Templates

Create three room templates as `Model`s inside `ServerStorage/Rooms` (you can use the Studio Explorer to add a `Folder` named `Rooms` under `ServerStorage`, then create the models inside it).

Each room template Model must have:
- `PrimaryPart` set to a reference part at the room origin (CFrame is what gets aligned to the slot's `PlayArea` folder origin).
- A `RoomEntry` part where the Runner is teleported when the room loads. Tag: `RunnerSpawn` is fine to reuse, OR use the room-specific `RoomEntry` part name.
- A `RoomExit` part / trigger that fires room completion when the Runner enters it. Tag: `FinishZone` for the final room, otherwise just name it `RoomExit`.
- Attribute `RoomType` on the root model — `"ButtonRoom"`, `"BridgeBuilder"`, or `"DoorDecoder"`.

##### Room A: ButtonRoom

- A small enclosed room (~40 studs wide, ~30 deep).
- 6 button parts arranged in a row or 2×3 grid.
- Each button:
    - Tag: `BuddyButton`
    - Attribute `InteractableId`: `"button_1"` through `"button_6"` (unique within this room)
    - A `BillboardGui` with placeholder label text "BUTTON" (User 2's code will overwrite labels at runtime).
    - A `ProximityPrompt` so the Runner can press it.
- A `RoomExit` part / door at the back wall. Tag: `RoomExit`.

##### Room B: BridgeBuilder

- A long room (~80 studs deep) with a chasm in the middle.
- A starting platform and an ending platform on the far side.
- 5–7 bridge segment parts spanning the chasm. Each:
    - Tag: `BuddyBridge`
    - Attribute `InteractableId`: `"bridge_1"` through `"bridge_n"`
    - Anchored, initially set to `Transparency = 0.7` and `CanCollide = false` (User 2's code will toggle these when the Guide activates them).
- The `RoomExit` is a part on the far platform. Tag: `RoomExit`.

##### Room C: DoorDecoder

- A small room with **3 doors** along the back wall.
- Each door:
    - A door-shaped `Model` (door + frame).
    - Tag the door root with `BuddyDoor`.
    - Attribute `InteractableId`: `"door_a"`, `"door_b"`, `"door_c"`.
    - A `ProximityPrompt` on the door.
    - A `BillboardGui` above the door with placeholder text "DOOR" (User 2 will fill in NPC messages).
- The `RoomExit` is behind whichever door turns out to be safe — but since "safe" is decided server-side per round, just put a teleport-style `FinishZone` part behind ALL three doors and let the server handle correctness.

Apply playful, distinct color schemes to each room so judges can tell them apart visually.

#### 5. Booth Template

Create `ServerStorage/GuideBooths/DefaultBooth` as a Model:

- A small enclosed room (~12×12 studs, fully walled).
- `PrimaryPart` set on a reference part at the booth origin.
- A `GuideSpawn` part inside (tag: `GuideSpawn`).
- A `ControlPanel` part on the front wall (a desk-height block, ~6×3 studs, facing the window). Add a `SurfaceGui` on its top face — User 2 will populate it.
- A `Window` part — a transparent (`Transparency = 0.5`, `CanCollide = false`) part on one wall, sized so the Guide can see out toward where the obby will load.
- Walls thick enough that the Guide cannot leave by walking. The booth has no door.

Theme it like a cozy "lookout post" or "lighthouse cabin", not a cybersecurity ops center.

#### 6. Polish Pass

- Add ambient lighting / skybox that feels warm and inviting, not corporate.
- Add some background music placeholders (`SoundService` children with `Looped = true`) — leave them disabled, User 2 may wire them up.
- Add basic SFX placeholders in `SoundService` named: `ButtonPress`, `WrongAnswer`, `RoomComplete`, `RoundComplete`, `BridgeActivate`.
- Avoid clutter that would obscure interactables.

### Coordination With User 2

- User 2 reads the same docs and assumes you will produce these exact tags / attributes / names. **Do not rename them** without updating `docs/TECHNICAL_DESIGN.md`.
- If you discover something User 2 needs that isn't in the docs (e.g. extra anchor parts), update `docs/TECHNICAL_DESIGN.md` "Map Object Conventions" yourself and mention it in `tasks/lessons.md`.
- Keep the `human_todo.md` checklist up to date — check items off as you finish them.

### When You Are Done

1. Verify every checkbox in the "Studio Map" section of `human_todo.md` is checked.
2. Save the Studio place.
3. Commit any changes you made to docs (you should not have changed any code).
4. Tell the team User 2 can begin scripting. They depend on your tags / attributes / names being final.
