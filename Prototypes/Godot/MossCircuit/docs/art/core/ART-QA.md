# Core reaction art — v15 candidate, 2026-10-24

## Bounded scope and source
Only `boss_core_hurt` (9 distinct poses, .27 s) and `boss_core_death` (16 distinct poses, .72 s). These counts fit the selected beats; there is no nine-frame technical limit. The existing ring/summon attack remains unchanged. New art cannot affect authority, damage timing, summon rules or collision.

Both sheets were produced using built-in `image_gen` with the actually inspected v14 `assets/enemies/boss_core.png` identity reference, true transparency requested. Existing attack was also visually reviewed. The full prompts, reference hash, original generation filenames, PNG SHA256 and Git blob SHA1 are recorded. No CLI/API fallback, pixel edits, image resizing, duplicate frame creation or raster postprocessing took place. The delivered PNGs are unchanged copies of the original generated files.

## Visual identity and action
Preserves the glowing teal-green reactor orb, segmented bronze-gold shell, dark inner mechanism, moss and dangling roots/cables, and the original integrated purple side ports. No face, humanoid limbs or new machine identity. Hurt is a small hovering shell recoil and stabilization; it never becomes an attack. Death loses orb/port light, tilts and descends into a recognizable low inactive reactor. No external projectile rings, summoned creatures, explosions, ground-range indicators or blast effects were added. Existing tiny purple port glow is part of the identity rather than an external attack.

The independent reviewer has visually confirmed identity, floating hurt, and death direction. Independent RGBA review additionally confirmed all 25 unique poses, padded region boundaries and fixed row registration. Its cyan-core color centroid moved from y176.811 to263.913 through death (largest local upward deviation only .012px), while its luminance proxy fell from156.189 to81.867. This color proxy is an approximate visual landmark, not a geometric physics center or a gameplay signal. Runtime review remains a separate gate, not implied by these static checks.

## Floating registration — NOT feet on ground
Core is a floating actor. The existing ActorDirector `base_foot` variable is reused only as a logical registration point; it is not evidence that Core has feet. No pose is individually aligned by its tail/root minimum, and no row offset is automatically derived from minimum-alpha bottom. That would erase descent and make the reactor hover in place while dying.

All frames share logical 512×400 canvas, centered anchor (.5,.8), and one action scale/reference height (hurt 278; death 248). X maps each original nominal source-column center to logical x256 with one rounded translation per column, plus one fixed per-action calibration offset: hurt -12px, death -16px. The independent reviewer measured an initial ring-center mismatch versus the real original hover; this one constant offset corrects it for the whole action. Every frame receives exactly the same extra shift, preserving sway and silhouette width. Keeping anchor.x=.5 lets this registration shift mirror naturally under flip_h without runtime changes. A proposed noncentered-anchor solution was rejected during review because the unchanged runtime offset does not mirror that anchor. No per-frame recentering is performed. Y uses explicitly selected whole-row source-layout corrections:

| Action | Source row partitions | Fixed whole-row dy |
|---|---|---|
| hurt | 0,418,836,1254 | -73,-473,-865 |
| death | 0,390,730,1000,1254 | -17,-337,-635,-880 |

The image model packed the lower death rows closer vertically. Equal-height row subtraction would make the final row rise back toward the initial hover height. The death corrections register that nonuniform atlas layout while preserving the progressive visible ring/core descent. Hurt row offsets register the approximately 400/392-pixel separation of the hovering orb centers. They preserve each row's natural sway, and are fixed for every pose in that row; no per-frame centering, scaling or tail-bottom leveling is performed.

Death is already usable in original row-major pose order: silhouette height decreases 248→139, and logical highest point lowers 72→191. There is a one-pixel top wobble at frames 10→11 (1-based), retained as natural rendering/tilt variation rather than normalized away. Visible tail/casing lower edge varies 318..333 and ends330, not rigidly locked to320. Hurt lower edge varies311..320. These are silhouette trajectories, NOT feet or a requirement for ground contact. The core/ring center trajectory is the primary floating-descent acceptance signal.

## Fresh static checks and reproducibility
- Each sheet is 1254×1254 RGBA with genuine fully transparent pixels.
- All 25 pose hashes are unique within each action; no repetition used to pad frame counts.
- Every region is meaningful alpha≥8 bbox plus four source pixels; transparent/very-low-alpha haze outside remains untouched in the source and simply is not sampled.
- Integer region/margin produces exactly 512×400 logical frames, all source bounds valid. Full per-pose boxes, translations and source row registration coordinates are in `fresh-art-qa.json`.
- `python build_metadata.py --project /path/to/MossCircuit --output /tmp/core-art-qa` reads installed PNGs and writes JSON only outside the project. Without `--project`, reads PNGs next to the script. It never writes PNGs or project assets.

## Installation and remaining gate
Install two PNGs and `action_manifest.json` to `assets/actions/boss_core/`. Runtime duration must be configured in ActorDirector config; manifest duration fields are descriptive. Program/review agents must verify real hurt/phase restoration, terminal death, lifetime, scale continuity, pause/reset and reduced-flash behavior. Static art checks are not substituted for gameplay QA.

## Final independent calibration gate — PASS
The independent review recomputed actual RGBA core landmarks after the constant X-registration adjustment: using pixel-area centers (+0.5) rather than pixel-index coordinates, first-frame world X residual versus original hover is below0.25px for both facing directions (hurt±0.203px; death±0.035px). Y differences of approximately1.19/2.07px remain as small original hovering-pose variations. Death centroid descent and progressive dimming remain valid. Final delivered anchor is centered (.5,.8); the rejected noncentered-anchor experiment is not the delivery. Final runtime gate remains with program/review agents.
