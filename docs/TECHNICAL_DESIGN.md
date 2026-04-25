# Buddy Bridge Technical Design

## Architecture Summary

Buddy Bridge uses a server-authoritative Roblox architecture.

The server owns:
- player pairs
- roles
- round state
- room state
- correct answers
- scoring
- rewards
- progression

Clients own:
- UI rendering
- local effects
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
- track which players are standing on which capsule pads
- broadcast "Confirm Pair" prompts when two players occupy a capsule pair
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
- clone room templates from `ServerStorage/Rooms` into a slot's `PlayArea` folder
- clone booth template from `ServerStorage/GuideBooths` into a slot's `Booth` folder
- position cloned models relative to the slot's reference CFrame
- teleport Runner and Guide to slot spawns
- destroy cloned content on round end
- prevent the Guide from leaving the booth (e.g. invisible wall, teleport on exit)

Public API ideas:
- `ReserveSlot()` → slot or nil
- `ReleaseSlot(slot)`
- `BuildArenaForRound(round)` (clones rooms, sets up booth, spawns players)
- `TeardownArenaForRound(round)`

### MatchService

Handles pairing players.

Responsibilities:
- create pair
- dissolve pair
- track player partner
- validate pair exists before starting round

Public API ideas:
- `CreatePair(playerA, playerB)`
- `GetPair(player)`
- `RemovePair(player)`
- `ArePaired(playerA, playerB)`

### RoleService

Handles Runner/Guide roles.

Responsibilities:
- assign roles
- swap roles
- validate role
- get role for player

Public API ideas:
- `AssignRoles(pair, runner, guide)`
- `GetRole(player)`
- `GetRunner(pair)`
- `GetGuide(pair)`

### RoundService

Orchestrates rounds.

Responsibilities:
- start round
- end round
- track timer
- advance rooms
- clean up round state

Public API ideas:
- `StartRound(pair)`
- `EndRound(roundId, reason)`
- `GetRoundForPlayer(player)`
- `AdvanceRoom(roundId)`

### RoomService

Creates and manages rooms.

Responsibilities:
- choose room sequence
- initialize room state
- spawn/load room instances if needed
- handle room completion
- cleanup room

Public API ideas:
- `BuildRoom(round, roomType)`
- `CompleteRoom(round, roomType)`
- `CleanupRoom(round)`

### ScenarioService

Chooses randomized scenarios.

Responsibilities:
- select button labels
- select correct/safe choices
- select door prompts
- provide guide clue data
- avoid repeats where possible

Public API ideas:
- `GenerateButtonScenario()`
- `GenerateDoorScenario()`
- `GetGuideManualForScenario(scenario)`

### GuideControlService

Handles Guide inputs.

Responsibilities:
- validate Guide role
- scan buttons
- activate bridges
- freeze hazards
- update Guide UI

Public API ideas:
- `RequestScan(player, targetId)`
- `ActivateBridge(player, bridgeId)`
- `FreezeHazard(player, hazardId)`

### RunnerInteractionService

Handles Runner inputs.

Responsibilities:
- validate Runner role
- button presses
- door choices
- interactables
- room-specific actions

Public API ideas:
- `PressButton(player, buttonId)`
- `ChooseDoor(player, doorId)`
- `UseInteractable(player, interactableId)`

### ScoringService

Calculates scores.

Responsibilities:
- track mistakes
- track room completions
- track pause bonuses
- calculate final rank
- calculate Trust Seeds

Public API ideas:
- `AddMistake(round, reason)`
- `AddTrustPoints(round, amount, reason)`
- `CalculateFinalScore(round)`

### RewardService

Grants progression.

Responsibilities:
- grant Trust Seeds
- update treehouse level
- unlock cosmetics if implemented

Public API ideas:
- `GrantRunRewards(pair, finalScore)`
- `GetProgression(player)`

### DataService

Stores player progression.

For hackathon MVP, this can be simple.

Responsibilities:
- load data
- save data
- provide safe data access

If time is short:
- implement session-only data first
- add DataStore persistence only after gameplay works

### AnalyticsService

Optional.

Can log:
- round started
- round completed
- room failed
- common wrong choices
- average mistakes

Useful for pitch but not required.

## Round State Shape

Suggested server round state:

```lua
{
    RoundId = "string",
    PairId = "string",
    Runner = Player,
    Guide = Player,
    CurrentRoomIndex = 1,
    RoomSequence = { "ButtonRoom", "BridgeBuilder", "DoorDecoder" },
    StartedAt = os.clock(),
    Mistakes = 0,
    TrustPoints = 0,
    PauseBonuses = 0,
    CompletedRooms = {},
    ActiveScenario = nil,
    IsActive = true,
    Connections = {},
}
```

## Scenario Shape

### Button Scenario

```lua
{
    Type = "ButtonRoom",
    Buttons = {
        {
            Id = "button_1",
            Label = "FREE PET",
            IsSafe = false,
            WarningTags = { "FreeReward", "Urgency" },
            Consequence = "SlimeSplash",
        },
        {
            Id = "button_2",
            Label = "OPEN GATE",
            IsSafe = true,
            WarningTags = {},
            Consequence = nil,
        },
    },
    GuideText = "Watch for urgency, free rewards, or requests for personal info.",
}
```

### Door Scenario

```lua
{
    Type = "DoorDecoder",
    Doors = {
        {
            Id = "door_1",
            Message = "Come alone for a secret prize.",
            IsSafe = false,
            WarningTags = { "PrivateInvite", "SecretReward" },
        },
        {
            Id = "door_2",
            Message = "Stay with your buddy and solve this puzzle.",
            IsSafe = true,
            WarningTags = {},
        },
    },
    GuideText = "The safest choice keeps the player with their buddy and avoids personal info.",
}
```

