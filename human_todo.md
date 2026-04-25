# Human TODO

These tasks need to be done manually. Some are split between the **Map User** (User 1, with Roblox MCP / Studio) and the **Scripting User** (User 2, with Rojo + Claude Code). Others require both to coordinate.

Claude should not mark related features complete until the human confirms these are done.

## Tooling Verification

- [ ] Confirm `aftman install` succeeds and pulls Rojo `7.7.0-rc4` and Selene `0.27.1`. If `7.7.0-rc4` is not the latest available `rc`, bump `aftman.toml` to the newest `7.7.0-rc*` tag from https://github.com/rojo-rbx/rojo/releases.
- [ ] Install the matching Rojo Studio plugin (must match the CLI version).
- [ ] Confirm `rojo serve default.project.json` connects to Studio successfully.

## Studio Map (User 1 — see `prompts/user1_map_prompt.md`)

### Lobby
- [ ] Create the main Lobby area
- [ ] Place 4 capsule pad pairs (8 pads total), each tagged `LobbyCapsule` with a `CapsuleId`, paired by a shared `CapsulePairId`
- [ ] Add lobby spawn so all players land in the lobby on join
- [ ] Add visual treehouse / garden area for progression display

### Play Arena Slots
- [ ] Build 4 `PlayArenaSlot` models in a hidden region (e.g. far below the lobby)
- [ ] Each slot has: `SlotIndex` attribute, `RunnerSpawn` part, `BoothAnchor` part, empty `PlayArea` Folder, empty `Booth` Folder

### Room Templates (in `ServerStorage/Rooms`)
- [ ] `ButtonRoom` Model with `PrimaryPart`, `RoomEntry`, `RoomExit`, and ~6 buttons each tagged `BuddyButton` with `InteractableId`
- [ ] `BridgeBuilder` Model with bridge segments tagged `BuddyBridge` and an endpoint tagged `RoomExit`
- [ ] `DoorDecoder` Model with 3 doors tagged `BuddyDoor` with `InteractableId`

### Booth Template (in `ServerStorage/GuideBooths`)
- [ ] `DefaultBooth` Model with `PrimaryPart`, `GuideSpawn`, `ControlPanel`, and a `Window` (transparent part) facing the play area

### Tags & Attributes Sanity Pass
- [ ] All required CollectionService tags applied (see `docs/TECHNICAL_DESIGN.md` "Map Object Conventions")
- [ ] All `InteractableId` attributes are unique within a room template
- [ ] All `RoomType` attributes set on room template root models

### Visual Polish
- [ ] Bright, playful colors / materials
- [ ] Clear signage for Runner and Guide areas
- [ ] Treehouse / garden visuals for progression
- [ ] Funny trap visuals (slime, chickens, fake explosions)
- [ ] Basic SFX placeholders for: button press, wrong answer, room complete, round complete

## Scripting (User 2 — see `prompts/user2_scripting_prompt.md`)

- [ ] All work tracked in `tasks/todo.md`
- [ ] User 2 must NOT modify the Studio map directly — only the `src/` tree

## Roblox Settings

- [ ] Set max players per server = 8 in Game Settings
- [ ] Enable Studio API access if DataStores are used
- [ ] Configure experience name and thumbnail before submitting
- [ ] Test with 2-player local server in Studio
- [ ] Publish test place before final Devpost submission

## Demo Prep

- [ ] Prepare one clean demo route through all 3 rooms
- [ ] Have two team members ready as Runner and Guide
- [ ] Practice pitch under time limit
- [ ] Take screenshots / GIFs for Devpost
- [ ] Record backup demo video
