# v15 Core reaction-only engineering QA / milestone closure

Baseline: published v14 `51a6f3ce4ae91e08212c7675df9a9f21620fee9f`, all1001 paths retained. Engine: Godot4.6.3 stable. Date:2026-10-24.

## Final verification

After the final mirror-safe Core registration was installed, generated `.godot` cache was removed, then cold headless import and all **46 standalone entry points** passed:42 tests, UI, and three art-icon checks. Exact exits, engine-error flags and logs are under `logs/`. Policy fixtures are inputs of other tests, not standalone SceneTree entry points.

- Author Core test: **56 assertions**, including real ring8/12 and summon cap behavior despite hurt; terminal death; owned-projectile cleanup but live-child preservation; original100coin/trophy reward without Warden protocol; wave6 timer and normal terminal cleanup. It also verifies all seven enemy profiles resolve authored hurt/death resources.
- Independent Core test: **403 assertions**, real attack-index cadence, warning half-HP crossing, release/cap/parent-child ownership and both modes, reaction priority/clock/anchors, pause/reset and no extra gameplay side effects.
- Existing authored-action regression: **343 assertions**, exact23-action approved set with Core death16, retaining all old tests and resources.
- **164 old runtime/scene/UI/assets/authority-data files** are byte-identical. All runtime `.gd` is unchanged. `verify_unchanged.py` checks the exact allowed actor config delta: Core hurt/death mapping plus one additional manifest path, nothing else.
- Final metadata can be reproduced byte-for-byte from untouched PNGs. Independent same-seed finite trace comparison and pixel measurements are under `../independent-v15-core/`; these are finite regressions, not proof over every possible play.

## Visual registration issue found and resolved

The first source registration passed state tests but its first Core center sat approximately7/10.7 world pixels right of the old hover pose. A suggested noncentral anchor was rejected because fixed sprite offsets could make one-facing calibration unsafe under horizontal mirroring. Final metadata keeps anchor(.5,.8) and shifts the **entire action** by a constant source X offset (hurt−12, death−16). It does not recenter individual frames or change their internal trajectory, scale, pixels or runtime code.

Independent actual RGBA cyan-center measurement using pixel-area centers reports first-pose X residual below0.25 world pixels in both facing directions (hurt±0.203px/death±0.035px); Y retains approximately1.19/2.07px of natural hover-pose difference. Fixed manual whole-row vertical corrections preserve the floating core's visible descent and dimming; `base_foot` is only a legacy logical-point variable, not a claim Core has feet. Source/trajectory details and limitations are in `docs/art/core/`.

## Bounded completion and limits

This batch adds only Core hurt9/.27s and death16/.72s. Five ordinary enemies and both Bosses now have authored hurt/death profiles. It does **not** complete all attack variants, VFX, GUI feel or the entire game. Existing Core attack9 still serves ring/summon. Existing event timing, damage, RNG, rewards and child lifecycle remain authoritative and unchanged.

No live GUI playtest, human balance acceptance or Windows export was performed. Logical/source-pixel geometry cannot substitute for those. The milestone closes here; see `docs/REACTION_COVERAGE.md` for the coverage matrix and explicit remaining work rather than silently expanding gameplay scope.

## Reproduction

```bash
python docs/validation/v15-core/run_regression.py --output /tmp/moss-v15-qa
python docs/art/core/build_metadata.py --project . --output /tmp/moss-v15-art
python docs/validation/v15-core/verify_unchanged.py --baseline /path/to/published-v14 --candidate . --output /tmp/moss-v15-unchanged.json
```

The runner sets writable HOME/XDG directories. To repeat a genuinely cold import, use a fresh extracted ZIP; generated cache is excluded from delivery. Final ZIP CRC/manifest/retained-path/fresh-runtime evidence is kept separately after packaging to avoid archive self-hash recursion.
