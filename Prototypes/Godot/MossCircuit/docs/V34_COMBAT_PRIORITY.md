# v34 combat priority — engineering and finite verification

Status: held-source and final-source/pack gates passed. The one ordinary attempt is explicitly accepted with limited observations, not an all-action pass. Helper/manual rollback and public evidence retain separate receipts. [Exact contract](V34_COMBAT_PRIORITY_CONTRACT.md) SHA4d62ed5b5dc8f6e2f0827c4e5188929ce8b0125a322ed9e08046780e89e55c37 was independently accepted before production edits under root's conditional same-scope approval.

## Mechanic and tradeoff

Unhandled playing-only LMB press selects the nearest pick-disk center to the click (exact ID tie); valid empty ground clears. The closed picking radius is16×actor scale+8world units, not any-pixel sprite selection. Finite position/scale/radius/squared-distance and viewport/canvas/field checks prevent invalid coordinates becoming a clear or an always-hit disk. Visible HUD/boss/objective/badge rectangles are explicitly excluded because several UI nodes intentionally ignore mouse events. The event's viewport point is transformed once through the current CanvasItem/camera transform, never hard-coded desktop scaling.

One transient `combat.focus_enemy_id` owns priority. `combat_focus.gd` is pure geometry/live-ID/range lookup. `_focus_click` changes only the ID; `_focus_view`, full-view metadata and captions remain read-only. Shared step/lifecycle boundaries clear invalid/dead/removed IDs. A later weapon slot revalidates a focus killed by an earlier slot before removal. Pause/settings/inventory/upgrade retain focus; encounter clear/title/newrun/dead/won clear. Merely leaving range or viewport preserves it.

Rivet/Shotgun/Rail/Return/Mortar retain their old strict-range, first-nearest fallback. Cryo/Bankshot retain their existing ordered eligible set and0.0001reach tolerance. Cryo changes orientation, not damage-victim iteration order. Orbit does not use priority. Existing damage, tempered multipliers, target brace, collision interception, projectile/blast snapshots, Return steering, Bankshot Guide and secondary targeting are untouched. Preferential aim is not a guarantee that the marked enemy is hit.

Idle rig overrides are optional slot→position values only for eligible directional copies; other slots use the existing common idle target. Default calls remain compatible. Selection does not reset rig ages/clock/generation/history. Static pale corner brackets and an additional existing-objective line show name/range eligibility; radial-only loadouts explicitly say aim is unchanged. Existing first-line objective and boss/HP/XP/mechanic HUD remain. Independent source-native layout/input checks passed; exact-pack controlled and ordinary scopes are separately recorded below.

## Current executed author proof

- Held R1 full regression:107 standalone checks plus reused-cache import =108 PASS, no engine ERROR, all657 frozen inputs unchanged. The initial author import was cold; subsequent aggregate import reused it.

-344 geometry/input-gate/lifecycle/read-only/idle assertions and228 controlled actual8-path attack assertions pass, both modes. Existing temper290/413 and mounted-weapon checks also pass.
- Actual six-route transactions SHA22e28521ba76fb7285a59b98593aecc7c4af9e24d497853119f73495324feaf8 and24-case combat SHAe7d93a1fcf01345c540bf9f868632310fd3e85572dbe431dbe12d43bf19212ec are byte-equal to independent fresh exact-v33R2 pre-code executions (not relabeled R1 baseline runs).
- Initial fire fixture had224passes/4failures: the Orbit target was110 away, beyond unchanged105radius. Production correctly left it untouched. Original script/log preserved; in-range Orbit fixture alone moves to90; all seven aimed paths remain110 and the dedicated outside-range case stays unchanged. Fresh rerun passed.

## Independent held-source acceptance

- A separate exact657-file copy had an actual cold import. Clean independent authority356, actual-combat945 and real GUI-dispatch/camera366 assertions pass. Six old transaction and24 combat outputs equal the fresh exact-v33R2 baseline bytes. All candidate inputs remained exact.
- Six controlled native cases used actual mouse input in both modes at960×540,1280×720 and1180×812 letterboxing, with14 captures. Current camera mapping, select/change/empty-AUTO, HUD/objective/boss exclusion, right-button/release/drag behavior, pause retention and per-copy cue were observed within their recorded cases. Closure used external Ctrl+C and window absence; do not relabel that as a normal exit0. ALSA/VSync environment warnings are disclosed. Final exact-PCK/ordinary results are separately scoped below.
- Measured focused Label minimum is49px (two23px lines plus spacing), while AUTO retains42px. Root accepted this transparent-area clarification after viewing native capture01; original objective/HUD/boss remain unobstructed. The exact [addendum](V34_OBJECTIVE_HEIGHT_ADDENDUM.md) records the rejected42px oracle and actual lower7px exclusion checks. Original contract4d62 remains byte-identical; no production change.
- Independent rejected fixture runs remain evidence: String-only snapshot-key serializer assumption, a close-Rail forward-muzzle-ray assumption disproved by exact old control, Arc recipient-count expectation (ordinary count2), and the exact42px label-height assertion. Clean corrected suites, not superficial counters from error logs, establish acceptance. An initial native y187 click was outside the measured label; corrected y176 lower-edge tests are separately recorded.

