# Editing the muzzle flash

`muzzle_flash.svg` is the self-contained, editable master for `assets/vfx/muzzle_flash.png`. This is newly authored semantic SVG artwork, not a recovered master or a pixel-identical copy of the earlier raster reference. It embeds no bitmap, font or external resource.

The nine named frame groups contain separate core, flame and ember groups; palette-role labels identify the warm colors. Their silhouettes progress from ignition and a short tongue to a long peak, split lobes, fragments and fading embers. Edit these shapes individually rather than making nine scaled copies.

## Keep the layout fixed

- Transparent **1254 × 1254** page; row-major **3 × 3** cells of **418 × 418**.
- The same anchor in every cell: **(0.28, 0.52)**, or **(117.04, 217.36)** cell-local pixels.
- All nine frames remain nonempty, with transparent margins. Do not crop, recenter or independently resize cells.
- Runtime timing, size and blending stay **30 fps**, **0.3 seconds**, **36 × 28 world units** and alpha mix. The reduced-effects style uses **0.4 opacity**.

## Export and review

From the project root, export the full page with consistent settings. For example, with Inkscape 1.4:

```sh
inkscape art_source/muzzle_flash_v44/muzzle_flash.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=muzzle_flash.preview.png
```

Review every complete cell at **36 × 28**, on dark and light backgrounds, at normal and 0.4 opacity. Preserve the open split lobes and clear peak-to-decay rhythm. Late embers are deliberately faint; tiny fragments may blend into a background, especially in reduced-effects mode. A magnified preview alone is insufficient.

After review, replace only the intended muzzle PNG and refresh its measured sheet/frame metadata and texture import. Keep all frame regions and anchors fixed. Editing previews are not a substitute for checking playback in the game.

This source covers only the muzzle flash. It does not replace the other five effect sheets or change firing hooks, pooling, damage, random state, or other gameplay behavior.
