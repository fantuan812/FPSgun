# Crawler hurt source-column registration candidate

**Isolated v18 candidate, not part of accepted v16/v17. Native small-scale GUI A/B accepted as recorded below; final integrated regression is still required.**

## Diagnosed defect

The existing nine-pose `crawler_hurt.png` was visually inspected alongside its original `beetle_walk.png` reference. Neutral eye/body position changed horizontally through each source row despite a mostly vertical recoil animation. A read-only white-eye feature measurement repeats the same pattern across all three rows: mean logical eye X per column is **176.50, 155.19, 125.81**. The first-to-last eye delta is **−52.92 source px**. This repeated column signature identifies layout spacing (~400 px actual versus 422.667 px assumed) rather than a different physical recoil in every third pose.

The source image is retained byte-for-byte. This is **not** a new generated image, not a new attack, and not per-frame bbox normalization.

## Narrow correction

Only crawler hurt's fixed source-column layout calibration changes:

- Columns 0/1/2 receive layout offsets `[0,21,51]` source pixels.
- One action-wide neutral-eye registration of `−25` aligns to the existing walk reference.
- Net fixed column offsets are **`[-25,-4,26]`**, repeated unchanged for every row.
- Only `AtlasTexture.margin.position.x` and descriptive logical alpha-bbox X move.
- Source regions, all Y coordinates/recoil, scale, 512×400 logical canvas, anchor, 260 reference height, nine-frame chronological order, 0.27-second duration, death data and all gameplay authority remain unchanged.

Corrected mean eye X per column is **151.50, 151.19, 151.81**. Neutral first-to-last X is **−1.92 source px**, while the original vertical recoil difference is preserved. Author values use semantic eyes and source-column layout, not independent frame bounding-box centering. `audit.py` reproduces every source measurement and asserts the exact metadata-change boundary. The modified existing `docs/art/contact_enemies/build_metadata.py` reproduces both runtime and documentary manifests; flanker outputs remain byte-identical and crawler death data is unchanged.

## Actual scale and checks

Crawler uses `assets/beetle_walk.png`, whose legacy padding makes its actual visible spawn height **255×57/414≈35.1087 world px**, not the requested full texture height 57. The focused Godot test instantiates the real `Art.actor` and `ActorDirector`, derives this height, checks both mirrored directions and all nine frames, and asserts fixed source/scale/anchor geometry. Corrected terminal eye X delta is about **−0.2597 world px**; previous X delta was about **−7.1463 world px**. These measurements are not a substitute for native rendered inspection.

Validation so far: focused registration test **316 checks, zero failures**, plus existing author and independent contact-enemy tests in the isolated art sandbox; deterministic metadata regeneration also passes. This is not the complete current-version regression or GUI acceptance.

Final integration must retain the native actual-size and mirrored hurt entry, row-boundary and hurt-to-walk results recorded below, and recheck actual damage-triggered behavior in the final regression. Do not introduce fake warning, movement pause, damage timing or a new contact attack. Accepted v16/v17 freezes remain untouched.


## Actual-size native GUI A/B review (2026-10-25)

QA used an external stationary presentation fixture, calling the real `_spawn_kind` and `ActorDirector` at visible height 35.10869. Gameplay was frozen; both horizontal facings were shown simultaneously. Source reaction time advanced at 0.005-second boundaries; this was not combat damage or continuous-motion certification.

Both QA and the art author inspected native baseline/candidate screenshots. Baseline source-row boundaries 2→3 and 5→6 visibly shift sideways. The corrected versions remove those horizontal resets while retaining vertical duck/recoil, recognizable poses and same scale. Hurt entry and frame 8→current walk handoff remain registered in both facings. Repeated hurt at age 0.180 is rejected (`[false,false]`) without restarting frame 6; expiry at 0.270 returns current move frame 2.

Stable evidence label: **Independent crawler registration A/B QA — 2026-10-25**; native capture names `crawler-baseline-*.jpg` and `crawler-aligned-*.jpg`; the independent integrated QA report owns publication of this evidence. Source PNGs were not changed by the fixture. The baseline/candidate fixture production difference is only the crawler action manifest. Art verdict: **accept this fixed-column metadata correction for integration**, subject to final candidate regression and unchanged-resource verification. `unchanged-resources.json` pins the relevant v17 source inputs for that check.
