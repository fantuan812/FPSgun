# Knifeleg Flanker — editable body and bounded local validation

## What changed

Three original SVG redraws supply the existing PNG paths:

| Body sheet | Runtime PNG | Poses |
| --- | --- | --- |
| Walk/idle | `assets/enemies/flanker.png` | 9 |
| Hurt | `assets/actions/flanker/flanker_hurt.png` | 9 |
| Death | `assets/actions/flanker/flanker_death.png` | 16 |

All three sheets remain 1254 × 1254. The low cobalt wedge, linked charcoal chassis, warm pivots, ivory-edged blade legs, moss and bright cream triangular face retain the angular spider identity. The flatter side-on treatment is not a pixel-identical restoration of the earlier three-quarter shaded art. The final corpse is an intact thin wreck, not an alpha fade or extinguished face.

Use the [editing and export guide](../art_source/flanker_v54/AUTHORING_SCOPE.md) for the three masters and workflow. The accepted repeat reproduced this new baseline with the reviewed renderer/options, not every possible tool version.

## Registration and behavior stay fixed

Walk uses the original `enemy_manifest.json` frame `region` and `alpha_bbox` XYWH crop authority. It is **not** Crawler's root-path fallback and has no Flanker `alpha_bounds` override. Retain all nine live records and the logical **418 × 418** canvas. Walk margins can contain half-pixels; newly measured paint bounds do not redefine live crops or historical metadata.

Walk scale is **57/170**, offset **(0, −112.5)**, neutral visible body-height reference **51.3 world units** and base foot **(0, 25.65)**. Hurt/death retain their variable source regions, **integral** margins, logical **512 × 400** canvas, reference heights **222/178**, scales **171/740** and **513/1780**, and offsets **(0, −9)/(0, −31)**. These registration constants are not a new fit to the redraw's painted bounds.

Death keeps runtime-to-physical order **[0, 1, 4, 2, 5, 3, 8, 6, 9, 7, 10, 11, 12, 13, 14, 15]**. Frame numbers here are zero-based runtime indices, not sheet order or Crawler's permutation. A low corpse's last painted pixel is not its registered foot or collision boundary.

Existing walk selection remains 9 fps with idle frame 0; hurt lasts 0.27 s and death lasts 0.72 s over sixteen poses. The `flank` movement keeps its existing forward pursuit plus sinusoidal lateral weave. Facing is toward the player rather than rotation into lateral velocity. Expired cooldown does not create a ranged attack, warning/charge phase or authored release for this family.

There is **no new attack sheet or attachment socket**. Contact remains centered at `enemy.pos`, not at a painted blade tip. The existing 0.28 s procedural idle-body squash/rotation retains its base offset rather than re-anchoring the foot. Fixed-foot results for the 34 authored samples must not be applied to that deformed pulse. Damage, movement, contact range, collision, invulnerability, priorities, rewards, cleanup, RNG, production code, UI and other art remain unchanged.

## Completed local checks

- Separate source-resource checks passed **124 walk, 124 hurt and 208 death predicates**. The corresponding packed checks passed those same per-sheet counts against their matching actual imported source reports. Imported region-crop identity is distinct from ART source-window pixels or a padded logical canvas.
- The resource-pack smoke check passed **1,068 predicates**. The documented default BUILD entry passed its unchanged **14 routes** on the separate source-and-test wrapper. These are not a new all-game or all-enemy suite; see the [runner documentation](BUILD_UI_VALIDATION.md).
- One controlled native desktop observation passed **523 checks**, produced **38 original images**, used **4 setups** and retained **38 post-intent authority guards**. Its logical viewport and OS window were both 960 × 540; other sizes, DPI modes and platforms are outside this visual scope.
- An author agent directly reviewed all 38 originals. A separate QA agent reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

Images cover 34 normal frames (9 walk, 9 hurt, 16 death), three selected body mirrors (walk0, hurt3, death15) and one reduced-flashes hurt3. All 34 normal samples also have numerical both-facing registration/foot observations. There is no full mirrored/reduced image matrix or procedural-attack screenshot.

The observer uses real configured Flankers with explicit controlled HP, positions, elapsed times, cooldown and player invulnerability inputs, then the existing EnemyAI, CombatRuntime and Director. Thirty-one before/at frame-selection pairs cover the sampled clocks.

Two numerical movement probes use the same far starting position and real enemy ID, with chosen nonnegative elapsed times producing opposite signs of the lateral sine term. Each real 0.1 s combat step observes 7.2 world units at the existing speed 72, its expected vector, sprite rounding, facing toward the player and expired-cooldown move state without a projectile. These are controlled samples, not a natural elapsed-time replay, screenshots of a whole weaving path, or a phase/range/clamp sweep. Position and elapsed time are intentionally reset before the body captures.

A separate numerical lifecycle probe uses controlled center distance 20 and zero elapsed time to observe damage 8 and procedural idle0 attack. Contact at age 0.04 does not restart the presentation; contact at age 0.14 does. Player invulnerability prevents extra damage in those later probes, so a presentation restart is not another successful damage event. The midpoint squash/rotation is measured without claiming a re-anchored foot.

Further bounded observations cover hurt priority while actual weave movement continues, trigger refusal, pause/style refresh, expiry/resume, death priority, reward once (XP 6/coins 3), corpse expiry and clear. Authority snapshots begin after intentional changes; they do not claim that movement, HP or rewards leave gameplay unchanged. No assets-disabled parity, corpse-cap stress, range sweep, physical-input automation, all-enemy matrix or full combat replay was added.

## Failure history and visual limits

The original strict resource-pack scene comparison failed on generated scene metadata. An exact semantic scene comparison and separately accepted continuation completed validation on the same unchanged package. This is not an all-phases first-pass result.

The first check-only prerequisite also exceeded its outer time budget and was not accepted. A separately authorized isolated repeat retained the same fixture, assets and native timeout while allowing a larger outer budget; it completed and passed independent review. The original timeout remains preserved, and its underlying cause is not asserted here. The actual native observer then passed on its first run, without a fixture or tolerance change. Narrowly classified tool/renderer warnings remain recorded; “warning-free” is not claimed.

The inspected cobalt wedge, dark chassis and blade supports remain connected. Hurt compression/recovery and ordered corpse flattening are coherent, but fine joints, moss, adjacent gait differences and late face geometry can merge at game scale. The final cream aperture is a tiny light mark, not always a clearly resolved triangle. Early corpse paint can obscure the reward; later the separate green reward marker sits above the thin wreck. Reward and cleanup outcomes are not inferred from pixels alone.

Selected mirrors change the body facing while retaining the controlled gameplay state, not a fresh opposite-direction weave/contact. Derived logical-canvas bounds are not intercepted renderer commands or exact painted bounds. Fixed-step stills and numerical timing do not establish real-time smoothness, every live encounter or a full gameplay experience.

## Delivery and publication status

Local restoration validation passed ten controls: two positive verification/restoration cases and eight refusal cases. A real resource-file backup, replacement and rollback restored the original package while preserving the existing executable bytes and mode. These are local file-restoration controls, not a delivery-executable launch, Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally validated asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.

