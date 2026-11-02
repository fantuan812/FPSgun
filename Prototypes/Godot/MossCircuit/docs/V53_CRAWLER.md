# Scrap Crawler — editable body and bounded local validation

## What changed

Three original SVG redraws supply the existing PNG paths:

| Body sheet | Runtime PNG | Size and poses |
| --- | --- | --- |
| Walk/idle | `assets/beetle_walk.png` | 1268 × 1241; 9 poses |
| Hurt | `assets/actions/crawler/crawler_hurt.png` | 1268 × 1241; 9 poses |
| Death | `assets/actions/crawler/crawler_death.png` | 1417 × 1110; 16 poses |

The rounded copper/rust shell, dark face with cream eyes, side hinge, rear moss and short connected legs retain the compact beetle identity. The flatter, more side-on treatment is not a pixel-identical restoration of the earlier shaded art. The death sequence settles into a low intact shell; the separate reward marker is not body paint.

Use the [editing and export guide](../art_source/crawler_v53/AUTHORING_SCOPE.md) for the three masters and reproducible export settings. The accepted repeat reproduced this new baseline with the reviewed renderer/options, not every possible tool version.

## Registration and behavior stay fixed

Keep the root walk path: no `assets/enemies/crawler.png` is introduced. Live walk slicing uses the existing `art_source/alpha_bounds.json` LTRB records, not the descriptive Crawler boxes in `enemy_manifest.json`. Uneven physical cells retain widths 422/423/423 and heights 413/414/414, with a padded logical texture of **423 × 414**. Newly measured paint bounds do not redefine those live crops or historical metadata.

Walk scale remains **19/138**. The Director's visible reference height is **1615/46 ≈ 35.108696 world units**, and its base foot is **(0, 3553/138) ≈ (0, 25.746377)**. This root fallback is not a 57-visible-pixel body with a 28.5 foot. Hurt/death retain their variable source regions, integral margins, logical **512 × 400** size, reference heights **260/215**, offsets and common registered foot.

Death retains runtime-to-physical order **[0, 1, 4, 2, 3, 5, 8, 6, 9, 7, 10, 12, 11, 13, 14, 15]**. Frame numbers here are zero-based runtime indices, not a request to reorder the sheet. Painted height and the last visible corpse pixel are not collision or foot-registration measurements.

Existing walk selection remains 9 fps with idle frame 0; hurt lasts 0.27 s and death lasts 0.72 s over sixteen poses. There is **no new attack sheet**. Contact still uses `enemy.pos` and the existing procedural idle-body squash/rotation. That pulse keeps the base offset rather than re-anchoring the foot; fixed-foot results for the 34 authored samples must not be applied to its deformed pose. Damage, chase, contact range, collision, invulnerability, state priority, rewards, cleanup, RNG, production code, UI and other art are unchanged.

## Completed local checks

- Separate source-resource checks passed **124 walk, 124 hurt and 208 death predicates**. The corresponding packed checks passed the same per-sheet counts against their matching actual imported source reports. Imported region-crop identity is distinct from ART source-window pixels or a padded logical canvas.
- The resource-pack smoke check passed **1,068 predicates**. The documented default BUILD entry passed its unchanged **14 routes** on the separate source-and-test wrapper. These are not a new all-game or all-enemy suite; see the [runner documentation](BUILD_UI_VALIDATION.md).
- One controlled native desktop observation passed **519 checks**, produced **38 original images**, used **4 setups** and retained **38 post-intent authority guards**. Its logical viewport and OS window were both 960 × 540; other sizes, DPI modes and platforms are outside this visual scope.
- An author agent directly reviewed all 38 originals. A separate QA agent reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

The images contain 34 normal frames (9 walk, 9 hurt, 16 death), three selected body mirrors (walk0, hurt3, death15) and one reduced-flashes hurt3. All 34 normal samples also have numerical both-facing registration/foot observations. There is no full mirrored or reduced screenshot matrix and no procedural-attack screenshot.

The observer uses a real configured Crawler with explicit controlled HP, positions, clocks and player invulnerability inputs, then the existing CombatRuntime and Director. Thirty-one before/at frame-selection pairs cover the sampled clocks. A bounded chase step observes 5.3 world units at the existing speed 53 before an intentional position reset for presentation samples.

A separate numerical lifecycle probe uses one controlled distance-20 contact at zero elapsed time. It observes damage 9 and the existing 0.28 s procedural attack, an early contact at age 0.04 that does not restart the presentation, and a later contact at age 0.14 that does. Player invulnerability prevents repeat damage in those later probes; presentation restart is not another successful damage event. The midpoint pulse is measured numerically with its existing squash and rotation, not claimed as a foot-reanchored authored pose.

Further bounded observations cover hurt precedence while AI moves, trigger refusal, pause/style refresh, expiry/resume, death priority, reward once, corpse expiry and clear. Authority snapshots begin after intentional gameplay/settings changes; they do not claim that movement, HP changes or rewards leave gameplay unchanged. No assets-disabled parity, corpse-cap stress, range sweep, physical-input automation, all-enemy matrix or full combat replay was added.

## Failure history and visual limits

The first source-resource attempt stopped before producing a report because an external preflight compared JSON floating-point size arrays with integer arrays. A strict numeric comparison corrected only that fixture check; the replacement run supplied the accepted source reports. The original failure is retained, and no production asset or registration was changed to pass it.

The original strict resource-pack scene comparison also failed on generated scene metadata. An exact semantic scene comparison and separately accepted continuation completed validation on the same unchanged package. This is not an all-phases first-pass result. The new native observer itself passed on its first run without a fixture revision. Narrowly classified tool/renderer warnings remain recorded; “warning-free” is not claimed.

In the inspected views, the compact copper shell, dark face and short legs remain connected. Hurt compression/recovery and runtime-ordered corpse lowering are coherent, but subtle gait changes, moss, hinges and late eye details merge at game scale. A low final corpse remains visible below the separate green reward marker; every painted eye is not necessarily individually readable. Retained nonuniform source envelopes can cause modest apparent volume changes between adjacent poses.

Selected mirrors change the body facing while retaining the controlled gameplay state, not a fresh opposite-direction chase/contact. Derived logical-canvas bounds are not intercepted renderer commands or exact painted bounds. Fixed-step stills and numerical timing do not establish real-time smoothness, every live encounter or a full gameplay experience.

## Delivery and publication status

Local restoration validation passed ten controls: two positive verification/restoration cases and eight refusal cases. A real resource-file backup, replacement and rollback restored the original package while preserving the existing executable bytes and mode. These are local file-restoration controls, not a delivery-executable launch, Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally validated asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.

