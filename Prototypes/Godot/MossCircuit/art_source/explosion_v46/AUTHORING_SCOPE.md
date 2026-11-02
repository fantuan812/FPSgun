# Editing the explosion

`explosion.svg` is the self-contained, editable master for `assets/vfx/explosion.png`. It is newly authored semantic SVG artwork based on the earlier raster reference, not a recovered master or a pixel-identical copy. It embeds no bitmap, font, script or external resource.

Nine named frame groups contain separate core, flame, smoke and ember geometry. Palette roles distinguish cream light, amber flame, copper edges and moss-green smoke. Edit the sequence from compressed ignition through a broad radial peak to broken lobes, separated clouds and sparse embers; do not replace it with nine scaled copies. The broad peak is Frame 04 (zero-based index 3).

## Keep the layout and runtime behavior fixed

- Transparent **1254 × 1254** page; row-major **3 × 3** cells of **418 × 418**.
- Fixed centered anchor **(0.5, 0.5)**, or **(209, 209)** cell-local pixels, in every frame.
- All nine frames remain nonempty with transparent margins. Do not crop, recenter or independently resize cells.
- Runtime timing remains **18 fps / 0.5 seconds**, with alpha mix and nearest filtering. The default display is **64 × 64 world units**; reduced effects use **0.4 opacity**.
- Radius-sized callers use a full-cell square with side **radius × √2**, not diameter. Keep this mapping and the separate gameplay-radius ring unchanged.
- The phase caller multiplies the texture by **#94c5ff**. Do not bake this tint into the master; the warm and green artwork may appear muted blue or olive under multiplication.

## Export and review

From the project root, export the whole page with consistent settings. For example, with Inkscape 1.4:

```sh
inkscape art_source/explosion_v46/explosion.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=explosion.preview.png
```

Review every complete cell at **64 × 64**, on dark and light backgrounds, at normal and 0.4 opacity. Also check the peak at the existing caller radii **85, 70, 95 and 105**, using the size mapping above and the phase tint where applicable. Preserve the open gaps between lobes and the clear peak-to-decay transition. Late fragments are deliberately faint, especially with reduced effects.

After review, replace only the intended explosion PNG and refresh its measured sheet/frame metadata and texture import. Keep frame regions and anchors fixed. Static editing previews are not a substitute for checking playback in the game.

This master covers only the explosion. It does not change other effects, damage, blast geometry, event hooks, delays, cooldowns, pooling, random state, UI or other gameplay behavior.