No all-action ordinary success, Windows/controller/audio, complete campaign or broad balance/performance acceptance is inferred from these checks. Previous v33 Arena433 terminal victory is an immutable separate supplement, not a v34 result. Source/history documentation is restored from accepted local-v33 release bytes rather than stale engineering pending notes; production baseline remains exact except the declared v34 focus paths. No remote or Library writes are performed by this implementation worker.

## Final source and resource PCK

Final promotion changes no held production byte:124 production inputs,664 frozen source inputs. Author and independent full110 standalone+import111 pass with no input changes or GDScript errors. Author final pre-freeze import was an actual cold new-root import; its later aggregate reused that cache. QA final aggregate reused its separately cold-imported held cache, applying only11 declared docs/test/UID/manifest paths. No cold-run claim is borrowed from another phase.

Both preset PCKs are41,405,276 bytes, SHA256250ea5966ff7ca35b42a13cd813ba5ff156288cfc97110a411dd73664ccbbe02. The unchanged ELF is2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0. Independent source-oracle regeneration equals author74af27ad3a27af47201c1d1c91243462c94cfdfe2eb396e903ec6e98a22e7169; packed resources849, authority356/combat945/views366 and Python3 pass. A Windows preset export is not Windows execution.

## Exact-pack controlled supplement

Two cases, Arena960 and Rooms1180×812 letterbox/edge camera, produced4 captures. Actual mouse selected an on-screen clipped actor; externally relocated living off-screen marks persisted with eligibility2/3 in the Arena case and0/3 in the separately configured Rooms case, not a temporal transition in one case. Actual bottom7px/black bars rejected click leakage and empty field cleared. Editor engine loaded the exact PCK from an empty reader using an external injected build/actor fixture with normal processing disabled. External fixture F9 quit exited0 and its window disappeared; this is not a shipped game quit control or ordinary release-ELF gameplay. Terminal-directed clicking did not establish actual WM focus loss, so no native focus-loss claim; direct notification/lifecycle tests remain headless.

## One ordinary attempt — accepted limitation, not a clean all-actions pass

One exact release-ELF Arena/Rivet433 attempt used real controls/tactical pauses without injected state, reset, undo or retry. Initial35scrap/100HP/Rivet was observed. Natural wave1 settlement and queued upgrades, plus a real unplanned Bankshot purchase retained as-is, led to wave2/LV5/120maxHP/100scrap with Rivet+Bankshot. Ambiguous/stale-looking menu frames do not establish exact intervening upgrade/purchase input chronology and do not imply a product bug.

Capture14 directly shows Violet Spitter PRIORITY with2/2 in-range weapons. Pause/build/back/resume and return-to-title navigation were observed across19 captures. But the next recorded resumed frame was already AUTO while kills increased: ordinary manual target-change, causal empty-ground clear and pause retention are NOT established. One final mark/empty-input batch was followed by an argument-size save failure for its two live screenshots; no outcome is inferred from inputs alone. Root explicitly accepted this finite observation on2026-10-26 and prohibited a second attempt chasing a cleaner story. Controlled-source/pack/native proofs remain separate, not silently upgraded to ordinary evidence.

After return to title, external Ctrl+C closed the process/window; no graceful/exit0 receipt exists. ALSA unavailable/dummy fallback and VSync warnings are disclosed, with no GDScript runtime error observed. Post-close all664 source/PCK/ELF identities remained exact. No full campaign, victory, Windows execution, audio output or physical-controller claim.

## Release evidence and inheritance

[Independent QA](validation/independent-v34/QA_REPORT.md) owns raw/corrected oracles, native/ordinary limits and exact helper/manual rollback. [Author evidence](validation/author-v34/AUTHOR_REPORT.md) preserves both full aggregates, focused failures/reruns, exact6/24 outputs and pack checks. Original4d62 contract and corrected7337ec9e presentation addendum are exact. Final source release inherits accepted LOCAL v33 history, changing only current README/delivery/v34 notes/manifest after the tested664 inputs; all124 production bytes remain exact. No runtime binary, generated profile/cache, private Library identity or remote mutation is included in source evidence. Local prepared Git IDs and recovery are not reachable Git delivery proof.
