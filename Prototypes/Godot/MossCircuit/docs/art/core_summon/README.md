> Final integrated true-scale native-window inspection accepted warning/release/recovery→walk in both facings, current-phase return after hurt and original ring separation. See [v17 QA](../../validation/v17-flow/QA_REPORT.md). This is phase/pose inspection, not continuous-video or human feel acceptance.

# Spore Reactor summon-attempt animation

## Why this changes the tell

The previous `boss_core_attack` source shows a radial projectile burst for both ring and summon. This independent 16-pose **summon attempt** visibly unfolds a low forked moss-root cradle, briefly holds a seed-light and retracts. The existing ring source and timing stay unchanged. No new ability is added.

The built-in `image_gen` generated the accepted source on 2026-10-25 after actual inspection of `assets/enemies/boss_core.png`. That image was used only for identity/style. The actual new source sheet was inspected: circular brass ring, cyan center and purple side vents retained, no child creature or radial projectile drawn. Full prompt is `generation-prompts.json`; original output `generated_images/exec-0fd6392d-6ed3-4634-89de-5db4feb1b8ea.png`. Project source `assets/actions/boss_core/boss_core_summon.png` preserves those original bytes.

- 0–6 warning: increasing root spread and slightly opening lower plates.
- 7: short seed-light at maximum spread; this marks an **attempt**, not a guaranteed child.
- 7–15 recovery: light disappears, roots close, intact hover returns.

Actual `EnemyAI` still decides release tick, phase count and cap. At phase 2 only pre-increment `attack_index % 3 == 2` chooses summon; other choices are ring, not simple alternation. Actual release attempts 1/2 children based on phase and may create zero when caps are full. The art never adds a child or changes gameplay clocks. Existing hurt/death priority must not delay, duplicate or replay the attempt.

## Geometry and source safety

Actual source size is **1312×1199 RGBA**, not the requested square. Equal quarter slicing would cut root tips and borrow adjacent rows. Explicit Y partitions `[0,320,622,910,1199]` and four 328-pixel-wide columns preserve all alpha≥8 pixels exactly once, with 4-pixel transparent source guards. The manifest uses one **512×400** logical canvas, fixed **(0.5,0.8)** anchor, reference height **246**, X registration **−6** source pixels and fixed per-row layout translations `[30,-264,-565,-847]`. No PNG edit, independent pose scale or per-pose recentering.

This is a floating creature. **Do not align every frame by its lowest root**: the roots are intended to unfurl. Upper body alpha edge remains 72–75 on the logical canvas while root ends vary 316–342. The source reference cyan-core centroid was measured at (207.37,222.90) within the original 418-pixel cell, relative to neutral body bounds `[124,136,201,218]`. New neutral centroid is (150.55,142.96), fixed to preserve the same approximate normalized orb location and hover height. The simple cyan-color mask is a registration aid, not proof of perfect perceptual alignment. Runtime window review remains required.

`build_metadata.py` reads source pixels only and writes deterministic metadata outside the input project. `source-analysis.json` records SHA, bounds, every source pose, alpha coverage and fixed transforms. All 16 poses have distinct pixel hashes; not a claim of hand-authored low-resolution frame-perfect motion.

## Runtime integration

Load `assets/actions/boss_core/attack_manifest.json` in addition to unchanged existing manifests. Only `boss_core` + actual `summon` selects `boss_core_summon` with true phase-driven segments warning `[0,6]`, attack `[7,7]`, recover `[7,15]` and locked AI aim during warning/recover. Keep old ring presentation as default. The release pose can be visible at first recovery tick; do not use a new delayed callback to spawn enemies. The art patch does not modify runtime or gameplay authority.

Focused source/atlas checks and Godot import are recorded here. Real final scaled/mirrored playback, interruption/resume and transition to walk require integrated rendered-window review; no GUI approval is implied by headless checks. The brief seed glow is baked into this source, so reduced-flash settings are not a guarantee of fully removing all luminous pixels.

`audit_orb_registration.py` and `orb-registration-audit.json` record an independent color-centroid registration audit using both the old hover source and all new frames. New neutral normalized orb error is below 0.004 body-height on either axis; final→initial source-pixel delta is about +8.38 X / +3.25 Y (5.63/2.18 world pixels at actual Boss height 57×2.9=165.3; source-to-world factor 165.3/246). These measured neutral differences are disclosed for final window review, not silently corrected by per-frame centering.
