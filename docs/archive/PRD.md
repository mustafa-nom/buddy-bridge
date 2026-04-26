# Buddy Bridge PRD

## Product Name

Buddy Bridge: A Two Player Trust Game

## One-Line Pitch

> Buddy Bridge is a 2-player co-op where the grownup has the safety rulebook and the kid has the actions — they have to talk to win, which is exactly the habit kids should build for the real internet.

This sentence is the **boss-pitch test** (judge Jenine: "I need to be able to explain it to my boss easily"). Every feature must defend itself against this sentence. If it doesn't, cut it.

## Challenge Alignment

This project is for the Roblox Civility Challenge, Early Learning track.

Prompt:

> Create co-op experiences where kids and parents learn together, building trust, starting conversations, and making digital citizenship feel like an adventure.

Buddy Bridge answers this by turning kid-and-grownup communication into the core gameplay mechanic.

After follow-up conversations, the LAHacks judges said this game could plausibly land in Roblox's **"Learn and Explore"** sort if executed well. They explicitly told us to **focus on 1–2 super polished levels** instead of building many shallow ones. We've taken that direction.

## Problem

Most online safety games for kids are built like quizzes. Kids don't want to play homework. Parents don't want to nag.

We need a game where the safe behavior **is** the gameplay — kids practice asking a trusted grownup before risky choices, and the grownup actually has a meaningful role to play.

## Product Goal

Create a fun, replayable Roblox 2-player co-op safety game where:
- one player has action and choice
- the other player has the safety knowledge
- both players need each other to win
- digital safety lessons emerge through mechanics, not popups
- it's good enough to plausibly belong in Roblox's "Learn and Explore" sort

## Target Players

### Primary

Parent-and-child pairs playing together.

### Secondary

Older sibling + younger sibling, friend pairs, or any 2-player team.

### Hackathon Judges

The game must be fun enough for a Roblox engineer to play, polished enough to feel shippable, and meaningful enough for a civility judge to see real impact.

## Core Gameplay Fantasy

The Explorer is loose in a chaotic but charming world.

The Guide is in a control booth with the rulebook.

The Explorer wants to act fast.

The Guide helps them slow down and choose.

Together they practice the habit:

> When something feels weird, pause and ask your grownup.

## Core Loop

1. Pair with another player (capsule pads or proximity-prompt invite).
2. Pick Explorer or Guide.
3. Start a round. The duo plays both MVP levels back-to-back:
   - **Stranger Danger Park** — find the lost puppy by gathering 3 clues from safe people, avoiding risky strangers.
   - **Backpack Checkpoint** — sort items into Pack It / Ask First / Leave It bins.
4. Score screen: time, mistakes, rank, Trust Seeds earned.
5. Trust Seeds grow the shared lobby treehouse / garden.
6. Replay for better ranks.

## MVP Scope

The MVP must include:

1. Two-player pairing in lobby (capsules + proximity-prompt invites)
2. Explorer / Guide roles
3. Guide booth instanced per duo
4. **Stranger Danger Park** — fully playable
5. **Backpack Checkpoint** — fully playable
6. Timer and mistake tracking
7. Score / rank screen
8. Trust Seed rewards
9. Basic treehouse / garden progression
10. Demo-ready visual polish

## Non-Goals for MVP

Do not build these for the hackathon:

- additional levels (Bridge Builder, Door Decoder, Kindness Chat Maze, Rumor Relay)
- monetization, gamepasses, dev products
- complex matchmaking
- voice moderation
- huge cosmetic shop
- long persistence layer (session data is fine for MVP)
- mobile-specific polish
- an AI moderation pass

The judges said: depth on two beats breadth on five. We follow that.

## User Stories

### Player Pairing

As a player, I want to pair with another player via a capsule pad or by approaching them, so we can start a 2-player run together.

Acceptance:
- A player on a pad sees "Waiting for buddy".
- A second player on the matching pad lets both confirm.
- Proximity-prompt invites work as an alternative path.
- The pair is stored server-side and survives until the round ends or someone leaves.

### Role Selection

As a duo, we want to choose Explorer or Guide.

