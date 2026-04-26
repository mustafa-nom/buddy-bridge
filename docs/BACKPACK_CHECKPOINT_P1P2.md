# Backpack Checkpoint V1 — P1 + P2 Implementation Notes

Companion to `BACKPACK_CHECKPOINT_DECISION.md` and `BACKPACK_CHECKPOINT_PRD_V1_POLISHED.md`. Records what shipped in P1 / P2, what's verified, what's out of scope.

## Files added / modified

**New (server)**
- `src/ServerScriptService/Services/Levels/BackpackCheckpoint/MiniBossDirector.lua` — VIP bag, sequential inner items, fail-on-high-combo.
- `src/ServerScriptService/Services/Levels/BackpackCheckpoint/GuideRehydrate.lua` — re-fires scanner state on Guide respawn.
- `src/ServerScriptService/Services/ScannerService.lua` (already P0; extended P1 with Veto + intro gate fire).

**New (client)**
- `src/StarterPlayerScripts/Guide/ScannerGuideHud.client.lua` — full Active Scanner workstation.
- `src/StarterPlayerScripts/UI/PixelPostIntroController.client.lua` (P0) — extended P2 with Continue button + gating.
- `src/StarterPlayerScripts/UI/TutorialPromptController.client.lua` — first-time role tutorial overlay.

**Modified**
- `src/ReplicatedStorage/RemoteService.lua` — added `RequestVeto`, `VetoActivated`, `VetoEnded`, `MiniBoss*`, `TutorialPrompt`, `FieldManualUpdated`.
- `src/ReplicatedStorage/Modules/Constants.lua` — wave/scan/intro/veto/mini-boss tunables.
- `src/ReplicatedStorage/Modules/ScoringConfig.lua` — combo multiplier table, Mini-Boss fail threshold, success bonus, Veto combo divisor.
- `src/ServerScriptService/Services/ScoringService.lua` — `AddTrustPoints` accepts multiplier; `ReduceStreak` for Veto cost.
- `src/ServerScriptService/Services/DataService.lua` — `EncounteredItems`, `MarkItemEncountered`, sub-tabled `HasSeenTutorial`, helper accessors.
- `src/ServerScriptService/Services/Levels/BackpackCheckpoint/BeltController.lua` — `HaltBelt` / `ResumeBelt` (used by Veto + Mini-Boss), Field-Manual encounter calls, Veto/MiniBoss state cleanup.
- `src/ServerScriptService/Services/Levels/BackpackCheckpoint/WaveDirector.lua` — hands off to `MiniBossDirector` after wave 3.
- `src/ServerScriptService/Services/Levels/BackpackCheckpointLevel.lua` — intro gate, respawn watcher, Explorer-death drop-not-bin recovery, tutorial gating.
- `src/ServerScriptService/Services/ExplorerInteractionService.lua` — passes combo multiplier through to scoring.
- `src/StarterPlayerScripts/Guide/Manuals/BackpackCheckpointManual.lua` — `MarkSeen` / `MarkAllSeen` for Field Manual session meta.
- `src/StarterPlayerScripts/Guide/GuideManualController.client.lua` — listens to `FieldManualUpdated`.

## Open Ambiguities resolved (Addendum A1–A6)

- **A1 (Trust Seeds on failed runs).** No change to `RewardService` — Mini-Boss fail still routes through `ScoringService.CalculateFinalScore` → rank → seeds-by-rank, so a failed run earns at least Bronze seeds for participation. Aligns with the addendum's lean: yes, partial.
- **A2 (V1+V3 lobby tie-in payload).** Out of scope for this PR; `RewardService` already grants seeds per-round, the tie-in can listen to the existing `RewardGranted` remote.
- **A3 (item-pool target).** Registry expanded from 13 → 20 items in P0 (within the 12-floor / 40-target range). Adding more items is data-only.
- **A4 (intro art).** Engineer-drawn placeholder used (text card with "✉ PIXEL POST" stamp). Map builder can replace with art later.
- **A5 (belt speed numbers).** Wave 1=6, Wave 2=8, Wave 3=10 studs/sec placeholder in `Constants.BACKPACK_BELT_SPEED_PER_WAVE`.
- **A6 (hard wave cap).** Not enabled. Wave-drain rule from edge case 9 stays as-is. Add `Constants.BACKPACK_MAX_WAVE_SECONDS` + a force-finish path if playtest demands.

