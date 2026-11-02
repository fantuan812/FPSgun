# Editing the dash trail and chain arc

`dash_trail.svg` and `chain_arc.svg` are the self-contained, editable masters for the matching PNGs in `assets/vfx/`. They are newly authored semantic SVG redraws using the earlier raster sheets as visual references—not recovered masters or pixel-identical copies. Neither embeds a bitmap, font, script or external resource.

Both masters use named frame and component groups, with named palette roles for cream highlights, moss greens, warm amber and copper. Edit the components rather than replacing the entire sheet with a generated image.

## Shared layout

Keep each transparent **1254 × 1254** page as a row-major **3 × 3** grid of **418 × 418** cells. All nine frames must remain distinct and nonempty, with transparent margins. Export the complete page; never crop, recenter or resize cells independently.

Runtime timing is **24 fps / 0.375 seconds**, with alpha mix and nearest filtering. Reduced effects multiply opacity by **0.4**. Preserve these settings and the existing caller tints, event order, cooldowns, pooling and gameplay behavior.

## Dash trail: preserve the leading point

The fixed anchor is **(0.76, 0.52)**, or **(317.68, 217.36)** cell-local pixels. The whole cell displays at **72 × 32 world units**. Its leading point stays near the right-hand anchor while the warm wake grows leftward, reaches its strongest shape at **Frame 04 (index 3)**, then breaks into uneven fragments.

Ordinary dash cues rotate with their supplied direction. The separate Pulse Boots cue uses the existing default angle and mint tint **#7fe9cb**. Do not combine these two emissions or change their transforms while editing the artwork.

## Chain arc: preserve both attachment points

The nominal anchor remains **(0.5, 0.5)**. Endpoint-driven playback uses the fixed contacts **(0.14, 0.54)** and **(0.87, 0.54)**—cell-local **(58.52, 225.72)** and **(363.66, 225.72)**. Keep both contacts in every frame. A thin branching link grows between them, peaks around **Frame 03 (index 2)**, then breaks into isolated segments and contacts. It must remain visually distinct from a broad dash wake.

The nominal cell display is **100 × 28 world units**. Endpoint playback rotates toward the destination and stretches horizontally so the **0.73-cell contact span**, not the full cell, matches the rounded endpoint distance. For nonzero endpoint distances, the complete displayed cell width is **distance ÷ 0.73**, while its height remains **28**. A requested zero-length link retains the renderer’s tiny positive horizontal scale (**0.00001**), rather than truly zero-width geometry or perfectly coincident rendered attachments. Preserve the requested endpoints and this existing normalization; it is not a promise that the tiny link is visually discernible. Padding extends beyond the contacts. Do not move contacts to the page edges or replace this mapping with full-width stretching.

## Export and review

For example, from the project root with Inkscape 1.4, export each full page consistently:

```sh
inkscape art_source/dash_chain_v48/dash_trail.svg \
  --export-type=png --export-area-page \
  --export-width=1254 --export-height=1254 --export-png-antialias=0 \
  --export-filename=dash_trail.preview.png
```

Use the same options with `chain_arc.svg` and a separate preview filename. Review all nine complete cells on dark and light backgrounds, at normal and reduced opacity. Check dash at 72 × 32 with its direction and Pulse tint samples; check chain at nominal size and several endpoint distances and directions with height 28. Thin or late remnants can become indistinguishable at reduced opacity, especially on light backgrounds.

After review, update only the intended PNGs and their measured sheet/frame metadata and texture imports. Keep anchors, endpoints and regions fixed. Static previews do not establish in-game cadence, endpoint alignment or gameplay correctness. These masters cover only the two effects; the other four VFX and all gameplay code remain separate.