Acceptance:
- Each pair has exactly one Explorer and one Guide.
- Server-side stored.
- Auto-assignment if the duo doesn't pick.

### Round Start

As a duo, we want to be teleported into our private play arena slot.

Acceptance:
- Slot reserved server-side.
- Level templates cloned into the slot.
- Explorer spawns at level entry; Guide spawns in booth.
- Booth is sealed.

### Stranger Danger Park

As the Explorer, I want to walk up to NPCs and decide whether to engage based on what I see.

As the Guide, I want to read the manual and tell my buddy who is safe.

Acceptance:
- 6–8 NPCs spawn at fixed positions, with randomized traits and roles.
- 3 clue-bearing safe NPCs exist somewhere in the pool.
- Explorer can inspect any NPC to reveal traits.
- Guide manual cross-references traits with risk signals.
- Talking to a safe NPC reveals a clue. Talking to a risky NPC triggers a friendly consequence + mistake.
- After 3 clues, the puppy location is revealed and reaching it completes the level.

### Backpack Checkpoint

As the Explorer, I want to sort items into the right bin.

As the Guide, I want to see the chart and tell my buddy where each item goes.

Acceptance:
- Items appear one-by-one on a conveyor.
- Three bins are present: Pack It, Ask First, Leave It.
- Server determines correct lane per item.
- Wrong lane = item bounces back, mistake counter increments.
- Correct lane = points + next item.
- After N items, level completes.

### Score Screen

As a duo, we want to see how we did.

Acceptance:
- Shows time, mistakes, rank, Trust Seeds earned.
- Replay or return-to-lobby buttons.

### Progression

As players, our successful runs should grow our lobby treehouse.

Acceptance:
- Trust Seeds increment after a completed run.
- Treehouse / garden visual updates accordingly.
- Session data is fine; persistence is post-MVP.

## Success Metrics

For the demo:

- A judge can understand the game in 10 seconds.
- A judge can repeat the one-line pitch back without rephrasing.
- A judge can have fun in 30 seconds.
- The Explorer and Guide must talk to win.
- The educational message lands without sounding like a lecture.
- The game can be replayed with randomized scenarios.
- The pitch credibly connects to Roblox's "Learn and Explore" sort.
- Visual style is cohesive end-to-end — the game does not look like four separate hackathon prototypes.

### The "Boss Pitch" Test

The Roblox judge (Jenine) needs to be able to explain this game to her boss. After playing, ask the judge to summarize the game in one sentence. If they say something close to *"two players, one has the rules and one has the actions, they teach kids to ask their grownup before risky online stuff"*, we passed. If they hedge or say "uh… it's like…", we failed the test and need to tighten the framing.

## Design Principles

1. Game first, education present and unashamed.
2. No quizzes. No popup lessons.
3. Communication is the mechanic.
4. The Guide always has knowledge the Explorer needs.
5. Funny consequences > punishing failures.
6. Two polished levels > five rough ones.
7. Replayability through randomization, not extra levels.

## Risks

### It feels like homework

Mitigation:
- Friendly tone, cartoon visuals, Cartoon font.
- No safety jargon. No "PII", no "phishing".
- All learning happens through doing.

### Guide role is boring

Mitigation:
- Guide gets active annotation buttons (✅/🚩/⚠️).
- Guide must read manual quickly under time pressure.
- Guide score contributes to duo score.

### Scope blowup

Mitigation:
- Two levels only. Cut everything else.
- Don't build persistence beyond session data unless time allows.

### Hard to test with 2 players

Mitigation:
- Add a debug solo mode behind a constant flag.
- Use Studio's local server testing with 2 players.

## Demo Pitch

Buddy Bridge is a 2-player safety game where one player explores and the other has the manual. To win, they have to pause, talk, and choose together.

We built it for the Civility Challenge because most online safety games feel like homework. Here the lesson **is** the gameplay — the kid sees the situation, the grownup has the rules, and they practice the habit of asking before acting.

We focused on two polished levels: Stranger Danger Park, where the duo has to find a lost puppy by talking to safe people and avoiding risky ones, and Backpack Checkpoint, a TSA-style sort where they decide what's OK to share. The judges told us to go deep on two — so we did.
