# Buddy Bridge Game Design

## High-Level Concept

Buddy Bridge is an asymmetric 2-player co-op safety game.

One player (the **Explorer**) walks through the level, meets characters, and handles items.

The other player (the **Guide**) stays in a private booth with a manual of warning signs and safety rules.

The Explorer can act, but doesn't know which choices are safe. The Guide knows the rules, but can't physically intervene. They must communicate to win.

This is intentionally **Keep Talking and Nobody Explodes** for kids — except the "manual" teaches real digital safety habits, and the Guide is meant to feel like the Explorer's grownup partner.

## Educational Framing

After follow-up conversations with the LAHacks judges, the educational angle is now front-and-center, not hidden. Buddy Bridge is positioned for Roblox's **"Learn and Explore"** sort:

- Kid-and-grownup co-op safety game.
- Two polished levels covering distinct concepts:
  1. **Stranger Danger Park** — recognizing risky strangers, asking a trusted adult, gathering safe info.
  2. **Backpack Checkpoint** — privacy and what's OK to share online (digital citizenship), themed as TSA-style sorting so we never break the kid-friendly tone.
- The lessons are taught **through the mechanic**, never via lecture popups.
- The judges said: *focus on 1–2 super polished levels and we'll see the vision*. Depth beats breadth.

## Design Pillars

### 1. Fun First, Educational Second

The game must play well as a co-op puzzler even before the lesson lands.

### 2. Asymmetric Co-op

Each player has different information and different abilities.

### 3. Replayable Levels

Levels randomize NPC traits, clue placement, and item rotations every run.

### 4. Education Through Mechanics

The lesson is always an action:
- pausing before talking to a stranger
- listening to your buddy before opening a door
- physically tossing a "private" item into the Leave It bin

### 5. Parent-Child Trust

The Guide is implicitly the grownup partner. The Explorer is implicitly the kid. The game gives them a real, low-stakes reason to talk.

### 6. One Cohesive Visual Style

Judge Andrew flagged this directly: consistent styling across the whole game. One cartoon palette, one prop language, one font, one NPC art style, one item art style, one UI feel. The lobby, both levels, the booth, the score screen, and the lobby treehouse should all read as parts of the same game — not a hackathon collage.

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

Pairs of capsule pads sit around the lobby (default 4 pad pairs).

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

After pairing, the duo enters role select:
- One picks Explorer, the other picks Guide.
- Auto-assigns if they don't choose in time.
- A **Start Round** button appears.
- When pressed, the round begins, the play area is built, and both players teleport in.

## Play Area Slots

The map contains N (default 4) **play arena slots** in a hidden region of the workspace. Each slot has:
- An `ExplorerSpawn` part
- A `GuideSpawn` part inside an enclosed booth
- A `PlayArea` empty folder (level templates get cloned in here)
- A `BoothAnchor` part where the booth template aligns

When a duo starts:
1. Server picks an open slot.
2. Clones both level templates from `ServerStorage/Levels` into the slot's `PlayArea` folder, positioned next to each other so the Explorer can portal between them.
3. Clones the booth template into the slot's `Booth` folder.
4. Teleports Explorer to the first level's entry point and Guide to `GuideSpawn`.
5. Locks the booth so the Guide cannot leave.

When the round ends, all cloned children are destroyed and the slot is released.

## Roles

### Explorer

The Explorer is the action / decision player.

They:
- walk through the world
- approach NPCs and decide whether to engage
- pick up and sort items
- make the actual final choice in any decision

Explorer HUD should show:
- timer
- current micro-objective ("Find 3 clues about the puppy")
- Guide annotations on nearby NPCs/items (if Guide flagged them)
- mistakes
- partner status

### Guide

The Guide is **stationed in a private booth**. They cannot physically follow the Explorer.

They:
- read the manual for the active level
- watch the Explorer through a window or camera UI
- send annotations to the Explorer ("this NPC = 🚩")
- talk over voice / chat to coordinate

