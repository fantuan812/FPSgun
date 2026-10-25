> Final r2 was accepted in the actual Linux game window for both-facing terminal handoff, interrupted/current-phase charge and readable warning. See [final integration QA](../../validation/v16-runtime/QA_REPORT.md). Earlier source-only limits below describe the authoring handoff, not replacement for that final evidence.

# Warden straight-charge animation

## Scope and visual decision

The prior `boss_warden_attack` sheet visibly raises both fists and slams the floor. Its reuse for the existing straight charge gives the wrong body tell. This batch adds one independent 16-pose **charge**, preserving the old slam bytes for `blast`; it does not change combat rules.

The accepted original was generated with the built-in `image_gen` on 2026-10-25, using `assets/enemies/boss_warden.png` only as an identity/style reference. Actual pixels were inspected. Full prompt: `generation-prompts.json`. Original generation output: `generated_images/exec-61998e80-d45a-43ae-a013-05f07c83f87f.png`. Runtime source bytes: `assets/actions/boss_warden/boss_warden_charge.png`.

- 0–5: planted stance → bent knees → fists tucked into a low forward ram.
- 6–11: active left-facing shoulder charge, leg articulation, modest trailing dust.
- 12–15: braking → rise → intact upright neutral stance.
- No overhead fists, ground-impact star, or radial slam in the new charge.
- Source order is unchanged. All 16 poses are distinct by pixel hash; this is not proof of ideal motion timing.

## Atlas contract

`assets/actions/boss_warden/attack_manifest.json` contains the new asset only. The source is 1254×1254 RGBA. `build_metadata.py` measures pixels read-only and emits deterministic metadata outside the input project. PNG pixels are neither re-painted nor cropped/resized on disk.

Naïve four-by-four division clips one dust fleck and borrows its remainder into pose 9. Explicit source partitions preserve complete alpha≥8 pixels exactly once. Each region has a true transparent guard, normally 4 px; the narrow gap between poses 8 and 9 permits 1 px on each side. Very-low-alpha fringe below threshold is not used to expand the measured body silhouette, consistent with the existing reaction pipeline.

All poses share a **512×400** logical canvas, fixed anchor **(0.5, 0.8)**, fixed reference height **207** source pixels. One action-wide X registration offset of −20 source pixels aligns neutral stance; fixed row translations remove sheet layout spacing, not within-row movement. No independent pose scaling or bbox normalization. The explicit recovery registration correction below is the only per-pose translation exception. Visible lower edges are 317–322 on the logical 320 baseline, preserving natural running lift while avoiding row jumps.

## Runtime integration contract

The controller observes the existing enemy `attack` value. Select the new asset **only for Warden `charge`**; preserve old blast selection and its timing. During charge only, use true AI-driven segments `warning:[0,5]`, `attack:[6,11]`, `recover:[12,15]`; use locked `aim` for horizontal facing during these states. Release frame 6 is descriptive, not an authority to move/damage/spawn. Real `charge_left`, `warning_left` and `recover_left` supply progress. A hurt reaction temporarily takes priority and then returns to the current actual phase; it must not replay a missed charge or alter gameplay time. Death remains higher priority.

The art worker does not edit `scripts/main.gd`, `scripts/actor_director.gd`, `data/actor_actions.json` or gameplay authority. Integration is coordinated separately.

## Verification / limits

Source/atlas checks and headless import results are recorded in `source-analysis.json` and the parent integration report. `tests/test_warden_charge_assets.gd` is a focused resource/geometry contract, not a gameplay or GUI acceptance substitute. Source sheet visually inspected, but final scaled animation, left/right mirroring, interruption/resume and charge-to-walk handoff still need actual rendered-window review. These are high-resolution pixel-style sprites, not native hand-pixelled 32×32 animation.


## Recovery alignment correction (2026-10-25)

A semantic-feature audit found that the final **upright neutral** image was translated left relative to the initial neutral: strongest bright faceplate centroid X223.6→193.0; shoulder highlight308.2→272.4, with effectively unchanged Y. This is not justified by a final charge lean; it would produce roughly a 10-world-pixel jump when switching to centered walk.

The original PNG bytes remain unchanged. Author-chosen recovery pose X corrections are `{12:0,13:10,14:20,15:31}` source pixels, applied only to `AtlasTexture.margin.position.x` and the descriptive logical alpha bbox. All other metadata, scale, centered anchor, source regions, chronological frames and gameplay timing remain unchanged. Corrected final faceplate is X224.0 vs initial223.6; final visible bbox center257.5 vs initial254.5. Progressive corrections during braking remove the terminal jump without silently normalizing every pose's bounding box. `semantic-anchor-audit.json` states the pixel-selection method and before/after measurements. Actual GUI A/B acceptance is recorded separately, not inferred from these numbers.
