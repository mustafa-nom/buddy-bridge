# PHISH — ScamCards Catalog

Source-of-truth content for the `ReplicatedStorage.ScamCards` ModuleScript that User 2 will build. Authored as markdown so writers (or judges, if asked) can read it without opening Studio. Each entry maps directly to the schema in `docs/PHISH_PRD.md` §10.

**MVP target:** 20 cards. ~15 phish across the 6 species, ~5 legit so KEEP isn't always wrong. Mix difficulty 1–3.

**Authoring rules:**
1. Use real public phishing patterns (KnowBe4, PhishMe templates, your own inbox). Never invent fictional companies — readers should feel "I've literally seen this before."
2. Sender domain typos must be subtle but spot-able (paypa**1**, fac**3**book, irs-gov-refund.**org** vs **.gov**).
3. Every red flag in `redFlags[]` must be visually findable on the card by a player using the right Tackle tool.
4. Legit cards have **zero red flags** — make them look boring and routine.
5. No real names of platforms outside email-relevant ones (Netflix, GitHub, IRS, banks are fine — they're educational targets; avoid Discord/Snapchat in card content).

---

## Card 1 — `phish_urgency_001` (Phish, Difficulty 1, UrgencyEel)

```
sender:   "Netflix Billing" <netflix-acct@netfllx-billing.com>
subject:  ⚠️ ACTION REQUIRED: Your account expires in 24 hours

body:
Hello,

We were unable to process your last payment. Your Netflix
subscription will be CANCELLED in 24 hours unless you update
your billing information immediately.

[UPDATE NOW]
→ http://netfllx-billing.com/restore

The Netflix Team

links: [{ displayText="UPDATE NOW", trueUrl="http://netfllx-billing.com/restore" }]
redFlags:
  - sender.address: Domain "netfllx" instead of "netflix"
  - subject:        Urgency language and time pressure
  - links[1]:       Mismatched domain
reward: { xp=15, coins=5 }
```

## Card 2 — `legit_github_001` (Legit, Difficulty 1)

```
sender:   "GitHub" <noreply@github.com>
subject:  [GitHub] A new sign-in to your account

body:
Hi mus-the-builder,

We noticed a new sign-in to your GitHub account from
Chrome on macOS in Los Angeles, CA, US.

If this was you, no action is needed.
If this wasn't you, please reset your password.

Thanks,
The GitHub Team

links: []
redFlags: []
reward: { xp=10, coins=3 }
```

## Card 3 — `phish_authority_001` (Phish, Difficulty 2, AuthorityAnglerfish)

```
sender:   "IRS Tax Department" <official@irs-gov-refund.org>
subject:  Your tax refund of $1,847.00 is ready

body:
Dear Taxpayer,

Our records indicate you are owed a refund of $1,847.00
from the previous tax year. To claim your refund, please
verify your identity using the secure link below.

[CLAIM REFUND]
→ https://irs-gov-refund.org/verify

Failure to verify within 5 business days will result
in forfeiture of the refund.

IRS Department of Revenue

links: [{ displayText="CLAIM REFUND", trueUrl="https://irs-gov-refund.org/verify" }]
redFlags:
  - sender.address: IRS uses .gov, not .org
  - body:           IRS does not contact taxpayers via email about refunds
  - subject:        Authority impersonation + soft urgency
reward: { xp=20, coins=8 }
```

## Card 4 — `phish_reward_001` (Phish, Difficulty 1, RewardTuna)

```
sender:   "Apple Rewards" <prize-team@apple-rewards-claim.net>
subject:  🎉 Congratulations! You've been selected for a free iPhone 15

body:
You have been randomly selected as our weekly winner!

To claim your free iPhone 15 Pro Max, please complete a
short verification below. Hurry — only 3 winners per week.

[CLAIM YOUR PRIZE]
→ https://apple-rewards-claim.net/winner/x73

— The Apple Rewards Team

links: [{ displayText="CLAIM YOUR PRIZE", trueUrl="https://apple-rewards-claim.net/winner/x73" }]
redFlags:
  - sender.address: Apple does not run "rewards" lotteries
  - body:           Too-good-to-be-true reward, no entry was made
  - links[1]:       Suspicious lookalike domain
reward: { xp=15, coins=5 }
```

## Card 5 — `phish_fear_001` (Phish, Difficulty 2, FearBass)

```
sender:   "Microsoft Account Team" <security-alert@ms-account-secure.com>
subject:  Suspicious login detected — action required

body:
We detected a sign-in attempt to your Microsoft account
from an unrecognized device in Lagos, Nigeria.

If this was not you, your account may be compromised.
Click below to secure it now:

[SECURE MY ACCOUNT]
→ https://ms-account-secure.com/recover

If you do not act within 24 hours, your account will be
locked.

links: [{ displayText="SECURE MY ACCOUNT", trueUrl="https://ms-account-secure.com/recover" }]
redFlags:
  - sender.address: Microsoft sender is microsoft.com, not "ms-account-secure"
  - body:           Fear-based geographic threat ("Nigeria") + urgency
  - links[1]:       Lookalike domain
reward: { xp=20, coins=8 }
```

## Card 6 — `legit_bank_001` (Legit, Difficulty 1)

```
sender:   "Chase" <no-reply@chase.com>
subject:  Your monthly statement is ready

body:
Hi Alex,

Your statement for account ending in 4291 is now available.
View it any time by signing in directly at chase.com or in
the Chase mobile app.

We never ask for your password by email.

Thank you for being a Chase customer.

links: []
redFlags: []
reward: { xp=10, coins=3 }
```

---

## Stub cards to flesh out (for User 2 / writers)

Drafted as one-liners; expand into full cards using the format above.

7. `phish_curiosity_001` (CuriosityCatfish, D1) — "You won't believe what your old classmate posted about you" → links to malware site.
8. `phish_familiarity_001` (FamiliarityFlounder, D2) — "Hey, it's me, can you do me a favor real quick?" from unknown sender.
9. `phish_urgency_002` (UrgencyEel, D2) — "Amaz0n delivery problem — confirm address in 12 hours."
10. `phish_authority_002` (AuthorityAnglerfish, D3) — "FBI Cyber Division: warrant pending unless you contact officer".
11. `phish_reward_002` (RewardTuna, D2) — Roblox-flavored "You earned 10,000 R$ for being our 1,000,000th visitor!"
12. `phish_fear_002` (FearBass, D3) — "Your icloud photos have been compromised, view leaked album".
13. `phish_curiosity_002` (CuriosityCatfish, D2) — "Is this you in this video?" link.
14. `phish_familiarity_002` (FamiliarityFlounder, D3) — Spoofed friend asking for Steam gift cards.
15. `phish_urgency_003` (UrgencyEel, D3) — "Your domain expires today — auto-renew failed."
16. `legit_school_001` (Legit, D1) — School announcement email about parent-teacher night.
17. `legit_shipping_001` (Legit, D2) — Real UPS delivery confirmation with tracking number that matches.
18. `legit_recovery_001` (Legit, D2) — Real-looking GitHub 2FA recovery code email.
19. `legit_newsletter_001` (Legit, D1) — Weekly newsletter from a subscribed source.
20. `phish_authority_003` (AuthorityAnglerfish, D2) — "Roblox Moderator: your account is under review".

## Difficulty tuning

- **D1 (~50%):** one obvious red flag a player can spot in <5 seconds.
- **D2 (~35%):** two red flags, one subtle (typo in domain).
- **D3 (~15%):** three red flags, requires a tool (URL Magnifier or Vibe Check Goggles) to confidently spot.

## Quotas

| Species | Cards | Notes |
|---------|-------|-------|
| UrgencyEel | 3 | D1×1, D2×1, D3×1 |
| AuthorityAnglerfish | 3 | D2×2, D3×1 |
| RewardTuna | 2 | D1×1, D2×1 |
| CuriosityCatfish | 2 | D1×1, D2×1 |
| FearBass | 2 | D2×1, D3×1 |
| FamiliarityFlounder | 2 | D2×1, D3×1 |
| **Legit** | **6** | D1×4, D2×2 — boring on purpose |
