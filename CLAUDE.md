# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Buddy Bridge** is a replayable 2-player asymmetric co-op Roblox experience designed for the LAHacks Roblox Civility Challenge.

The game is inspired by **Keep Talking and Nobody Explodes**, 2-player co-op puzzlers, and cozy parent-child Roblox experiences like Grow a Garden.

One player is the **Explorer**, who moves through the world, meets characters, and handles items.

The other player is the **Guide**, who stays in a control booth and sees the rules, warning signs, and clue manuals the Explorer doesn't.

### Educational Goal — and Why It's Now Front-and-Center

After follow-up conversations with the LAHacks judges, the educational angle is now **explicitly part of the pitch**, not a hidden layer. The judges indicated this game could plausibly be promoted in Roblox's **"Learn and Explore"** sort if the execution is polished. That changes how we present the game:

- The game **is** an educational experience for kids about online safety, civility, and digital citizenship.
- It must still feel like a fun Roblox co-op game — not a quiz, not a lecture.
- The lessons are taught through **mechanics**, where communication between the Explorer and the Guide is the way you actually solve the level.
- Polish 1–2 levels deeply rather than ship many shallow ones. Judges said they only need to see the vision — the depth in two levels proves we could build out the rest.

### The "Explain It To My Boss" Test (from judge Jenine)

The Roblox judge needs to be able to explain this game to her boss in one sentence. That means:

- **One clear problem**, not vague.
- **One clear mechanic** that addresses it.
- **One clear reason** anyone would actually want to play.

Our one-line pitch (drilled in `docs/JUDGING_STRATEGY.md`):

> Buddy Bridge is a 2-player co-op where the grownup has the safety rulebook and the kid has the actions — they have to talk to win, which is exactly the habit kids should build for the real internet.

Every design decision should make that sentence more obviously true. If a feature can't be defended by that sentence, cut it.

### Validated By Judges

After the follow-up conversations:
- **Stranger Danger framing is verified** (judge Andrew): scenes with classic stranger-danger archetypes (white van, person with a knife, person asking your name, etc.). Use these explicit cues in NPC traits.
- **Backpack Checkpoint / TSA framing is verified** (judge Andrew): keep it.
- **Asymmetric-info-relayed-for-life-skills is the core mechanic** (judge Andrew). It's the pitch hook — lead with it.
- **Visual consistency matters** (judge Andrew): one cohesive art style across lobby, both levels, NPCs, items, booth. No mix-and-match.
- **Reference comp** (judge Jenine): *Ecos La Brea* — educational MMO that doesn't feel like homework. Aim for that bar.

Core message:

> Pause. Talk. Choose together.

The Explorer wants to act. The Guide has the safety knowledge. Communication is the mechanic.

NO FILE SHOULD BE BIGGER THAN 500 LINES. If a file is getting too large, split logic into smaller modules and require them.

## Server / Multiplayer Model

- **Max players per server:** 8
- **Players per duo:** 2 (one Explorer, one Guide)
- **Max simultaneous duos per server:** 4

Each duo plays in its own **instanced play area**. The map has N pre-built **play arena slots** in a hidden area of the workspace. When a duo starts a round, the server picks an open slot, clones the room templates from `ServerStorage` into it, and teleports both players there.

The lobby is a single shared social space. The play arenas are private to each duo.

### Lobby Flow

The lobby supports two ways to pair:

1. **Capsules:** Pairs of capsule pads sit around the lobby. Two players step into matching capsules (or two adjacent pads) and a `StartPair` prompt appears. When both confirm, they become a duo.
2. **Player Proximity Prompt:** Walking up to another player exposes a "Invite to Play" `ProximityPrompt`. Triggering it sends an invite. The target sees an accept/decline prompt. On accept, the pair is formed.

After pairing, the duo picks Explorer/Guide (or auto-assigns), then presses **Start Round**.

### Guide Booth Design

When a round starts, the Guide is **teleported to a private control booth** attached to the duo's play arena slot. The booth is enclosed (cannot leave during the round) and contains:

