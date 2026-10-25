# Crawler hurt registration — independent isolated A/B QA

2026-10-25 UTC. **Accept metadata correction for integration/regression**, within the scope below. This is not a v17 source amendment or an already published release.

## Exact setup

- Frozen baseline: v17 source manifest SHA-256 `2d4c9d8f465cf1863a2da6dee5b5304b654fbb3a298672dbab14e8e73859bc7f`.
- Baseline crawler action manifest SHA-256 `45ca7df2111d238d060011cdabf7f2bbdd6d11734d2ac86986d1605c4fae0b7d`.
- Candidate crawler action manifest SHA-256 `99546710d4015da3bd91f1c3c770bb13add88ba2124405c5d52a57dabd2861d8`.
- 103 production inputs are fingerprinted in `source-verification.json`, including runtime `art_source/alpha_bounds.json`. Baseline matches v17 for every path; **the only candidate difference is `assets/actions/crawler/action_manifest.json`**. PNG pixels, scripts, data, source regions, Y recoil, scale, anchor, reaction timing and death metadata were not modified by QA.
- Two isolated QA projects share the same `qa_crawler.gd/.tscn`, with stripped documentation/test assets rather than representing a new full shipping package. Frozen v17 and its final QA evidence remain untouched.

## Actual native graphical A/B

Actual Godot 4.6.3 cloud Linux GUI, OpenGL/Mesa llvmpipe, logical 960×540 viewport; native window-only captures 1180×812. Automated CUA keyboard inputs controlled the fixture. These are not headless screenshots, Windows tests, human play, or recorded continuous-motion review.

The fixture instantiates the real main scene and two real `_spawn_kind("crawler", ...)` actors at fixed world positions, with opposite horizontal facings. Registered visible actor height is **35.10869 world pixels** (255×57/414), not an enlarged debug rendering or an assumed 57-pixel visible body. It freezes authoritative simulation and advances the production ActorDirector in 0.005-second steps until each requested frame boundary. A caption explicitly marks stationary presentation-only QA. This fixture does not claim legitimate gameplay progression or actual combat damage input.

Inspected baseline and corrected walk0→hurt0; hurt2→3; hurt5→6; hurt8→current walk2. Baseline and corrected screenshots show identical scene/actor placements.

- **Baseline defect reproduced:** at both source-row boundaries, each crawler's body visibly shifts sideways despite fixed world position, reversing direction under mirroring. This agrees with fixed source-column spacing drift, not movement AI.
- **Candidate accepted:** repeated horizontal row resets are removed in both facings. Vertical duck/recoil and natural leg changes remain intact. Hurt entry and terminal handoff stay registered; no crop/scale pop was seen.
- Repeating hurt at age 0.180 leaves frame6/age unchanged and returns `[false,false]`, as expected for the production reaction restart guard. Expiry at 0.270 returns to **current walk frame2**, not frame0.
- The art worker independently inspected baseline hurt2/3/5/6 and corrected hurt0/2/3/5/6/8 plus return captures and concurred with this scoped acceptance.

All 17 files in `captures/` are direct native game-window-only JPEG bytes. They contain neither surrounding desktop nor editor/browser/dock content. Names identify baseline/aligned, frame, repeated-hit trigger and return. No screenshot was enlarged or repainted.

## Actual damage pipeline — controlled headless supplement

`independent_crawler_hit_pipeline.gd` executes production primary-hit collision (`_hit_segment`) followed by real main simulation and the damage observer, for Arena/Rooms and both sides.

- Baseline **48/48 PASS**, candidate **48/48 PASS**, no ERROR.
- First hit reduces HP and starts hurt0 through the real observer.
- Second real hit still damages without restarting reaction age.
- Authoritative movement continues during hurt.
- Hurt expiry returns to the current walk phase; a later hit starts a new reaction.
- A lethal hit interrupts into death0, removes the enemy from combat and increments kills exactly once; later hurt cannot restart death.
- Recorded authority traces (position, HP, elapsed time, enemy count, RNG, run state, kills and reaction age/state) match **exactly** between baseline and candidate for these finite scenarios. See `hit-pipeline-comparison.json` and both raw logs.

This test validates controlled integration, not ordinary combat GUI or broad randomized parity. Existing author checks are documented by the artist; this evidence does not mislabel them as an independent full-version suite.

## Remaining promotion gate and harness issue

Programmer integration and a fresh full regression on the ensuing exact frozen candidate remain required. Native normal gameplay, continuous real-time motion, performance, Windows export and human feel are not certified by this isolated batch.

During initial slim-copy setup, QA mistakenly omitted runtime `art_source/alpha_bounds.json`; headless parsing immediately exposed it before graphical launch. The original matching file was copied into both QA projects and the fixed parse completed without ERROR. This was a fixture-preparation fault, not a product bug or a source edit.

`EVIDENCE_SHA256.json` indexes all distributed evidence except itself. Full QA project caches, obsolete failed setup logs and unrelated desktop images are intentionally excluded.
