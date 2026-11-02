# Editing the shield impact

`shield_impact.svg` is the self-contained, editable master for `assets/vfx/shield_impact.png`. It is newly authored semantic SVG artwork based on the earlier raster reference, not a recovered master or a pixel-identical copy. It embeds no bitmap, font, script or external resource.

Nine named frame groups separate the arc, core, contact spark and shards. Named palette roles distinguish a cream core, restrained green rim and warm contact accents. Preserve the local right-hand crescent: compact contact grows into a tall arc, splits into upper and lower fragments, then decays into sparse shards. It is not a full shield bubble or a radial explosion. The tall peak is Frame 04 (zero-based index 3).

## Keep layout and behavior fixed

- Transparent **1254 × 1254** page; row-major **3 × 3** cells of **418 × 418**.
- Fixed centered anchor **(0.5, 0.5)**, or **(209, 209)** cell-local pixels, in every frame.
- All nine frames remain nonempty with transparent margins. Do not crop, recenter or independently resize cells. The visible crescent is deliberately asymmetric within its full cell.
- Actual runtime timing remains **18 fps / 0.5 seconds**, with alpha mix and nearest filtering. The default display is **56 × 56 world units**; healing cues use **32 × 32**, and reduced effects use **0.4 opacity**. The historical art recommendation of 24 fps / 0.375 seconds is not the runtime authority.
- Radius-sized callers use a full-cell square with side **radius × √2**, not diameter. Keep this mapping and separate gameplay rings unchanged. The gravity cue's visual radius of 100 is distinct from its gameplay pull radius of 150.

Existing caller colors multiply the texture: white, healing **#83e8a5**, gravity **#cb92e8**, thorns **#ff947d**, and recoil **#a9d9ba**. Keep the bright neutral core; do not bake one module's tint into the master.

## Export and review

From the project root, export the whole page with consistent settings. For example, with Inkscape 1.4:

```sh
inkscape art_source/shield_impact_v47/shield_impact.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=shield_impact.preview.png
```

Review every complete cell at **56 × 56** and **32 × 32**, on dark and light backgrounds, at normal and 0.4 opacity. Check the peak at the existing radius-100 and radius-130 caller sizes with the relevant tints. Preserve the open left side and the separation between the broken arc fragments. Late remnants are intentionally faint and may be indistinguishable at small sizes with reduced effects.

After review, replace only the intended shield-impact PNG and refresh its measured sheet/frame metadata and texture import. Keep frame regions and anchors fixed. Static editing previews are not a substitute for checking playback in the game.

This master covers only the shield-impact effect. It does not change other effects, shielding or healing rules, damage, pull or push geometry, event hooks, delays, cooldowns, pooling, random state, UI or other gameplay behavior.