- A clue manual UI for the active level (warning signs, sorting chart, etc.)
- Level-specific control / annotation UI (mark NPCs as risky, flag items, etc.)
- A live view of the Explorer — either through a transparent window in the booth wall or via a camera feed UI

The Guide does **not** physically follow the Explorer. This keeps the asymmetry sharp, prevents visual clutter when multiple duos run simultaneously, and makes communication the only way to coordinate.

### Play Area Slot Lifecycle

1. `PlayAreaService` reserves an open slot when `RoundService:StartRound` is called.
2. Level templates (`ServerStorage/Levels/*`) are cloned into the slot's `PlayArea` folder, positioned via the slot's reference part/CFrame.
3. The booth template (`ServerStorage/GuideBooths/*`) is cloned into the slot's `Booth` folder.
4. Explorer is teleported to the slot's `ExplorerSpawn`. Guide is teleported to the slot's `GuideSpawn` inside the booth.
5. On round end, the slot's cloned children are destroyed and the slot is released back to the pool.

## Hackathon Context

This project is for the **Roblox Civility Challenge** at LAHacks.

Judges care about:
1. Fun Roblox gameplay and execution
2. Parent-child co-op learning
3. Civility, trust, and digital citizenship
4. A game that does not feel like a boring educational quiz
5. Replayability and potential real-world impact

Important judge insight (after our follow-up conversation):
- The judges DO want something educational. The game could plausibly land in Roblox's **"Learn and Explore"** sort if polished.
- They told us to **focus on 1–2 super polished levels** — not many shallow ones. They will see the vision from depth, not from breadth.
- One judge is a Roblox Studio software engineer and wants something fun to actually play.
- One judge is on the civility team and cares about parents and kids learning together.
- Another judge likes examples where parents naturally play with kids, like Grow a Garden.

Therefore:
- Lean into the educational framing. This is a kid + grownup co-op safety game.
- Still no lectures, still no quiz screens. Teach through mechanics.
- Pick **2 levels** and polish them to a shippable bar:
  1. **Stranger Danger Park** (the headline level — Keep-Talking-and-Nobody-Explodes style social safety)
  2. **Backpack Checkpoint** (a shorter sorting level disguising digital citizenship — privacy and what to share online)
- Skip every other level concept until those two are demo-ready.

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
│   │   ├── LevelTypes.lua
│   │   ├── ScenarioRegistry.lua
│   │   ├── NpcRegistry.lua            (Stranger Danger NPC pool)
│   │   ├── ItemRegistry.lua           (Backpack Checkpoint item pool)
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
│       ├── LevelService.lua
│       ├── ScenarioService.lua
│       ├── ScoringService.lua
│       ├── GuideControlService.lua
│       ├── ExplorerInteractionService.lua
│       ├── RewardService.lua
│       ├── DataService.lua
│       └── AnalyticsService.lua
│
├── ServerStorage/
│   ├── Levels/
│   │   ├── StrangerDangerPark (Model)
│   │   └── BackpackCheckpoint (Model)
│   ├── NpcTemplates/                  (NPC rigs for Stranger Danger)
│   ├── ItemTemplates/                 (Item models for Backpack Checkpoint)
│   └── GuideBooths/
│       └── DefaultBooth (Model)
│
├── StarterPlayerScripts/
│   ├── ClientBootstrap.client.lua
│   ├── Explorer/
│   │   ├── ExplorerController.client.lua
│   │   ├── PromptController.client.lua
│   │   └── NpcDescriptionCardController.client.lua
│   ├── Guide/
│   │   ├── GuideController.client.lua
│   │   ├── GuideManualController.client.lua
│   │   └── GuideAnnotationController.client.lua
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
2. Two players pair up via capsule pads or proximity-prompt invite.
3. They pick (or are auto-assigned) one of:
   - **Explorer**
   - **Guide**
