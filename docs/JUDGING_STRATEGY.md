# Judging Strategy

## Main Positioning (Updated After Judge Conversations)

After follow-up conversations with the judges, we have direct validation and concrete framing guidance.

### The One-Line Pitch (the "explain to my boss" sentence)

The Roblox judge (Jenine) explicitly said she needs to be able to explain the game to her boss easily. That means we need ONE clear sentence that lands the problem, the mechanic, and the appeal at once. Use this as the headline:

> **Buddy Bridge is a 2-player co-op where the grownup has the safety rulebook and the kid has the actions — they have to talk to win, which is exactly the habit kids should build for the real internet.**

Variants for different audiences (use the one that fits the listener):

- **Engineer-leaning judge:** "It's Keep Talking and Nobody Explodes for kids and parents — one has the manual, one plays the level."
- **Civility / educator judge:** "It teaches kids to ask their grownup before risky online choices, by making 'asking' the actual mechanic."
- **Roblox boss-pitch:** "2-player asymmetric-info co-op. Parent gets the rules, kid gets the choices. Two polished levels covering stranger danger and online privacy. Built for Learn and Explore."

If a feature in the game can't be defended by the headline sentence, it doesn't ship.

### What The Judges Validated

After the follow-up conversation:

- **Educational angle is wanted.** Don't hide it — lead with it. The game could land in Roblox's **"Learn and Explore"** sort.
- **Two polished levels, not five shallow ones.** Depth proves the vision.
- **Stranger Danger framing is verified** (judge Andrew). He specifically called out classic archetypes — *the white van*, *the guy with the knife*, etc. — as the cues parents-as-Guide give to kids-as-Explorer. Bake those literal archetypes into NPC traits.
- **TSA / Backpack Checkpoint is verified** (judge Andrew). Keep it.
- **The mechanic IS the pitch hook** (judge Andrew): "education game where you give hidden information for one person who knows something and relays it to the other for life skills." Lead every conversation with this one sentence.
- **Visual consistency matters** (judge Andrew). One coherent art style across lobby, both levels, NPCs, items, booth. No franken-game.
- **Reference comp** (judge Jenine): *Ecos La Brea* on Roblox — educational MMO that doesn't feel like homework. Aim for that bar.

### The Three-Filter Test (Jenine's checklist)

Every design call should answer yes to these:

1. **Is the problem clear?** Not vague. Not "civility writ large". A specific, narrow thing: kids don't pause to ask a trusted adult before risky online choices.
2. **Does it have potential impact?** Real habit-building, not test-prep. The same way kids learn anything that sticks: by repeated low-stakes practice with someone they trust.
3. **Will people actually want to play?** A 2-player co-op with talking and choices is fun by default. We're not asking kids to read.

## Why This Fits Roblox

Roblox players already love:
- 2-player co-op puzzlers
- talking-and-doing party games
- treehouse / garden progression
- playing with parents and siblings

Buddy Bridge uses those native patterns instead of forcing a school lesson into Roblox.

## Why This Fits "Learn and Explore"

Most "educational" Roblox experiences feel like quiz shells. Buddy Bridge teaches a **habit** — *pause, ask your buddy, then decide* — through the only way habits actually form, which is repeated low-stakes practice. The mechanic IS the lesson.

