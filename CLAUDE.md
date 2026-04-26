# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## Project Overview

**PHISH!** is a cozy fishing collection game for Roblox where every fish you reel in is a real online-safety moment in disguise. The internet is the ocean. Some catches are valuable. Some are bait. Some are scams. Some are kindness. The player becomes a **digital angler** who learns — through gameplay, not lectures — to spot phishing, scams, rumors, AI hallucinations, fake authority, and toxic messages, while collecting genuine kindness fish and accurate-info fish for their aquarium.

The project was pivoted from a prior concept (**Buddy Bridge**) on 2026-04-25. All Buddy Bridge docs now live in `docs/archive/`. The git tag `pre-phish-pivot` preserves the previous state. The Lua source under `src/` still reflects Buddy Bridge — code conversion is a follow-up task tracked in `tasks/todo.md` (P1+P2).

### Hackathon Context

Built for the **Roblox Civility Challenge** at LAHacks. Judging criteria:

1. Gameplay execution (does it feel like a real Roblox game?)
2. Level design
3. Story / message quality (does it actually teach something?)
4. Potential real-world impact
5. Themes: civility, life skills, media literacy, scam prevention, digital literacy, AI fluency, phishing defense, parent/kid appeal

Judges have hinted that a polished entry could land in Roblox's **"Learn and Explore"** sort. Lean into that — but the game must feel like a Roblox fishing game first, education second.

### The "Explain It To My Boss" Test

The Roblox judge needs to be able to explain this game to her boss in one sentence:

> **PHISH! is a cozy Roblox fishing game where every fish you reel in is a real online-safety moment in disguise — kids learn to spot scams, phishing, and AI lies by playing, not by being lectured.**

Every design decision should make that sentence more obviously true. If a feature can't be defended by that sentence, cut it.

### Core Player Fantasy

> *"I am a digital angler exploring the internet ocean, catching weird scam fish, rare truth fish, kindness fish, and boss phishers."*

The verbs the player performs (Cast, Verify, Reel, Cut Line, Report, Release) **are** the digital safety lessons. Verifying a Rumor Fish before reeling is literally fact-checking. Cutting a Scam Bait line is literally refusing a phishing lure. Reporting a Mod Imposter is literally reporting a fake admin. The mechanic *is* the message.

## Player Model

**Solo-first.** PHISH! must be fun and complete as a single-player experience. A kid should be able to load in alone and have a satisfying session.

**Optional Buddy Mode** (post-MVP): a second player can act as a coach with the Field Guide open, advising the angler. This reuses the prior Buddy Bridge plumbing (LobbyService, MatchService, RoleService, PlayAreaService, Guide booth) but is **not** required to play and is **not** in MVP scope.

**Server limits:** target 8 players per server, each in their own pond instance (or sharing a chill social pond — TBD in P2). MVP can ship single-player-per-server if instancing slows us down.

## MVP Scope (read this before adding anything)

For the hackathon we are shipping **one polished pond** with **~12 fish** spanning four digital-citizenship categories. Depth on one pond beats breadth across many. See `docs/PHISH_MVP_PLAN.md` for the full checklist.

- **Pond:** Starter Cove (cozy lake, dock, golden-hour lighting)
- **Fish:** ~12 fish — Scam Bait, Rumor Fish, Mod Imposters, Kindness Fish — see `docs/PHISH_CONTENT.md`
- **Verbs:** Cast, Verify, Reel, Cut Line, Report
- **UI:** Field Guide (reuses existing `BookView.lua`), Journal/Aquarium screen, HUD with rod/lure state
- **Reward loop:** XP + journal entries + aquarium display

**Cut for MVP:** boss fish, multiple ponds, Buddy Mode UI, persistent DataStore, cosmetics shop, rarity gachas. Listed in the doc so we don't accidentally build them.

## Game Design Rules

### Rule 1: Fishing First, Education Second

Every interaction must be playable as a fun fishing game first. The lesson lives inside the verb — never on a popup quiz.

### Rule 2: No Lectures

No paragraphs of safety text. The Field Guide entries are the only place rules appear, and they're framed as angler's-journal lore ("Free Robux Bass: glittery and fast, but the gold dust is fake — cut the line"), not as parental advice.

### Rule 3: Education Through Mechanics

Each digital-safety lesson maps to a verb the player executes. Verify before reeling = fact-check. Cut Line = refuse phishing. Report = report a fake mod. Release = unfollow / mute.

### Rule 4: Replayability

- Randomized fish spawn order per session
- Bobber/ripple cues vary so players can't memorize "always reel the gold one"
- Rarity tiers create chase
- Aquarium and journal complete-the-set meta-loop
- Time-of-day or weather variants gate certain fish

