# Brood Keeper: editable body artwork

These are newly authored SVG redraws, not recovered original vector masters. Four self-contained SVGs provide all 50 body poses:

| Master | Runtime poses | Effective PNG |
| --- | ---: | --- |
| `brood_keeper_walk.svg` | 9 | `assets/enemies/brood_keeper.png` |
| `brood_keeper_summon.svg` | 16 | `assets/actions/brood_keeper/brood_keeper_summon.png` |
| `brood_keeper_hurt.svg` | 9 | `assets/actions/brood_keeper/brood_keeper_hurt.png` |
| `brood_keeper_death.svg` | 16 | `assets/actions/brood_keeper/brood_keeper_death.png` |

All sheets are 1254 × 1254. Named outer frame groups follow runtime order; their positions follow the existing source windows. Nested groups separate the broad olive body, gold supports, integrated cream face, moss, rear hive and five projecting tube rims. Every pose has articulated component and joint coordinates. The cream face and hive remain in the final low wreck.

## Registration is part of the asset contract

Do not recenter, trim, scale-to-fit, repack or rewrite crop metadata after changing painted bounds. No transparent anchor dots or clipping masks are used to force bounds.

- **Walk:** the live `enemy_manifest.json` region and XYWH alpha-bbox define the retained crop. The logical canvas is 418 × 418, reference height 204, draw scale 513/1360, sprite offset (0, −87), and logical anchor (209, 398). The neutral body reference is 76.95 world units; the fixed base foot is (0, 38.475).
- **Hurt:** existing 418 × 360 windows, zero margins, reference height 269 and anchor (209, 330) remain authoritative.
- **Summon and death:** restore the original 313 × 360 logical canvas from the existing variable-height windows and integral margins. The anchor is (156.5, 330); reference heights are 225 and 206 respectively. Some adjacent source windows overlap in transparent 8-pixel strips. Preserve those blank strips; these are not disjoint regular grids.
- **Death order:** retain the `source_index` sequence `0,1,4,5,2,3,6,7,8,9,10,11,12,13,14,15`. It is not a `source_pose_index` alias and must not be replaced with physical row-major order.
- Keep the complete original action-frame records, references, anchors, timing, and whole `art_source/alpha_bounds.json` unchanged. The latter does not supply a Brood Keeper walk override.

Current measured bounding boxes and clearance are recorded separately in provenance. Retained historical bbox/clearance fields are not measurements of the new pixels and do not authorize recropping. Current PNG and SVG hashes have distinct meanings; the original selected raster manifest records remain historical provenance.

## Animation and gameplay boundaries

The summon body clip serves both the annulus warning and the summon attempt. Frames 0–6 anticipate, frame 7 is the release presentation, and frames 7–15 recover. The low frame 11 followed by the rise at frame 12 is intentional source correspondence. Gameplay events are driven by AI state, not by a new frame callback or hive socket.

The body sheets contain no annulus, projectile, child or spawn effect. Annulus placement, summon positions and child limits, contact damage, warning/recovery durations, facing, hurt priority, death cleanup and reward placement stay in the existing code/data. Editing the art must not change those origins or rules. Static mirrored examples are not evidence of fresh mirrored attacks or spawning.

The rounded R3 body is deliberately more side-on and flatter-shaded than the original rendered art. Rear joints and the upper fifth port can partially merge at actual size; gait, hurt and late-death microchanges are subtle. Static sheet inspection does not establish real-time animation cadence or broad combat coverage.

## Export and edit workflow

Edit semantic parts within the existing frame transforms. Preserve all 50 windows and all transparent overlap strips. Export each SVG to the corresponding same-path 1254 × 1254 PNG with the established binary-alpha settings, then verify the fixed per-frame registration and a bounded actual-size preview before integration. Keep the masters under this ignored authoring directory; the existing `.gdignore` and export exclusions prevent them from becoming new runtime imports. Private authoring generators and validation fixtures are not required to edit these self-contained masters.
