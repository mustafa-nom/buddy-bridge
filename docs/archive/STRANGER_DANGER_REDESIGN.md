# Stranger Danger Park — Redesign

Replaces the puppy-clue + Explorer-acts loop with a Keep-Talking-and-Nobody-Explodes style submit loop where the **Guide commits the answer** and the **Explorer is the eyes**.

Backpack Checkpoint is unaffected by this redesign.

## One-Line Pitch

> The Explorer walks the park and describes who looks suspicious. The Guide is the only one who can actually accuse anybody — and they have to type in exactly what the Explorer says.

## What Changed vs. The Current Loop

| Old | New |
|---|---|
| Explorer talks to NPCs, collects 3 clues, finds the puppy | Explorer inspects NPCs, identifies the 3 risky ones |
| Explorer commits decisions in-world | Guide commits the answer in the booth |
| Manual is the centerpiece for the Guide | Manual is a togglable side reference; the booth itself is the puzzle |
| Clue/fragment system, puppy spawn, level exit | Submit-3-badges system with attempts |
| Mistakes from talking to risky NPCs | Mistakes from wrong submissions, 3-strike fail |

## Roles

### Explorer (eyes only)
- Walks the park, inspects NPCs via ProximityPrompt.
- Inspecting reveals the NPC's **behavior cue** (e.g. "Calling you over from a parked car") and their **badge** (color + shape on their shirt).
- The behavior cue is what tells you who's risky. The badge is just *how you describe them to your buddy*.
- Cannot accuse anyone in-world. Has to relay to the Guide.

### Guide (commits the answer)
- Sits in a booth with 3 pedestals, each holding one slot of the accusation.
- Booth is the puzzle. Manual is a togglable side reference, **closed by default**.
- Clicks a slot pedestal → a small UI opens with a color picker (4 options) and a shape picker (4 options) → confirm to fill that slot.
- Walks to a submit pad to commit the 3-slot accusation.

## Identifier System

- **Colors:** Red, Blue, Green, Yellow
- **Shapes:** Star, Circle, Square, Triangle
- 16 possible badges. **Full uniqueness rule:** every NPC in the round gets a different badge. No two NPCs share a color, no two share a shape — so descriptors like "blue star" are always unambiguous.
- With 4 colors × 4 shapes, an NPC count of up to 4 is the strictest "no shared color *or* shape" interpretation. With ~6–8 NPCs we relax to: badges are pairwise unique (no two NPCs share *both* color and shape), but Risky NPCs in particular are guaranteed to have no overlapping descriptors with each other. (Open: confirm 6–8 NPC target before implementation; if we want strict no-color-and-no-shape-overlap on the full 8, expand the palette to 5×5.)

## Booth Layout

