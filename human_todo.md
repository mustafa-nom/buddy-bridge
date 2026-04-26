# Human TODO — PHISH!

Things only a human (or the Roblox MCP map-builder agent) can do in Roblox Studio or Creator Dashboard. Claude can't touch Studio directly.

The prior Buddy Bridge `human_todo.md` lived here; check git history if you need it (or `docs/archive/` for the BB MVP scope).

## Tooling (do once)

- [ ] `aftman install` — installs Rojo 7.7.0-rc.1 and Selene 0.27.1 from `aftman.toml`
- [ ] Verify `rojo --version` and `selene --version` work in this repo's terminal
- [ ] Install Rojo Studio plugin (if not already), connect to `rojo serve`

## Lodge (lobby) — Studio-built

- [ ] Build the **Lodge**: a cozy fishing-cabin lobby that replaces the prior Buddy Bridge lobby
  - Wood-cabin aesthetic, warm lighting, soft ambient SFX
  - **Aquarium display zone** — large glass tank or pond inset where caught fish swim
  - Spawn point for new players
  - Door / dock-portal that teleports to Starter Cove (or just a seamless walkway)
  - NPC or sign explaining "Grab a rod and head to the dock" (1-line tutorial nudge)

## Starter Cove (pond) — Studio-built

- [ ] Build **Starter Cove**: the MVP pond
  - Water plane (translucent, with ripple VFX or shader if time)
  - Wooden dock the player stands on while fishing
  - Surrounding terrain — gentle hills, trees, lily pads, fireflies
  - **Golden-hour lighting** — pick this and lock it for MVP (no day/night cycle)
  - Ambient SFX: water lapping, distant birds, occasional splash
  - Cast zone marker (optional visible aim-cone or just a dock edge)

## Tools + Models — Studio-built

- [ ] **Fishing rod** tool model — placed in `StarterPack` or given on dock entry
- [ ] **Bobber** + **lure** visual assets (cast-time visuals)
- [ ] **12 fish models** per `docs/PHISH_CONTENT.md` — placed in `ServerStorage/FishTemplates/`
  - MVP-acceptable: simple primitive shapes (sphere body + colored fins) with category-coded colors. Ugly-but-shipping > pretty-but-incomplete.
  - Each fish model needs a clear silhouette so it reads in the aquarium
- [ ] Bobber visual variants for the 4 category cues (glitter / shimmer / fake-badge / soft-glow)

## Tags + Attributes (Roblox MCP)

These get set in Studio so the Lua services can `CollectionService:GetTagged(...)` them.

- [ ] Tag the dock cast zones with `PhishCastZone`
- [ ] Tag the aquarium display volume with `PhishAquariumDisplay`
- [ ] Tag fish templates with `PhishFishTemplate` and set attribute `FishId` matching `FishRegistry`
- [ ] Tag the Lodge spawn with `PhishLodgeSpawn`

(Final tag list will be confirmed in P2 when services are written. Update this file then.)

## Studio Settings

- [ ] Server limits: solo-friendly. Up to 8 players per server is fine; MVP can also run 1-per-server if instancing is simpler
- [ ] Audio: ambient cap audible but not loud
- [ ] Lighting: ShadowMap or Future, golden-hour ClockTime
- [ ] Avatar settings: any (PHISH! doesn't constrain avatars)

## Rojo / Build Sanity

- [ ] After Studio sync, run `rojo build default.project.json -o build.rbxl` from CLI and confirm it succeeds
- [ ] After major Studio map edits, save the place file and confirm `init.meta.json` files in `src/` were not deleted (Rojo's `ignoreUnknownInstances` rule depends on them)

## Demo Prep

- [ ] Pre-populate a demo player profile so the aquarium has 1 fish on first load (Compliment Carp recommended)
- [ ] 2-laptop dry run: judge plays solo, teammate watches for hangs
- [ ] Print or memorize the 90-second demo script from `docs/PHISH_MVP_PLAN.md`

## Creator Dashboard

- [ ] Place name set to `PHISH!` (or whatever the team picks)
- [ ] Game thumbnail / icon (golden-hour pond + glittery bobber works)
- [ ] Game description mentions "fishing" + "online safety" framing
- [ ] Submit to the LAHacks Roblox Civility Challenge per their submission instructions

## Out of Scope (do not build in Studio)

- Multiple ponds beyond Starter Cove
- Boss fish models
- Cosmetics shop UI
- Buddy Mode booth (Buddy Bridge had one — don't rebuild for MVP)