4. Round starts. Server reserves a play arena slot, clones the level, teleports both players in.
5. Explorer plays the level. Guide stays in the booth with the manual.
6. They communicate to solve the level.
7. Round ends.
8. Score screen shows time, mistakes, Trust Seeds.
9. Trust Seeds grow the shared lobby treehouse/garden.
10. Players replay for better ranks.

For the demo flow, a round plays **both** of the two MVP levels back-to-back: Stranger Danger Park, then Backpack Checkpoint. They are linked by a portal between play areas in the same slot.

### Roles

#### Explorer

The Explorer is the action / decision player.

They:
- walk around the world
- meet NPCs and decide whether to engage
- pick up and sort items
- experience consequences (good or funny)

The Explorer does **not** have the safety rulebook.

#### Guide

The Guide is stationed in a private booth attached to the duo's slot.

They:
- have the manual of warning signs / safety rules for the active level
- see the Explorer through a window or camera UI
- describe risk to the Explorer over voice/chat
- annotate or flag NPCs/items via UI for the Explorer to see

The Guide does **not** move through the level. Communication is the only way to coordinate.

## MVP Levels

For the hackathon MVP we are shipping **2 super-polished levels**, not three minimum-viable ones. Judges said depth on two beats breadth on five. Cut every additional concept until both of these are demo-ready.

### Level 1: Stranger Danger Park (headline level)

A small park / town plaza with ~6–8 NPCs. The duo has a friendly micro-quest framing — for example, **"find the lost puppy"** — that requires gathering 3 clues from NPCs. Some NPCs are safe to talk to. Some are not. The Guide has the manual; the Explorer is the only one who can actually approach.

#### Loop

1. Explorer walks up to an NPC. ProximityPrompt: "Take a closer look".
2. Server reveals the NPC's visible **traits** (location, clothing, what they're holding, body language) to both the Explorer (as a small description card) and the Guide (with manual cross-reference highlights).
3. Guide consults the manual and tells the Explorer to approach or stay back.
4. If the Explorer chooses to engage:
   - **Safe NPC** → gives a clue or a fragment of the puppy's location.
   - **Dangerous NPC** → consequence (NPC tries to lure Explorer / Explorer trips and runs back / mistake counter increments).
5. Once 3 clues collected, a finish zone unlocks (e.g., the puppy appears at a fountain).

#### Guide manual entries (examples — keep tone friendly, kid-readable)

🚩 Risky signals:
- Calling you over from a parked car
- Asking you to come somewhere private or away from the crowd
- Offering candy, free game items, or "a secret"
- Asking your real name, school, or address
- Standing alone in a place adults usually don't hang around

✅ Safer signals:
- Behind a counter / register at a shop
- Wearing a uniform or name tag
- Helping multiple people, not just you
- With family or kids in a busy public area

#### Replayability

Each round randomizes:
- Which NPCs are safe vs. dangerous
- Which traits each NPC presents
- Which safe NPCs hold which clues
- The puppy's final hiding spot

So the Guide can never just memorize "talk to the guy in the red hat". They must read the manual every run.

### Level 2: Backpack Checkpoint (shorter polish piece)

A TSA-style sorting checkpoint. Items move down a conveyor belt one at a time. The Explorer must drop each item into one of three bins:

- ✅ **Pack It** (OK to share)
- ⚠️ **Ask First** (gray area — ask a grownup)
- ⛔ **Leave It** (keep private)

The Guide has the chart that says where each item belongs.

The items are visual stand-ins for digital citizenship concepts but are themed as physical things, **without using direct labels like "your address"**. Examples:

- A glowing house model = home address → Leave It
- A school crest banner = school name → Leave It
- A padlock card = a password → Leave It
- A phone with a number floating above it = phone number → Leave It
- A name tag with a real name handwritten = real name → Ask First
- A photo Polaroid of yourself = a personal photo → Ask First
- A balloon with your birthdate = birthday → Ask First
- A controller = favorite game → Pack It
- A paint palette = favorite color → Pack It
- A funny meme card = a joke / meme → Pack It

