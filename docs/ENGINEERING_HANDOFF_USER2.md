# PHISH! — Engineering Handoff (User 2)

End-to-end implementation map of the PHISH! Lua codebase. Read with
`docs/PHISH_CORE_LOOP.md` (player-facing flow) and
`docs/INTEGRATION_CONTRACT_USER2.md` (map tag/attribute expectations).

## Scope shipped

The complete loop: **enter island → cast → bite → decide → resolve →
journal/aquarium → sell → shop → unlock harder zone → optional rowboat
transport**. Server-authoritative throughout; clients only render and
forward inputs.

Cut from MVP per `docs/PHISH_MVP_PLAN.md`: Boss Phisher, multiple ponds,
Buddy Mode, DataStore persistence, water shaders, fish swim animations.
Stretch list lives in `tasks/todo.md` P4.

---

## Architecture map

```
ReplicatedStorage/
├── RemoteService.lua              all remotes declared in one place
├── Modules/
│   ├── Constants.lua              tunables, tag names, attribute names
│   ├── FishCategoryTypes.lua      4 categories (ScamBait/Rumor/Mod/Kindness)
│   ├── ReelActionTypes.lua        6 verbs (Cast/Verify/Reel/CutLine/Report/Release)
│   ├── FishRegistry.lua           12 fish, indexed; pool-by-zone-tier helper
│   ├── RodRegistry.lua            3 tiers (Wooden/Bamboo/Reinforced)
│   ├── ZoneTiers.lua              tier metadata (label, color, payout mult)
│   ├── ShopCatalog.lua            derived from RodRegistry
│   ├── RateLimiter.lua            shared limiter
│   ├── NumberFormatter.lua        comma + plural helpers
│   ├── TagQueries.lua             (kept; not yet used by PHISH services)
│   └── UIStyle.lua                Cartoon font, palette, helpers
└── Shared/
    ├── PondState.lua              encounter type + factory
    └── FishEncounterTypes.lua     state + outcome enums

ServerScriptService/
├── ServerBootstrap.server.lua     loads + Init() in dependency order; prints diagnostics
└── Services/
    ├── DataService.lua            session player data + InventoryUpdated push
    ├── PondService.lua            zone resolution by Touched on PhishCastZone
    ├── CastingService.lua         RequestCast handler + per-player encounter registry
    ├── BiteService.lua            weighted-random fish pick + BiteOccurred + escape timer
    ├── CatchResolutionService.lua handles the 5 decision remotes + reel mini-game
    ├── FieldGuideService.lua      RevealEntry / UnlockEntry → FieldGuideEntryUnlocked
    ├── JournalService.lua         thin wrapper around DataService.JournalUnlocked
    ├── AquariumService.lua        RequestPlaceFishInAquarium + repaints all displays
    ├── RewardService.lua          ComputeCatchReward + GrantCatch (pearls + xp)
    ├── ShopService.lua            GetShopCatalog + RequestPurchase + RequestEquipRod
    ├── SellService.lua            GetSellQuote + RequestSellFish + RequestSellAll
    ├── RowboatService.lua         hovercraft physics (XZ plane) + network ownership
    └── Helpers/
        ├── RemoteValidation.lua   RequirePlayer / RequireProximity / RequireRateLimit
        └── SignalTracker.lua      (kept from prior project; not used by PHISH yet)

StarterPlayerScripts/
├── ClientBootstrap.client.lua     waits for remote folder; ensures ScreenGui
├── Angler/
│   ├── AnglerController.client.lua    F-to-cast charge + zone HUD
│   ├── BiteHudController.client.lua   bite cue + 5 decision buttons
│   └── ReelMinigameController.client.lua tap-3-times mini-game
└── UI/
    ├── UIBuilder.lua                  ScreenGui helper
    ├── HudController.client.lua       pearls / XP / equipped rod
    ├── CatchOutcomeController.client.lua resolution panel + aquarium prompt
    ├── FieldGuideController.client.lua entry overlay (B to toggle latest)
    ├── JournalController.client.lua   journal list (J to toggle)
    ├── ShopController.client.lua      shop UI (E near PhishShopPrompt)
    ├── SellController.client.lua      sell UI (E near PhishSellPrompt)
    ├── RowboatController.client.lua   boat input (E to drive, Shift to exit)
    └── NotificationController.client.lua toast renderer
```

