# Amber Ram / Charger — editable body and bounded local validation

## What changed

Four original SVG redraws supply the existing Charger PNG paths, with nine explicit poses per sheet:

| Body sheet | Runtime PNG | Sequence |
| --- | --- | --- |
| Walk/idle | `assets/enemies/charger.png` | Restrained bob and alternating heavy-foot support |
| Charge | `assets/actions/charger/charger_charge.png` | Brace, forward charge and recovery |
| Hurt | `assets/actions/charger/charger_hurt.png` | Flinch and return |
| Death | `assets/actions/charger/charger_death.png` | Knee buckle into a low armored wreck |

The ivory horn/collar, overlapping rounded shoulder and haunch armor, shadowed belly, moss ridge and broad feet retain the creature's heavy identity. The geometric treatment is not a pixel-identical restoration of the earlier shaded artwork. No brace arc, warning path, projectile or new horn-contact socket is baked into the body.

Use the [editing and export guide](../art_source/charger_v52/AUTHORING_SCOPE.md) for the four masters and reproducible export settings. The accepted repeat reproduced this new baseline with the reviewed renderer/options, not every possible tool version.

## Registration and gameplay stay fixed

All sheets remain 1254 × 1254. Walk retains the original `enemy_manifest.json` frame `region` and `alpha_bbox` (XYWH) crop authority and padding to a logical 418 × 418 canvas. Action windows remain 418 × 320 with their complete existing per-frame origins, zero margins, reference heights and anchor. In particular, death frames 0 and 1 retain source Y positions **59 and 63**, not a normalized Y70 row. Newly measured paint bounds do not redefine live crops or historical registration metadata.

The neutral body-height reference is **68.4 world units**, with base foot **(0, 34.2)**. These values are not the measured height or painted bottom of every pose, nor the dimensions of the full logical canvas. A low wreck and its registration point must not be confused with a new collision boundary.

Frame numbers are zero-based. Existing behavior remains:

- Walk selection uses 9 fps; idle reuses frame 0.
- Warning lasts 0.65 s across charge frames 0–3, charging lasts 0.6 s across frames 4–6, and recovery lasts 0.8 s across frames 7–8. This is AI-phase selection, not a replacement nine-frame attack clock.
- Hurt lasts 0.27 s and can override visible animation while authoritative AI movement continues. Expiry resumes the current phase.
- Death takes presentation priority; existing combat removal, one reward and 0.72 s corpse disposal remain unchanged.

The charge does **not** fire a projectile. Movement and contact remain centered on `enemy.pos`, not the painted horn. The warning-only front brace retains its 120-degree cone and 0.5 primary-damage multiplier; brace arc and charge-path telegraphs remain separate presentation. Damage, collision, speed, cooldowns, phase transitions, locked aim, RNG, production code, UI and other art are unchanged.

## Completed local checks

- Four separate source-resource checks passed **124 predicates per sheet**. The four corresponding packed checks passed 124 each against their matching actual imported source reports. Imported crop identity is distinct from ART pixels or a padded logical canvas.
- The resource-pack smoke check passed **1,068 predicates**. The documented default BUILD entry passed its unchanged **14 routes** on the separate source-and-test wrapper. These are not a new all-game or all-enemy suite; see the [runner documentation](BUILD_UI_VALIDATION.md).
- A unique controlled native desktop observation passed **556 checks**, produced **41 original images**, used **5 setups** and retained **41 post-intent authority guards**. The logical viewport and OS window were both 960 × 540; other sizes, DPI modes and platforms are outside this new visual scope.
- An author agent directly reviewed all 41 originals. A separate QA agent reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

The images comprise 36 normal body frames, four selected body mirrors (walk0, charge4, hurt4, death8) and one reduced-flashes hurt4. All 36 normal samples also have numerical both-facing foot/registration observations. There is no full mirrored or reduced screenshot matrix.

The observer uses real configured Chargers with explicit controlled HP, remaining clocks, positions and invulnerability resets, followed by the existing EnemyAI, CombatRuntime and Director. Thirty before/at frame-selection pairs and actual due transitions at zero elapsed time distinguish warning, charging and recovery. Selected lifecycle observations cover trigger refusal, hurt override while AI moves, retrigger/resume, pause/style refresh, death priority, reward-once, expiry and clear.

One bounded movement probe records 31 world units followed by a capped 155, at the existing speed 310, then fresh recovery without carrying excess elapsed time into it. Its oversized direct combat step is not normal frame cadence or a field-edge test. Four controlled distance-20 contact samples distinguish active move/charging from safe warning/recovery after the tick. Three exterior primary-defense resolver samples distinguish warning-front half damage from warning-side and unbraced charging full damage. They do not replay weapon acquisition or sweep cone edges, contact range, interior positions or all weapons.

Authority snapshots start after intentional gameplay/settings changes; they do not claim that movement, HP changes or rewards leave gameplay unchanged. No assets-disabled parity, corpse-cap stress, all-enemy matrix, physical-input automation or full combat replay was added.

## Failure history and visual limits

The first art pilot was held for a flat crate-like torso and thin legs. A later pilot stopped at its first pose on fixed-crop containment. Both remain preserved; the accepted rig corrected geometry rather than moving crops or hiding overflow.

The original strict resource-pack scene comparison failed on generated scene metadata. An exact semantic scene comparison and separately accepted continuation completed validation on the same unchanged package. This is not an all-phases first-pass result. The new native observer itself passed on its first run without a fixture revision. Narrowly classified tool/renderer warnings remain recorded; “warning-free” is not claimed.

The inspected horn, rounded armor and heavy supports stay connected and readable. Fine hinges, gait differences and late hurt/death changes can merge at game scale; not every adjacent pose is equally distinguishable. The separate brace arc and orange warning path overlap parts of the horn/front/feet. A reward beneath a corpse can be obscured; reward and cleanup outcomes are not inferred from visible pixels alone.

Selected mirrors reflect only the body. In particular, charge4 faces right while retaining the actual locked leftward AI aim; it is not a fresh rightward charge. Derived logical-canvas bounds are not intercepted renderer commands or exact painted bounds. Fixed-step stills and numerical timing do not establish real-time smoothness, every live encounter or a full gameplay experience.

## Delivery and publication status

Local restoration validation passed ten controls: two positive verification/restoration cases and eight refusal cases. A real resource-file backup, replacement and rollback restored the original package while preserving the existing executable bytes and mode. These are local file-restoration controls, not a delivery-executable launch, Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally validated asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.
