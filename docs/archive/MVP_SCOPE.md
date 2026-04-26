# Buddy Bridge MVP Scope

## Goal

Ship a polished hackathon demo with **two levels**, both deep enough to convey the full vision.

The judges' explicit guidance: *focus on 1–2 super polished levels — we'll see the vision*. We are taking that direction literally.

The demo should prove:
- this is a fun 2-player Roblox safety game
- the co-op mechanic creates trust and communication
- the lessons land through gameplay, not popups
- the game is replayable
- this could plausibly belong in Roblox's "Learn and Explore" sort

## MVP Must-Haves

### 1. Lobby

Required:
- shared lobby area
- capsule pad pairing
- proximity-prompt invite alternative
- role select (Explorer / Guide)
- start round button

Nice to have:
- treehouse / garden visual progression in the lobby

### 2. Roles

Required:
- Explorer role
- Guide role
- role-specific spawn locations
- role-specific UI

### 3. Round System

Required:
- start round
- play both MVP levels back-to-back inside one play arena slot
- timer
- mistake count
- final score

### 4. Stranger Danger Park

Required:
- 6–8 NPCs at fixed spawns with randomized roles + traits
- micro-quest framing (find the lost puppy)
- 3 clue-bearing safe NPCs per round
- Explorer can inspect → reveal traits to both players
- Explorer can talk → server validates safe vs. risky
- Guide manual UI cross-references trait risk
- Guide can annotate NPCs (✅/🚩/⚠️) for the Explorer's HUD
- correct path: 3 clues → puppy spawn → level complete
- wrong choices: friendly consequence + mistake counter

### 5. Backpack Checkpoint

Required:
- conveyor belt that feeds items one-by-one
- 3 bins: Pack It / Ask First / Leave It
- N items per round (default 6) drawn from a randomized rotation
- Guide sees the chart of which item belongs in which bin
- Guide can annotate items
- Explorer can sort items into bins
- correct sort: trust points + advance
- wrong sort: bounce back + mistake

### 6. Score Screen

Required:
- time
- mistakes
- rank
- Trust Seeds earned
- replay / return-to-lobby buttons

### 7. Trust Seed Progression

Required:
- earn Trust Seeds after a run
- display Trust Seeds in lobby
- simple TreehouseLevel or garden growth visual

## MVP Cut List

Do not build unless must-haves are done:

- additional levels (Bridge Builder, Door Decoder, Kindness Chat Maze, Rumor Relay)
- monetization, gamepasses, dev products
- large cosmetic shop
- global leaderboards
- badges
- AI-generated content
- complex persistence (session-only data is fine for MVP)
- mobile-specific polish
- voice chat features

## Time Priority

### First Priority
Playable 2-player loop end-to-end (pair → role → start → both levels → score → return).

### Second Priority
Polish on Stranger Danger Park (the headline level the judges will spend the most time with).

### Third Priority
Polish on Backpack Checkpoint.

### Fourth Priority
Replayability + scoring + treehouse progression.

### Last Priority
Stretch: extra item types, extra trait variety, sounds, particle polish.

## Hackathon Demo Script

The demo should go like this:

1. Two players pair via capsule pads.
2. They pick Explorer and Guide.
3. Round starts. They teleport into the duo's slot.
4. **Stranger Danger Park** plays out: Explorer inspects NPCs, Guide reads manual, they collect 3 clues and avoid risky strangers, find the puppy.
5. Explorer steps through the portal into **Backpack Checkpoint**.
6. They sort 6 items together. Guide reads chart, Explorer drops items in bins.
7. Score screen: time, mistakes, rank, Trust Seeds.
8. Returning to the lobby shows the treehouse / garden growing.
9. Pitch hits the Learn-and-Explore framing.

## Definition of Done

MVP is done when:

- Two players can complete a full round end-to-end.
- Stranger Danger Park works with full randomization.
- Backpack Checkpoint works with full item rotation.
- Each role has a meaningful, non-boring action loop.
- Score screen works and replay returns the duo to the lobby cleanly.
- No critical errors in output.
- No file in `src/` exceeds 500 lines.
- `selene src/` passes or known issues are documented.
