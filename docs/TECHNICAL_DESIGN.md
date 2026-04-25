# Buddy Bridge Technical Design

## Architecture Summary

Buddy Bridge uses a server-authoritative Roblox architecture.

The server owns:
- player pairs
- roles
- round state
- level state
- NPC role / trait assignment
- item correctness
- scoring
- rewards
- progression

Clients own:
- UI rendering
- local effects (sparkles, sounds)
- local input capture
- camera behavior
- animations

## Server Capacity

- 8 players max per server.
- Each duo = 2 players.
- Up to 4 simultaneous duos per server.
- Each duo gets its own play arena slot (instanced area).

## Service Responsibilities

### LobbyService

Handles the lobby pairing flow.

Responsibilities:
- track which players are standing on which capsule pads (via `LobbyCapsule`-tagged parts)
- broadcast "Confirm Pair" prompts when both pads of a `CapsulePairId` are occupied
- handle proximity-prompt invites and accept/decline responses
- forward confirmed pairs to `MatchService:CreatePair`
- detect a player walking off a pad / leaving lobby and clean up pending state

Public API ideas:
- `OnPlayerEnterCapsule(player, capsuleId)`
- `OnPlayerLeaveCapsule(player, capsuleId)`
- `RequestInvite(fromPlayer, targetPlayer)`
- `RespondToInvite(player, inviteId, accepted)`

### PlayAreaService

Manages the pool of play arena slots.

Responsibilities:
- discover slots in `Workspace/PlayArenaSlots` at startup
- reserve / release slots
- clone level templates from `ServerStorage/Levels` into a slot's `PlayArea` folder, side by side
- clone booth template from `ServerStorage/GuideBooths` into a slot's `Booth` folder
- position cloned models relative to the slot's reference CFrame
- teleport Explorer and Guide to the right spawns
- destroy cloned content on round end
- prevent the Guide from leaving the booth (invisible wall, teleport on exit)

Public API ideas:
- `ReserveSlot()` → slot or nil
- `ReleaseSlot(slot)`
- `BuildArenaForRound(round)`
- `TeardownArenaForRound(round)`

### MatchService

Handles pairing players.

Public API ideas:
- `CreatePair(playerA, playerB)`
- `GetPair(player)`
- `RemovePair(player)`
- `ArePaired(playerA, playerB)`

### RoleService

Handles Explorer/Guide roles.

Public API ideas:
- `AssignRoles(pair, explorer, guide)`
- `GetRole(player)`
- `GetExplorer(pair)`
- `GetGuide(pair)`

### RoundService

Orchestrates rounds. A round plays both MVP levels back-to-back: Stranger Danger Park, then Backpack Checkpoint.

Public API ideas:
- `StartRound(pair)`
- `EndRound(roundId, reason)`
- `GetRoundForPlayer(player)`
- `AdvanceLevel(roundId)`

### LevelService

Builds and manages the active level inside a round. Replaces the previous `RoomService`.

Responsibilities:
- decide the level sequence for the round (MVP: hardcoded `{ "StrangerDangerPark", "BackpackCheckpoint" }`)
- initialize level state
- wire up the cloned level instance with the chosen scenario
- handle level completion
- cleanup level state

Public API ideas:
- `StartLevel(round, levelType)`
- `CompleteLevel(round, levelType)`
- `CleanupLevel(round)`

### ScenarioService

Generates randomized scenarios.

Responsibilities:
- **Stranger Danger Park**: pick which NPC slots get which roles (safe-with-clue / safe-no-clue / risky), assign each NPC 1–3 visible traits from `NpcRegistry`, distribute clues, choose puppy spawn point.
- **Backpack Checkpoint**: pick item rotation from `ItemRegistry`, set lane assignments per item.
- avoid back-to-back repeats where possible

Public API ideas:
- `GenerateStrangerDangerScenario(slot)`
- `GenerateBackpackCheckpointScenario(slot)`

### GuideControlService

Handles Guide inputs.

Responsibilities:
- validate Guide role and active round
- handle annotation requests (`RequestAnnotateNpc`, `RequestAnnotateItem`)
- broadcast annotations to the Explorer
- update Guide manual data when level changes

