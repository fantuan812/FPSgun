# Scrap Crawler editable artwork

These are newly authored SVG redraws, not recovered original masters. The three self-contained masters contain 34 named, articulated poses with no embedded raster, external fonts or runtime script dependency.

| Master | Formal PNG | Size | Poses |
| --- | --- | --- | --- |
| `crawler_walk.svg` | `assets/beetle_walk.png` | 1268 × 1241 | 9 |
| `crawler_hurt.svg` | `assets/actions/crawler/crawler_hurt.png` | 1268 × 1241 | 9 |
| `crawler_death.svg` | `assets/actions/crawler/crawler_death.png` | 1417 × 1110 | 16 |

## Editing the body

Each frame group has a stable runtime-index name, such as `crawler_death_frame_02`. Its nested semantic groups separate far and near legs, dark underbody, rear and shoulder carapace, face/cream eyes, circular side hinge, rear moss and wear marks. Edit those real shapes and joint positions rather than moving a finished frame uniformly. Keep the connected, rounded copper/rust shell, short heavy support and visible cream eyes. The final corpse is a low intact shell; its eyes are not extinguished.

The SVG files are self-contained snapshots of one shared construction. When changing a shared feature, carry the corresponding edit through the relevant frame groups. The private authoring generator and validation reports are not runtime dependencies or public editing requirements.

## Registration that must not change

- **Keep the root walk path.** Do not add or substitute `assets/enemies/crawler.png`. The current root-path fallback has different registration behavior.
- Walk slicing is governed by the existing `art_source/alpha_bounds.json` LTRB records, not the descriptive Crawler boxes in `enemy_manifest.json`. Preserve that entire file. The physical cells are uneven: widths 422/423/423 and heights 413/414/414. The padded logical texture is **423 × 414**.
- Walk scale is **19/138**. The Director's visible reference height is **1615/46 ≈ 35.108696**, and the fixed world foot is **(0, 3553/138) ≈ (0, 25.746377)**. The nominal `Art.actor` height argument is not a request to resize this redraw to 57 visible pixels.
- Hurt and death retain their original variable source regions, integral margins and **512 × 400** logical size. Their reference heights are **260** and **215**, with the existing offsets and common world foot unchanged.
- Death uses authored runtime-to-physical order **[0, 1, 4, 2, 3, 5, 8, 6, 9, 7, 10, 12, 11, 13, 14, 15]**. Frame group names are runtime indices; their placement preserves the original physical source windows. Do not reorder or repack the sheet.
- Keep real painted geometry inside each retained crop. Do not use alpha masks, clipping, hidden pixels, new bounding-box fitting or recentering to satisfy containment.

Current measured boxes and clearance are documented separately in `art_source/provenance.json`. Retained historical manifest boxes and clear-margin values are not measurements of the redraw. The manifest's current PNG/full-cell hashes and SVG lineage are identified separately. Do not run a legacy atlas tool that rewrites live crops from newly measured pixels.

## Formal export

The formal runtime assets are deterministic PNG exports of these SVGs. Export the full page at the exact dimensions above using the established Inkscape 1.4 settings, transparent background and `--export-png-antialias=0`. Do not trim the canvas or substitute an image-generator reference for the formal output.

Before replacing a formal PNG, verify a bounded fresh export against its accepted new baseline, all fixed registered regions, binary alpha, distinct poses and unchanged import sidecars. A source edit creates a new baseline that requires review; a byte difference is not permission to overwrite an accepted file silently. Keep `.gdignore` and the export exclusion for this master directory so SVG editing files are not runtime payloads.

## Gameplay is outside this art unit

There is **no new attack sheet or attack action clip**. The existing procedural contact attack continues to use the registered idle body, with its existing squash/rotation behavior. Chase, contact at `enemy.pos`, the strict existing contact-distance test, damage, hitboxes and state priority are unchanged; no mouth or leg socket has been introduced.

Walk remains the existing 9 fps selection. Hurt retains its 0.27 s action and death its 0.72 s / 16-pose progression and cleanup. The death artwork does not make a permanent corpse or alter reward handling. Code, encounter data and action records remain the authority for behavior.

## Visual limits

The redraw is flatter and more side-on than the rendered reference. Fine gait, joints and late eye marks can merge at the small registered size. Retained nonuniform source envelopes can produce modest apparent volume changes between neighboring poses. Static comparison and mirrored panels establish art/registration illustrations, not native cadence, live contact, every facing or a full enemy-combat matrix. Runtime observations and release acceptance are separate from this editing guide.