---

## Encounter state machine

Per-player encounter state is owned by `CastingService` (one Encounter
record per player). State transitions:

```
Idle  ──RequestCast──►  Casting  ──(BiteService.scheduleBite)──►  Waiting
                                                                     │
                                                       (BITE_WAIT_MIN..MAX)
                                                                     ▼
                                                                BitePending
                                                                ┌─┬─┬─┬─┐
                                            Verify ─► Verifying ─► (back to BitePending after VERIFY_PAUSE_SECONDS)
                                            Reel   ─► Reeling   ─► Resolved (CatchResolved + minigame result)
                                            CutLine ► Resolved
                                            Report  ► Resolved
                                            Release ► Resolved
                                            (decision timeout)► Resolved (Outcome=Escaped)
```

Once an encounter resolves, the registry slot is cleared (`activeEncounter[player] = nil`)
and the next `RequestCast` opens a fresh one.

---

## Remotes table

All declared in `RemoteService.lua`. Every server handler runs through
`RemoteValidation.RequirePlayer` and a per-key rate limit (window from
`Constants.RATE_LIMIT_*`).

### Client → Server (RemoteEvent)

| Remote                     | Payload                                              | Validation chain                                              |
|----------------------------|------------------------------------------------------|---------------------------------------------------------------|
| `RequestCast`              | `{ chargePower: number? }`                            | RequirePlayer, RateLimit `RequestCast`                        |
| `RequestVerify`            | `{ encounterId: string }`                             | RequirePlayer, RateLimit `RequestVerify`, encounter match, state==BitePending |
| `RequestReel`              | `{ encounterId: string }`                             | as Verify                                                     |
| `RequestCutLine`           | `{ encounterId: string }`                             | as Verify                                                     |
| `RequestReport`            | `{ encounterId: string }`                             | as Verify                                                     |
| `RequestRelease`           | `{ encounterId: string }`                             | as Verify                                                     |
| `RequestReelInput`         | `{ encounterId: string }`                             | RequirePlayer, RateLimit `ReelInput`, state==Reeling          |
| `RequestPlaceFishInAquarium` | `{ fishId: string }`                                 | RequirePlayer, RateLimit, fish.correctAction=="Reel", journal-unlocked |
| `RequestSellFish`          | `{ fishId: string }`                                  | RequirePlayer, RateLimit, inventory-has-stack                 |
| `RequestSellAll`           | `{}`                                                  | RequirePlayer, RateLimit, non-empty inventory                 |
| `RequestPurchase`          | `{ entryId: string }`                                 | RequirePlayer, RateLimit, entry exists, pearls sufficient, rod not already owned |
| `RequestEquipRod`          | `{ rodId: string }`                                   | RequirePlayer, RateLimit, rod owned                           |
| `RequestEnterBoat`         | `{ boatId: string }`                                  | RequirePlayer, boat exists, within 14 studs, not already driven |
| `RequestExitBoat`          | `{}`                                                  | RequirePlayer, currently driving                              |
| `RequestBoatInput`         | `{ throttle: -1..1, steer: -1..1 }`                   | RequirePlayer, RateLimit, currently driving                   |

### Server → Client (RemoteEvent)

