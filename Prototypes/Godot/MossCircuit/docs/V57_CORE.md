# Spore Reactor / Core — editable body and bounded local validation

## What changed

Five self-contained SVG redraws supply the existing PNG paths:

| Body sheet | Runtime PNG | Poses | Sheet pixels |
| --- | --- | ---: | --- |
| Walk/hover | `assets/enemies/boss_core.png` | 9 | 1254 × 1254 |
| Base ring attack | `assets/actions/boss_core_attack.png` | 9 | 1254 × 1254 |
| Summon | `assets/actions/boss_core/boss_core_summon.png` | 16 | **1312 × 1199** |
| Hurt | `assets/actions/boss_core/boss_core_hurt.png` | 9 | 1254 × 1254 |
| Death | `assets/actions/boss_core/boss_core_death.png` | 16 | 1254 × 1254 |

The floating mint orb, bronze/olive ring, purple canisters, moss and connected root ribbons remain recognizable. Anticipation opens into an outward root release; summon uses a broad root cradle and small decorative seed; death lowers an intact dim orb and ring onto a root mound. The new planar/concentric style is not a pixel-identical recreation of the older shaded artwork.

Use the [editing and export guide](../art_source/core_v57/AUTHORING_SCOPE.md) for masters, renderer options and provenance. The accepted new baseline was independently repeated; that does not promise identical output across every renderer version. The identity pilot covered three keys, then nine complementary keys, before all 59 poses. Static art acceptance is distinct from runtime acceptance.

## Registration and behavior remain fixed

The neutral reference height is **165.3 world units**, with registered base foot **(0, 82.65)**. These are existing runtime values, not new fits to painted bounds.

| Clip | Logical canvas | Reference height | Draw scale | Sprite offset |
| --- | --- | ---: | --- | --- |
| Walk | 418 × 418 | 218 | 1653/2180 | (0, −80) |
| Base attack | 418 × 340 | 231 | 551/770 | (0, −42.5) |
| Summon | 512 × 400 | 246 | 551/820 | (0, 3) |
| Hurt | 512 × 400 | 278 | 1653/2780 | (0, 19) |
| Death | 512 × 400 | 248 | 1653/2480 | (0, 4) |

Walk retains live `enemy_manifest.json` frame `region` and XYWH `alpha_bbox` crop authority, not an `alpha_bounds` override or root fallback. Walk margins can contain half-pixels; action margins are integral. Base-attack row origins remain 67, 458 and 844. Core windows have no overlaps, but its mixed action windows are not a uniform grid to recrop.

All 59 frames retain **identity source order**. Base attack preserves `source_frame`; summon/hurt/death preserve `source_pose_index`. There is no inherited Warden hurt swap or death permutation. Existing horizontal and row adjustments are already embodied in the records and must not be applied twice. Historical crop/measurement fields and newly measured paint bounds remain distinct. The registered foot is not a painted contact point or collision boundary.

Walk remains 9 fps with idle frame 0. Base-ring warning selects frames 0–3 over 0.85 s; the actual 0.35 s attack reaction selects 4–8 during AI recovery of 0.7 s, then holds frame 8. Summon warning selects 0–6 over 0.85 s and recovery 7–15 over 0.7 s. Hurt remains 0.27 s and death 0.72 s. Priorities, manual selectors and event ordering are unchanged.

Ring projectiles originate at the enemy position, not a canister, root or painted ray. Child spawns use the existing actor-relative radius-50 logic, not the decorative seed. The orange warning circle is a separate runtime presentation. Existing HP, phase rules, movement/contact, collision, RNG, rewards, cleanup, UI and other artwork are unchanged.

## Completed local checks

- Five separate source reports passed **126 walk, 126 base attack, 210 summon, 126 hurt and 210 death predicates**. Corresponding packed reports passed the same per-sheet counts against the matching actual imported source reports. Six runtime JSON authorities are separate from provenance; imported region-crop identity is not a padded logical canvas or ART-window substitution.
- Resource-pack smoke validation passed **1068 checks**. The unchanged default BUILD entry passed **14 routes**, reporting **4931 numeric checks and one text check** on the separate source-and-test wrapper. See [runner documentation](BUILD_UI_VALIDATION.md). Neither is a full-game suite.
- The corrected native observation passed **887 predicates**, produced **65 original 960 × 540 images**, used **6 setups**, and retained **65 post-intent authority guards**. Fifty-four before/at selector pairs cover the sampled clocks.
- An author agent directly reviewed all 65 accepted originals; a separate QA agent directly reviewed 16 selected originals. These are AI-agent still-image reviews, not human playtesting. The author delivery used two explicitly granted windows, 30 then 35 distinct originals, without reopening images or claiming completion after only the first window.

The image matrix is **59 normal samples** (9 walk, 9 ring/base attack, 16 summon, 9 hurt, 16 death), five selected body mirrors (walk 0, attack 4, summon 7, hurt 3, death 15), and one reduced-hurt 3. All 59 normal frames also have numerical both-facing registration observations. No full mirrored/reduced image matrix was added.

