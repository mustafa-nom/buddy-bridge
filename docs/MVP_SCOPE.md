# Buddy Bridge MVP Scope

## Goal

Ship a playable, polished 36-hour hackathon demo.

The demo should prove:
- this is a fun 2-player Roblox game
- the co-op mechanic creates trust and communication
- the learning is hidden inside gameplay
- the game is replayable

## MVP Must-Haves

### 1. Lobby

Required:
- simple lobby area
- players can pair
- players can select Runner/Guide
- start round button

Nice to have:
- treehouse/garden visual progression
- lobby decorations

### 2. Roles

Required:
- Runner role
- Guide role
- role-specific spawn locations
- role-specific UI

### 3. Round System

Required:
- start round
- end round
- timer
- mistake count
- current room tracking
- final score

### 4. Button Room

Required:
- multiple buttons
- randomized labels
- one or more safe choices
- Guide clue UI
- Runner presses buttons
- correct opens path
- wrong triggers consequence

### 5. Bridge Builder

Required:
- Guide activates bridge pieces
- Runner crosses bridge
- needs communication
- room completion trigger

### 6. Door Decoder

Required:
- multiple doors
- NPC-style messages
- Guide clue card
- Runner chooses door
- correct advances
- wrong consequence

### 7. Score Screen

Required:
- time
- mistakes
- rank
- Trust Seeds earned
- replay/return button

### 8. Trust Seed Progression

Required:
- earn Trust Seeds after run
- display Trust Seeds
- simple TreehouseLevel or garden growth

## MVP Cut List

Do not build unless must-haves are done:

- monetization
- gamepasses
- dev products
- large cosmetic shop
- global leaderboards
- badges
- more than 3 rooms
- advanced story
- AI-generated content
- complex persistence
- mobile-specific polish
- voice chat features

## Time Priority

### First Priority

Playable 2-player loop.

### Second Priority

Three polished rooms.

### Third Priority

Replayability and scoring.

### Fourth Priority

Visual polish and progression.

### Last Priority

Extra content.

## Hackathon Demo Script

The demo should go like this:

1. Two players pair in lobby.
2. One becomes Runner.
3. One becomes Guide.
4. Start run.
5. Button Room shows chaotic/funny choice.
6. Guide helps Runner avoid fake button.
7. Bridge Builder shows active cooperation.
8. Door Decoder shows trust/safety choice.
9. Score screen shows results.
10. Trust Seeds grow treehouse/garden.
11. Explain replayability through randomized scenarios.

## Definition of Done

MVP is done when:
- Two players can complete a full run.
- Each role has something meaningful to do.
- At least 3 rooms work.
- Game can be replayed.
- Score screen works.
- No critical errors in output.
- No file exceeds 500 lines.
- `selene src/` passes or known lint issues are documented.