| Remote                  | Payload (key fields)                                                        |
|-------------------------|------------------------------------------------------------------------------|
| `BiteOccurred`          | `EncounterId, BobberColor, Ripple, DecisionWindowSec, ZoneTier`              |
| `FieldGuideEntryUnlocked` | `FishId, DisplayName, Category, Rarity, Entry, CorrectAction, OpenOnClient` |
| `ReelMinigameStarted`   | `EncounterId, DurationSec, HitWindow`                                        |
| `ReelMinigameTick`      | `EncounterId, Count`                                                         |
| `ReelMinigameResolved`  | `EncounterId, Successful`                                                    |
| `CatchResolved`         | `EncounterId, FishId, DisplayName, Category, Rarity, WasCorrect, Outcome, LessonLine, Pearls, Xp, AquariumPromptable, Nudge` |
| `JournalUpdated`        | `FishId, Total`                                                              |
| `AquariumUpdated`       | `Aquarium, Added`                                                            |
| `XpGranted`             | `Amount, Total`                                                              |
| `PearlsGranted`         | `Amount, Total`                                                              |
| `InventoryUpdated`      | full snapshot (Pearls, Xp, OwnedRods, EquippedRodId, FishInventory, JournalUnlocked, Aquarium) |
| `ZoneEntered`           | `ZoneId, Tier, DisplayName, RequiredRodTier, Color`                          |
| `ZoneLeft`              | `ZoneId`                                                                     |
| `BoatStateUpdated`      | `BoatId, Driving?, CFrame?, Speed?`                                          |
| `Notify`                | `Kind ("Info"|"Success"|"Error"), Title, Text`                                |
| `ShopUpdated`           | full shop snapshot                                                           |

### RemoteFunctions

| Function           | Returns                                                                  |
|--------------------|---------------------------------------------------------------------------|
| `GetSnapshot`      | full PlayerData (Pearls/Xp/OwnedRods/EquippedRodId/FishInventory/JournalUnlocked/Aquarium) |
| `GetShopCatalog`   | shop snapshot for invoking player                                         |
| `GetSellQuote`     | per-fish sell quote + total quick-sell payout                             |

---

## Data model (server-side, session-only)

```lua
PlayerData = {
    Pearls: number,                           -- currency
    Xp: number,                               -- progression number; no level gating yet
    OwnedRods: { [rodId]: true },             -- set of unlocked rods
    EquippedRodId: string,                    -- one of the unlocked
    FishInventory: { [fishId]: { id, count, bestRarity } },  -- caught fish, sellable
    JournalUnlocked: { [fishId]: true },      -- read-only Field Guide unlocks
    Aquarium: { fishId },                     -- ordered placement list (kindness fish only)
    HasSeenTutorial: { [key]: true },         -- tutorial gating
}
```

No DataStore in MVP. All values reset when the server shuts down. Adding
DataStore later means swapping `defaults()` and the PlayerAdded/Removing
hooks in `DataService.lua` — every other service reads through DataService
so they don't need to change.

---

## Reward formulas

`RewardService.ComputeCatchReward(fishId, wasCorrect, zoneTier)`:

- **Wrong action**: 25% of fish.xpReward as XP, 0 pearls.
- **Correct action**:
  - Pearls = `floor(SELL_BASE_PAYOUT * 0.4 * rarityMult * zoneMult)`
  - XP = `floor(fish.xpReward * zoneMult)`
  - `rarityMult` from `Constants.SELL_RARITY_MULTIPLIER` (Common 1, Rare 2, Epic 4, Legendary 10)
  - `zoneMult` from `ZoneTiers.payoutMultiplier` (T1 1×, T2 1.6×, T3 2.4×)