### Rule 5: Solo-Coherent

The game must hold together played alone. Anything that requires a second player gets gated behind optional Buddy Mode.

## Core Engineering Principles

These carry over from the prior project unchanged. They are non-negotiable.

### Server Authority

All important game logic runs server-side:
- fish spawn selection
- catch validation (was this the correct verb for this fish?)
- XP / currency / journal grants
- aquarium contents
- player progression

Clients render UI, play effects, and request actions. Never trust client values for catches, rewards, or fish identity.

### Networking Discipline

All remotes go through `RemoteService.lua` (in `src/ReplicatedStorage/`). Every remote must have:
- a clear payload shape
- server-side validation
- rate limiting if user-triggered (use `RateLimiter.lua`)
- a comment explaining purpose

### Performance

- Avoid per-frame server loops; prefer events.
- Use CollectionService tags for interactables (fish, lures, dock zones).
- Pool VFX where practical.
- Keep UI updates event-driven.

### Data Integrity

Player progression updates only through server APIs. Never let the client directly grant XP, journal entries, aquarium fish, or cosmetics.

### Lifecycle & Cleanup

Every session must clean up event connections, temporary instances, timers, and active prompts when the player leaves. Use `SignalTracker.lua` patterns.

### File Size

**No Lua source file may exceed 500 lines.** If a file approaches the limit, split it. The two existing files near the limit (`BookView.lua` at 472, `BeltController.lua` at 466) must be watched during repurposing.

### Rojo Folder Convention: `init.meta.json`

Every folder under `src/` that maps to a Roblox service or container **must contain an `init.meta.json` with**:

```json
{
  "ignoreUnknownInstances": true
}
```

Without this, every Rojo sync wipes Studio-built map content. **Never delete an existing `init.meta.json`.** When you create a new subfolder under `src/`, create one inside it.

## Script Types (Rojo / Roblox)

- `.server.lua` = Server Script, runs on game start
- `.client.lua` = Client Script, runs on player join
- `.lua` = ModuleScript, only runs when required

If a ModuleScript registers callbacks or remote handlers, it must be required by a bootstrap script (`ServerBootstrap.server.lua` / `ClientBootstrap.client.lua`) or it will never execute.

## Target Directory Structure

The current `src/` tree still reflects the Buddy Bridge concept and will be migrated in P1/P2 (see `tasks/todo.md`). Below is the **planned PHISH! target**.

```
src/
├── ReplicatedStorage/
│   ├── RemoteService.lua                  (KEEP — extend with PHISH! remotes)
│   ├── Modules/
│   │   ├── Constants.lua                  (KEEP)
│   │   ├── UIStyle.lua                    (KEEP — Cartoon font)
│   │   ├── NumberFormatter.lua            (KEEP)
│   │   ├── RateLimiter.lua                (KEEP)
│   │   ├── TagQueries.lua                 (KEEP)
│   │   ├── FishRegistry.lua               (NEW — data-driven from PHISH_CONTENT.md)
│   │   ├── FishCategoryTypes.lua          (NEW — ScamBait, Rumor, ModImposter, Kindness)
│   │   ├── ReelActionTypes.lua            (NEW — Cast, Verify, Reel, CutLine, Report, Release)
│   │   └── ScoringConfig.lua              (KEEP — repurpose for catch rewards)
│   └── Shared/
│       ├── PondState.lua                  (NEW — replaces RoundState)
│       └── FishEncounterTypes.lua         (NEW)
│
├── ServerScriptService/
│   ├── ServerBootstrap.server.lua         (KEEP — rewire for PHISH! services)
│   └── Services/
│       ├── PondService.lua                (NEW — manages active pond, fish spawn)
│       ├── CastingService.lua             (NEW — handles Cast remotes, lure state)
│       ├── BiteService.lua                (NEW — picks fish, server-authoritative)
│       ├── CatchResolutionService.lua     (NEW — validates verb, grants reward)
│       ├── FieldGuideService.lua          (NEW — server side of guide unlocks)
│       ├── JournalService.lua             (NEW)
│       ├── AquariumService.lua            (NEW)
│       ├── ScoringService.lua             (KEEP — repurpose)
│       ├── RewardService.lua              (KEEP — repurpose for XP/currency)
│       ├── DataService.lua                (KEEP — extend with journal/aquarium)
│       └── AnalyticsService.lua           (KEEP)
│
├── ServerStorage/
│   ├── Ponds/
│   │   └── StarterCove (Model)            (Studio-built)
│   └── FishTemplates/                     (Studio-built fish rigs)
│
└── StarterPlayerScripts/
    ├── ClientBootstrap.client.lua         (KEEP)
    ├── Angler/
    │   ├── AnglerController.client.lua    (NEW — replaces ExplorerController)
    │   ├── CastingController.client.lua   (NEW)
    │   ├── ReelMinigameController.client.lua (NEW — repurpose BeltController timing pattern)
    │   └── PromptController.client.lua    (KEEP)
    └── UI/
        ├── HudController.client.lua       (KEEP base — adapt to angler HUD)
        ├── FieldGuideController.client.lua (NEW — reuses BookView.lua)
        ├── JournalController.client.lua   (NEW)
        ├── AquariumViewController.client.lua (NEW)
        ├── NotificationController.client.lua (KEEP)
        └── UIBuilder.lua                  (KEEP)
```

