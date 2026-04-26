# PHISH! — Core Loop

The minute-to-minute gameplay an engineer needs to implement. If you're writing the casting/biting/reel pipeline, start here.

## High-Level Sequence

```
Idle on dock
    │
    ▼
[Cast]  ─────────────►  Lure flies, lands in water
    │
    ▼
Waiting for bite (server picks fish, weighted by pond + time-of-day)
    │
    ▼
[BiteOccurred]  ─────►  Bobber dips, ripple appears (CATEGORY-HINTING visual)
    │
    ▼
Decision window  (~3 sec, configurable)
    │     │     │     │
    │     │     │     └─► [RequestReport]    → for Mod Imposter visual cues
    │     │     └────────► [RequestCutLine]  → refuses, lure resets, no reward
    │     └──────────────► [RequestVerify]   → opens Field Guide entry, costs ~2-3 sec
    │                                            (Verify reveals true category;
    │                                             player still chooses Reel/Cut/Report)
    └──────────────────► [RequestReel]      → commits to the catch
                              │
                              ▼
                          Reel mini-game (tension/timing, ~3-6 sec)
                              │
                              ▼
                    [CatchResolved] ────► server validates verb-vs-fish
                              │
                              ▼
                    Outcome panel (XP, journal entry, lesson line, optional Aquarium prompt)
                              │
                              ▼
                          Back to Idle on dock
```

## Per-Step Detail

### Cast
- Client: hold rod input → charge bar; release → fires `RequestCast` with `{ aimDirection, chargePower }`
- Server: validates rate-limit, computes lure landing position, sets player into `Casting` state
- Client: plays cast animation, spawns lure visual, transitions to Waiting

### Waiting / Bite Selection
- Server picks the next fish for this cast: weighted random over the pond's spawn table (`FishRegistry`), filtered by time-of-day and player's recent catches (anti-clumping)
- Server schedules `BiteOccurred` after a randomized 2–6 sec wait
- Bite payload includes the **visible cue** (bobber color, ripple pattern) — **not** the fish's true identity
- Client renders the cue; player has to read it

### Decision Window
- ~3 seconds (tune in `Constants.lua`). HUD shows four buttons: **Verify / Reel / Cut Line / Report**
- If the player does nothing within the window → fish escapes, lure resets, small "let it slip" beat (no penalty for first-timers; consider tutorial flag)
- Verify briefly pauses the timer and opens the relevant Field Guide entry (server confirms the entry is unlocked or unlocks it on first use)

### Reel Mini-Game (only on `RequestReel`)
- Short tension/timing minigame — direction-input rhythm, ~3–6 sec
- Reuse the timing/tick pattern from the existing `BeltController.lua` (Buddy Bridge BPC). Pattern is solid; rebuild as `ReelMinigameController.client.lua` rather than fork the file.
- Server is authoritative on success/failure of the reel itself, but **the catch identity was already decided at bite-time** — the minigame just adds skill expression, it doesn't change *what* you caught.

### Catch Resolution (`CatchResolved`)
- Server determines: `{ wasCorrectVerb: bool, fish: FishId, category, rarity, xpDelta, journalUnlocked, lessonLine }`
- Lesson line is one short sentence from `FishRegistry`, e.g.:
  - Correct Cut Line on Free Robux Bass: *"Smart move — anything that promises free in-game stuff for nothing is the bait."*
  - Wrong Reel on Faux-Mod Flounder: *"That wasn't a real moderator. Real Roblox staff never ask for your password."*
- Client shows outcome panel for ~3 sec, then returns to Idle

### Outcome Panel
- Always show: fish name, rarity, XP delta, lesson line
- If correct: journal-entry-unlocked toast
- If a Kindness Fish or True Catch: "Place in Aquarium?" prompt
- If wrong: friendly buzzer, but never harsh — kids should laugh, not feel scolded

## Loop Length

- **Per cast:** 30–60 sec start-to-finish (Cast → Wait → Bite → Decide → Reel → Outcome)
- **Per session:** 5–10 min before player chooses to leave; 15–20 min for journal-completionist

## Required Remotes

(All declared in `RemoteService.lua`. Server authority on every one. Rate-limit `RequestCast`, `RequestVerify`, `RequestReel`, `RequestCutLine`, `RequestReport`.)

| Remote | Direction | Payload | Purpose |
|--------|-----------|---------|---------|
| `RequestCast` | C→S | `{ aimDirection, chargePower }` | Player throws lure |
| `BiteOccurred` | S→C | `{ bobberCue, rippleCue, decisionWindowSec }` | Notify player of bite |
| `RequestVerify` | C→S | `{ encounterId }` | Open Field Guide for this encounter |
| `FieldGuideEntryUnlocked` | S→C | `{ fishId, entryText }` | Reveal/unlock entry |
| `RequestReel` | C→S | `{ encounterId }` | Commit to reel |
| `RequestCutLine` | C→S | `{ encounterId }` | Refuse the catch |
| `RequestReport` | C→S | `{ encounterId }` | Report imposter |
| `CatchResolved` | S→C | `{ fishId, category, rarity, xpDelta, lessonLine, wasCorrect }` | Final result |
| `JournalUpdated` | S→C | `{ fishId }` | Add to journal |
| `RequestPlaceFishInAquarium` | C→S | `{ fishId }` | Display in aquarium |
| `AquariumUpdated` | S→C | `{ fishId, slot }` | Aquarium changed |
| `XpGranted` | S→C | `{ amount, total }` | XP UI update |

## State Machine (Server-side, per player)

```
Idle  ──RequestCast──►  Casting  ──(timer)──►  Waiting
                                                  │
                                              (timer)
                                                  ▼
                                              BitePending  ──(decision timeout)──►  Idle
                                              │ │ │ │
                          ┌───────Verify──────┘ │ │ └────Report──────┐
                          ▼                     │ │                   ▼
                     Verifying ──(resume)──► (back to BitePending)  Resolving (Report)
                                                │ │                    │
                                       Reel─────┘ └─CutLine──┐         │
                                       │                     ▼         │
                                       ▼                  Resolving    │
                                    Reeling                (CutLine)   │
                                       │                     │         │
                                       ▼                     ▼         ▼
                                  Resolving ─────► CatchResolved ─► Idle
                                    (Reel)
```

Use `PondState.lua` (new shared module) to model the state. Adapt the existing `RoundState.lua` patterns.

## Reused Code

These existing modules/patterns should be reused, not rebuilt:

- `BookView.lua` (`StarterPlayerScripts/Guide/`) — full-page reader with state machine. Repurpose for **Field Guide UI**.
- `BeltController.lua` (`ServerScriptService/Services/Levels/BackpackCheckpoint/`) — timing/tick loop. Repurpose pattern for **Reel mini-game**.
- `RateLimiter.lua` — wrap every player-triggered remote.
- `SignalTracker.lua` — clean up player connections on leave.
- `ScoringConfig.lua` — extend for catch-XP formula.
- `RemoteService.lua` — add new remotes alongside existing ones.

## Open Engineering Questions

- **Anti-spam on Cut Line:** if a kid just spams Cut Line on every bite, they never engage with the verbs. Consider: tiny cooldown after Cut Line, or "you cut 5 in a row — try Verify on the next one!" tutorial nudge.
- **Verify cost balance:** Verify must feel useful but not free. ~2-3 sec pause feels right; tune in playtest.
- **Multi-player pond instancing:** MVP can run a single shared pond per server (8 players fishing the same dock). If it feels crowded, fall back to one pond per player using existing `PlayAreaService` slot-pool pattern.
