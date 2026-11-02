# Editing the hit spark

`hit_spark.svg` is the self-contained, editable master for `assets/vfx/hit_spark.png`. It is newly authored semantic SVG artwork, not a recovered master or a pixel-identical copy of the earlier raster reference. It embeds no bitmap, font or external resource.

Nine named frame groups contain separate core, ray, ring and debris geometry. The sequence develops from a central hot point through a radial star and broken ring to sparse debris and a final ember. Edit these shapes individually rather than making nine scaled copies or borrowing the directional muzzle-flash silhouette.

## Keep the layout and color behavior fixed

- Transparent **1254 × 1254** page; row-major **3 × 3** cells of **418 × 418**.
- The same centered anchor in every cell: **(0.5, 0.5)**, or **(209, 209)** cell-local pixels.
- All nine frames remain nonempty, with transparent margins. Do not crop, recenter or independently resize cells.
- Keep the bright core neutral cream. Existing module tints multiply the texture; do not bake a module's color into the master. Some modules deliberately share or have similar tint colors.
- Runtime timing, size and blending stay **27 fps**, **one third of a second**, **32 × 32 world units** and alpha mix, with nearest filtering. Reduced effects use **0.4 opacity**. The historical manifest's suggested 30 fps is not the runtime timing authority.

## Export and review

From the project root, export the full page with consistent settings. For example, with Inkscape 1.4:

```sh
inkscape art_source/hit_spark_v45/hit_spark.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=hit_spark.preview.png
```

Review every complete cell at **32 × 32**, on dark and light backgrounds, at normal and 0.4 opacity. Check a representative peak with all eight existing module tint assignments. Preserve the radial opening, broken-ring separation and clear decay. Sparse late remnants are deliberately faint, especially in reduced-effects mode; a magnified preview alone is insufficient.

After review, replace only the intended hit-spark PNG and refresh its measured sheet/frame metadata and texture import. Keep regions and anchors fixed. Editing previews are not a substitute for checking playback in the game.

This source covers only the hit spark. It does not replace the muzzle flash or other effect sheets, or change hit hooks, visual cooldowns, pooling, damage, random state or other gameplay behavior.