Physical:
- **3 slot pedestals** in a row, each with a SurfaceGui showing its current `(Color, Shape)` selection or `Empty`.
- **1 submit pad** in front of the slots.
- **1 manual toggle button** (UI button on the Guide's screen, not physical).

UI overlay (opens when a slot is clicked):
- Color picker: 4 colored buttons.
- Shape picker: 4 shape icons.
- Confirm button. Esc/click-out cancels without writing.

## Loop

1. Round starts → scenario picks 3 risky NPCs and assigns unique badges to all NPCs.
2. Explorer inspects NPCs. Description card shows behavior + badge. They verbally relay risky-looking ones to the Guide.
3. Guide clicks slot pedestal → picks color + shape from the UI → confirms. Repeats for slots 2 and 3.
4. Guide walks onto the submit pad.
5. Server validates each slot independently against the 3-badge answer set (order-agnostic).
   - **All 3 correct:** all slots flash green, level ends, round proceeds to Backpack Checkpoint.
   - **Some wrong:** correct slots stay green and lock; wrong slots flash red and stay editable. Attempts counter decrements.
6. Guide clicks any red slot to reopen its picker UI and try again. Greens are not editable.
7. Resubmit. Repeat up to 3 attempts total.
8. **3 wrong submits → round fails** → kid-friendly recap → return to lobby.

## Submit Feedback Rules

- Validation is order-independent — accusing slot 1 = "blue star" is correct as long as "blue star" is one of the 3 risky badges, regardless of which slot.
- Per-slot feedback after each submit:
  - **Green:** badge matches one of the risky set. Slot locks.
  - **Red:** badge does not match. Slot is editable; click it to reopen picker.
- Attempts shown as 3 X-marks above the submit pad, filling in red as they're used.

## Failure Framing

Gentle, kid-friendly. No scary game-over screen.

> "Looks like a few got past us — but everyone got home okay. Wanna try again?"

Return to lobby. Pair stays paired so they can re-queue immediately.

## Code Impact

### Modified

- `src/ServerScriptService/Services/Scenarios/StrangerDangerScenario.lua`
  - Drop puppy spawn / landmark / fragment / `SafeWithClue` distinction.
  - Roles collapse to `Risky` and `Safe`. Force exactly 3 Risky.
  - Assign each NPC a unique `(Color, Shape)` badge. Store the multiset of risky badges as the answer.
- `src/ServerScriptService/Services/Levels/StrangerDangerLevel.lua`
  - Remove puppy-marker activation, level-exit Touched wiring, clue completion path.
  - Apply badge to NPC torso (SurfaceGui with color background + shape image — no asset uploads needed).
  - Wire booth pads: ClickDetector on each slot pedestal opens picker UI for that slot; Touched on the submit pad triggers validation.
- `src/ServerScriptService/Services/ExplorerInteractionService.lua`
  - `RequestInspectNpc` now also returns the badge.
  - Remove `RequestTalkToNpc` (no clue collection anymore).
- `src/ServerScriptService/Services/GuideControlService.lua`
  - Remove `RequestAnnotateNpc` and `GuideAnnotationResult`.
  - Add `RequestSetSlotBadge { SlotIndex, Color, Shape }` and `RequestSubmitAccusation`.
- `src/ReplicatedStorage/RemoteService.lua`
  - Add: `BoothStateUpdated`, `RequestSetSlotBadge`, `RequestSubmitAccusation`, `OpenSlotPicker` (server → Guide client when they click a pedestal).
  - Remove: `PuppyRevealed`, `RequestAnnotateNpc`, `GuideAnnotationResult`.
- `src/ReplicatedStorage/Shared/RoundState.lua`
  - Drop `CluesCollected`. Add `AttemptsLeft` (start 3) and `BoothState { Slots = {[1..3]={Color, Shape, Locked}}, History = {} }`.
- `src/StarterPlayerScripts/Guide/GuideManualController.client.lua`
  - Manual default-closed. Add toggle button.
- `src/StarterPlayerScripts/Guide/` — new controller for booth picker UI + slot displays.
- `src/ServerScriptService/Services/ScoringService.lua`
  - Wrong submission counts as a mistake. Failing all 3 attempts = no rank.

### Removed

- `PuppyRevealed` remote, `OnClueCollected` flow.
- `PuppyFound` celebration overlay (recent commit `d0910aa`).
- Annotation system (server + client).

## Studio TODO (`human_todo.md`)

To be added by the map builder:

1. **Booth template** (`ServerStorage/GuideBooths/DefaultBooth`):
   - 3 slot pedestals tagged `BB_BoothSlot`, attribute `BB_SlotIndex` = 1, 2, 3. Each has a SurfaceGui on the top face showing `(Color, Shape)` or "Empty".
   - 1 submit pad tagged `BB_BoothSubmit`, with a SurfaceGui above showing 3 X-marks for attempts.
   - Booth is enclosed; Guide cannot leave during the round.
2. **NPC templates** — no shirt asset upload needed. The level code applies a SurfaceGui on the torso at runtime with the chosen color background + shape image. Map builder just needs to ensure each template has a torso part the script can attach to.

## Open Items Before Coding

1. **NPC count target:** confirm 6–8 NPCs per round so the badge palette is sized right. If 8, may need to expand to 5 colors or 5 shapes to keep "no two NPCs share a color *or* a shape" possible. Simpler interpretation (no two share both) works fine with 16 combos.
2. **Manual contents:** keep the existing risky-behavior list (`StrangerDangerLogic.Cues`). No changes needed beyond display.
3. **Score screen:** does a failed run still grant any Trust Seeds (participation), or zero? Current lean: zero. Failure goes straight to "Wanna try again?" recap, not the full score screen.
