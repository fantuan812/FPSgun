# Brood Keeper — editable body and bounded local validation

## What changed

Four original SVG redraws supply the existing PNG paths:

| Body sheet | Runtime PNG | Poses |
| --- | --- | --- |
| Walk/idle | `assets/enemies/brood_keeper.png` | 9 |
| Shared warning/recovery | `assets/actions/brood_keeper/brood_keeper_summon.png` | 16 |
| Hurt | `assets/actions/brood_keeper/brood_keeper_hurt.png` | 9 |
| Death | `assets/actions/brood_keeper/brood_keeper_death.png` | 16 |

All four sheets remain 1254 × 1254. Broad olive mass, connected gold supports, an integrated cream face and a smaller rear-mounted hive with five projecting tube rims replace the pilot's dominant flat disc. The final corpse retains a low body, face and hive rather than fading away. The flatter, more side-on treatment is not a pixel-identical recreation of the original shaded artwork.

Use the [editing and export guide](../art_source/broodkeeper_v55/AUTHORING_SCOPE.md) for the four masters and workflow. A separate repeat reproduced the accepted new baseline with the reviewed renderer/options; it is not a claim about every tool version.

## Fixed registration and unchanged behavior

Walk retains the live `enemy_manifest.json` frame `region` and `alpha_bbox` XYWH crop authority, with a logical **418 × 418** canvas, reference height **204**, scale **513/1360**, offset **(0, −87)** and logical anchor **(209, 398)**. It has no Brood Keeper `alpha_bounds` override. The neutral body-height reference is **76.95 world units**, and the base foot is **(0, 38.475)**; neither is a new fit to the redraw's painted bounds. Walk margins may contain half-pixels.

Hurt retains its **418 × 360** source windows, zero margins, reference height **269** and anchor **(209, 330)**. Summon/death restore the original **313 × 360** logical canvas from variable-height windows and integral margins, with reference heights **225/206** and anchor **(156.5, 330)**. Some source windows overlap in transparent **8-pixel strips**. These are not disjoint regular grids, and the blank overlap must remain blank.

Death keeps the `source_index` sequence **[0, 1, 4, 5, 2, 3, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]**. Frame numbers here are zero-based runtime indices, not physical row-major order or a renamed source-pose field. Retained historical bbox/clearance metadata and current paint measurements are distinct. A corpse's last painted pixel is not its registered foot or collision boundary.

The existing walk selector remains 9 fps with idle frame 0; hurt lasts 0.27 s and death lasts 0.72 s. The shared body clip uses warning frames 0–6 and recovery frames 7–15. Annulus warning lasts 1.0 s, summon warning 0.65 s and recovery 0.7 s. Frame 7 presents release; the low frame 11 followed by the rise at frame 12 is intentional source correspondence. AI state—not a new animation callback—drives gameplay.

There is **no new hive socket, projectile or child-spawn attachment**. Annulus placement retains its post-clamp fixed center, inner/outer radii 70/180 and separate 0.2 s impact. It is a ring band, not a filled blast. The later summon attempt retains the configured child, positional formula and living-child limit. Contact remains centered at the enemy position, not a painted foot or tube. Facing/locked aim, hurt priority, movement, HP, collision, rewards, cleanup, RNG, production code, UI and other assets remain unchanged.

## Completed local checks

- Separate source-resource checks passed **124 walk, 208 summon, 124 hurt and 208 death predicates**. Matching packed checks passed the same per-sheet counts against their corresponding actual imported source reports. Imported region-crop identity is distinct from source-window pixels or a padded logical canvas.
- The resource-pack smoke check passed **1,068 predicates**. The documented default BUILD entry passed its unchanged **14 routes** on the separate source-and-test wrapper. See the [runner documentation](BUILD_UI_VALIDATION.md); this is not a new all-game or all-enemy suite.
- One controlled native desktop observation passed **749 checks**, produced **55 original 960 × 540 images**, used **5 setups** and retained **55 post-intent authority guards**. Forty-six before/at selector pairs cover the sampled clocks. Other window sizes, DPI modes and platforms are outside this visual scope.
- An author agent directly reviewed all 55 originals; a separate QA agent directly reviewed 16 selected originals. These are AI-agent visual reviews, not human playtesting.

