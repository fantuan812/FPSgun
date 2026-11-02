# Knifeleg Flanker — editable body source

These three self-contained SVG masters are newly authored vector redraws, not recovered original vector masters. Named semantic groups keep the cobalt wedge carapace, linked charcoal chassis, warm pivots, moss, cream triangular face and ivory-edged blue blade limbs editable. The exported body contains no projectile, contact marker or baked weapon.

## Effective assets and pose order

| Master | Effective PNG | Logical animation |
|---|---|---|
| `flanker_walk.svg` | `assets/enemies/flanker.png` | 9 walk poses |
| `flanker_hurt.svg` | `assets/actions/flanker/flanker_hurt.png` | 9 hurt poses |
| `flanker_death.svg` | `assets/actions/flanker/flanker_death.png` | 16 death poses |

All three atlas canvases are 1254 × 1254. They do not share one uniform frame geometry: the walk is a 3 × 3 set of 418 × 418 cells; actions use their retained explicit source regions. The death atlas's physical layout is not animation order. Runtime death order uses source poses **0, 1, 4, 2, 5, 3, 8, 6, 9, 7, 10, 11, 12, 13, 14, 15**. Edit the named runtime/source-pose group rather than sorting the sheet visually.

There is no Flanker attack sheet or authored attack clip. Its existing procedural contact-attack presentation uses the walk body. Do not add an attack PNG to imitate a four-state family.

## Registration is a fixed contract

- **Walk:** `assets/enemies/enemy_manifest.json` supplies the live region and alpha-bbox XYWH crop. This is not Crawler's root-path fallback and has no Flanker `alpha_bounds` override. Retain every original region/bbox, 418 × 418 logical canvas and padding. The first visible reference height is 153, displayed height 51.3, scale 57/170, sprite offset `[0, -112.5]`, logical anchor `[209, 398]`, and world base-foot offset `[0, 25.65]`. Walk margins may include half-pixels.
- **Hurt/death:** retain all original 512 × 400 logical sizes, source regions, **integral** margins, anchor `[256, 320]`, source-pose indices and reference heights 222/178. Their scales are 171/740 and 513/1780, with offsets `[0, -9]` and `[0, -31]`. These are original registration constants, not a new fit-to-bbox calculation.
- Keep the entire `art_source/alpha_bounds.json` and all action frame records unchanged. Newly measured redraw bboxes and clearance belong only to current provenance, never silently to runtime crop/scale metadata.
- Preserve genuine geometry inside the existing windows/crops. Do not add invisible pixels, mask away overflow, recenter a pose, or enlarge a window to satisfy a validator.

## Editing and export workflow

1. Open one SVG in a vector editor. Keep its canvas and named groups. Change connected semantic parts, not a uniform whole-body transform repeated across all frames.
2. Maintain distinct gait articulation, hurt compression/recovery and runtime-ordered collapse. The seven pilot keys remain the identity/registration reference. Keep the cream front visible in the final low wreck; do not introduce a late eye-extinguishing effect absent from this design.
3. Export a full-page transparent PNG at exactly 1254 × 1254 using the pinned deterministic renderer/options for this asset pipeline. The reviewed export uses binary alpha and antialiasing disabled. Never overwrite accepted outputs during a trial.
4. Check full-sheet identity, all 34 retained windows/crops, alpha containment and runtime-order previews at actual registered scale. Any repeat comparison is against the accepted new SVG export, not old raster pixel equality.
5. Bind each imported source report separately. Packed verification must compare to the corresponding actual imported source report, not substitute ART pixel hashes or assume transparent RGB is unchanged by import.

The current PNG hash, SVG hash, full-cell ART RGBA hash, imported crop hash and visible-RGBA hash describe different objects. Keep their labels distinct. Historical raster/source prose and old measured bboxes remain explicitly historical records; current derivations describe the new pixels. Live crop values stay authoritative even when the current painted bbox is smaller.

## Unchanged consumer behavior

The existing `flank` movement combines forward pursuit and sinusoidal lateral weave. Existing contact damage is measured at `enemy.pos` (not a blade-tip socket), with its original threshold and procedural attack response. There is no new shot origin, projectile, warning/release clip or attachment socket. Walk remains 9 fps; hurt lasts 0.27 s and death 0.72 s with the existing 16-pose ordering. State priority, facing, repeat gates, rewards, owner-bullet cleanup and corpse lifetime are unchanged code/data behavior, not authored in these SVGs.

## Visual limits and delivery boundary

The new body deliberately uses a low, flatter side-on cobalt wedge rather than reproducing the original three-quarter rendered shading. Fine far-leg articulation, small gait differences and late death changes merge at actual 1× scale; the final cream triangle is a tiny mark. Enlarged inspection aids and static mirrored panels are not native cadence, movement, contact or gameplay proof. Native checks and direct visual review are separate evidence.

This guide is staged separately from the accepted runtime source until the normal local delivery/prose step. It does not claim a remote release, public-ledger update, completion of all game art, or runtime acceptance by itself.
