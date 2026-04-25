# Buddy Bridge PRD

## Product Name

Buddy Bridge: A Two Player Trust Obby

## One-Line Pitch

Buddy Bridge is a replayable two-player Roblox obby where one player runs the course and the other guides them with hidden clues, controls, and trust-building prompts.

## Challenge Alignment

This project is for the Roblox Civility Challenge, especially the Early Learning track.

Prompt:

> Create co-op experiences where kids and parents learn together, building trust, starting conversations, and making digital citizenship feel like an adventure.

Buddy Bridge answers this by turning parent-child communication into the core gameplay mechanic.

## Problem

Most educational safety games feel like quizzes or lectures.

Kids do not want to play a game that feels like school. Parents do not want to force children through boring safety lessons.

The real challenge is to make online safety and civility feel like play.

## Product Goal

Create a fun, replayable Roblox co-op game where:
- kids and parents naturally talk to each other
- one player has action
- one player has context
- both players need each other
- digital safety lessons emerge through play
- the game is enjoyable even without the educational framing

## Target Players

### Primary

Parent and child pairs playing together.

### Secondary

Friends, siblings, or any two players who enjoy co-op obbies.

### Hackathon Judges

The game must be fun enough for a Roblox engineer to enjoy and meaningful enough for a civility judge to see real impact.

## Core Gameplay Fantasy

The Runner is in a chaotic obby.

The Guide is in a control booth with secret information.

The Runner wants to move fast.

The Guide helps them avoid traps.

Together they learn to pause, talk, and choose together.

## Core Loop

1. Pair with another player.
2. Choose Runner or Guide.
3. Start a randomized obby run.
4. Complete 3-5 co-op rooms.
5. Earn score based on time, mistakes, and teamwork.
6. Earn Trust Seeds.
7. Use Trust Seeds to grow/decorate the lobby treehouse.
8. Replay for better ranks and unlocks.

## MVP Scope

The MVP must include:

1. Two-player pairing
2. Runner and Guide roles
3. Guide booth UI
4. Three playable rooms:
   - Button Room
   - Bridge Builder
   - Door Decoder
5. Timer and mistake tracking
6. Score/rank screen
7. Trust Seed rewards
8. Basic treehouse/garden progression
9. Demo-ready polish

## Non-Goals for MVP

Do not build these unless MVP is already solid:

- full data persistence
- monetization
- gamepasses
- complex matchmaking
- more than 3 rooms
- large open world
- advanced AI moderation
- huge cosmetic shop
- long story campaign
- complicated tutorial

## User Stories

### Player Pairing

As a player, I want to pair with another player so that we can start a two-player challenge.

Acceptance criteria:
- A player can invite or join another player.
- The pair is stored server-side.
- Both players are assigned to the same round.
- A player can leave the pair.

### Role Selection

As a pair, we want to choose Runner and Guide roles so we can play different parts of the game.

Acceptance criteria:
- Each pair has exactly one Runner and one Guide.
- Roles are stored server-side.
- Players spawn in role-specific locations.
- Role UI updates correctly.

### Round Start

As a pair, we want to start a run and be placed into the correct areas.

Acceptance criteria:
- Runner spawns in the obby start.
- Guide spawns in the booth.
- Timer starts.
- First room loads.
- UI switches to role-specific HUD.

### Button Room

As the Runner, I want to press buttons to open the path.

As the Guide, I want to scan or read clues to help the Runner choose safely.

Acceptance criteria:
- Button labels are randomized.
- Safe/wrong buttons are chosen server-side.
- Runner can request button presses.
- Wrong button triggers funny consequence.
- Correct button completes the room or opens the path.

### Bridge Builder

As the Runner, I want to cross a gap.

As the Guide, I want to activate bridge pieces so the Runner can cross.

Acceptance criteria:
- Guide controls bridge pieces.
- Runner cannot complete without Guide help.
- Bridge state is server-authoritative.
- Room completes when Runner reaches endpoint.

### Door Decoder

As the Runner, I want to choose a door based on messages.

As the Guide, I want to see clue cards that help identify the safest door.

Acceptance criteria:
- Door prompts are randomized.
- Correct/safest door is determined server-side.
- Wrong doors trigger mild/funny consequence.
- Correct door advances the round.

### Score Screen

As a pair, we want to see how we did.

Acceptance criteria:
- Shows time
- Shows mistakes
- Shows trust points
- Shows rank
- Shows Trust Seeds earned
- Offers replay or return to lobby

### Progression

As players, we want our successful runs to grow the lobby/treehouse.

Acceptance criteria:
- Trust Seeds increase after completed rounds.
- Treehouse/garden level updates visually.
- Basic progression works even if persistence is session-only.

## Success Metrics

For the hackathon demo:

- A judge can understand the game in 10 seconds.
- A judge can have fun within 30 seconds.
- The Runner and Guide must talk to win.
- The learning message is obvious after playing but not annoying during play.
- The game can be replayed with randomized scenarios.
- The pitch clearly connects gameplay to parent-child trust.

## Design Principles

1. Game first, education second.
2. No quizzes unless disguised as physical gameplay.
3. Communication is the mechanic.
4. The Guide should help, not lecture.
5. The Runner should act, not just read.
6. Funny consequences are better than punishing failures.
7. Keep rooms short and replayable.
8. Ship a polished MVP instead of many unfinished ideas.

## Risks

### Risk: It feels educational and boring

Mitigation:
- Keep text short.
- Make rooms physical and funny.
- Use obby mechanics, not question panels.

### Risk: Guide role is boring

Mitigation:
- Give the Guide buttons, scanners, bridge controls, and real-time decisions.
- Do not make Guide only read.

### Risk: Too much scope

Mitigation:
- Build 3 rooms only.
- Make each room polished.
- Save optional rooms for after MVP.

### Risk: Hard to test with 2 players

Mitigation:
- Build local debug commands.
- Support Studio 2-player test.
- Create role override dev commands if needed.

## Demo Pitch

Buddy Bridge is a two-player trust obby. One player is the Runner and plays through the course. The other is the Guide and sees the clues, controls, and context. To win, they have to pause, talk, and choose together.

We wanted to avoid making an educational game that feels like homework. Instead, we made communication the mechanic. That mirrors real digital safety. Kids often see the exciting button, message, or shortcut, while parents can help them slow down and understand context. Buddy Bridge turns that real-world relationship into a fun Roblox game.
