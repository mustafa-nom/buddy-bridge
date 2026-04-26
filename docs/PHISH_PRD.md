# PHISH — Product Requirements (Canonical Design)

> **Spot the scam. Save the sea.** A Roblox MMO fishing game where the fish are scams. Cast a line, reel in suspicious messages, and decide: KEEP it or CUT BAIT.
>
> Built for the Roblox Civility Challenge (36-hour jam). This document supersedes the prior "PHISH!" 6-verb design — older docs (`docs/GAMEDESIGN.md`, `docs/PHISH_CORE_LOOP.md`, `docs/PHISH_CONTENT.md`, `docs/PHISH_MVP_PLAN.md`) are kept for reference but should not be treated as authoritative.

## 1. Vision & pillars

PHISH flips digital-safety games. Kids are not the prey — they're the **hunters**. The Phishing Sea is full of scams disguised as messages; players become anglers who learn to spot them by catching them. Education is delivered entirely through gameplay (no tutorials, no quizzes, no NPCs lecturing).

Five pillars:
1. **Familiar loop** — copy the cast/reel/inspect rhythm of beloved Roblox fishing games.
2. **Stealth education** — every mechanic teaches a real digital-literacy skill.
3. **Empowerment, not fear** — Coast Guard rank, not survivor mode.
4. **Repetition with variation** — hundreds of scam examples for pattern recognition.
5. **Social by design** — civility is the path to the highest tier, not a side note.

## 2. Core loop

```
Spawn at dock
  → Equip rod, walk to water
  → Cast line, water ripples
  → Bite hits, rhythm mini-game to reel
  → Inspection card surfaces showing scam content
  → Inspect (sender, body, links)
  → Decide: KEEP (legit) or CUT BAIT (phish)
  → Result animation + feedback card
  → Coins added, Phish-Dex updated, XP gained
  → Loop
```

A full catch cycle should take **20–45 seconds** depending on difficulty. Players should land 30–50 catches in a 20-minute session.

## 3. Zones

MVP ships only **Inbox Lake**. Other zones are designed but not built:

| Zone | Theme | Real-world skill |
|------|-------|------------------|
| **Inbox Lake** (MVP) | Email phishing | Sender/link inspection |
| DM Bay | Social media DMs | Discord/Insta scams |
| The Stream | SMS smishing | Fake delivery/bank texts |
| Voice Cove | Vishing | Robocalls, fake tech support |
| Crypto Reef | Investment scams | Pump and dump |
| The Deep | Spear phishing & deepfakes | Targeted attacks |
| Shopper's Cove | E-commerce scams | Fake stores / giveaways |

Visual aesthetic differs per zone (Inbox Lake = bright sunny; The Deep = dark foggy). Visual language reinforces difficulty.

## 4. Phish-Dex (scam species)

Pokedex-style collection. Catching 3–5 of a species unlocks the full dex entry (real-world info). Full data lives in `docs/PHISH_PHISH_DEX.md`. MVP ships the first 6:

| Species | Real pattern | Tell |
|---------|--------------|------|
| Urgency Eel | Time pressure | "Account closes in 24 hours!" |
| Authority Anglerfish | Impersonation | Fake IRS, fake bank, fake police |
| Reward Tuna | Too good to be true | "You won a free iPhone!" |
| Curiosity Catfish | Clickbait | "You won't believe..." |
| Fear Bass | Threat-based | "Suspicious login detected!" |
| Familiarity Flounder | Social engineering | "Hey it's me, remember?" |

Plus at least one **legit fish** (clean, normal-looking) for the cards that should be KEPT.

Post-MVP: Spear Marlin, Whale, Clone Cod, Romance Ray, Crypto Kraken, Deepfake Dolphin.

## 5. Tackle (upgrades)

| Tool | What it does | Real skill it teaches |
|------|--------------|-----------------------|
| **URL Magnifier** (MVP) | Hover any link in a card to see true destination | Hover-to-preview |
| **Vibe Check Goggles** (MVP) | Highlights manipulation words in red | Emotion-bait awareness |
| Header Hook | Reveals sender's true email | Sender verification |
| Source Sonar | Cross-references claims | Source verification |
| Reverse Image Lure | Flags stolen profile pics | Reverse image search |
| Two-Factor Tackle | Protects against one scam loss/day | MFA value |