## Remotes

All remotes must be created through `RemoteService`.

### Client to Server

- `RequestPairFromCapsule(capsuleId)` — server already knows player position via touch detection; this is a confirm action
- `RequestInvitePlayer(targetUserId)` — fired by the proximity-prompt path
- `RespondToInvite(inviteId, accepted)`
- `LeavePair()`
- `SelectRole(roleName)`
- `StartRound()`
- `RequestPressButton(buttonId)`
- `RequestChooseDoor(doorId)`
- `RequestGuideScan(targetId)`
- `RequestActivateBridge(bridgeId)`
- `RequestFreezeHazard(hazardId)`
- `ReturnToLobby()`

### Server to Client

- `InviteReceived(inviteData)`
- `CapsulePairReady(capsuleData)` — both pads occupied, ready to confirm
- `PairAssigned(pairData)`
- `RoleAssigned(roleName)`
- `RoundStarted(roundData)`
- `RoundStateUpdated(statePatch)`
- `GuideManualUpdated(manualData)`
- `RunnerFeedback(feedbackData)`
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
4. Check target id exists in current room.
5. Check action is allowed in current room state.
6. Apply rate limit if spammable.

### Runner Actions

Runner can:
- press buttons only in Button Room
- choose doors only in Door Decoder
- use runner interactables only when close enough

Server should check distance where possible.

### Guide Actions

Guide can:
- scan only active room objects
- activate bridge controls only in Bridge Builder
- use controls only assigned to their pair/round

## Map Object Conventions

Use CollectionService tags for interactables.

Suggested tags:
- `BuddyButton`
- `BuddyDoor`
- `BuddyBridge`
- `BuddyCheckpoint`
- `BuddyHazard`
- `GuideControl`
- `RunnerSpawn`
- `GuideSpawn`
- `FinishZone`
- `LobbyCapsule` (capsule pad in the lobby)
- `LobbyCapsulePair` (groups two capsule pads as a pair)
- `PlayArenaSlot` (root part of a play arena slot)

Important attributes (set on the relevant Instance in Studio):
- `RoomType` — `"ButtonRoom"` | `"BridgeBuilder"` | `"DoorDecoder"`
- `InteractableId` — unique within a room template
- `CapsuleId` — for lobby pads
- `CapsulePairId` — shared between two paired pads
- `SlotIndex` — for play arena slots (1..N)

### Room Template Layout

Each room template (in `ServerStorage/Rooms`) should be a single `Model` with:
- `PrimaryPart` set to a reference part at the room's origin
- All interactables tagged with the appropriate `Buddy*` tag
- Each interactable has an `InteractableId` attribute (e.g. `"button_1"`, `"door_a"`)
- A `RoomEntry` part where the Runner spawns when this room loads
- A `RoomExit` part / trigger that fires room completion

### Play Arena Slot Layout

Each slot (in `Workspace/PlayArenaSlots`) should be a `Model` with:
- A `SlotIndex` attribute
- A `RunnerSpawn` part
- A `GuideSpawn` part (inside the booth template anchor)
- A `PlayArea` empty `Folder` (rooms get cloned in here)
- A `Booth` empty `Folder` (booth template gets cloned in here)
- A `BoothAnchor` part with a CFrame that the booth template's `PrimaryPart` aligns to

### Booth Template Layout

The booth template (in `ServerStorage/GuideBooths/DefaultBooth`) is a `Model` with:
- `PrimaryPart` set
- A `GuideSpawn` part inside it
- A `ControlPanel` part on the front face (clickable / SurfaceGui anchor)
- A `Window` (transparent part) facing the Runner's path, OR a `CameraScreen` SurfaceGui
- Walls thick enough to prevent the Guide from leaving

## Client Controllers

### ClientBootstrap

Requires all client controllers.

### RoleSelectController

Handles lobby role UI.

### RunnerController

Handles Runner-specific prompts and interactions.

### GuideController

Handles Guide-specific HUD mode.

### GuideManualController

Displays clue cards and manual info.

### GuideControlsController

Displays control buttons and sends requests.

### RoundHudController

Shows timer, mistakes, trust points, and role.

### ScoreScreenController

Shows final score and replay options.

### NotificationController

Shows short messages.

## Development Order

Implement in this order:
1. RemoteService
2. Constants/RoleTypes/RoomTypes
3. MatchService
4. RoleService
5. RoundService skeleton
6. Basic lobby pairing
7. Runner/Guide spawn flow
8. Button Room
9. Score tracking
10. Bridge Builder
11. Door Decoder
12. Score screen
13. Trust Seed reward
14. Lobby progression
15. Polish and bug fixes

## Testing Plan

### Solo Testing

Add temporary debug mode:
- assign one player as Runner
- simulate Guide actions through command buttons
- skip pairing when `DEBUG_SINGLE_PLAYER = true`

Remove or disable for final demo if necessary.

### Two-Player Studio Testing

Test:
- pairing
- role assignment
- round start
- Runner UI
- Guide UI
- Button Room correctness
- Bridge controls
- Door choices
- round ending
- score screen

### Failure Cases

Test:
- Runner leaves
- Guide leaves
- wrong player tries Guide control
- wrong player tries Runner action
- round ends during action
- player resets character
- spam clicking buttons

## Code Quality

- Keep files under 500 lines.
- Split scenario data into registries.
- Split UI creation into helper modules.
- Avoid massive services.
- Avoid hardcoded room-specific hacks in generic systems.
- Parameterize reusable functions.
- Do not duplicate remote validation logic if helper functions can handle it cleanly.
