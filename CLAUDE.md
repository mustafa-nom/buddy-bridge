# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Buddy Bridge** is a replayable 2-player asymmetric co-op Roblox obby designed for the LAHacks Roblox Civility Challenge.

The game is inspired by **Keep Talking and Nobody Explodes**, 2-player obbies, and cozy parent-child Roblox experiences like Grow a Garden.

One player is the **Runner**, who plays through an obby full of buttons, bridges, doors, and traps.

The other player is the **Guide**, who stays in a control booth and sees extra information, clue cards, and controls that help the Runner.

The hidden learning goal is early digital safety, trust, civility, and parent-child communication. However, the game should **not feel like an educational game**. It should feel like a fun Roblox co-op obby first.

Core message:

> Pause. Talk. Choose together.

The game should be fun and replayable even if the player ignores the educational theme.

NO FILE SHOULD BE BIGGER THAN 500 LINES. If a file is getting too large, split logic into smaller modules and require them.

## Server / Multiplayer Model

- **Max players per server:** 8
- **Players per duo:** 2 (one Runner, one Guide)
- **Max simultaneous duos per server:** 4

Each duo plays in its own **instanced play area**. The map has N pre-built **play arena slots** in a hidden area of the workspace. When a duo starts a round, the server picks an open slot, clones the room templates from `ServerStorage` into it, and teleports both players there.

The lobby is a single shared social space. The play arenas are private to each duo.

### Lobby Flow

The lobby supports two ways to pair:

1. **Capsules:** Pairs of capsule pads sit around the lobby. Two players step into matching capsules (or two adjacent pads) and a `StartPair` prompt appears. When both confirm, they become a duo.
2. **Player Proximity Prompt:** Walking up to another player exposes a "Invite to Play" `ProximityPrompt`. Triggering it sends an invite. The target sees an accept/decline prompt. On accept, the pair is formed.

After pairing, the duo picks Runner/Guide (or auto-assigns), then presses **Start Round**.

### Guide Booth Design

When a round starts, the Guide is **teleported to a private control booth** attached to the duo's play arena slot. The booth is enclosed (cannot leave during the round) and contains:

- A control panel UI for room-specific actions (scan, activate bridge, etc.)
- A clue manual UI
- A live view of the Runner — either through a transparent window in the booth wall or via a camera feed UI showing the Runner's path

The Guide does **not** physically follow the Runner. This keeps the asymmetry sharp, prevents visual clutter when multiple duos run simultaneously, and makes communication the only way to coordinate.

### Play Area Slot Lifecycle

1. `PlayAreaService` reserves an open slot when `RoundService:StartRound` is called.
2. Room templates (`ServerStorage/Rooms/*`) are cloned into the slot's `PlayArea` folder, positioned via the slot's reference part/CFrame.
3. The booth template (`ServerStorage/GuideBooths/*`) is cloned into the slot's `Booth` folder.
4. Runner is teleported to the slot's `RunnerSpawn`. Guide is teleported to the slot's `GuideSpawn` inside the booth.
5. On round end, the slot's cloned children are destroyed and the slot is released back to the pool.

## Hackathon Context

This project is for the **Roblox Civility Challenge** at LAHacks.

Judges care about:
1. Fun Roblox gameplay and execution
2. Parent-child co-op learning
3. Civility, trust, and digital citizenship
4. A game that does not feel like a boring educational quiz
5. Replayability and potential real-world impact

Important judge insight:
- One judge is a Roblox Studio software engineer and wants something fun to actually play.
- One judge is on the civility team and cares about parents and kids learning together.
- Another judge likes examples where parents naturally play with kids, like Grow a Garden.

Therefore:
- Do not build a lecture game.
- Do not build a quiz game.
- Do not over-explain lessons.
- Build a fun 2-player obby where communication is the mechanic.
- Let the safety and civility message emerge through gameplay.

## Development Commands

### Build & Sync

```bash
rojo build default.project.json -o build.rbxl
rojo serve default.project.json
```

### Linting

```bash
selene src/
```

### Tools

Managed via Aftman, see `aftman.toml`.

Expected tools:
- Rojo 7.6.1 or compatible
- Selene for linting

## Script Types

This is critical for Roblox/Rojo development:

- `.server.lua` = Server Script, runs automatically on game start
- `.client.lua` = Client Script, runs automatically on player join
- `.lua` = ModuleScript, only runs when required by another script

