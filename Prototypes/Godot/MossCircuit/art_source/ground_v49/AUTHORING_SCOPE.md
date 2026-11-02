# Ruined garden ground — editable SVG source

`ground_atlas.svg` is the editable master for `assets/ground_atlas.png`. This is a new semantic vector redraw of the dark teal, moss-covered machine-garden floor, not a recovered historical master. The original raster is a visual reference only; it is not embedded. Historical provenance remains in `art_source/provenance.json`, alongside the explicitly scoped current ground derivation.

## Edit the master

The self-contained SVG has nine named `tile_00` through `tile_08` groups and named soil, moss, stone, copper and cable detail groups. Keep the 1254 × 1254 page and the nine full 418 × 418 cells in this row-major order:

| Index | Variant |
| --- | --- |
| 0 | Quiet mineral soil |
| 1 | Clustered moss |
| 2 | Fractured stone |
| 3 | Amber pebbles |
| 4 | Buried paving |
| 5 | Grass tufts |
| 6 | Buried cable |
| 7 | Mossy stones |
| 8 | Quiet dominant dirt |

Tile 8 deliberately avoids a strong landmark because the existing selection favors it. Keep the floor restrained behind actors, pickups and combat markers. These are static variants, not animation frames.

Every cell is fully opaque. Do not add transparent gutters, crop to visible bounds, recenter cells, reorder variants or bake the game's joint lines into the PNG. Decorative cracks, paving and cables are not obstacles or collision geometry. The floor has deliberate tile joints; this is not a seamless-texture claim.

## Export from the project root

Edit the SVG, then export the whole page without antialiasing:

```sh
inkscape art_source/ground_v49/ground_atlas.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=assets/ground_atlas.png
```

The formal PNG was reproduced byte-for-byte with Inkscape 1.4 (`e7c3feb100`, 2024-10-09) and these options. Keep the renderer and options fixed when checking deterministic output; arbitrary versions or other renderers may produce different pixels. Preserve the existing PNG path and import settings.

## Review at the actual display scale

Review each full cell at 80 × 80, both unmodified and with the existing RGB draw multiplier `(0.65, 0.75, 0.72)`. Then inspect a small, explicitly fixed neighboring-tile arrangement with the separate dark joint lines. A hand-chosen preview arrangement is not the gameplay map generator or evidence about seed distribution. Tiny grain and moss marks may merge at this scale.

This asset replacement does not change tile size, tint, nearest filtering, joint drawing, map-cell selection, conditional RNG consumption, arena dimensions, walkability, collision, camera, draw order, UI or gameplay. Static art previews alone do not establish live actor contrast or runtime behavior; those require separate in-game checks.