MVP = URL Magnifier + Vibe Check Goggles, both implemented as highlight effects on the inspection card.

## 6. Roles (civility as a hard mechanic)

Three tiers, earned through play:

- **Angler** (default) — cast, catch, build collection.
- **Coast Guard** — top players (≥80% accuracy across ≥50 catches). Can broadcast a server-wide warning when they spot a species spike. Special hat. Earns mentor XP for helping new players.
- **Harbor Master** — one per server, rotates every 5 minutes. Highest-scoring active Coast Guard. Can call server-wide events. Crown cosmetic.

## 7. Boss & events

- **The Phisherman** (MVP boss) — recurring NPC scammer. Appears every ~7 minutes at a designated spawn. Players ID three of his disguises across catches to "build a case" and arrest him. Reward: rare cosmetic for top contributor.
- **The Kraken of Lies** (post-MVP) — multi-player deepfake fight.
- **Pollution events** — when too many players miss, water turns murky. Server has to hit a collective accuracy threshold.
- **Holiday frenzies** — IRS scams in March/April, fake-delivery in November, romance in February. Real-world timing means kids learn the scam right before they encounter it.

## 8. Inspection card (the most important UI)

This is where 90% of the game happens. It must feel great. Card shows:

- **Sender:** name, email/handle, profile-pic color
- **Subject** line
- **Body** (formatted like a real email/DM)
- **Links** (with display text vs. true URL)
- **Attachments** (if any)

Tools (URL Magnifier, Vibe Check Goggles) highlight suspicious bits in red on hover/tap.

Two large bottom buttons: **KEEP** (green, fish icon) and **CUT BAIT** (red, scissors icon).

Optional decision timer based on difficulty (Easy = unlimited, Hard = 5s).

## 9. Aesthetic

Cozy. Bright. Low-poly. Animal Crossing meets a wholesome dock. Warm sunset palette (oranges, soft blues, sandy beige). Threat colors only on actual scam reveals.

**Phish fish look subtly wrong:** glitchy textures, mismatched scales, weird colors, eyes too big or in wrong places. Real fish look clean and natural. Visual literacy reinforces lesson literacy.

Music: chill lo-fi, looping ocean ambience. Light "ding" on correct catch. Soft "bonk" on wrong catch (never punishing).

## 10. Data shapes (User 2 reference)

### ScamCard (one per fishable item)

```lua
{
  id = "phish_urgency_001",
  zone = "InboxLake",
  isLegit = false,
  species = "UrgencyEel",         -- maps to fish FishId
  difficulty = 2,                  -- 1..5
  sender = {
    name = "PayPal Security",
    address = "security@paypa1-verify.com",
    avatarColor = Color3.fromRGB(0, 70, 173),
  },
  subject = "URGENT: Account suspended in 24 hours",
  body = "Dear Customer,\n\n...",
  links = {
    { displayText = "Verify Now", trueUrl = "http://paypa1-secure.ru/login" },
  },
  redFlags = {
    { element = "sender.address", reason = "Domain has typo (paypa1 not paypal)" },
    { element = "subject",        reason = "Urgency language" },
    { element = "links[1]",       reason = "URL doesn't match displayed company" },
  },
  reward = { xp = 15, coins = 5 },
}
```

Catalog of MVP cards lives in `docs/PHISH_SCAM_CARDS.md`.

### PhishDex species (one per species)

See `docs/PHISH_PHISH_DEX.md` for the full catalog. Schema:

```lua
{
  id = "UrgencyEel",
  displayName = "Urgency Eel",
  realPatternName = "Urgency-based phishing",
  rarity = "Common",
  description = "Slippery and fast. Rushes you into bad decisions.",
  realWorldInfo = "Scammers create fake time pressure to bypass critical thinking.",
  redFlags = { "Time-based threats", "All-caps subject lines", "Account-closure threats" },
  defenseStrategy = "Pause. Real urgent issues can be resolved by calling the company directly.",
  catchesToUnlock = 3,
  iconAsset = "rbxassetid://...",
}
```

### PlayerData (DataStore)

```lua
{
  coins = 0,
  totalCatches = 0,
  correctCatches = 0,
  accuracy = 0.0,
  role = "Angler",                       -- Angler | CoastGuard | HarborMaster
  unlockedSpecies = { UrgencyEel = 5 },  -- count per species
  unlockedTackle = { "BasicRod", "URLMagnifier" },
  equipped = { rod = "BasicRod", tackle = "URLMagnifier" },
  civicXP = 0,
  lastSession = 0,
}
```

