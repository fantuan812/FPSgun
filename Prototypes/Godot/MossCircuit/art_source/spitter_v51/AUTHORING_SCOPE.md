# Violet Spitter editable body sheets

These four self-contained SVGs are newly authored redraws, not recovered historical masters. The earlier raster art remains the visual reference and its provenance is retained. Each SVG contains nine explicit articulated poses: shared named shell, tank, cannon, hose and leg parts are editable vector geometry, not embedded raster or nine uniform transforms.

| SVG | Formal PNG | Pose sequence |
| --- | --- | --- |
| `spitter_walk.svg` | `assets/enemies/spitter.png` | Idle/alternating quadruped gait |
| `spitter_shoot.svg` | `assets/actions/spitter/spitter_shoot.png` | Warning brace, release at frame 4, recovery |
| `spitter_hurt.svg` | `assets/actions/spitter/spitter_hurt.png` | Flinch and return |
| `spitter_death.svg` | `assets/actions/spitter/spitter_death.png` | Kneel and low collapsed wreck |

Frame numbers here are zero-based. All sheets remain 1254 × 1254 pixels. Walk uses nine fixed 418 × 418 cells. Actions use 418 × 320 windows with the existing nonuniform row origins; do not replace those windows with a regular square grid.

## Editing and formal export

Edit the SVG's named pose/component groups. Preserve the page, frame translations, occupied crop limits and transparent background. Do not add a weapon, projectile, flash, mouth socket, hidden registration pixel, font dependency, external reference or embedded image. The source exclusion marker `.gdignore` and export exclusions keep editable masters out of the runtime pack; runtime uses the corresponding same-path PNGs.

The accepted new-art repeat used Inkscape 1.4 (`e7c3feb100`, 2024-10-09), with page export, 1254 × 1254 output and antialiasing disabled:

```sh
inkscape spitter_walk.svg --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=spitter.png
```

Use the analogous filenames for the other three sheets. That one repeat reproduced the new baseline bytes and decoded frame identities under the pinned environment/options; it is not a promise of identical PNG bytes under arbitrary tool versions. Inspect warnings rather than suppressing them. The reviewed exporter emitted two known warnings per sheet, so “warning-free” is not claimed.

## Registration is not a measured redraw bounding box

The existing `enemy_manifest.json` Spitter `region` and `alpha_bbox` values are live walk-crop authority and must remain unchanged. Art pads each crop back to logical 418 × 418, with bottom anchor at y = 398. Display height remains 54.15 world units, using the original first-frame height 185 (scale 54.15 / 185); the Director's base foot remains `(0, 27.075)`.

For action sheets preserve the complete existing frame records, including window origins, zero margin, anchor `(209, 300)` and explicit reference height:

| Action | Row y origins | Reference height |
| --- | --- | --- |
| Shoot | 36, 451, 840 | 213 |
| Hurt | 40, 458, 857 | 222 |
| Death | 68, 492, 885 | 252 |

Each row's x origins are 0, 418 and 836. The action scale is 54.15 divided by its reference height. Do not fit, recenter or rescale to a newly measured alpha box. The retained action `alpha_bbox` and walk `minimum_clear_margin` values are explicitly historical QA measurements; they are not current redraw measurements. Current alpha > 8 source-window-local LTRB bounds and clearance are recorded separately in `art_source/provenance.json` under the four current derivations. Walk `pixel_sha256` describes the current full 418 × 418 ART RGBA cell; manifest `source_sha256` describes PNG bytes, while `source_svg_sha256` describes SVG bytes.

Do not run the legacy atlas validator as a redraw updater: it rewrites the live walk crop from new pixels. Any deliberate registration change would be a separate gameplay-facing change, not part of this art replacement.

## Consumer behavior stays unchanged

Walk uses the existing 9 fps frame selection, with idle frame 0. Spitter shooting is AI-phase driven, not a generic nine-frame clock: warning 0.65 s maps frames 0–3, the shot transitions to recovery starting at frame 4, and recovery lasts 0.7 s across frames 4–8. Hurt lasts 0.27 s; death lasts 0.72 s with existing corpse cleanup. Hurt may override the visible body while the AI phase continues. Existing priorities, locked facing, horizontal mirroring, collision, projectile ownership, damage, cooldowns and RNG remain unchanged.

The projectile origin remains **`enemy.pos`**, not the painted cannon mouth. Do not infer or add a cannon socket. Static mirror illustrations do not establish live firing alignment.

## Visual scope and limits

The redraw keeps connected teal armor, purple tank/cannon, dark hoses and a cream bore lip. Its flatter, more geometric and side-on treatment is deliberate rather than pixel equality with the earlier shaded reference. All 36 static poses were directly reviewed at their fixed registered scale. Fine gait, far legs, hoses and late hurt details can merge at that scale. Release and collapse are more pronounced. The late death belly can extend below the foot registration marker: the marker is a fixed anchor, not a guarantee that every painted point lies above it.

Art review and repeat export alone do not establish runtime cadence, AI transitions, import/pack identity, native mirror behavior or delivery. Those are separate acceptance boundaries. This guide neither changes the production assets nor claims remote publication.