Public API ideas:
- `RequestAnnotateNpc(player, npcId, marker)`  marker ∈ ✅/🚩/⚠️/clear
- `RequestAnnotateItem(player, itemId, lane)`

### ExplorerInteractionService

Handles Explorer inputs.

Responsibilities:
- validate Explorer role and active round
- **Stranger Danger**: handle `RequestInspectNpc` (reveal traits) and `RequestTalkToNpc` (commit + apply outcome)
- **Backpack Checkpoint**: handle `RequestPickupItem` and `RequestPlaceItemInLane`
- distance / proximity validation where applicable

Public API ideas:
- `InspectNpc(player, npcId)`
- `TalkToNpc(player, npcId)`
- `PickupItem(player, itemId)`
- `PlaceItemInLane(player, itemId, laneId)`

### ScoringService

Public API ideas:
- `AddMistake(round, reason)`
- `AddTrustPoints(round, amount, reason)`
- `CalculateFinalScore(round)`

### RewardService

Public API ideas:
- `GrantRunRewards(pair, finalScore)`
- `GetProgression(player)`

### DataService

Session-only for MVP.

### AnalyticsService

Optional. Useful events: round started/completed, level failed, common wrong calls, average mistakes per level.

## Round State Shape

```lua
{
    RoundId = "string",
    PairId = "string",
    Explorer = Player,
    Guide = Player,
    SlotIndex = 1,
    LevelSequence = { "StrangerDangerPark", "BackpackCheckpoint" },
    CurrentLevelIndex = 1,
    StartedAt = os.clock(),
    Mistakes = 0,
    TrustPoints = 0,
    CluesCollected = 0,
    ItemsSorted = 0,
    CompletedLevels = {},
    ActiveScenario = nil,
    IsActive = true,
    Connections = {},
}
```

## Scenario Shapes

### Stranger Danger Park Scenario

```lua
{
    Type = "StrangerDangerPark",
    PuppySpawnId = "puppy_spawn_3",
    Npcs = {
        {
            Id = "npc_1",
            SpawnPointId = "npc_spawn_a",
            Role = "SafeWithClue",       -- "SafeWithClue" | "SafeNoClue" | "Risky"
            Traits = { "BehindHotdogStand", "WearingApron" },
            ClueText = "I saw a fluffy pup near the fountain.",
        },
        {
            Id = "npc_2",
            SpawnPointId = "npc_spawn_b",
            Role = "Risky",
            Traits = { "InsideParkedCar", "OfferingCandy" },
            ClueText = nil,
        },
        -- ...
    },
    GuideManual = {
        RiskyTags = { "InsideParkedCar", "OfferingCandy", "AskingPersonalInfo", "WantsToGoSomewherePrivate", "AloneInBackAlley" },
        SafeTags = { "BehindHotdogStand", "WearingApron", "PoliceUniform", "WithKidsAtPlayground", "ReadingOnBench" },
    },
}
```

### Backpack Checkpoint Scenario

```lua
{
    Type = "BackpackCheckpoint",
    ItemSequence = {
        {
            Id = "item_1",
            ItemKey = "RealName",
            DisplayLabel = "A name tag with a handwritten name",
            CorrectLane = "AskFirst",
        },
        {
            Id = "item_2",
            ItemKey = "HomeAddress",
            DisplayLabel = "A glowing tiny house",
            CorrectLane = "LeaveIt",
        },
        -- ...
    },
    GuideManual = {
        Lanes = {
            PackIt = { "FavoriteGame", "FavoriteColor", "FunnyMeme", "PetDrawing" },
            AskFirst = { "RealName", "PersonalPhoto", "Birthday", "BigAchievement" },
            LeaveIt = { "HomeAddress", "SchoolName", "Password", "PhoneNumber", "PrivateSecret" },
        },
    },
}
```

## Remotes

All remotes must be created through `RemoteService`.

### Client to Server

