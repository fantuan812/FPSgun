# MossCircuit v18 — independent final QA

2026-10-25 UTC. **Accepted for the tested presentation-only scope.** No new release-blocking failure found. This report uses stable snapshot labels and repository-relative evidence references; no execution-workspace locations are required for verification.

## Frozen source and independent full regression

- Tested source: `frozen-v18-candidate`, 1,531 files including MANIFEST.json.
- Tested manifest SHA-256: `7e70a28d97b1b4f279c290d81d181213fdf39ab2a62c97bb1f5eb3cbd1ccd806`.
- Fresh independent snapshot: `independent-v18-cold-copy`; no `.godot` before import. All 1,530 manifest entries verified, then rechecked in both source and QA copy after regression with zero differing bytes. See `source-verification.json`.
- Independent cold import and **all 58 standalone entry points PASS**: 59 passes including import, zero ERROR, all success markers, and `input_changes: []`. See `regression/result.json`, `summary.json`, `input-hashes.json` and raw logs.
- Focused final results include discrete UI values 34 checks; crawler fixed-column registration 316 checks at actual visible height 35.10869; actual primary-hit pipeline 48 checks; and the existing full contact-enemy/action/mode/transaction coverage. These headless results are not substituted for GUI inspection.
- Production changes are limited to `ui/moss_ui.gd` and `assets/actions/crawler/action_manifest.json`. Final UI SHA-256: `55ce901e2d1c10c2b47ea9f8084108300cbde1693aa58d352b2bbe2285e43ee7`. Final crawler manifest SHA-256: `99546710d4015da3bd91f1c3c770bb13add88ba2124405c5d52a57dabd2861d8`.

## Final native graphical UI check

Actual Godot 4.6.3 cloud Linux GUI, OpenGL/Mesa llvmpipe, logical 960×540 viewport. Native window captures are 1180×812 including the game's letterboxing. **Not Windows/exported executable testing and not human play.** Inputs were automated CUA mouse/keyboard operations.

The final UI was tested using `fixture/qa_shop.gd/.tscn`. This explicitly controlled setup creates four weapons, 100 scrap and one forced Shock Mortar offer; it does not claim those were legitimately earned. All subsequent selections, purchases, refreshes, inventory interruptions and sales use production UI/transaction code through actual mouse/keyboard input. All 103 production inputs in that GUI copy match the final frozen source, including runtime alpha-bounds metadata; see `gui-runtime-hashes.json` and `gui-source-match.json`.

Observed sequence:

1. The full-slot first offer remains readable at zero scroll with destructive-replacement warning, selector and action visible together. Labels now read **WEAPONS 4 / 4**, **REPLACE / 46 SCRAP**, **REFRESH / 5 SCRAP**, without spurious `.0` suffixes.
2. Keyboard selector chose **Rail Lance in slot 3** rather than default slot 1. Tab/Return replaced it with Shock Mortar. Scrap **100→54**, generation **2→3**, all four slots retained, offer SOLD.
3. Two clicks on disabled SOLD did not charge again. Inventory showed correct slot 3 and **MODULES 0 / 8**. Escape returned to the same stock/scrap/generation.
4. Real refresh cost exactly 5: **54→49**, generation 4. Scrolled to Medic Seed; BUY showed **28 SCRAP**. Expanding item details preserved scrap and generation. **STACK CAP: 1** was integer-formatted while the continuous field retained **ICD: 0.00s**.
5. Purchased Medic Seed: **49→21**, generation 5. Inventory showed **MODULES 1 / 8**, **Medic Seed x1 / 1**, and the same stack-cap/cooldown details.
6. Returned to shop, scrolled the inventory column, and observed **SELL ONE +14**. Selling refunded exactly **21→35**, generation 6, removed the module, and inventory showed **MODULES 0 / 8**. No unwanted re-roll or extra transaction was observed.

Ten direct game-window-only screenshots under `screenshots/` document this sequence: initial/selected/purchased/inventory/return/refresh, module details/inventory/sell-visible/sold. The original JPEG transport bytes are saved with matching `.jpg` suffixes, not edited or enlarged. No desktop, editor, browser, dock or unrelated content is distributed.

## Crawler native A/B and actual-hit integration

The full accepted crawler A/B evidence is included under `crawler-ab/` with its own report/index, 17 native game-window captures, identical fixture sources and raw hit-pipeline logs. This is actual-size **stationary rendered phase-stepping** of two real `_spawn_kind("crawler", ...)` actors facing opposite directions, not ordinary combat GUI or recorded continuous real-time motion.

- Baseline hurt2→3 and hurt5→6 visibly relocated the body horizontally at source-row boundaries despite fixed world positions.
- Corrected fixed-column metadata removes those resets in both facings, preserves vertical duck/recoil and natural leg changes, and keeps hurt entry/terminal hurt8→current walk2 registered. No crop/scale pop was observed.
- Repeated hurt trigger at age 0.180 was rejected without restarting frame6; expiry at 0.270 returned to current walk2. The art worker independently inspected the native captures and concurred.
- A/B damage-pipeline tests use actual primary-hit collision plus main simulation/damage observer. Baseline and candidate each pass 48 checks across both modes/sides with exactly equal finite authority traces: damage still applies during an existing hurt reaction, movement continues, age is not restarted, expiry follows current walk time, and lethal damage interrupts to death0 with a single kill.

The A/B GUI captures predate the final integer-only UI change. `gui-source-match.json` proves their corrected crawler manifest is byte-identical to final v18 and the **only** runtime difference from that aligned A/B copy is `ui/moss_ui.gd`; all animation, AI, source PNG, timing, death and flanker inputs remain the same. The actual-hit test was rerun as part of the final full 58-entry suite. This evidence is not mislabeled as a new complete campaign or a final-build replay of every animation pose.

## Scope and remaining limits

Completed: exact final cold full suite; final native discrete-value formatting; full-slot keyboard replacement; duplicate SOLD clicks; refresh; read-only module details; module purchase/sale; interrupted inventory returns; accepted actual-scale mirrored crawler registration and final hit-pipeline regression.

No full Arena/Rooms campaign was repeated for these two presentation-only changes. Prior v17 normal Rooms and v16-r2 full Arena results remain historical evidence, not new v18 runs. Windows, real target-GPU performance, gamepad/touch, audio, human balance/timing and continuous-motion video review remain untested.

No publication was performed by QA. Frozen source and earlier immutable evidence were not edited. Publisher-specific documentation/parent-commit updates and final archive/remote identity verification remain separate release gates. `EVIDENCE_SHA256.json` indexes all files here except itself; nested `crawler-ab/EVIDENCE_SHA256.json` is retained and independently valid.