Guide UI should show:
- the active manual page
- live Explorer position / current target
- annotation buttons (✅ Safe / 🚩 Risky / ⚠️ Ask first)
- timer
- score / progress

The booth has thick walls and no door. Communication is the only output.

## Level 1: Stranger Danger Park

### Setting

A small, friendly park / town plaza. Trees, benches, a fountain, a hot dog stand, a parked car off to the side, a back alley behind a shop. Bright, kid-readable color palette — not a horror map.

### Quest Framing

Each round opens with a small NPC scene:
- A child NPC says "I lost my puppy! Can you help me find them?"
- The Guide sees: "Find 3 clues about the puppy from safe people. Avoid risky strangers."

The puppy spawns at a randomized location at round start. Three clue fragments are distributed to three randomly-chosen safe NPCs. Once all 3 clues are collected, a sparkle leads the Explorer to the puppy.

### NPCs

A pool of 6–8 NPCs spawn at fixed positions but with **randomized traits and roles** each round. Each NPC has 1–3 visible **traits** drawn from a shared trait pool. The server assigns each NPC one of three roles:

- **Safe with clue** (3 NPCs, randomly chosen)
- **Safe but no clue** (2 NPCs)
- **Risky** (2–3 NPCs)

### Trait Pool (visible to Explorer; cross-referenced by Guide manual)

Lean into classic, **recognizable** stranger-danger archetypes. Judge Andrew specifically validated using cues like the white van, the person with a knife, and strangers asking for personal info. These are the cues parents already use with kids; the game just makes them playable.

🚩 Risky traits:
- "Calling you over from inside a **white van**"
- "Holding a **knife** in the alley behind the shop"
- "Asking your **real name and school**"
- "Offering candy or game items to come with them"
- "Wants you to come somewhere private / out of the crowd"
- "Standing alone in a place adults don't usually hang out"

✅ Safe traits:
- "Behind the counter at the hot dog stand, wearing an apron"
- "Wearing a uniform and helping multiple customers"
- "With their kids in the playground"
- "A police officer / park ranger in uniform"
- "Sitting on a public bench reading a book, ignoring you"

### Scene Anchors (the "different backgrounds and scenes" judge Andrew described)

Each NPC spawn is anchored to a distinct sub-scene of the park, so the level reads as a series of recognizable vignettes rather than a homogeneous mob. This is intentional — judges should be able to point at a scene and name the lesson.

Required sub-scenes:

- **The white van** (parking spot off to one side) — risky archetype anchor
- **The alley behind the shop** — risky archetype anchor
- **The hot dog stand / shop counter** — safe archetype anchor (uniformed worker)
- **The playground** — safe archetype anchor (parent with kids)
- **The ranger booth / officer post** — safe archetype anchor
- **The public bench / fountain area** — neutral / safe archetype anchor

Roles randomize per run, but the scene backdrops stay consistent so the visual association sticks.

### Loop

1. Explorer approaches an NPC. Server reveals their traits via a small description card visible to both Explorer and Guide.
2. Guide reads manual, calls out: "Looks safe — ask about the puppy" or "Stay away".
3. Optional: Guide presses ✅ / 🚩 annotation button so a colored ring appears around that NPC for the Explorer.
4. Explorer either walks away or triggers a second prompt: "Talk to them".
5. Server validates:
   - Safe NPC + has clue → reveals a clue line ("I think I saw a fluffy pup near the fountain") and emits a clue collected event.
   - Safe NPC, no clue → friendly small talk, no penalty.
   - Risky NPC → consequence (Explorer trips and runs back to spawn point of the level / brief slowdown / mistake counter +1). Funny, not scary.
6. After 3 clues collected, a sparkle path appears toward the puppy.
7. Reaching the puppy completes the level.

### Hidden Lessons (taught by mechanic, never stated)

- Pause before approaching a stranger.
- Trust your grownup's read on the situation.
- Some "free candy / private prize" offers are red flags.
- Safe adults are usually doing a job or with their family.

## Level 2: Backpack Checkpoint

### Setting