- `RequestPairFromCapsule(capsuleId)` — confirm action; server already knows pad occupancy
- `RequestInvitePlayer(targetUserId)`
- `RespondToInvite(inviteId, accepted)`
- `LeavePair()`
- `SelectRole(roleName)` — `"Explorer"` | `"Guide"`
- `StartRound()`
- `RequestInspectNpc(npcId)`
- `RequestTalkToNpc(npcId)`
- `RequestPickupItem(itemId)`
- `RequestPlaceItemInLane(itemId, laneId)`  laneId ∈ `"PackIt"` | `"AskFirst"` | `"LeaveIt"`
- `RequestAnnotateNpc(npcId, marker)` (Guide only)  marker ∈ `"Safe"` | `"Risky"` | `"AskFirst"` | `"Clear"`
- `RequestAnnotateItem(itemId, lane)` (Guide only)
- `ReturnToLobby()`

### Server to Client

- `InviteReceived(inviteData)`
- `CapsulePairReady(capsuleData)`
- `PairAssigned(pairData)`
- `RoleAssigned(roleName)`
- `RoundStarted(roundData)`
- `RoundStateUpdated(statePatch)`
- `LevelStarted(levelType, levelData)`
- `LevelEnded(levelType, summary)`
- `NpcDescriptionShown(npcId, traits, audience)`  audience indicates whether description is for Explorer, Guide, or both
- `NpcAnnotationUpdated(npcId, marker)`
- `ItemAnnotationUpdated(itemId, lane)`
- `ConveyorItemSpawned(itemId, displayLabel)`
- `ItemSortResult(itemId, laneId, correct)`
- `ClueCollected(clueText, totalCollected)`
- `GuideManualUpdated(manualData)`
- `ExplorerFeedback(feedbackData)`
- `ScoreUpdated(scoreData)`
- `ShowScoreScreen(finalScoreData)`
- `RewardGranted(rewardData)`
- `ProgressionUpdated(progressionData)`
- `Notify(notificationData)`

## Validation Rules

### General

Every server remote handler must:
1. Check player exists.
2. Check player is in active round when required.
3. Check player role matches action.
4. Check target id exists in current level state.
5. Check action is allowed in current level (e.g. `RequestPlaceItemInLane` only valid in Backpack Checkpoint).
6. Apply rate limit if spammable.

### Explorer Actions

- `RequestInspectNpc` and `RequestTalkToNpc` only in Stranger Danger Park, only if Explorer is within proximity of the NPC server-side.
- `RequestPickupItem` and `RequestPlaceItemInLane` only in Backpack Checkpoint, only on the currently active belt item.

### Guide Actions

- `RequestAnnotateNpc` only in Stranger Danger Park.
- `RequestAnnotateItem` only in Backpack Checkpoint.
- All annotations validated against the duo's active level / scenario.

## Map Object Conventions

Use CollectionService tags for interactables.

