# Scrap Warden — editable body and bounded local validation

## What changed

Five self-contained SVG redraws supply the existing PNG paths:

| Body sheet | Runtime PNG | Poses |
| --- | --- | ---: |
| Walk/idle | `assets/enemies/boss_warden.png` | 9 |
| Base blast | `assets/actions/boss_warden_attack.png` | 9 |
| Charge | `assets/actions/boss_warden/boss_warden_charge.png` | 16 |
| Hurt | `assets/actions/boss_warden/boss_warden_hurt.png` | 9 |
| Death | `assets/actions/boss_warden/boss_warden_death.png` | 16 |

All sheets remain 1254 × 1254. Overlapping front/top/side plates, an inset cream visor, moss, a copper stack, unequal fists and thick feet give the body a layered mechanical identity. The raised, braced, bent and collapsed poses are component-led rather than a globally flattened standing silhouette. The new planar, sparsely weathered style is not a pixel-identical recreation of the older shaded artwork.

Use the [editing and export guide](../art_source/warden_v56/AUTHORING_SCOPE.md) for the five masters and workflow. A separate repeat reproduced the accepted new baseline with the reviewed renderer/options; it does not promise identical output across every tool version.

## Registration and behavior remain fixed

The neutral height reference is **148.2 world units**, with registered base foot **(0, 74.1)**. These are retained runtime values, not new fits to painted bounds.

| Clip | Logical canvas | Reference height | Draw scale | Sprite offset |
| --- | --- | ---: | --- | --- |
| Walk | 418 × 418 | 184 | 741/920 | (0, −97) |
| Base blast | 418 × 340 | 213 | 247/355 | (0, −51.5) |
| Charge | 512 × 400 | 207 | 247/345 | (0, −16.5) |
| Hurt | 512 × 400 | 258 | 247/430 | (0, 9) |
| Death | 512 × 400 | 213 | 247/355 | (0, −13.5) |

Walk retains live `enemy_manifest.json` frame `region` and XYWH `alpha_bbox` crop authority, not a root fallback or an `alpha_bounds` override. Walk margins can contain half-pixels; action margins are integral, including zero margins for base blast. The base-blast windows retain row origins 125, 508 and 843 and three transparent five-pixel overlap bands. They are not a disjoint grid to recrop.

Base blast retains `source_frame`; charge/hurt/death retain `source_pose_index`. Hurt runtime 6/7 uses physical poses 7/6. Death preserves **[0, 1, 4, 5, 2, 6, 3, 8, 7, 9, 10, 11, 12, 13, 14, 15]**. Existing charge x/row adjustments and recovery corrections are already incorporated in its records. Historical bbox/clearance metadata and current paint measurements remain distinct. Painted feet, a corpse's last pixel and the registered foot are not interchangeable collision boundaries.

Walk remains 9 fps with idle frame 0. Charge warning uses frames 0–5 over 0.85 s, charging 6–11 over 0.6 s, and recovery 12–15 over 0.8 s. The later base-blast warning uses frames 0–4 over 0.85 s; its real 0.35 s attack reaction selects frames 5–8 during AI recovery of 0.7 s, then holds frame 8. Hurt remains 0.27 s and death 0.72 s. These selectors and priorities are unchanged production behavior, not new animation callbacks.

Charge/contact originate at the enemy position. The line and the radius-105 blast at the stored warning-entry target remain separate presentation and gameplay systems, not a hand socket or painted hitbox. Body-local orange sparks and charge dust are decorative. Existing locked aim/facing, movement, HP, phase-two rules, collision, RNG, boss rewards/protocol, cleanup, UI and other assets are unchanged.

## Completed local checks

- Five separate source-resource reports passed **126 walk, 126 base attack, 210 charge, 126 hurt and 210 death predicates**. Their corresponding packed reports passed the same counts against the matching actual imported source reports. Six runtime JSON authorities are checked separately from the provenance file. Imported region-crop identity is not a padded logical canvas or substituted ART-window identity.
- Resource-pack smoke validation and the unchanged documented default BUILD entry passed. The latter has **14 routes** on the separate source-and-test wrapper; see [runner documentation](BUILD_UI_VALIDATION.md). Neither is an all-enemy or full-game suite.
- The accepted corrected native observation passed **885 predicates**, produced **65 original 960 × 540 images**, used **6 setups** and retained **65 post-intent authority guards**. Fifty-four before/at selector pairs cover the sampled clocks. Other resolutions, DPI modes and platforms are outside this visual scope.
- An author agent directly reviewed all 65 accepted originals; a separate QA agent directly reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

