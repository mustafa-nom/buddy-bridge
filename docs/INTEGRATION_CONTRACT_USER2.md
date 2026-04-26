# PHISH! — User 2 ↔ User 1 Integration Contract

User 2 (Lua / systems / UI) needs the following from User 1 (map / Studio
art) to wire the gameplay loop. Tags and attributes are read at runtime via
`CollectionService` — no hardcoded paths. Anchors that don't exist degrade
gracefully (cast defaults to tier 1, no aquarium displays, no boats), so
demoing partial map content is safe.

If a tag name needs to differ on User 1's side, **don't rename across
multiple files** — change it in one place: `src/ReplicatedStorage/Modules/Constants.lua`,
table `Constants.TAGS`. Every service reads from there.

---

## Tags expected from User 1

| Tag                      | Applies to       | Used by                    | Notes |
|--------------------------|------------------|----------------------------|-------|
| `PhishCastZone`          | BasePart (water-edge / dock surface) | PondService             | Player Touched activates the zone. Required attribute `ZoneTier` (1/2/3). Optional `ZoneId` (string). Multiple parts can share a tier. |
| `PhishLodgeSpawn`        | SpawnLocation    | (optional, future tutorial) | Currently unused at runtime. Keep tagging the lodge spawn so future hooks find it. |
| `PhishAquariumDisplay`   | BasePart         | AquariumService            | A BillboardGui is created on each tagged part, listing every fish placed across all current players. |
| `PhishShopPrompt`        | BasePart         | ShopController             | Player within 12 studs + presses E → opens shop. Place near the fisherman NPC or shop counter. |
| `PhishSellPrompt`        | BasePart         | SellController             | Same UX as shop. Place near the fishmonger / sell crate. |
| `PhishRowboat`           | Model (Rowboat root) | RowboatService          | Server tracks each tagged Model. Required: model has a `PrimaryPart` (or any BasePart child — the service will set PrimaryPart). Optional attributes `BoatId`, `BoatSpeed`, `BoatTurnRate`. |
| `PhishRowboatSeat`       | BasePart inside a Rowboat model | RowboatController | Player within 10 studs + presses E → drives. WASD/arrows to control, Shift to exit. |
| `PhishFishTemplate`      | Model in `ServerStorage/FishTemplates` | (future visual swap) | Required attribute `FishId` matching the registry id. Currently unused at runtime; reserved for the polish pass that swaps placeholder fish for real models. |

---

## Attributes referenced

| Attribute       | On                     | Type    | Default | Used by               |
|-----------------|------------------------|---------|---------|------------------------|
| `ZoneTier`      | `PhishCastZone` parts  | number  | 1       | PondService, ShopService nudge text |
| `ZoneId`        | `PhishCastZone` parts  | string  | full-path | PondService                |
| `FishId`        | fish template models   | string  | required | future fish-spawn art swap |
| `BoatId`        | rowboat models         | string  | full-path | RowboatService             |
| `BoatSpeed`     | rowboat models         | number  | 28      | RowboatService             |
| `BoatTurnRate`  | rowboat models         | number  | 1.5     | RowboatService             |

Tier 1 corresponds to "Calm Cove", tier 2 to "Murky Channel", tier 3 to
"Phisher's Trench". Names + colors are in `Modules/ZoneTiers.lua`.

---

## Diagnostics

`ServerBootstrap.server.lua` prints a `[PHISH!] Map diagnostics:` block
about a second after boot listing the count of every expected tag. If a
tag is missing or zero, that's the first place to look.

Example healthy output:

```
[PHISH!] Map diagnostics:
  CastZone (PhishCastZone): 4
  LodgeSpawn (PhishLodgeSpawn): 1
  Aquarium (PhishAquariumDisplay): 1
  ShopPrompt (PhishShopPrompt): 1
  SellPrompt (PhishSellPrompt): 1
  Rowboat (PhishRowboat): 2
  RowboatSeat (PhishRowboatSeat): 2
  FishTemplate (PhishFishTemplate): 0
```

`FishTemplate=0` is fine for MVP — it's reserved for the polish pass.

---

## Folder conventions

User 2 will not write or rename anything inside these Studio-managed folders.
They have `init.meta.json` files with `ignoreUnknownInstances: true`, which
lets User 1 add map content without it being wiped on Rojo sync:

- `ServerStorage/Levels/` (vestigial from prior project; safe to leave or repurpose)
- `ServerStorage/NpcTemplates/` (vestigial)
- `ServerStorage/ItemTemplates/` (vestigial)
- `ServerStorage/GuideBooths/` (vestigial)

User 2 does not place anything in those folders. New PHISH! art lives in a
freshly-created `ServerStorage/PhishAssets/` (User 1 to create) — but
nothing in src/ runtime references it, so the structure is User 1's call.

---

## What User 2 will NOT do

- Rename any tag User 1 has delivered without coordinating in this doc.
- Modify Studio geometry or art (parts/models/decals).
- Add Lua scripts outside the standard Rojo-mapped tree under `src/`.

## What User 2 expects in turn

- Tags applied per the table above.
- Cast zones (tier 1 minimum) somewhere reachable from the lodge spawn so
  the demo path is: spawn → walk to dock → cast.
- A shop prompt and a sell prompt within 30 studs of each other (preferred)
  near the lodge so the loop "catch → sell → buy upgrade → cast deeper" is
  a single circuit.
- Rowboat (optional for MVP demo): one tagged `PhishRowboat` model with a
  `PhishRowboatSeat` part attached. The service is happy with zero boats.
