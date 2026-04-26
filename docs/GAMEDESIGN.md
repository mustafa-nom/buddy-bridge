# PHISH! — Game Design

> **One-liner:** A cozy Roblox fishing game where every fish you reel in is a real online-safety moment in disguise.

> **Core fantasy:** *"I am a digital angler exploring the internet ocean, catching weird scam fish, rare truth fish, kindness fish, and boss phishers."*

## Premise

The Internet Ocean is being polluted by scam bait, fake links, rumors, AI hallucinations, fake moderators, and toxic messages. Real catches — kindness, friends, accurate info — still swim in there too. The player restores safe waters by **catching the right things in the right way**.

The verb the player executes **is** the digital safety lesson. There are no quizzes. There is no lecture popup. The game is fun on its own; the education is the gameplay.

## Player Model

**Solo-first.** A kid loads in, picks up the rod, casts, catches fish, fills the aquarium. Complete experience without anyone else.

**Optional Buddy Mode** (post-MVP): a second player can join with the Field Guide open and coach the angler over voice/chat. Maps cleanly to the existing Buddy Bridge plumbing — kept around for parent/kid appeal but not required for the demo.

## The Four Fish Categories

> *ASSUMED — confirm with user once full prompt content received.*

Each fish category maps to one digital-citizenship theme. The category is hinted by the **bobber color and ripple pattern** (visible cue) but only confirmed after the player either Verifies or commits.

### 1. Scam Bait 🪝

**Real-world theme:** Phishing, fake giveaways, "free Robux", suspicious links, scam DMs.

**Visual cue:** Glittery / gaudy bobber. Loud splash. Often shaped like loot.

**Correct verb:** **Cut Line.** The right move is to refuse the catch entirely. Anything that promises something for nothing is the lure.

**Wrong verb:** Reeling — you "catch" the bait, lose XP, and the fish dissolves into seaweed.

**Examples:** Free Robux Bass, Crown Carp, Lottery Lobster.

### 2. Rumor Fish 💭

**Real-world theme:** Misinformation, AI hallucinations, "I heard from a friend", made-up facts.

**Visual cue:** Shifting / shimmering bobber that looks slightly *off*. Color flickers.

**Correct verb:** **Verify.** Open the Field Guide before reeling. The Field Guide will tell you whether this fish's "fact" is real or made up. If real → reel. If made up → release.

**Wrong verb:** Reeling without Verify — you spread the rumor downstream and a school of small Rumor Fish appears, polluting the pond.

**Examples:** Telephone Trout, Hallucinated Halibut, Wiki-Forgery Walleye.

### 3. Mod Imposters 🎭

**Real-world theme:** Fake admins, fake support, "Roblox Staff" DMs asking for your password, scammers impersonating authority.

**Visual cue:** Bobber that looks official — fake badge, fake uniform color. *Almost* right but not quite.

**Correct verb:** **Report.** A short report animation, the imposter dissolves, and a real "True Authority" fish briefly appears as a thank-you visual.

**Wrong verb:** Reeling — the imposter "takes your stuff" (XP loss + a "they tricked you" learning beat).

**Examples:** Faux-Mod Flounder, Pseudo-Support Shark, Counterfeit-Admin Cod.

### 4. Kindness Fish + True Catches ✨

**Real-world theme:** Genuine compliments, real friends, accurate info, helpful behavior.

**Visual cue:** Soft glow, gentle ripple, warm color. Calm.

**Correct verb:** **Reel** (and optionally **Place in Aquarium**). These are the keepers. Highest XP, journal-worthy, fill the aquarium.

**Wrong verb:** Cutting Line — you lose a kind interaction. Small XP penalty + a "you let a good one go" beat.

**Examples:** Compliment Carp, Helpful Hint Herring, Real-Friend Rainbow.

## The Verb Set

The player has six possible actions per encounter. Choosing the right verb for the fish is the entire game.

| Verb | What it does | Lesson |
|------|--------------|--------|
| **Cast** | Throw the lure into the water | Engagement (you have to participate to learn) |
| **Wait** | Passive — bobber settles, fish approaches | Patience before judging |
| **Verify** | Open Field Guide entry for this bobber type before reeling | Fact-check before believing |
| **Reel** | Commit to bringing the fish in | Accept genuine things |
| **Cut Line** | Refuse the catch entirely | Refuse phishing / scams |
| **Report** | Flag the catch as an imposter | Report fake authority |
| **Release** | Reel in then immediately release (post-Verify) | Unfollow / mute / don't engage further |

## Rarity Tiers

Rarity drives chase + replayability. It does **not** correlate with how dangerous a fish is — Common Scam Bait is just as harmful as a Legendary Scam Bait, just less rare to encounter.

| Tier | Spawn weight | Visual | Reward |
|------|--------------|--------|--------|
| Common | ~60% | Standard | Base XP |
| Rare | ~25% | Small particle aura | 2x XP, journal entry |
| Epic | ~12% | Glow + larger silhouette | 4x XP, journal + aquarium slot |
| Legendary | ~3% | Pond-wide effect, music sting | 10x XP, named aquarium fish, cosmetic |

## Aquarium / Collection Loop

- Every successfully-handled fish (correct verb) unlocks a Field Guide entry.
- Kindness Fish + True Catches can be placed in the player's aquarium.
- Aquarium is visible in the Lodge (lobby) — encourages return visits.
- Filling categories of the journal grants cosmetics (rod skins, lure colors, hat).

## Why This Doesn't Feel Like Homework

- **No quiz screens.** Ever. The Field Guide is a fishing journal, not a test.
- **The lesson is downstream of the verb, not upstream.** You catch first, learn after.
- **Wrong choices are funny, not punishing.** Cutting a Kindness Fish gives a little sad-trombone "you let a good one go" — kid laughs, learns, keeps fishing.
- **Reference comp:** *Ecos La Brea* — educational MMO that doesn't feel like one. Aim for that bar.

## Replayability

- Randomized fish spawn order per session
- Bobber cues vary slightly so memorization-only doesn't work
- Time-of-day variants (Golden Hour Cove vs. Foggy Cove) gate certain fish
- Rarity chase + aquarium completion
- Post-MVP: weather, multiple ponds, boss fish, seasonal events

## Out of Scope (do not build)

- Boss fish
- Multiple ponds beyond Starter Cove
- Buddy Mode UI
- DataStore persistence
- Cosmetics shop / currency economy
- Trading

These live in `docs/PHISH_MVP_PLAN.md` under "Cut for MVP" so they don't sneak in.