If a ModuleScript sets up callbacks, event listeners, game state, or services, it must be required by a bootstrap server/client script or it will never execute.

## Target Directory Structure

```
src/
├── ReplicatedStorage/
│   ├── RemoteService.lua
│   ├── Modules/
│   │   ├── Constants.lua
│   │   ├── RoleTypes.lua
│   │   ├── RoomTypes.lua
│   │   ├── ScenarioRegistry.lua
│   │   ├── ScoringConfig.lua
│   │   ├── PlayAreaConfig.lua
│   │   ├── NumberFormatter.lua
│   │   └── UIStyle.lua
│   └── Shared/
│       ├── RoundState.lua
│       └── ScenarioTypes.lua
│
├── ServerScriptService/
│   ├── ServerBootstrap.server.lua
│   └── Services/
│       ├── LobbyService.lua
│       ├── MatchService.lua
│       ├── RoleService.lua
│       ├── PlayAreaService.lua
│       ├── RoundService.lua
│       ├── RoomService.lua
│       ├── ScenarioService.lua
│       ├── ScoringService.lua
│       ├── GuideControlService.lua
│       ├── RunnerInteractionService.lua
│       ├── RewardService.lua
│       ├── DataService.lua
│       └── AnalyticsService.lua
│
├── ServerStorage/
│   ├── Rooms/
│   │   ├── ButtonRoom (Model)
│   │   ├── BridgeBuilder (Model)
│   │   └── DoorDecoder (Model)
│   └── GuideBooths/
│       └── DefaultBooth (Model)
│
├── StarterPlayerScripts/
│   ├── ClientBootstrap.client.lua
│   ├── Runner/
│   │   ├── RunnerController.client.lua
│   │   ├── PromptController.client.lua
│   │   └── ObbyFeedbackController.client.lua
│   ├── Guide/
│   │   ├── GuideController.client.lua
│   │   ├── GuideManualController.client.lua
│   │   └── GuideControlsController.client.lua
│   └── UI/
│       ├── LobbyPairController.client.lua
│       ├── RoleSelectController.client.lua
│       ├── RoundHudController.client.lua
│       ├── ScoreScreenController.client.lua
│       ├── NotificationController.client.lua
│       └── LobbyProgressionController.client.lua
```

The map (Lobby, PlayArenaSlots, room/booth templates) is **built in Roblox Studio** by a separate user with the Roblox MCP. See `human_todo.md` and `prompts/user1_map_prompt.md`.

### Rojo Folder Convention: `init.meta.json`

Every folder under `src/` that maps to a Roblox service or container **must contain an `init.meta.json` with**:

```json
{
  "ignoreUnknownInstances": true
}
```

This tells Rojo not to delete instances inside that container that it doesn't know about. Without it, every Rojo sync would wipe Studio-built map content (lobby, play arena slots, room templates, booth template) because those instances live in `Workspace` / `ServerStorage` and are not represented on disk.

**Rule for any future agent:** if you create a new subfolder under `src/`, create an `init.meta.json` inside it with the contents above. Never remove the existing `init.meta.json` files. If Rojo starts deleting Studio-built parts on sync, the cause is almost always a missing or removed `init.meta.json`.

The actual Studio map may need to be built manually. See `human_todo.md`.

## Core Gameplay

### Main Loop

1. Players enter lobby.
2. Two players pair up.
3. They select or receive roles:
   - Runner
   - Guide
4. Round starts.
5. Runner enters obby.
6. Guide enters control booth.
7. The round loads 3-5 randomized rooms.
8. Runner sees physical obstacles and choices.
9. Guide sees clue cards, safety rules, and controls.
10. Players communicate to solve rooms.
11. They finish the run.
12. Game calculates score:
    - time
    - mistakes
    - trust points
    - pause bonuses
    - teamwork streak
13. Players earn Trust Seeds.
14. Trust Seeds upgrade/decorate the shared lobby treehouse/garden.
15. Players replay for better ranks, faster times, and more cosmetics.

### Roles

#### Runner

The Runner is the action player.

They:
- run and jump through obby rooms
- press buttons
- choose doors
- carry items
- avoid traps
- make final selections

The Runner should not have all the information.

#### Guide

The Guide is the support player.

They:
- see clue cards
- scan suspicious objects
- activate bridge pieces
- freeze hazards
- read short parent-style prompts
- guide the Runner through the room

