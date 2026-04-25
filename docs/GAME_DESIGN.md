# Buddy Bridge Game Design

## High-Level Concept

Buddy Bridge is an asymmetric 2-player co-op obby.

One player runs the course.

The other player guides them from a control booth.

The Runner sees action but lacks context.

The Guide sees context but cannot directly complete the obby.

They must communicate to win.

## Design Pillars

### 1. Fun First

The game must feel like a real Roblox obby/party game.

### 2. Asymmetric Co-op

Each player has different information and responsibilities.

### 3. Replayable Rooms

Rooms should support randomized labels, prompts, safe choices, and consequences.

### 4. Hidden Learning

The learning is embedded in mechanics:
- pause before clicking
- ask for help
- verify before choosing
- protect private info
- de-escalate conflict

### 5. Parent-Child Trust

The game should create a reason for kids and parents to talk.

## Server Capacity & Duo Model

- 8 max players per server.
- Each duo = 2 players.
- Up to 4 simultaneous duos per server.
- Each duo plays in its own instanced play area (slot).

The lobby is shared social space. Play arenas are private to each duo.

## Lobby & Pairing

The lobby is a single hub area where all 8 players spawn.

There are two ways to pair:

### Capsules

Pairs of capsule pads sit around the lobby (e.g. 4 pad pairs).

- A player steps onto a capsule pad.
- A "Waiting for buddy..." prompt appears.
- A second player steps onto the matching pad.
- Both players see a **Confirm Pair** prompt.
- When both confirm, they form a duo.

### Player Proximity Prompts

- Walk up to another player.
- Trigger their "Invite to Play" `ProximityPrompt`.
- The target sees an Accept / Decline UI.
- On accept, both become a duo.