## Edge cases covered (per addendum)

P0: 1, 2, 5, 6 (partial — death-only), 9, 10, 11, 17, 19, 25, 26, 27, 31, 32.
P1: 7 (skipped per fallback — single active item retained), 8, 12, 13, 14, 15, 16, 20, 21, 22, 23, 24.
P2: 3, 4, 6 (Explorer death clears Held; full benign-drop polling deferred), 18, 28, 29, 30.

## Out of scope (deliberate descopes)

- **Two-on-belt in Wave 3.** Single active item retained in Wave 3 per the multi-active-item milestone fallback. The `ActiveItems` map shape change can land post-hackathon without breaking the demo.
- **Drop-not-bin polling.** Only Explorer death clears `HeldByPlayer`. The "wandered out of bin radius" benign recovery is not implemented; the fall-off timer ultimately catches it as a mistake.
- **Hard wave cap (A6).** Wave-drain rule has no wall-clock ceiling. Acceptable for a 36-hour demo; add a cap if pacing playtests too long.
- **InnerItem nesting (envelope-with-payload).** PRD sketch shows `innerItem = nil`; not modeled in `ItemRegistry`. Mini-Boss bag stands in as the only "nested" content for V1.
- **V1+V3 lobby Trust Garden tie-in (stretch).** Not built. Decision doc lists it as a stretch; left as a note in `human_todo.md` if added.

## Verification status

### Static checks (done)

- All `.lua` files under 500 lines (max: BookView.lua at 472, untouched).
- No remaining references to `RequestAnnotateItem` / `ItemAnnotationUpdated` (only one historical comment in `ScannerService`).
- All BPC remotes routed through `RemoteService.lua` with role + rate-limit validation in handlers.
- All round-scoped state lives on `round.LevelState[BackpackCheckpoint]`; no module-level mutable state.

### selene (HUMAN — not installed locally)

`selene src/` should be run by the user; the project lists it as a HUMAN task in `tasks/todo.md`.

### Studio smoke tests (HUMAN — 2-player local server)

P1:
- [ ] Wave 1–3 progression with combo bar ticking through ×1.0 → ×1.5 → ×2.0.
- [ ] Veto: re-locks lanes for 3s, halves combo, button greys out for the rest of the round.
- [ ] Mini-Boss success path: 3 inner items sorted correctly → bonus → level complete.
- [ ] Mini-Boss fail path: build streak ≥5, deliberately wrong-sort an inner item → round ends with `MiniBossFail`, kid-friendly toast appears.
- [ ] Mini-Boss below threshold: streak <5 wrong sort → `AddMistake`, bag continues.
- [ ] Scanner Guide HUD: Scan reveals tags, Highlight rings cycle, Lane Unlock toggles correctly.

P2:
- [ ] Pixel Post intro: Continue button shows after 3s; Wave 1 only spawns once both clients dismiss OR after the 30s timeout.
- [ ] Field Manual: items seen in run 1 show green seen-dot in run 2 within the same session.
- [ ] Guide rehydrate: force Guide death (or `Humanoid:LoadCharacter()`) mid-round; HUD redraws active item / lane locks / scan tags / Mini-Boss state correctly.
- [ ] Drop-not-bin: kill Explorer mid-carry; item stays at last position; no extra mistake; fall-off timer continues.
- [ ] Tutorial: first BPC round of session shows the per-role overlay; second BPC round same session does not.

Cross-level regression (per addendum, run when annotation split landed):
- [ ] Stranger Danger round: NPC annotation buttons still work (`RequestAnnotateNpc` → ring colors), no `RemoteService` "remote not found" warnings.
- [ ] SD → BPC back-to-back round: clean transition, no orphan UI panels carry between levels.

PartnerLeft regression:
- [ ] Close one client mid-Wave-2 / mid-Mini-Boss; verify the round ends cleanly, no orphaned models, slot is released.
