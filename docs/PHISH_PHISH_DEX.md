# PHISH — Phish-Dex Species Catalog

The Pokedex of scams. Source-of-truth for `ReplicatedStorage.PhishDex` ModuleScript (User 2). Schema in `docs/PHISH_PRD.md` §10.

Six species ship in MVP. All are visually instantiated as fish models in `ServerStorage.PhishFishTemplates` by User 1's builder; their **`FishId` attribute matches the `id` field below exactly**.

---

## 1. UrgencyEel — `id = "UrgencyEel"`

- **realPatternName:** Urgency-based phishing
- **rarity:** Common
- **description:** Slippery and fast. Rushes you into bad decisions before you can think.
- **realWorldInfo:** Scammers create fake time pressure to bypass critical thinking. Real companies almost never require action within hours.
- **redFlags:**
  - Time-based threats (24 hours, immediately, etc.)
  - All-caps subject lines
  - Threats of account closure or loss
- **defenseStrategy:** Pause. Real urgent issues can be resolved by calling the company directly using the number on their official website (not the email).
- **catchesToUnlock:** 3
- **Visual cue (User 1):** elongated red-orange body, lightning-bolt fin, eyes too small.

## 2. AuthorityAnglerfish — `id = "AuthorityAnglerfish"`

- **realPatternName:** Authority impersonation
- **rarity:** Uncommon
- **description:** Wears a glowing fake badge. Pretends to be someone in charge.
- **realWorldInfo:** Scammers impersonate IRS, banks, police, school admins, or employers. Real institutions rarely email about urgent action — they call or send postal mail.
- **redFlags:**
  - Domain doesn't match the real institution (.org vs .gov, lookalike spelling)
  - Threats of legal/financial consequence
  - Asks for verification info you wouldn't volunteer
- **defenseStrategy:** If a "bank/IRS/police" emails you, close the email, look up the institution's real number on their official site, and call them.
- **catchesToUnlock:** 3
- **Visual cue (User 1):** dark navy body with a fake glowing "OFFICIAL" badge near the gills.

## 3. RewardTuna — `id = "RewardTuna"`

- **realPatternName:** Too-good-to-be-true reward
- **rarity:** Common
- **description:** Glittery and gold. Promises something for nothing.
- **realWorldInfo:** "You won!" emails for contests you never entered are universally scams. Real giveaways require you to actually enter, and never ask for personal info to claim.
- **redFlags:**
  - You didn't enter a contest
  - "Free [expensive item]"
  - Asks for shipping fee or "verification" payment
- **defenseStrategy:** If you didn't enter, you didn't win. Delete.
- **catchesToUnlock:** 3
- **Visual cue (User 1):** gold body with confetti-pattern scales and oversized fins.

## 4. CuriosityCatfish — `id = "CuriosityCatfish"`

- **realPatternName:** Clickbait / curiosity scam
- **rarity:** Common
- **description:** Wide eyes, wider mouth. Wants you to click before you read.
- **realWorldInfo:** Scammers exploit curiosity ("Is this you in this video?", "What people are saying about you") to get clicks on malware or credential-stealing pages.
- **redFlags:**
  - Vague subject line designed to make you ask "what?"
  - No personal context (doesn't actually mention your name or specifics)
  - Single big "view" or "open" link
- **defenseStrategy:** Real shared content has context. If the email is just bait + a link, it's bait.
- **catchesToUnlock:** 3
- **Visual cue (User 1):** big-eyed gray fish with whiskers and a hook for a tail.

## 5. FearBass — `id = "FearBass"`

- **realPatternName:** Threat / fear-based phishing
- **rarity:** Uncommon
- **description:** Spiky and dark. Scares you into clicking before you check.
- **realWorldInfo:** "Suspicious login detected" / "Your account is under review" / "We have your photos" — scammers weaponize fear to short-circuit verification habits.
- **redFlags:**
  - Threat with tight deadline ("act in 24 hours or lose access")
  - Claims of leaked data or compromised account
  - Geographic scare ("login from Russia/Nigeria/etc.")
- **defenseStrategy:** Don't click the email's link. Open a new tab and sign in directly to the real site. Real alerts will be visible there too.
- **catchesToUnlock:** 3
- **Visual cue (User 1):** dark spiky body with red glowing eyes.

## 6. FamiliarityFlounder — `id = "FamiliarityFlounder"`

- **realPatternName:** Social engineering via familiarity
- **rarity:** Rare
- **description:** Looks like someone you know. Feels off when you read it twice.
- **realWorldInfo:** Scammers spoof friends' or family members' accounts (or hack them) to ask for gift cards, money transfers, or personal info. The hook is that you trust the sender, so you skip the verification step.
- **redFlags:**
  - Out-of-character request (gift cards, urgent transfer, vague favor)
  - Won't talk on a phone call ("can't call right now")
  - Sender address subtly different from the real person's
- **defenseStrategy:** Call the person on a number you already have. If they didn't send it, their account or yours has a problem.
- **catchesToUnlock:** 3
- **Visual cue (User 1):** flat pale body that mimics other species' colors poorly — clearly an imitation.

---

## Legit fish (not species — visual flavor for the KEEP cards)

- **PlainCarp** (`id = "PlainCarp"`) — clean teal, normal proportions, no weird marks. The "this is fine" fish.
- **HonestHerring** (`id = "HonestHerring"`) — silver, clean fins, gentle silhouette.

User 2's `ScamCards` will pick these IDs for the visual the player sees while inspecting a legit card.

---

## Authoring rules

1. Every species' description should read like a Pokedex entry — vivid, ~12 words.
2. `realWorldInfo` is the educational payload. Keep it ≤2 sentences. No jargon.
3. `redFlags` are the *visible* tells on a scam card. They must be checkable by a player on the inspection UI.
4. `defenseStrategy` should give the kid a single concrete action they can take in real life.
5. `catchesToUnlock` defaults to 3. Bump rarer species (Legendary tier post-MVP) to 5.