After pairing, the duo enters a small role-select stage:
- One picks Runner, the other picks Guide (default auto-assigns if they don't choose in time).
- A **Start Round** button appears.
- When pressed, the round begins, the play area is built, and they teleport in.

## Play Area Slots

The map contains N (default 4) **play arena slots** in a hidden region of the workspace. Each slot has:
- A `RunnerSpawn` part
- A `GuideSpawn` part inside an enclosed booth
- A `PlayArea` empty folder (rooms get cloned in here)
- A `Booth` reference part / folder

When a duo starts:
1. Server picks an open slot.
2. Clones room templates from `ServerStorage/Rooms` into the slot's `PlayArea` folder.
3. Clones the booth template from `ServerStorage/GuideBooths` into the slot's `Booth` folder.
4. Teleports Runner to `RunnerSpawn` and Guide to `GuideSpawn`.
5. Locks the booth so the Guide cannot leave during the round.

When the round ends, all cloned children are destroyed and the slot is released.

## Roles

### Runner

The Runner:
- moves through the obby
- interacts with physical objects
- chooses buttons and doors
- experiences consequences
- reaches checkpoints

Runner UI should show:
- timer
- current objective
- mistakes
- simple prompts
- partner status

### Guide

The Guide is **stationed in a private booth** attached to the duo's play arena slot. They cannot follow the Runner physically.

The Guide:
- sees clue cards
- scans interactables
- activates bridge controls
- sees hidden correct choices
- receives short conversation prompts
- helps Runner avoid traps

The booth is a small enclosed room with:
- A control panel desk (interactive UI part on the front face)
- A transparent window or camera-view UI showing the Runner's current room
- Clue cards / manual displayed on a wall or screen

The Guide cannot leave the booth during a round. This forces communication via voice / chat instead of physical co-location.

Guide UI should show:
- current room manual
- scan results
- control buttons
- safety clues
- Runner camera/status
- round timer

## Room Design

### Room 1: Button Room

#### Player Experience

Runner enters a room with multiple buttons.

Some look helpful. Some are traps.

Guide has a manual showing suspicious signs and can scan button categories.

#### Example Buttons

- FREE PET
- SECRET ADMIN
- OPEN GATE
- DAILY REWARD
- CLICK FAST
- VERIFY ACCOUNT
- SAFE BRIDGE
- PASSWORD PRIZE

#### Correct Choice Logic

Correct button should usually be the boring/safe one, but not always obvious.

Suspicious features:
- urgency
- free reward
- secret
- password request
- too good to be true
- leaving the group

#### Consequences

Wrong button:
- slime splash
- harmless explosion
- fake coins vanish
- platform resets
- chickens spawn
- mistake count increases

Correct button:
- path opens
- trust points awarded
- next room unlocks

#### Hidden Lesson

Pause before clicking suspicious offers.

### Room 2: Bridge Builder

#### Player Experience

Runner sees disconnected platforms.

Guide sees a control panel with bridge pieces.

Guide must activate the correct sequence.

Runner must time jumps.

#### Mechanics

Guide controls:
- bridge toggle
- rotate platform
- freeze moving platform
- safe jump indicator

Runner mechanics:
- jump
- wait
- cross checkpoint
- signal ready

#### Hidden Lesson

Progress requires trust and communication.

### Room 3: Door Decoder

#### Player Experience

Runner sees 3 doors with NPC message bubbles.

Guide sees clue cards explaining warning signs.

Runner must choose the safest door.

#### Example Doors

Door A:
> "Come alone for a secret prize."

Door B:
> "Stay with your buddy and solve this puzzle."

Door C:
> "Tell me your real name first."

Safest: Door B

#### Consequences

Wrong door:
- sends Runner to mini-reset
- creates funny animation
- adds mistake

Correct door:
- opens next path
- awards trust points

#### Hidden Lesson

Avoid private stranger interactions and personal info requests.

## Optional Rooms

### Privacy Gate

Runner carries item blocks.

Guide has chart:
- okay to share
- ask first
- keep private

Runner sorts items correctly to open gate.

### Kindness Chat Maze

NPC says something mean.

Runner chooses response path.

Guide sees emotional meter.

Kind/calm choices open path.

Toxic choices darken maze or spawn obstacles.

### Rumor Relay

Runner hears changing messages from NPCs.

Guide sees original source.

Players identify the accurate message.

## Scoring

### Score Components

- Completion score
- Time bonus
- Mistake penalty
- Pause bonus
- Teamwork streak
- No-wrong-click bonus
- Room completion bonuses

### Ranks

- Bronze
- Silver
- Gold
- Perfect Trust Run

### Trust Seeds

Trust Seeds are awarded based on:
- finishing the run
- rank
- low mistakes
- perfect rooms

Trust Seeds upgrade the lobby/treehouse.

## Progression

### Lobby Treehouse

After runs, players return to a shared treehouse/garden.

Trust Seeds can:
- grow plants
- unlock decorations
- unlock trails
- unlock pets
- change booth skins
- unlock new room themes

For MVP:
- implement a simple TreehouseLevel number
- show visual upgrade stages if possible

## Tone

Use playful language.

Avoid:
- "cybersecurity module"
- "digital citizenship curriculum"
- "learning objective"
- "phishing assessment"
- "parent intervention"

Use:
- "trust"
- "buddy"
- "pause"
- "guide"
- "safe choice"
- "teamwork"
- "oops"
- "try again"

## Example End-of-Round Copy

Good:
> Nice run! You paused before risky choices and trusted your buddy.

Bad:
> You have completed the online safety education module.

## Tutorial

Keep tutorial very short.

Runner:
> You run, jump, and choose. Your Guide sees clues you do not.

Guide:
> You have the manual and controls. Help your Runner choose safely.

Both:
> Talk before big choices.

## Replayability Features

MVP:
- randomized button labels
- randomized correct button
- randomized door scenario
- timer
- ranks
- mistakes
- replay button

Post-MVP:
- room order randomization
- daily challenge
- cosmetics
- more rooms
- leaderboards
- badges
