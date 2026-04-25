# Backpack Checkpoint — Decision

**Pick: V1 (The Polished Conveyor)**, with the V1+V3 lobby tie-in as the stretch upgrade.

This supersedes the Backpack Checkpoint section in `GAME_DESIGN.md` and `PRD.md`. V2 (Airport World) and V3 (Trust Garden) as full level replacements are out of scope.

See [`BACKPACK_CHECKPOINT_PRDS_README.md`](BACKPACK_CHECKPOINT_PRDS_README.md) and [`BACKPACK_CHECKPOINT_PRD_V1_POLISHED.md`](BACKPACK_CHECKPOINT_PRD_V1_POLISHED.md) for the source PRDs.

## Why V1

The decision was made *after* the Stranger Danger redesign locked in (see [`STRANGER_DANGER_REDESIGN.md`](STRANGER_DANGER_REDESIGN.md)). That redesign reshaped the demo's center of gravity: Stranger Danger is now the heavy, mechanically novel KTANE-style level. The second level needs to complement it, not compete with it.

### 1. Mechanical asymmetry inversion = demo variety

| Level | Asymmetry shape |
|---|---|
| **Stranger Danger (new)** | Guide *types* what Explorer *sees*. Guide commits the answer; Explorer is eyes only. |
| **Backpack Checkpoint V1** | Explorer *acts* on what Guide *reads*. Explorer commits in-world; Guide is the chart. |

Two genuinely different shapes of "you have to talk to win" in one demo. V2 and V3 both keep the Guide-as-narrator pattern Stranger Danger used to have — picking either of them makes the demo feel like one mechanic at two scales.

### 2. Build budget reality

The Stranger Danger redesign added net-new surface: booth pedestals, slot picker UI, submit/feedback state machine, badge rendering on NPCs, attempts system. V2 (explorable airport hub with 4 stations + tower cameras) stacks too much on top of that for 36 hours. V3 doubles the **art**-polish bill on top of the booth's new art surface.

V1 is the lowest-cost option. It lets us spend the saved hours pouring polish into Stranger Danger's new puzzle, which is now the headline level.

### 3. CLAUDE.md already says BPC should be "shorter and tighter"

> "This level is shorter and tighter than Stranger Danger Park. It exists to convey a second concept (privacy / digital citizenship) and to give the demo a satisfying second beat."

The new Stranger Danger is even heavier than the old one. V1 leans into the "tighter second beat" role. V3 fights it.

### 4. Boss-test sentence still holds

- Stranger Danger: *talk before strangers.*
- V1 Backpack Checkpoint: *talk before sharing.*

One-line pitch covers both levels cleanly. The "asymmetric-info-relayed-for-life-skills" mechanic is recognizable across both.

## Stretch: V1 + V3 Lobby Tie-In

If V1 is shipping ahead of schedule, layer the V3 cozy hook into the **lobby**, not as a second level:

- The lobby treehouse becomes a Trust Garden that grows from successful V1 runs. Trust Seeds awarded at the score screen literally plant in the garden.
- This captures the Grow-a-Garden / parent-child Roblox lane judges keep referencing, without owning V3's full level art budget.
- It's strictly additive on top of V1. If time runs out, cut it cleanly.

This was already noted in `BACKPACK_CHECKPOINT_PRDS_README.md` as a hybridization option. Promote it from "worth considering" to "stretch goal."

## What's Superseded

- `GAME_DESIGN.md` Backpack Checkpoint section → defer to V1 PRD.
- `PRD.md` Backpack Checkpoint references → defer to V1 PRD.
- V2 and V3 PRDs stay in `docs/` as historical artifacts but are not the build target.

## Build Order Implication

Recommended sequencing for the rest of the hackathon:

1. Stranger Danger redesign (booth + picker UI + badges) — headline level, hardest.
2. V1 Backpack Checkpoint — registry content + conveyor polish.
3. End-to-end demo flow: lobby → SD → BPC → score → lobby.
4. Stretch: V3 lobby treehouse garden tie-in.
5. Polish pass on whatever's weakest before the demo.

If anything slips, cut the stretch first, then BPC polish features (combos, mini-boss bag), keeping the core Pack/Ask/Leave loop intact.

## Open Items

1. Confirm V1's Active Scanner Guide tools (Scan / Highlight / Lane-Lock / Veto) don't accidentally re-create the annotation system we're removing from Stranger Danger. They live on different remotes — that's fine — but check the UI vocabulary stays distinct so the Guide isn't confused mid-round.
2. Decide whether Trust Seeds from a *failed* Stranger Danger run can still feed the stretch lobby garden (lean: yes, partial seeds for participation), since SD's redesign now has a hard fail state.