The map (Starter Cove pond, Lodge lobby, fish models) is **built in Roblox Studio** by a separate user with the Roblox MCP. See `human_todo.md` and `prompts/` (which still reflect Buddy Bridge — pending rewrite in P1).

## RemoteService Conventions

All remotes are declared in `RemoteService.lua`. Planned PHISH! remotes:

### Casting / Catching
- `RequestCast` (player triggered cast, payload: aim direction, charge level)
- `BiteOccurred` (server → client, fires when a fish bites)
- `RequestVerify` (player asked Field Guide before reeling)
- `RequestReel` (player commits to reeling)
- `RequestCutLine` (player refuses the catch)
- `RequestReport` (player flags a Mod Imposter)
- `CatchResolved` (server → client, final result + lesson line)

### Field Guide / Journal / Aquarium
- `FieldGuideEntryUnlocked`
- `JournalUpdated`
- `AquariumUpdated`
- `RequestPlaceFishInAquarium`

### Progression
- `XpGranted`
- `RewardGranted`

### UI
- `Notify`
- `SetHudMode`

## Workflow

### Planning

- Enter plan mode for any non-trivial task.
- Write the plan to `tasks/todo.md` with checkable items before implementing.
- For large features, break work into small milestones.
- If something goes sideways, stop and re-plan.

### Execution

- Prefer small, modular files. One service, one responsibility.
- Keep each file under 500 lines.
- Build playable gameplay before polish.

### Verification Before Done

- Run `selene src/`
- `rojo build default.project.json -o build.rbxl` succeeds
- No file exceeds 500 lines
- Server authority preserved
- Remotes validate input
- Update `tasks/todo.md`

### Bug Fixing

1. Find root cause
2. Fix directly
3. No temporary hacks unless explicitly marked as a hackathon fallback
4. Log repeated mistakes in `tasks/lessons.md`

### Self-Improvement

After any user correction:
- Update `tasks/lessons.md`
- Add a rule preventing the repeat
- Review `tasks/lessons.md` before starting a new major feature

### Human TODO

See `human_todo.md` for things to be created manually in Roblox Studio or Creator Dashboard. Check it before claiming a feature is fully complete.

## Scoring Model

Score should reward correct verbs, not just speed.

Suggested:
- Base XP per correct catch
- Rarity multiplier
- Verify-before-reel bonus (encourages fact-checking habit)
- Streak bonus (consecutive correct verbs)
- Mistake penalty (small — we don't want to punish kids for missing once)

Ranks: Tadpole / Angler / Captain / Lighthouse Keeper. Keep formulas in `ScoringConfig.lua`.

## UI Style

Roblox-native, playful, kid-friendly.

- Programmatically created `TextLabel` / `TextButton` / `TextBox` use `Enum.Font.Cartoon` unless there's a clear reason otherwise.
- Large readable buttons, short prompts, bright friendly styling.
- Avoid scary cybersecurity language, corporate terms, long explanations.

## Important Files

- `docs/GAMEDESIGN.md` — top-level design
- `docs/PHISH_CORE_LOOP.md` — minute-to-minute loop and remote sequence
- `docs/PHISH_CONTENT.md` — fish catalog
- `docs/PHISH_MVP_PLAN.md` — hackathon scope
- `tasks/todo.md` — current implementation checklist (P0/P1/P2/P3)
- `tasks/lessons.md` — patterns and mistakes to avoid
- `human_todo.md` — manual Studio tasks
- `docs/archive/` — old Buddy Bridge docs (do not treat as current)

## Build & Sync

```bash
rojo build default.project.json -o build.rbxl
rojo serve default.project.json
selene src/
```

Tools managed via Aftman (`aftman.toml`): Rojo 7.7.0-rc.1, Selene 0.27.1.
