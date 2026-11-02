# Violet Spitter — editable body and bounded local validation

## What changed

Four original SVG redraws now supply the existing Spitter PNG paths, with nine explicit poses per sheet:

| Body sheet | Runtime PNG | Sequence |
| --- | --- | --- |
| Walk/idle | `assets/enemies/spitter.png` | Alternating quadruped support and restrained bob |
| Shoot | `assets/actions/spitter/spitter_shoot.png` | Brace, cannon extension, recoil and recovery |
| Hurt | `assets/actions/spitter/spitter_hurt.png` | Flinch and return |
| Death | `assets/actions/spitter/spitter_death.png` | Progressive kneel into a low intact wreck |

The new flat geometric treatment is not a pixel-identical restoration of the earlier shaded artwork. The teal shell, purple tank/cannon, connected hoses, brass joints and cream bore rim preserve its identity. No projectile, muzzle flash, player weapon or new cannon-mouth socket is baked into the body.

Use the [editing and export guide](../art_source/spitter_v51/AUTHORING_SCOPE.md) for the four editable masters and reproducible export settings. The accepted repeat reproduced this new baseline under the reviewed renderer/options, not under every possible tool version.

## Registration and gameplay stay fixed

All sheets remain 1254 × 1254. Walk retains the original `enemy_manifest.json` Spitter frame `region` and `alpha_bbox` (XYWH) crop authority, with padding to a logical 418 × 418 canvas; new measured alpha bounds do not redefine those live fields. Action windows remain 418 × 320 at their existing nonuniform row origins. Fixed reference heights, zero action margin and anchor remain unchanged.

The neutral body-height reference is **54.15 world units**, not a square canvas or the measured height of every posed silhouette. The Director retains base foot `(0, 27.075)`. A low wreck may extend below that registration point; it is not a painted-bounds clipping line. Current redraw measurements are separate from historical measurement metadata.

Frame numbers are zero-based. Existing behavior remains:

- Walk selection uses 9 fps, with idle reusing frame 0. The AI can remain in its move phase while stationary inside its distance deadband.
- Warning lasts 0.65 s across shoot frames 0–3. The actual shot enters recovery at frame 4; recovery lasts 0.7 s across frames 4–8. This is AI-phase selection, not a new generic nine-frame attack clock.
- Hurt lasts 0.27 s and can override the visible body while AI phases continue. Expiry resumes the current phase rather than emitting another shot.
- Death lasts 0.72 s; combat removal, owned-projectile cleanup, one reward and later nonhero corpse disposal retain their existing behavior.

The projectile origin remains **`enemy.pos`**, not the painted cannon mouth. Damage, collision, movement, cooldowns, priorities, locked facing, RNG, production code, UI and other art are unchanged.

## Completed local checks

- Four separate source-resource checks passed **124 predicates per sheet**. Four corresponding packed checks also passed 124 each, compared against the matching actual imported source report. Crop identity is distinct from a padded logical texture or an original-art pixel hash.
- The resource-pack smoke check passed **1,068 predicates**. The documented default BUILD entry passed its unchanged **14 routes** on the separate source-and-test wrapper. These are not a new all-game or all-enemy test suite; see the [runner documentation](BUILD_UI_VALIDATION.md).
- A unique controlled native desktop observation passed **550 checks**, produced **41 original images**, used **5 setups** and retained **41 post-intent authority guards**. The inspected logical viewport and OS window were both 960 × 540; other display sizes, DPI modes and platforms are outside this new visual scope.
- An author agent directly reviewed all 41 originals. A separate QA agent reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

The 41 images comprise 36 normal body frames, four selected body mirrors (walk0, shoot4, hurt3, death8) and one reduced-flashes hurt3. All 36 normal samples also have numerical both-facing foot/registration observations. There is no full mirrored or reduced-flashes screenshot matrix.

The observer starts real configured Spitters and uses explicit controlled HP and remaining-clock inputs followed by the existing EnemyAI, CombatRuntime and Director. A due transition at zero elapsed time observes the actual projectile at the enemy center before same-step movement; one later finite step records velocity-derived motion. Controlled damage inputs are not evidence of acquiring that damage through every weapon or collision route.

Thirty-one before/at frame-selection pairs, selected warning/recovery, hurt override/retrigger/resume, paused processing, style refresh, terminal priority, reward-once, corpse expiry and clear behavior were checked within that finite fixture. Corpse-cap stress, all enemies, full combat/proc replay and physical-input automation were not added. Authority snapshots begin after intentional gameplay/settings changes; they do not claim that firing, damage or rewards leave gameplay unchanged. No assets-disabled parity comparison was used.

## Failure history and limits

The original strict resource-pack scene comparison failed on generated scene metadata. Its original failure remains preserved. An exact semantic scene comparison and the separately accepted continuation completed validation on the same unchanged package; this is not described as an all-phases first-pass result. The new native observer itself passed on its first run without a fixture revision.

Export and native runs retain their narrowly classified warning allowances; “warning-free” is not claimed. Earlier version-specific failures and evidence remain historical rather than being relabeled by this result.

The inspected body stays connected and readable, with a clear release extension and lower death silhouette. Fine joints, far legs, hoses, gait differences and late hurt/death adjustments can merge at game scale. Not every adjacent pose is equally distinguishable. The existing warning ring is separate presentation. A projectile at the enemy center or reward underneath the corpse can be obscured by the body; their numerical outcomes are not inferred from isolated visible pixels.

Selected mirrors reflect only the body. In particular, the shoot mirror retains the actual leftward AI aim/projectile and is not a fresh rightward shot. Derived logical-canvas bounds are not intercepted renderer commands or pixel-perfect painted bounds. Fixed-step stills and numeric timing do not establish real-time cadence, every live encounter or a full gameplay experience.

## Delivery and publication status

Local restoration validation passed ten controls: two positive verification/restoration cases and eight refusal cases. A real resource-file backup, replacement and rollback restored the original package while preserving the existing executable bytes and mode. These are local file-restoration controls, not a delivery-executable launch, Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally validated asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.