#### Loop

1. Item appears on conveyor.
2. Explorer can pick it up and walk it to a bin OR press a corresponding button.
3. Guide reads the chart, calls out the bin.
4. Server validates the lane choice.
   - Correct → trust points, next item.
   - Wrong → item bounces back, mistake counter, friendly buzzer SFX.
5. After N items, level completes.

This level is **shorter and tighter** than Stranger Danger Park. It exists to convey a second concept (privacy / digital citizenship) and to give the demo a satisfying second beat.

### Future / Cut Levels

We are explicitly not building these for MVP, but they live in `docs/GAME_DESIGN.md` so the team has the catalog ready if there's leftover time:

- Bridge Builder (cooperation / timing)
- Door Decoder (warning sign reading — overlaps with Stranger Danger)
- Kindness Chat Maze (de-escalation)
- Rumor Relay (misinformation)

## Game Design Rules

### Rule 1: Fun First, Educational Second

Every level must be playable as a fun co-op game first. The lesson lives inside the mechanic — never on a popup.

Bad:
> "Answer this safety question to continue."

Good:
> "Your buddy has the manual of warning signs. You're the only one who can actually walk up to the stranger."

### Rule 2: No Lectures

No paragraphs of safety text. The manual the Guide reads is the only place rules appear, and it's framed as gameplay reference, not a lecture.

Use:
- short clue cards
- environmental feedback
- funny but not punishing consequences
- a quick end-of-level recap line, max one sentence

### Rule 3: Education Through Mechanics

Each lesson must be represented by an action the Explorer takes.

Examples:
- Pause before talking to a stranger = waiting for the Guide's read on traits before triggering "Talk"
- Don't share private info = literally tossing the "address" item into the Leave It bin
- Trust your grownup = the level cannot be solved without listening to the Guide

### Rule 4: Replayability

Even with only 2 levels, randomization is what makes it replayable.

Use:
- randomized NPC traits / safe-vs-dangerous roles in Stranger Danger Park
- randomized clue distribution
- randomized item set in Backpack Checkpoint
- timer + ranks
- Trust Seeds
- lobby/treehouse progression

### Rule 5: Asymmetric Co-op

Explorer and Guide must see different information.

If a player can complete the level alone, redesign it. The Guide must always hold knowledge the Explorer needs.

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

### Explorer Interactions

- `RequestInspectNpc` (reveals NPC traits to both players)
- `RequestTalkToNpc` (commits to engaging an NPC)
- `RequestPickupItem` (Backpack Checkpoint)
- `RequestPlaceItemInLane` (Backpack Checkpoint)
- `ExplorerFeedback`

### Guide Controls

- `RequestAnnotateNpc` (Guide flags an NPC as ✅/🚩 for Explorer's HUD)
- `RequestAnnotateItem` (Guide flags item bin choice)
- `GuideManualUpdated`
- `GuideAnnotationResult`

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

- Lobby with pairing flow (capsules + proximity-prompt invites)
- Explorer/Guide role assignment
- Guide booth (instanced per duo)
- Round start, level transition, and end flow
- **Stranger Danger Park** — fully playable with randomized NPCs and clues
- **Backpack Checkpoint** — fully playable with randomized item rotation
- Timer and mistake counter
- Score screen
- Trust Seed reward
- Basic lobby/treehouse progression
- Polished demo-ready UI (Cartoon font, friendly visuals)
- Pitch script that lands the Learn-and-Explore framing without sounding like homework

## Important Files

- `docs/PRD.md`: Product requirements
- `docs/GAME_DESIGN.md`: Gameplay design
- `docs/TECHNICAL_DESIGN.md`: Architecture and implementation details
- `docs/MVP_SCOPE.md`: Hackathon scope
- `docs/JUDGING_STRATEGY.md`: How this project should be framed for judges
- `tasks/todo.md`: Current implementation checklist
- `tasks/lessons.md`: Mistakes and patterns to avoid
- `human_todo.md`: Manual Studio tasks