The observer uses actual configured Core records, EnemyAI, CombatRuntime and Director. The first captured ring release records eight actual bullets at `enemy.pos`, with angles `2πi/N + 0.13`, speed 145, life 4 and damage 15, at a zero-duration release step before projectile motion. Separate numerical preparation completes a phase-one ring and a phase-two twelve-bullet ring before the natural third attack selects summon. No attack index or kind is assigned by the fixture.

Phase-two HP and `anim_hp` inputs are explicitly controlled. Repeated natural ring/ring/summon cycles then observe the selected living-child cap: **empty → 2 new children; existing 2 → 1 new child; existing 3 → 0**. Actual configured crawler records carry the parent ID and appear at actor-relative radius 50, using `elapsed + iπ`. Partial/full-cap outcomes have no additional image timeline; this is not a global-90 saturation test.

To prevent old bullets, nearby children or a residual reaction from contaminating subsequent captures, a declared setup parks the player far away, relocates existing children, and advances the real recovery and Director by 4.1 s. Ring lifetime and reaction expire naturally; recovery exits without leftover movement, and unchanged player HP plus an empty reaction are required. This is an intentional overshoot preparation, **not normal main-loop cadence or a stand-off movement/contact-damage test**. No forced reaction clearing occurs.

The bounded lifecycle observes current-player-facing base attack versus locked summon aim, phase-driven attack refusal, hurt/retrigger priority, paused actual-main-process age, noncompounding normal/reduced refresh, a full-cap summon event beneath hurt, and resumption at recovery frame 7. Death removes its owned projectile, leaves three living children, produces the XP100/coins50 pickup and grants the existing 100-credit trophy once. It grants no Warden protocol or HP repair. A stationary owned-projectile sentinel is explicitly synthetic cleanup input, not a natural ring trajectory.

Guards start after intentional timer/HP/position changes and legitimate events. They do not claim damage, spawning or rewards preserve authority state. No full boss fight, assets-disabled parity, contact-angle/range, projectile-collision, corpse-cap, all-weapons or RNG matrix was added.

## Preserved failures and visible limits

The original strict resource-pack inventory comparison failed on generated scene metadata. Exact scene-semantic checks and a separately accepted continuation completed validation on the same unchanged package. It is not an all-phases first-pass result.

The original native attempt genuinely failed strict stderr validation despite an engine exit of zero. Two reached reads assumed that the default Core-only build contained `boss_protocol`; that optional key is created by the Warden reward, not the Core reward. The errors aborted the death-capture method and lifecycle tail. Only **665 checks and 48 images** completed: 219 death checks and three lifecycle checks were missing. Its partial `failures` array was not acceptance, and the 48 failed-attempt images remain unaccepted.

The root-authorized external-fixture revision changes exactly three optional reads—two assertions and one report observation—to the existing production `get("boss_protocol", false)` convention. It does not seed a flag, change gameplay/assets, weaken warnings or tolerances, alter the schema/counts, or repeat upstream source/pack/default checks. A fresh check-only prerequisite and separate native attempt passed the unchanged 887/65/6/65 scope.

In the accepted originals, the orb, ring, ports and attached roots remain coherent and unclipped. Hover and hurt changes are modest, tiny moss/bolts merge at actual size, the armor is relatively planar, and attack accents are quieter than the old shaded reference. Death frame 3 makes a discrete brightness change; later frames lower and tilt the dim intact ring. This is not a claim of a gradual brightness fade. A separate green reward becomes visible above the low final body.

The center-origin ring bullets are not individually separable behind the body in the frozen release stills. Summon frame 7 does not yet show newly spawned child sprites; the next combat pass positions them, and at frame 8 onward they overlap the Core's sides. These observations do not create a decorative emitter socket or prove whole-scene synchronization. Mirrors flip only the body, not AI aim, player, projectiles or reward. Reduced imagery covers hurt 3 only.

Derived logical-canvas bounds are not intercepted raster commands or exact painted bounds. Fixed registration does not promise planted roots. Still frames and numerical timing do not establish continuous smoothness, every final main-loop tint, all directions, other resolutions/DPI, other platforms or every live encounter.

## Delivery and publication status

Local delivery passed the separate ten-control check: two positive paths and eight refusal controls. The local catalog advanced from 116 to 118 entries with two chunks and five payload paths. Actual resource-file replacement and rollback restored the preceding V56 package, with executable bytes and mode unchanged. This is local acceptance only. No delivery-executable or Windows launch, installation, CI or extra full-game coverage is claimed.

This separate V57 snapshot is composed after the V56 consolidated snapshot, which excluded Core. The public delivery catalog preserves its 94 records and adds the two V57 records; the 116-to-118 count above describes only the earlier local acceptance fixture. Publication identity is recorded separately after commit verification. These five sheets do not establish that every project image is newly authored.