## 11. Client/server split

**Server owns:** all scam card data (so client can't peek at `isLegit`), catch random selection, score validation, DataStore persistence, role assignment, boss event scheduling.

**Client owns:** cast input + rod animation, reel mini-game, inspection UI rendering, tackle inspection effects (highlights), HUD updates.

The KEEP/CUT BAIT decision goes server-side for validation; server returns result + the card's `redFlags` for the feedback panel.

## 12. Studio file structure (target)

```
PHISH (Place)
├── Workspace
│   ├── PhishMap (built by User 1)
│   │   ├── PhishIsland, PhishLodge, PhishDock, PhishWater (~128 tiles), PhishBoat
│   │   ├── PhishFishermanShop, PhishSellShop, PhishPolish
│   │   ├── PhishNpcAngler        (NEW — give-rod NPC)
│   │   ├── PhishBoardOfFame      (NEW — leaderboard SurfaceGui)
│   │   └── PhishermanSpawn       (NEW — invisible spawn for The Phisherman)
│   └── (default Roblox stuff)
├── ReplicatedStorage
│   ├── PhishFishTemplates  (8 species — 6 phish + 2 legit, built by User 1)
│   ├── PhishBobbers, PhishLures
│   ├── ScamCards (User 2 — ModuleScript with all card data)
│   ├── PhishDex (User 2 — ModuleScript with species data)
│   └── Tackle, Remotes, SharedConstants (User 2)
└── ServerScriptService, StarterPlayer, StarterGui (all User 2)
```

## 13. Phases (36-hour timeline)

- **Phase 0 — Pre-flight (1.5h):** lock design, prep assets.
- **Phase 1 — Foundation (3h):** dock, water, NPC angler, rod tool, ambient. **(Map ✓ done; rod tool is User 2.)**
- **Phase 2 — Core loop (8h):** cast → reel → inspect → decide → result with one card. (User 2.)
- **Phase 3 — Content & Phish-Dex (6h):** 20 cards, 6 species data, dex UI. (User 2 + content.)
- **Phase 4 — Multiplayer & Roles (6h):** leaderboard, Coast Guard, Harbor Master, Phisherman event. (User 2.)
- **Phase 5 — Polish & feel (6h):** SFX, particles, juice. (Shared.)
- **Phase 6 — Submission (2.5h):** publish, video, writeup.

## 14. Cut-scope plan

**Must have:** Inbox Lake (one zone), full cast→reel→inspect→decide loop, 15+ cards, 6 species in dex, coin/accuracy tracking, HUD with role badge, ≥2 players seeing each other, title splash + welcome sign.

**Nice to have (cut first):** rhythm reel mini-game (replace with one-click), Phisherman event (replace with "every 5min, hardest card"), Coast Guard broadcast button, Harbor Master rotation, particle polish, second tackle, server-wide leaderboard.

**Won't have (post-jam):** other zones, custom 3D fish, voice acting, trading, daily challenges, holiday events, advanced tackle, mentor system.

## 15. Win condition (judging rubric mapping)

- **Progress & Development:** scoping a single zone at high polish > five zones half-done.
- **Storyboarding & Message Quality:** the lesson lives in the loop. Story = "the sea was once clean, scammers polluted it, anglers are taking it back."
- **Potential Impact:** the empowerment reframe is the X-factor. Pattern recognition through play maps to durable real-world behavior.

## 16. Submission checklist

- [ ] Game published as public Roblox experience
- [ ] Thumbnail set (sunset dock + title)
- [ ] Description includes educational angle
- [ ] Tags include "education," "safety," "civility"
- [ ] Tested with 3+ concurrent players
- [ ] No critical bugs in core loop
- [ ] Demo video (60–90s) recorded and uploaded
- [ ] Writeup drafted addressing all 3 judging criteria
- [ ] Submitted before deadline with 30+ min buffer

## Tagline options

- **"Spot the scam. Save the sea."** (primary)
- "Cast. Reel. Don't get phish'd."
- "The fish are scams. You are the angler."
- "Hunt the phishers. Earn your rank."

Welcome-sign copy:
> **PHISH** — Cast. Reel. Inspect. Don't get phish'd.