The Guide should not physically solve the obby. Their job is to communicate and support.

## MVP Rooms

For the hackathon MVP, prioritize 3 polished rooms over many half-built rooms.

### Room 1: Button Room

Runner sees several tempting buttons.

Examples:
- FREE PET
- SECRET PRIZE
- OPEN GATE
- FAST SHORTCUT
- PASSWORD DOOR
- DAILY REWARD

Guide sees which buttons are suspicious and which are safe.

Wrong buttons cause funny chaos:
- slime splash
- platform drops
- chicken explosion
- temporary slowdown
- fake shortcut resets the player

Hidden lesson:
- Pause before clicking.
- Suspicious offers often use urgency, free rewards, or secrets.

### Room 2: Bridge Builder

Runner must cross gaps.

Guide controls bridge segments from the booth.

Guide must:
- rotate bridge pieces
- activate safe platforms
- time moving pieces
- warn Runner when to jump

Hidden lesson:
- Trust and communication make progress possible.

### Room 3: Door Decoder

Runner sees several doors with NPC messages.

Examples:
- "Come alone for a secret prize."
- "Tell me your real name first."
- "Stay with your buddy and solve this puzzle."
- "Click fast before time runs out."

Guide sees clue cards explaining which door is safest.

Hidden lesson:
- Do not follow strangers privately.
- Do not share personal info.
- Ask someone you trust when something feels weird.

### Optional Rooms After MVP

Only build these after the core game is fun.

#### Privacy Gate

Runner carries item cards through a gate.

Items:
- favorite color
- username
- home address
- password
- school name
- favorite game
- parent phone number

Guide has a privacy chart:
- okay to share
- ask first
- never share

#### Kindness Chat Maze

Runner opens doors by picking responses to NPC chat messages.

Guide sees the emotional meter and recommended de-escalation hints.

#### Rumor Relay

Runner sees rumors changing between NPCs.

Guide sees original source and helps Runner identify misinformation.

## Game Design Rules

### Rule 1: Fun First

Every room must be playable as a fun co-op game even without the lesson.

Bad:
> "Answer this safety question to continue."

Good:
> "Your partner sees which button is safe, but you are the only one who can press it."

### Rule 2: No Lectures

Avoid long popups explaining online safety.

Use:
- short clue cards
- environmental feedback
- funny consequences
- quick end-of-room recap only if needed

### Rule 3: Education Through Mechanics

Each lesson must be represented by an action.

Examples:
- Pause before clicking = waiting for Guide scan before pressing button
- Trust parent = Runner asks Guide before choosing door
- Safe communication = both players must coordinate bridge timing
- Privacy = physically sorting items into safe/private baskets

### Rule 4: Replayability

The game must support repeated runs.

Use:
- randomized room order
- randomized button labels
- randomized safe choices
- timer
- score ranks
- Trust Seeds
- cosmetic unlocks
- lobby/treehouse progression

### Rule 5: Asymmetric Co-op

Runner and Guide must see different information.

If both players can solve the room alone, redesign the room.

## Core Engineering Principles

### Server Authority

All important game logic must run server-side:
- role assignment
- round state
- scoring
- button correctness
- room completion
- rewards
- player progression
- randomized scenario selection

Clients can:
- render UI
- play effects
- handle local input
- request actions

Never trust client values for:
- score
- role
- current room
- completed rooms
- rewards
- safe/correct answers
- timers

### Networking Discipline

All remotes go through `RemoteService`.

Every remote must have:
- clear payload shape
- server-side validation
- rate limiting if user-triggered
- comments explaining purpose

### Performance

- Avoid per-frame server loops unless necessary.
- Use events and triggers.
- Use CollectionService tags for interactables.
- Pool visual effects where practical.
- Keep UI updates event-driven.

### Data Integrity

Player progression must be updated only through server APIs.

Never let the client directly grant:
- Trust Seeds
- cosmetics
- badges
- round completions
- score

### Lifecycle & Cleanup

Every round must clean up:
- event connections
- temporary room objects
- player states
- guide booth controls
- active prompts
- timers

Services should expose cleanup methods when needed.

## RemoteService Conventions

Create all remotes in `RemoteService.lua`.

Suggested remotes:

### Lobby / Match / Role

- `RequestPairFromCapsule` (player stepped into a capsule slot)
- `RequestInvitePlayer` (proximity prompt invite)
- `RespondToInvite` (accept / decline)
- `PairAssigned`
- `SelectRole`
- `RoleAssigned`
- `LeavePair`