The screenshots cover **50 normal samples** (9 walk, 16 shared action, 9 hurt, 16 death), four selected body mirrors (walk 0, summon 7, hurt 3, death 15) and one reduced-flashes hurt 3. All 50 normal samples also have numerical both-facing registration/foot observations. There is no full mirrored/reduced image matrix.

The captured action timeline is specifically the **annulus-first** route. Real configured Brood Keepers use the existing EnemyAI, CombatRuntime and Director, with explicitly controlled remaining clocks, HP, positions and player invulnerability. Warning 6 compression contrasts with the tall release 7 pose. The selected band hit records damage 11; center/outside geometry observations do not constitute an angular or edge-tolerance sweep. The impact center remains pinned after an intentional later position change; this is not evidence of a physical push.

The next real summon attempt is observed **numerically**, not through a second screenshot timeline: one configured Crawler appears at the existing elapsed-angle offset 50 with its parent identity. A later selected case supplies three living children of that parent; the capped attempt adds zero children but still enters the same recovery/frame 7 presentation. This checks the selected child-cap 3 case, not the global enemy-cap 90 or every spawn condition.

Other bounded numeric observations distinguish move contact from warning/recovery safety, with explicit HP/invulnerability resets and child separation. They cover phase-driven attack refusal, hurt while the AI phase continues, pause/style refresh, expiry/resume, death priority, reward once (XP 12/coins 6), child survival, corpse expiry and clear. A stationary owner-bullet sentinel is **synthetic cleanup input**, not evidence that Brood Keeper naturally fires a projectile.

Authority snapshots begin after intentional changes and legitimate gameplay outcomes; they do not claim that damage, spawning or rewards leave state unchanged. No assets-disabled parity, corpse-cap stress, all-weapons matrix, physical-input playback or full combat replay was added.

## Preserved history and visual limits

The first two body pilots remain visual holds despite passing numerical crop checks: the hive read as a dominant flat disc above insufficient body mass. A third revision first proved two design keys, then the remaining nine pilot poses, before the complete 50-pose redraw and repeat. Earlier holds were not relabeled as passes.

A workspace replacement interrupted preparation before the first Brood export. The accepted prior baseline and dependencies were restored and independently checked; their historical acceptance was not treated as a fresh Brood runtime result. The current Brood source, package and native observations were performed after that restoration.

The original strict resource-pack scene comparison failed on generated scene metadata. An exact semantic scene comparison and separately accepted continuation completed validation on the same unchanged package. This is not an all-phases first-pass result. The current check-only prerequisite and unique native observation passed without a native-fixture revision. Narrowly classified tool/renderer warnings remain recorded; “warning-free” is not claimed.

One inherited descriptive evidence label still names three sheets and an older frame grouping. It is not the operative schema: the accepted mappings and predicates bind **four sheets and 50 frames**. The original executed record is preserved rather than silently relabeled.

In the inspected stills, the broad body, attached face and rear hive remain coherent. Warning/release and ordered corpse lowering read, but tiny upper ports, joints, adjacent gait differences and late eye details merge at game scale; five separate ports are not legible in every pose. The late flattened wreck sits below a separate small green reward marker. Reward/cleanup outcomes are not inferred from pixels alone.

Selected mirrors retain the controlled gameplay state and original locked target; they are not fresh opposite-direction attacks. The reduced image covers only hurt 3. Hurt snapshots show controlled Director presentation, not every final main-loop tint. Derived logical-canvas bounds are not intercepted renderer commands or exact painted bounds. Fixed-step stills and numerical timing do not establish real-time smoothness or every live encounter.

## Delivery and publication status

Local restoration validation passed ten controls: two positive verification/restoration cases and eight refusal cases. A real resource-file backup, replacement and rollback restored the original package while preserving the existing executable bytes and mode. These are local file-restoration controls, not a delivery-executable launch, Windows launch, installation, CI or additional full-game coverage.

Remote publication and remote-dependent history composition remain pending. This locally validated asset set is not a published-release announcement, and no unverified remote parent or completed historical-suffix assembly is asserted.