Suggested tags:
- `LobbyCapsule` (lobby pad)
- `LobbyCapsulePair` (groups two pads — optional, can be inferred from `CapsulePairId`)
- `PlayArenaSlot` (root of a slot)
- `ExplorerSpawn` (spawn point in slot)
- `GuideSpawn` (inside booth)
- `BoothAnchor` (where booth template's `PrimaryPart` aligns)
- `LevelEntry` (where Explorer enters a level)
- `LevelExit` (trigger that fires level completion)
- `BuddyNpcSpawn` (NPC spawn point in Stranger Danger Park)
- `BuddyConveyor` (conveyor belt root in Backpack Checkpoint)
- `BuddyBin` (one of the three sorting bins; `LaneId` attribute = `"PackIt"` | `"AskFirst"` | `"LeaveIt"`)
- `BuddyPortal` (portal between Stranger Danger Park and Backpack Checkpoint inside the slot)
- `RoundFinishZone` (final exit after both levels complete)

Important attributes (set on the relevant Instance in Studio):
- `LevelType` — `"StrangerDangerPark"` | `"BackpackCheckpoint"`
- `CapsuleId` — for lobby pads
- `CapsulePairId` — shared between paired pads
- `SlotIndex` — for slots
- `NpcSpawnId` — for NPC spawn parts in Stranger Danger Park (e.g. `"npc_spawn_a"`)
- `LaneId` — for bins in Backpack Checkpoint
- `BeltStart` / `BeltEnd` — attributes or named parts on the conveyor

### Level Template Layout

Each level template (in `ServerStorage/Levels`) is a single `Model` with:
- `PrimaryPart` set
- A `LevelEntry` part where the Explorer is teleported when the level starts
- A `LevelExit` part / trigger that fires level completion
- Level-specific tagged parts (NPC spawns, conveyor, bins, etc.)

#### StrangerDangerPark template

- 6–8 `BuddyNpcSpawn` parts each with a unique `NpcSpawnId`
- A `PuppySpawn` set of candidate parts (e.g. 4 candidate spawn points; one chosen per round)
- Themed park decoration

#### BackpackCheckpoint template

- A conveyor belt model (visual)
- 3 bins tagged `BuddyBin`, each with `LaneId`
- A `BeltStart` and `BeltEnd` reference part
- A standing area for the Explorer

### Play Arena Slot Layout

Each slot in `Workspace/PlayArenaSlots` should contain:
- `SlotIndex` attribute
- `ExplorerSpawn` part (tagged `ExplorerSpawn`)
- `BoothAnchor` part (tagged `BoothAnchor`)
- empty `PlayArea` folder
- empty `Booth` folder

The slot must have enough space to host both level templates side-by-side, with a `BuddyPortal` between them set up by the server when the round starts.

### Booth Template Layout

The booth template (`ServerStorage/GuideBooths/DefaultBooth`) is a `Model` with:
- `PrimaryPart` set
- `GuideSpawn` part inside (tagged `GuideSpawn`)
- A `ControlPanel` part with a `SurfaceGui` mounted, used by `GuideManualController` to draw the manual UI
- A `Window` (transparent) part facing the play area
- Walls thick enough that the Guide cannot leave by walking

## Client Controllers

### ClientBootstrap

Requires every client controller.

### LobbyPairController

Capsule confirm UI + invite UI.

### RoleSelectController

Lobby role pick UI.

### ExplorerController

Routes Explorer-side input to the right per-level controllers and shows nearby annotations.

### GuideController

Routes Guide-side input to the right per-level controllers and renders the manual.

### GuideManualController

Renders the active manual page (Stranger Danger trait list / Backpack Checkpoint chart) on the booth's `ControlPanel` SurfaceGui.

### GuideAnnotationController

Annotation buttons; sends `RequestAnnotateNpc` / `RequestAnnotateItem`.

### NpcDescriptionCardController

Shows the small NPC trait card to the Explorer when they inspect an NPC, plus mirrors annotations into the world (colored ring around NPCs).

### RoundHudController

Timer, mistakes, trust points, current micro-objective.

### ScoreScreenController

Final score and replay options.

### NotificationController

Short toast messages.

## Development Order

Implement in this order:

1. RemoteService
2. Constants / RoleTypes / LevelTypes
3. MatchService + LobbyService
4. RoleService
5. RoundService skeleton
6. PlayAreaService (clone + teleport)
7. LobbyPair / RoleSelect client UI
8. **Stranger Danger Park** — full slice
9. ScoringService
10. **Backpack Checkpoint** — full slice
11. Score screen
12. Trust Seeds + treehouse progression
13. Polish + bug fixes

## Testing Plan

### Solo Testing

Add a `DEBUG_SOLO` flag in `Constants.lua` that auto-pairs the lone player with a stub second player and lets you toggle role with a key. Disable for final demo.

### Two-Player Studio Testing

Test:
- pairing (capsule + invite)
- role select
- both levels back-to-back
- annotation flow
- score screen
- replay path

### Failure Cases

- Explorer leaves mid-round
- Guide leaves mid-round
- spam clicking inspect / annotate
- Explorer tries Guide remote
- Guide tries Explorer remote
- player resets character
- 4 duos running simultaneously without crosstalk

## Code Quality

- Keep files under 500 lines.
- Split scenario data into registries (`NpcRegistry`, `ItemRegistry`).
- Split UI creation into helper modules.
- Avoid massive services.
- Avoid hardcoded level-specific hacks in generic systems.
- Parameterize reusable functions.
- Do not duplicate remote validation; lift it into a helper.
