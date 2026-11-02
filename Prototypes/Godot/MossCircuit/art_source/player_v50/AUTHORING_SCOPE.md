# Editable player body sheets

These are newly authored SVG redraws, not recovered historical masters. Each of the five self-contained SVGs contains nine individually articulated poses, with named body-part groups. The shared visual design is a moss-green scavenger robot: cream face surround, amber eyes, compact torso, backpack, gloves and heavy boots. Weapons are separate assets, never baked into these body sheets.

## Formal sources and outputs

| SVG master | Existing PNG output |
| --- | --- |
| `hero_walk.svg` | `assets/hero_walk.png` |
| `hero_attack.svg` | `assets/weapon_mounts/clean_hero_attack.png` |
| `hero_dash.svg` | `assets/actions/hero_dash.png` |
| `hero_hurt.svg` | `assets/actions/hero_hurt.png` |
| `hero_death.svg` | `assets/actions/hero_death.png` |

Every page remains **1254 × 1254**. The inactive historical `assets/actions/hero_attack.png` is not an output or fallback. Idle uses walk frame 0; it is not an extra sheet. The five masters contain 45 stored frames, not independent directional banks. Left-facing bodies use the existing horizontal mirror behavior.

## Keep registration fixed

Edit the visible geometry inside an existing frame group; do not fit, recenter, rescale or repack the frame to its new alpha bounds. Maintain the connected head/neck/torso/backpack design, and articulate limbs rather than applying nine copies of a single whole-body transform.

- **Walk:** the underlying source grid is nine 418 × 418 cells, but the runtime crop is the existing per-frame **LTRB** `alpha_bbox` in `art_source/alpha_bounds.json`. The existing crop and calculated margins are registration data, not a request to remeasure this redraw. Leave that entire file unchanged. New measured visual bounds belong in current provenance only. Logical walk size stays 418 × 418; its display scale is 64/418. The visible character is not therefore 64 pixels tall.
- **Actions:** the actual source windows are 418 × 340, with fixed nonuniform row origins: attack **38, 442, 832**; dash **74, 448, 858**; hurt **59, 452, 843**; death **88, 487, 850**. Do not substitute a uniform 418-high row grid. Preserve region, margin, anchor, release frame, source-frame fields and reference heights. Reference heights are attack **208**, dash **275**, hurt **254**, death **276**; the action anchor is `(0.5, 328/340)`.
- The shared world foot, logical glove/socket coordinates, mirrored socket behavior and held-weapon attachment remain defined by the existing code and metadata. Shape gloves around the fixed positions in `data/hero_sockets.json` and `assets/weapon_mounts/hero_modular_manifest.json`; do not move those positions to suit a drawing. They also influence authoritative firing origins.
- No hidden or isolated alpha pixels may be added just to manipulate bounds. No raster embedding, script, external reference or font is required by a master.

Action `alpha_bbox` metadata is source-window-local **XYWH**, measured at alpha greater than 8. These export pixels use binary alpha, so that threshold and nonzero alpha select the same pixels. Updated measurements must not replace fixed reference heights or change scale. Walk bounds use a different convention and remain frozen as described above.

## Pose and timing intent

Walk uses alternating legs, arm motion and body bob. Attack frames 0–2 anticipate the existing release at frame 3, then recoil and recover. Dash lowers and extends the body; hurt flinches and recovers; death kneels, collapses and dims the eyes before holding the final body.

Timing is owned by the existing director and game data, not by SVG: the selected walk frame advances at 9 fps; warning selects attack frames 0–2, and the attack reaction selects frames 3–8 over 0.28 seconds. Dash, hurt and death keep their existing durations (normally 0.16, 0.27 and 0.72 seconds). Do not change hitboxes, collision, invulnerability, cooldowns, state priorities, damage, RNG or input behavior as an art edit. Do not bake the runtime hurt flash into the sprite.

## Export and inspect

The formal PNGs were exported with Inkscape 1.4 using full-page 1254 × 1254 output and antialiasing disabled. From the master directory, the equivalent command for each file is:

```sh
inkscape hero_walk.svg --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=hero_walk.png
```

Use a separate output location while editing; do not overwrite the accepted source PNG until the new result is reviewed. Repeatability depends on the pinned renderer and options, not on an assumption that every future Inkscape version emits identical PNG bytes. Preserve transparency, all nine distinct nonempty poses and the original registration windows. Export only the five listed effective outputs and preserve their existing import sidecars.

Inspect at **actual registered scale**, not by independently zooming every bounding box. Include a fixed-foot overlay, right/left examples, and representative separately rendered held weapons. Static previews are not proof of runtime cadence or every weapon/aim combination. Fine gait details, antenna details and late eye slits can merge at small size; fixed anticipation/recoil glove positions may overlap part of the face. These limits do not justify silently changing sockets or crops.

The original historical provenance remains available. Current derivation records identify the new SVG-to-PNG lineage without relabeling unrelated actors, the four previously editable Stitch sheets, or the inactive baked attack image.