### Round

- `StartRound`
- `RoundStarted`
- `RoundEnded`
- `RoundStateUpdated`
- `ReturnToLobby`

### Runner Interactions

- `RequestPressButton`
- `RequestChooseDoor`
- `RequestUseInteractable`
- `RunnerFeedback`

### Guide Controls

- `RequestGuideScan`
- `RequestActivateBridge`
- `RequestFreezeHazard`
- `GuideManualUpdated`
- `GuideControlResult`

### Scoring / Rewards

- `ScoreUpdated`
- `ShowScoreScreen`
- `RewardGranted`
- `ProgressionUpdated`

### UI

- `Notify`
- `SetHudMode`

## Data Model

For hackathon MVP, keep persistence simple.

Suggested player data:

```lua
{
    TrustSeeds = 0,
    BestTime = nil,
    BestRank = nil,
    TotalRuns = 0,
    PerfectRuns = 0,
    Cosmetics = {},
    EquippedCosmetic = nil,
    TreehouseLevel = 1,
}
```

Do not overbuild monetization or complex persistence during the hackathon.

If ProfileStore is not already installed and time is short, use DataStoreService wrapper or temporary session data. However, server authority still applies.

## Scoring Model

Score should reward teamwork, not only speed.

Suggested scoring:
- Base score for finishing
- Time bonus
- Mistake penalty
- Pause bonus
- Trust streak bonus
- No-wrong-click bonus
- Guide assist bonus

Ranks:
- Bronze
- Silver
- Gold
- Perfect Trust Run

Keep formulas centralized in `ScoringConfig.lua`.

## UI Style

The UI should feel Roblox-native, playful, and kid-friendly.

Use:
- large readable buttons
- short prompts
- bright friendly styling
- simple icons
- minimal walls of text

Font convention:

Programmatically created `TextLabel`/`TextButton`/`TextBox` should use `Enum.Font.Cartoon` unless there is a clear reason not to.

Avoid:
- scary cybersecurity language
- corporate terms
- long educational explanations
- adult-only UI complexity

## Workflow

### Planning

- Enter plan mode for any non-trivial task.
- Write the plan to `tasks/todo.md` with checkable items before implementing.
- For large features, break work into small milestones.
- If something goes sideways, stop and re-plan. Do not blindly keep coding.

### Execution

- Prefer small, modular files.
- One service should have one responsibility.
- Keep each file under 500 lines.
- For non-trivial changes, pause and ask: "Is there a simpler way?"
- Avoid overengineering. This is a 36-hour hackathon project.
- Build playable gameplay before polish.

### Verification Before Done

Before marking any task complete:
- Run `selene src/`
- Check that no file exceeds 500 lines
- Verify server authority
- Verify remotes validate input
- Verify the feature works in a 2-player Studio test if possible
- Update `tasks/todo.md`

### Bug Fixing

When given a bug:
1. Find the root cause
2. Fix it directly
3. Do not create temporary hacks unless explicitly marked as a hackathon fallback
4. Log what was fixed in `tasks/lessons.md` if it was a repeated mistake

### Self-Improvement

After any correction from the user:
- Update `tasks/lessons.md`
- Add a rule that prevents repeating the mistake
- Review `tasks/lessons.md` before starting a new major feature

### Human TODO

See `human_todo.md` for things that need to be created manually in Roblox Studio or Creator Dashboard.

Claude should check this file before claiming a feature is fully complete.

## MVP Feature Checklist

- Lobby with pairing flow
- Runner/Guide role assignment
- Guide booth
- Round start and end flow
- Button Room
- Bridge Builder Room
- Door Decoder Room
- Timer and mistake counter
- Score screen
- Trust Seed reward
- Basic lobby/treehouse progression
- Polished demo-ready UI
- Clear final pitch alignment with early learning and civility

## Important Files

- `docs/PRD.md`: Product requirements
- `docs/GAME_DESIGN.md`: Gameplay design
- `docs/TECHNICAL_DESIGN.md`: Architecture and implementation details
- `docs/MVP_SCOPE.md`: Hackathon scope
- `docs/JUDGING_STRATEGY.md`: How this project should be framed for judges
- `tasks/todo.md`: Current implementation checklist
- `tasks/lessons.md`: Mistakes and patterns to avoid
- `human_todo.md`: Manual Studio tasks