The closest existing comp on Roblox is **Ecos La Brea** (Jenine's reference): genuinely educational, but it doesn't break the world to teach. Buddy Bridge aims for the same bar.

We have two distinct concepts, each with its own polished level:

1. **Stranger Danger Park** — recognizing risky strangers and asking a trusted adult before engaging. Classic archetypes (white van, person with a knife, stranger asking your name) appear as concrete NPC scenes.
2. **Backpack Checkpoint** — privacy and what's OK to share online (digital citizenship), themed as TSA-style luggage sorting so it stays kid-friendly.

## Judge-Specific Strategy

### Roblox Studio Engineer Judge

What they care about:
- Is this actually fun?
- Does it use Roblox well?
- Is the gameplay clear in 30 seconds?
- Real execution, not a demo prototype?

Show them:
- the lobby, capsule pairing, role select
- live 2-player play of Stranger Danger Park
- the live annotation flow (Guide presses 🚩, ring appears around NPC for Explorer)
- the conveyor belt in Backpack Checkpoint
- replay flow
- clean implementation under the hood

Lead with the mechanic, not the lesson. The fun lands first.

### Civility Team Judge

What they care about:
- parent-child trust
- starting real conversations
- digital citizenship
- real impact

Show them:
- the Guide booth (the parent's seat)
- how the manual gives the Guide real authority — they're not just watching
- Stranger Danger Park's NPC traits and the warning-sign manual
- Backpack Checkpoint's Pack It / Ask First / Leave It (the "ask first" lane is a deliberate design choice — it teaches that asking is a valid option, not a fallback)
- end-of-round message

Lead with: *"The grownup has the manual the kid doesn't. They have to talk."*

### Third Judge (parent-child fit)

What they care about:
- not feeling like school
- parents and kids naturally playing together
- Grow-a-Garden-style cozy shared experience

Show them:
- the cozy lobby treehouse
- Trust Seeds growing the garden after runs
- the kid-friendly tone (Cartoon font, friendly NPC art, no scary visuals)
- replayability through randomization

Lead with: *"This is the kind of game a parent can hand a kid and play alongside, not a worksheet."*

## Pitch Structure

### 1. Hook

> Buddy Bridge is a 2-player safety game where one player explores and the other has the manual. To win, you have to talk.

### 2. Problem

> Most online safety games for kids feel like quizzes. Kids tune them out. We wanted to make the safe behavior the gameplay itself.

### 3. Solution

> The Explorer sees the situation. The Guide has the rules. They have to pause, talk, and choose together — exactly the habit we want kids to build with their grownups.

### 4. Two Levels

> Stranger Danger Park: a friendly park with classic stranger-danger scenes — a white van off to the side, a person with a knife in the alley, a stranger asking your name. Your buddy has the warning manual. You decide who to talk to. Find the lost puppy by gathering clues from the safe people.
>
> Backpack Checkpoint: TSA-style sorting. Items come down a conveyor. Your buddy has the chart. You decide what goes in Pack It, Ask First, or Leave It. It's privacy and digital citizenship without ever using those words.

### 5. Why Two Polished Levels

> You told us to go deep on one or two — we did. Both levels randomize every run, so replays aren't memorization. The framework supports more levels post-hackathon.

### 6. Roblox Fit

> 8 players per server, up to 4 simultaneous duos, each in their own private slot. Consistent cartoon styling end-to-end so it reads as one cohesive game, not a hackathon mash-up. Already shaped to live in the "Learn and Explore" sort if it ships there.

## Demo Lines

Use lines like:

> The grownup has the manual the kid doesn't. That asymmetry IS the lesson.

> Notice how the kid never reads a popup that says 'don't share your address'. They just learn to throw the glowing house into the Leave It bin because their buddy told them to.

> Every NPC's traits randomize each run, so the Guide can't memorize 'avoid the guy in the red hat'. They have to actually read the manual.

> The Ask First lane in Backpack Checkpoint is intentional. We wanted the game to teach that asking your grownup is a valid choice — not a punishment.

## Avoid Saying

Avoid:
- "cybersecurity training"
- "PII"
- "phishing"
- "safety curriculum"
- "we quiz the player"

Use:
- "safety habit"
- "ask your buddy"
- "buddy with the manual"
- "co-op"
- "Learn and Explore"
- "two polished levels"
- "randomized every run"

## Final Pitch

Buddy Bridge is a 2-player kid-and-grownup safety game. One of you explores. The other has the manual. To win, you pause, talk, and choose together — exactly the habit kids should build online with their trusted adults.

We focused on two levels, polished deep. Stranger Danger Park is a Keep-Talking-and-Nobody-Explodes-style park scene where the Explorer can talk to NPCs but only the Guide knows which ones are risky. Backpack Checkpoint is a TSA-style sorting station that teaches digital citizenship — what's OK to share — without ever using lecture words.

The judges told us to go deep on one or two levels and they'd see the vision. So we did. The framework supports more concepts post-hackathon, but for the demo, two polished, replayable levels carry the whole story.
