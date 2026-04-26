# PHISH! — Fish Catalog

The data spec for every fish in the game. **`FishRegistry.lua` should read directly from the structure described here** so writers can edit content without touching code.

> *ASSUMED — confirm with user.* Specific fish names, lessons, and bobber cues below are first-pass fill-ins. The user almost certainly has their own canonical list in the missing portion of the original prompt. This doc is structured so rows can be replaced wholesale without restructuring.

## Schema

Each fish is a record with these fields:

```lua
{
    id = "free_robux_bass",
    displayName = "Free Robux Bass",
    category = "ScamBait",          -- ScamBait | Rumor | ModImposter | Kindness
    rarity = "Common",              -- Common | Rare | Epic | Legendary
    bobberCue = {                    -- visible to player at bite-time
        color = Color3.fromRGB(255, 215, 0),
        rippleStyle = "GlitterSplash",
    },
    correctVerb = "CutLine",        -- Cast | Verify | Reel | CutLine | Report | Release
    fieldGuideEntry = "Glittery and fast, but the gold dust is fake. The promise of free Robux is the lure — that's the whole scam.",
    lessonLineCorrect = "Smart move — anything that promises free in-game stuff for nothing is the bait.",
    lessonLineWrong = "Free Robux is never free. The bait took your XP — but you can recognize it next time.",
    xpReward = 10,
    spawnWeight = 30,                -- relative weight in pond spawn pool
    timeOfDay = { "Day", "Dusk" },  -- when this fish can spawn
}
```

## MVP Catalog (12 Fish)

### Scam Bait (3 fish)

| ID | Display Name | Rarity | Bobber Cue | Correct Verb | Lesson |
|----|--------------|--------|------------|--------------|--------|
| `free_robux_bass` | Free Robux Bass | Common | Gold sparkle, glitter splash | Cut Line | Free in-game currency offers are scams |
| `lottery_lobster` | Lottery Lobster | Rare | Confetti splash, rainbow ripple | Cut Line | "You won a prize you didn't enter" is always a scam |
| `link_shark` | Link Shark | Epic | Underline-shaped ripple, blue glow | Cut Line | Random links from strangers are dangerous; don't click |

### Rumor Fish (3 fish)

| ID | Display Name | Rarity | Bobber Cue | Correct Verb | Lesson |
|----|--------------|--------|------------|--------------|--------|
| `telephone_trout` | Telephone Trout | Common | Wobbly ripple, color shifts | Verify → Release | Things "your friend heard" often get distorted; check before sharing |
| `wiki_walleye` | Wiki-Forgery Walleye | Rare | Pages-fluttering ripple | Verify → Release | Anyone can edit the internet; check more than one source |
| `hallucinated_halibut` | Hallucinated Halibut | Epic | Translucent shimmer, pixel-glitch | Verify → Release | AI sometimes makes things up confidently; verify what it tells you |

### Mod Imposters (3 fish)

| ID | Display Name | Rarity | Bobber Cue | Correct Verb | Lesson |
|----|--------------|--------|------------|--------------|--------|
| `faux_mod_flounder` | Faux-Mod Flounder | Common | Fake-badge bobber, slightly off blue | Report | Real Roblox mods never DM you for your password |
| `pseudo_support_shark` | Pseudo-Support Shark | Rare | "Support" lifebuoy, wrong shade | Report | Real support doesn't ask you to share your account |
| `counterfeit_admin_cod` | Counterfeit-Admin Cod | Epic | Crown bobber, missing detail | Report | If "an admin" says you're in trouble unless you act fast, it's fake |

### Kindness Fish + True Catches (3 fish)

| ID | Display Name | Rarity | Bobber Cue | Correct Verb | Lesson |
|----|--------------|--------|------------|--------------|--------|
| `compliment_carp` | Compliment Carp | Common | Soft pink glow, gentle ripple | Reel → Aquarium | Kind words are real treasure; keep them |
| `helpful_hint_herring` | Helpful-Hint Herring | Rare | Warm yellow glow, calm splash | Reel → Aquarium | Genuine help looks calm and clear, not urgent or sketchy |
| `real_friend_rainbow` | Real-Friend Rainbow | Legendary | Slow rainbow shimmer, music sting | Reel → Aquarium | Real friends don't ask for things in exchange; they show up consistently |

## Stretch Catalog (post-MVP, ~6 fish)

Authored only if MVP locks early. Format identical to above.

- `crown_carp` (Scam Bait, Rare) — fake "you've been chosen" prizes
- `chain_letter_chub` (Rumor, Common) — "send this to 10 friends" forwards
- `urgent_urchin` (Scam Bait, Common) — "act now or lose your account" pressure
- `boss_phisher` (Scam Bait, Legendary) — boss-fish encounter combining all scam tactics
- `meme_minnow` (Kindness, Common) — funny stuff that is just funny stuff (always Reel)
- `verified_voucher` (Kindness, Rare) — actual confirmed-true info you should keep

## Authoring Rules

1. **One verb per fish.** Don't make a fish where multiple verbs are "kind of right." Ambiguity confuses the lesson.
2. **The correct verb must map to a real-world digital safety action.** Cut Line = refuse phishing. Verify = fact-check. Report = report. Reel = accept genuine. Release = unfollow/disengage.
3. **The bobber cue must be readable.** Players need to be able to *learn* the cues. Don't ship a fish whose cue is identical to a different-category fish.
4. **Lesson lines stay friendly.** Never scolding. Never adult-cybersecurity language. Test by reading aloud as if explaining to a 9-year-old.
5. **Lesson lines stay short.** One sentence. If you need two, the fish concept isn't tight enough.
6. **No real names of products or platforms** (don't write "Discord", "Snapchat") — keep it Roblox-internal-feeling. "DMs" and "in-game" are fine.

## Field Guide Entry Style

Each entry is the angler's lore-flavored description of the fish, **not** a safety lecture. Compare:

> **Bad** (lecture): *"This fish represents phishing scams. Phishing is when someone tries to trick you into giving them your password..."*

> **Good** (lore): *"Glittery and fast, but the gold dust comes off in your hands. The promise is the lure — and the promise is what you have to refuse."*

The lesson is delivered through the verb the player executes, not through reading the entry.