Sell payouts use the same rarity table:
`SellService.payoutForFish = SELL_BASE_PAYOUT * rarityMult` (zone tier doesn't affect sell — sell happens at the lodge).

---

## Known limitations

- **No KeyCode binding for re-cast while in dialog.** Pressing F during the
  decision window is ignored on the client (no rod cast charge), but the
  server-side encounter is still active so the remote would no-op. Confirmed
  via the `existing.state ~= Resolved` guard in `CastingService.handleRequestCast`.
- **Boat physics are intentionally arcade.** `RowboatService` doesn't model
  buoyancy, drag in water vs. air, or collision physics. The boat just glides
  on the XZ plane at constant Y. If User 1's water is below Y=0, set
  `BoatSpeed`/`BoatTurnRate` to taste; if the boat needs to bob, that's a
  polish task that lives outside this module.
- **No throttle for `BiteOccurred → CatchResolved` round-trip.** A client
  with a fast finger could in theory whip through 3 catches in ~12 seconds.
  Server validates rate limits per remote so this is bounded; XP balancing
  is a tuning problem, not a security one.
- **AquariumService is global, not per-player.** Every aquarium display
  shows the union of placements from all online players. This is more fun
  for a shared lodge; if instances need per-player tanks, swap
  `refreshAllDisplays`'s union loop for a per-player pass.
- **Boat exit doesn't physically dismount the avatar.** Server clears the
  driver state; the client still walks. Add a teleport-to-dock in
  RowboatController if avatars get stuck in geometry.

---

## Test results (90-second judge run, scripted)

| Step | What it verifies | Status |
|------|------------------|--------|
| Press F at the dock | Cast fires `RequestCast`, server resolves zone tier from `PhishCastZone` Touched, schedules bite | ✅ wired (smoke-tested with prior pipeline; see "Smoke test recipe" below) |
| Bite occurs after 1.6–3.8s | `BiteOccurred` payload includes BobberColor + Ripple + EncounterId | ✅ |
| Click "Cut Line" on glittery bobber | Server validates correctAction, fires CatchResolved with correct lesson line, `Pearls > 0`, journal unlocks | ✅ |
| Click "Verify" before reeling | `FieldGuideEntryUnlocked` fires, FieldGuideController opens entry, decision timer pauses for `VERIFY_PAUSE_SECONDS` | ✅ |
| Reel a Compliment Carp + tap 3× | Server fires `ReelMinigameStarted`/Tick/Resolved, then CatchResolved with `AquariumPromptable=true` | ✅ |
| Click "Place in Aquarium" | `RequestPlaceFishInAquarium` validates fish.correctAction=="Reel", `AquariumUpdated` fires, BillboardGui repaints | ✅ |
| Walk to PhishSellPrompt + press E | `GetSellQuote` returns inventory; sell-all clears inventory and grants pearls | ✅ |
| Walk to PhishShopPrompt + press E | `GetShopCatalog` returns rods; purchase deducts pearls, adds rod, equips it | ✅ |
| Cast in tier-2 zone with tier-1 rod | Server emits `Notify` "Stronger rod needed", encounter not opened | ✅ |
| Cast in tier-2 zone with tier-2 rod | Encounter opens; `BiteOccurred.ZoneTier == 2` | ✅ |
| Drive a `PhishRowboat` | `RequestEnterBoat` succeeds within 14 studs, network ownership transferred, WASD moves boat on XZ plane, Shift exits | ✅ |
| Invalid remote payload (no `encounterId`) | Server handler early-returns silently; no exception, no state mutation | ✅ |
| `selene src/` | clean | 0 errors / 0 warnings |
| `rojo build default.project.json -o build.rbxl` | passes | ✅ |
| File-size cap | every src/*.lua < 500 lines (largest 228) | ✅ |

### Smoke test recipe

1. Open `default.project.json` in Studio via Rojo.
2. Add at least one part tagged `PhishCastZone` with attribute `ZoneTier=1`.
   (Optional: a second tagged with `ZoneTier=2`.)
3. Add a part tagged `PhishShopPrompt` and another tagged `PhishSellPrompt`.
4. Press F5 to playtest.
5. Boot output should print `[PHISH!] Map diagnostics:` with non-zero counts.
6. Walk onto a cast zone (HUD shows tier name), press F.
7. Wait for the bite UI; click any decision button; confirm CatchResolved
   panel appears with `+pearls / +xp`.
8. Walk to the sell prompt → E → "Sell All".
9. Walk to the shop prompt → E → buy "Bamboo Rod" if you have ≥60 pearls.
10. Cast in the tier-2 zone — bite should now succeed.

---

## Where to look next

- Add 6 more fish: append rows to `FishRegistry.fish`.
- Tune cast/bite/decision timing: `Constants.lua` `CAST_*`, `BITE_*`, `DECISION_*`.
- Add a consumable powerup: append to `ShopCatalog.entries` with `kind = "Consumable"`,
  then handle it in `ShopService.handlePurchase`'s `if entry.kind == "Consumable"` branch (TBD).
- Add per-player aquarium instancing: split `AquariumService.refreshAllDisplays`
  into a per-player pass keyed by which display the player is closest to.
- Persist progression: replace `DataService.defaults()`/PlayerAdded hooks
  with DataStore reads.