A bright, cartoon airport-style checkpoint. A conveyor belt feeds items past the Explorer. Three colored bins sit on the wall:

- ✅ **Pack It** (green bin) — OK to share online
- ⚠️ **Ask First** (yellow bin) — gray area
- ⛔ **Leave It** (red bin) — keep private

### Theme Note

This is a digital citizenship lesson disguised as TSA-style luggage sorting. We never use direct labels like "your address". Each item is a physical stand-in.

### Item Pool

🟢 Pack It:
- A controller = favorite game
- A paint palette = favorite color
- A funny meme card = a joke
- A pet drawing = drawing of your pet

🟡 Ask First:
- A name tag with a real name handwritten = real name
- A polaroid of yourself = personal photo
- A balloon with a date floating above it = birthday
- A trophy = a big achievement

🔴 Leave It:
- A glowing house model = home address
- A school crest banner = school name
- A padlock card = a password
- A phone with a number floating above = phone number
- A locked diary = private secret

### Loop

1. An item appears at the start of the conveyor.
2. The Guide sees the chart and can press ✅/⚠️/⛔ to annotate the item for the Explorer.
3. The Explorer either picks up the item and carries it to a bin, or stands near a bin and triggers the corresponding ProximityPrompt.
4. Server validates:
   - Correct lane → item disappears in a sparkle, +trust points, conveyor advances.
   - Wrong lane → buzzer SFX, item bounces back to belt, mistake counter +1.
5. After N items (default 6), level completes.

### Hidden Lessons

- Some info is fine to share, some isn't, and "ask a grownup first" is its own valid choice.
- Sorting is a real act, which makes the concept stick better than reading it on a popup.

## Future / Cut Levels

Not in MVP. Listed for the team's future reference only.

### Bridge Builder

Cooperative timing — Guide activates platforms while Explorer crosses.

### Door Decoder

Three doors with NPC chat bubbles; pick the safe message. Concept overlaps with Stranger Danger Park, so we cut it.

### Kindness Chat Maze

NPC says something mean. Explorer picks a response path. Guide sees emotional meter.

### Rumor Relay

A rumor changes between NPCs as it spreads. Guide sees the original; Explorer must identify the truth.

## Scoring

### Score Components

- Level completion bonus (per level)
- Time bonus
- Mistake penalty
- Trust streak bonus (consecutive correct calls)
- Clue/item perfect bonus

### Ranks

- Bronze
- Silver
- Gold
- Perfect Trust Run

### Trust Seeds

Trust Seeds are awarded based on:
- finishing the round
- rank
- low mistakes
- perfect levels

Trust Seeds upgrade the lobby treehouse / garden visually.

## Progression

### Lobby Treehouse

Returning to the lobby after a run shows a treehouse / garden that grows.

For MVP:
- track a `TreehouseLevel` integer per player or per duo
- show a few visual upgrade stages (sapling → small tree → flowering tree → tree with treehouse)

## Tone

Use playful, age-appropriate language.

Avoid:
- "cybersecurity module"
- "digital citizenship curriculum"
- "phishing assessment"
- "intervention"
- explicit naming of categories like "PII"

Use:
- "buddy"
- "pause"
- "ask your grownup"
- "safe choice"
- "Pack it / Ask first / Leave it"
- "Looks risky — let's pass on that one"

## Example End-of-Level Copy

Good:
> Nice run! You paused before risky strangers and asked your buddy.

Bad:
> You have completed the online safety education module.

## Tutorial

Keep tutorial extremely short. Two lines per role, max.

Explorer:
> You walk, talk, and pick things up. Your buddy has the manual you don't.

Guide:
> You have the safety manual. Read what your buddy sees and tell them what's risky.

Both:
> Talk before big choices.

## Replayability Features

MVP:
- randomized NPC traits + roles in Stranger Danger Park
- randomized clue distribution
- randomized item rotation in Backpack Checkpoint
- timer + ranks
- mistakes
- replay button
- Trust Seeds + treehouse growth

Post-MVP:
- additional levels
- daily challenge
- cosmetics
- leaderboards
- badges
