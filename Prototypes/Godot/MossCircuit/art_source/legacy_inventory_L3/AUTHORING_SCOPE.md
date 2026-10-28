# Editable mechanism icons

The eight SVG files here are the editable masters. They use original geometric shapes, named groups and editable palette attributes—not embedded raster images or traced bitmap masters. PNGs are runtime exports; concept or reference images are not the source of truth.

## File pairs

Each master exports to the matching file under `assets/items/`:

| SVG master | Runtime PNG |
| --- | --- |
| `arc_relay.svg` | `arc_relay.png` |
| `kill_cell.svg` | `kill_cell.png` |
| `dash_resin.svg` | `dash_resin.png` |
| `mirror_shell.svg` | `mirror_shell.png` |
| `thorn_crown.svg` | `thorn_crown.png` |
| `blood_valve.svg` | `blood_valve.png` |
| `scrap_mine.svg` | `scrap_mine.png` |
| `pulse_boots.svg` | `pulse_boots.png` |

Every image has a transparent 64×64 canvas. `assets/items/mechanism_icon_manifest.json` binds each icon to its own PNG with region `[0, 0, 64, 64]`. These are direct file bindings, not cells in a shared atlas. The former `mechanism_atlas_v4.png` is no longer a runtime resource; older v4 atlas documentation is historical.

## Editing and exporting

1. Edit the SVG geometry, groups, fill or stroke palette attributes. Keep the 64×64 canvas, transparency, identifiers and file pairing intact. Preserve your edited SVG rather than regenerating it from an older drawing recipe.
2. Export a preview outside the game project. With Inkscape, for example, after creating a separate preview folder:

   ```sh
   inkscape art_source/legacy_inventory_L3/arc_relay.svg \
     --export-area-page --export-width=64 --export-height=64 \
     --export-antialias=0 --export-type=png \
     --export-filename=../icon-preview/arc_relay.png
   ```

3. Check transparent edges and readability as 48-pixel card icons and 24-pixel purchase-forecast icons. Inspect the complete icon and label, not just a cropped thumbnail.
4. Replace only the matching runtime PNG after review. Let Godot import it normally; do not hand-edit generated texture caches. Retain the manifest's direct path and full-canvas region.
5. Use the project's documented portable checks and inspect the affected BUILD, inventory, shop and purchase-forecast views after an edit.

Artwork changes do not authorize changes to item statistics, stacking rules, triggers, prices or gameplay behavior.