The screenshots cover **59 normal samples** (9 walk, 16 charge, 9 base blast, 9 hurt, 16 death), five selected body mirrors (walk 0, charge 6, attack 5, hurt 3, death 15), and one reduced-flashes hurt 3. All 59 normal samples also have numerical both-facing registration/foot observations. There is no full mirrored/reduced image matrix.

Real configured Warden records use the existing EnemyAI, CombatRuntime and Director. The attack index is not assigned by the observer: the first charge completes before the second blast is requested. Remaining clocks, player/enemy positions, HP and invulnerability are explicit controlled inputs. Phase screenshots are frozen observations after those inputs and actual transitions, not a naturally played encounter.

The captured blast records an inclusive radius-105 hit at the warning-entry target, **335 units from the boss**, with damage 18 and the existing 0.2 s flash. It does not prove an angular/range sweep or a fist-origin attack. The separate charge line retains its 186-unit endpoint and 101.2 width; no ordinary-Charger brace was introduced.

One bounded numerical lifecycle observes half-HP phase-two movement (35 × 1.25) and cooldown (3/1.2), locked charge aim versus current-player-facing blast body with a fixed target, and center-distance-20 contact outcomes in move/warning/charging/recover (**18/0/18/0**). It also observes 31 units of charge motion followed by 155 more with capped remaining duration and no leftover recovery time. The second direct combat step deliberately overshoots; it is not normal main-loop cadence.

Hurt priority/retrigger refusal, continued AI movement beneath hurt presentation, pause/style refresh, expiry/resume, death priority, corpse expiry and clear are bounded numerical observations. One stationary owned-projectile sentinel is **synthetic cleanup input**, not evidence that Warden naturally shoots. Existing boss protocol, 50 credit, 25 max HP and an XP60/coins30 pickup are observed once despite a repeated existing reward callback. This is not a balance test or a full boss fight.

Guards begin after intentional inputs and legitimate gameplay outcomes; they do not claim that damage or rewards leave state unchanged. No assets-disabled parity, corpse-cap stress, all-weapons matrix or physical-input playback was added.

## Preserved failures and visible limits

The first three-key body pilot remains an art hold despite numerical crop acceptance: its frontal oval mass and compressed poses did not convey the intended chunky golem. The accepted revision first covered three design keys, then twelve complementary keys, before all 59 poses and the independent repeat. Earlier holds and explicitly recovered display deliveries remain recorded rather than silently relabeled.

The original strict resource-pack inventory comparison failed on generated scene metadata. Exact semantic scene checks and a separately accepted continuation completed validation on that same unchanged package. This is not an all-phases first-pass result.

The first native attempt genuinely failed **29 cascading blast assertions**. Its preparatory charge ended 44 units from the player; after recovery became move, legitimate center contact started a 0.28 s reaction. That reaction obscured the next warning and refused the 0.35 s release retrigger. The actual second attack index, target, radius and damage were correct; no production defect was established. The failed report and all 65 failed-attempt captures remain preserved, not visually accepted.

The authorized external-fixture correction only separates the player before that preparatory recovery expiry, restores the intended later-warning position, and strengthens the existing reaction-empty closure. It neither clears a reaction forcibly, skips combat steps, assigns an attack index, weakens tolerances nor changes source assets. A fresh check-only prerequisite and separate native attempt passed with the same 885/65/6/65 scope. A prior static-only auxiliary recovery-clock expectation was also corrected to the unchanged AI value before execution; neither correction is a gameplay fix.

In the inspected accepted stills, layered body masses, visor, asymmetric fists and component collapse remain coherent. Gait, late hurt and tiny final visor/moss details are subtle. Raised arm links are slim and mechanical but attached. The warning line overlays part of the body, and the green death reward is separate from the low wreck.

Mirrors retain the controlled state and original target; they are not newly aimed opposite-direction attacks. Reduced imagery covers only hurt 3. During the controlled blast-position probe, the hero is relocated while the independently frozen weapon rig and target effect remain near the earlier target. Those stills are **not whole-scene hero/weapon synchronization or effect-cadence evidence**, nor evidence that ordinary gameplay leaves weapons behind. No extra synchronization pass or recapture was performed.

Derived logical-canvas bounds are not intercepted renderer commands or exact painted bounds. Fixed registration does not promise planted painted feet. Fixed-step images and numerical timing do not establish real-time smoothness, every final main-loop tint or every live encounter.

## Delivery and publication status

Local restoration passed ten controls: two positive verify/restore paths and eight refusal controls. The recorded real resource-pack replacement and rollback restored the prior pack, with the existing executable's full bytes and mode unchanged. This validates local restoration and rollback, not a delivery-executable or Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally tested asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.
