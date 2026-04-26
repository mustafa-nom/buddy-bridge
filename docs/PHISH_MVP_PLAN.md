# PHISH! — MVP Plan

Hackathon scope. Read before adding any feature. If a feature isn't here, it's not in MVP.

## Demo Target (90 seconds)

A judge sits down. They:

1. **(0:00–0:10)** Spawn into the **Lodge** lobby. See the aquarium with one example fish swimming.
2. **(0:10–0:20)** Walk to the dock. Pick up the rod. Tutorial pops a 2-line nudge: "Cast. Watch the bobber. Decide what to do."
3. **(0:20–0:40)** **Cast 1** — bite occurs with a glittery gold bobber (Free Robux Bass). Judge cuts the line. Lesson line: "Smart move — free in-game stuff is the bait."
4. **(0:40–1:00)** **Cast 2** — bite with a wobbly shimmering bobber (Telephone Trout). Judge taps Verify, sees the Field Guide entry, then Releases. Journal entry unlocks.
5. **(1:00–1:20)** **Cast 3** — bite with a soft pink glow (Compliment Carp). Judge reels, plays the brief reel mini-game, succeeds. "Place in aquarium?" → yes.
6. **(1:20–1:30)** Quick pan to the Lodge aquarium showing the new Compliment Carp swimming. Pitch line: *"Every fish is a real online-safety moment in disguise — they learn by playing, not by being lectured."*

If we can hit that demo, we can credibly enter the Civility Challenge and the **Learn and Explore** sort.

## MVP Feature Checklist

### Pond + Map (Studio-built, see `human_todo.md`)
- [ ] **Lodge** lobby with dock entrance and aquarium display zone
- [ ] **Starter Cove** pond — water plane, dock, golden-hour lighting, ambient props
- [ ] Fishing rod tool model in Lodge
- [ ] Bobber + lure visual asset
- [ ] 12 fish models (or convincing placeholders) — `FishTemplates/`

### Server (Lua, P2 in `tasks/todo.md`)
- [ ] `FishRegistry.lua` — data-driven from `PHISH_CONTENT.md`
- [ ] `PondService` — manages active pond, fish spawn weights, time-of-day
- [ ] `CastingService` — cast remote, lure state
- [ ] `BiteService` — picks fish (server-authoritative), schedules `BiteOccurred`
- [ ] `CatchResolutionService` — validates verb-vs-fish, grants rewards
- [ ] `FieldGuideService` — manages unlocks
- [ ] `JournalService`, `AquariumService`
- [ ] Extend `ScoringService`, `RewardService`, `DataService`

### Client (Lua)
- [ ] `AnglerController` — rod input, cast charge, decision window UI
- [ ] `CastingController` — visuals
- [ ] `ReelMinigameController` — adapt `BeltController` timing pattern
- [ ] `FieldGuideController` — reuses `BookView.lua`
- [ ] `JournalController`, `AquariumViewController`
- [ ] Adapt existing `HudController`, `NotificationController`

### Networking
- [ ] All planned remotes added to `RemoteService.lua` (see `PHISH_CORE_LOOP.md`)
- [ ] Rate-limiting on every player-triggered remote
- [ ] Server-side validation on every catch resolution

### Polish (last 4–6 hours)
- [ ] Cast/reel SFX
- [ ] Fish-specific bite sounds (4 variants — one per category)
- [ ] Water shader / ripple VFX
- [ ] Fish swim animations in aquarium
- [ ] Cartoon-font Field Guide pages match `UIStyle.lua`
- [ ] Tutorial nudge on first cast

### Demo Prep
- [ ] Demo script (90 sec, written down)
- [ ] Pre-populated demo player profile so the aquarium looks alive on first spawn
- [ ] Two-laptop test: judge plays, teammate watches for hangs

## Cut for MVP (do not build)

The temptation list. Crossing this line is the most common way hackathon projects miss their demo.

- ❌ **Boss fish** (the legendary "Boss Phisher") — content for a future build
- ❌ **Multiple ponds** beyond Starter Cove
- ❌ **Buddy Mode UI** — solo-only for the demo; co-op is post-MVP
- ❌ **Persistent DataStore** — session-only progression is fine for judging
- ❌ **Cosmetics shop / currency economy** — XP only, no spending
- ❌ **Trading**
- ❌ **Weather / time-of-day variants** — pick one (golden hour) and lock it
- ❌ **Daily quests / events**
- ❌ **Leaderboards**
- ❌ **Voice chat / chat moderation features**

If a teammate insists on adding one of these, point them at this list.

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Water shader takes longer than expected | Med | Med | Ship with a flat translucent plane + ripple decals. Polished water is "nice to have," not blocker. |
| Fish models take longer than expected | High | High | Use 12 simple primitives (spheres + colored fins) before chasing custom rigs. Ugly-but-shipping > pretty-but-incomplete. |
| Players spam Cut Line (refuse everything) and never engage | Med | High | Tutorial nudges Verify on cast 2; small cooldown on Cut Line; lesson copy on consecutive Cut Lines suggests "try Verify next time." |
| Reel mini-game frustrates kids | Med | Med | Easy by default; consider auto-success on first 3 reels of a session. |
| Multiplayer pond feels chaotic | Low | Med | MVP can run one player per server (use existing `PlayAreaService` slot pool). |
| Educational mapping is unclear to judges | Low | High | Demo script explicitly names the metaphor on cast 1. Lesson line on screen reinforces. |
| `BookView.lua` repurpose breaks under fish-entry data shape | Low | Low | It's already a flexible page renderer; worst case fork it as `FieldGuideView.lua`. |

## Two-Day Hackathon Timeline (rough)

> Adjust to actual remaining time at task start.

**Day 1**
- 2h — P1 code archive (Buddy Bridge → `src/archive/`)
- 4h — P2 server services scaffolding (Pond, Casting, Bite, CatchResolution, FieldGuide)
- 3h — P2 client (Angler controller, decision window UI)
- 2h — `FishRegistry` + first 6 fish wired in
- 1h — Smoke test: cast → bite → cut line → resolve

**Day 2**
- 3h — Reel mini-game + Field Guide UI (BookView reuse)
- 2h — Journal + Aquarium screens
- 2h — Remaining 6 fish + lesson copy editing
- 2h — SFX + polish + tutorial nudge
- 2h — Demo script + dry runs
- 1h — Buffer

If we lose a day → cut to 6 fish, no aquarium (just a journal), no reel mini-game (just a 1-second wait).

## Definition of Done (per item)

A checklist item is done when:
1. The Lua compiles and `selene src/` is clean.
2. The feature works in 1-player Studio test.
3. Server authority is preserved.
4. Remote payloads are validated.
5. No file exceeds 500 lines.
6. `tasks/todo.md` is updated.
