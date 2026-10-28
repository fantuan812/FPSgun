# Editing the five inventory icons

These are original geometric redraws, built from editable SVG shapes rather than embedded bitmaps. They are inventory icons, not held-weapon sprites. The SVG files are the masters; PNG files are derived runtime images.

Masters are in `art_source/legacy_inventory_L4/`. Their corresponding PNGs are in `assets/items/`:

| Icon | SVG master | Runtime PNG |
| --- | --- | --- |
| Cryo Sprayer | `cryo_sprayer_icon.svg` | `cryo_sprayer_icon_editable.png` |
| Fracture Coil | `fracture_coil.svg` | `fracture_coil_editable.png` |
| Bankshot Driver | `bankshot_driver_icon.svg` | `bankshot_driver_icon_editable.png` |
| Bounce Guide | `bounce_guide.svg` | `bounce_guide_editable.png` |
| Feedback Diode | `feedback_diode.svg` | `feedback_diode_editable.png` |

## Edit and export

1. Edit the SVG directly in a vector editor or text editor. Named groups separate components; `data-palette` tags identify related fill colors.
2. Keep the current 64×64 canvas and transparent background when replacing a shipped icon. Export to a separate working folder first, not over the master or runtime image.
3. For crisp, hard-edged output, Inkscape supports this command (create `icon-export/` first):

   ```sh
   inkscape art_source/legacy_inventory_L4/cryo_sprayer_icon.svg --export-type=png --export-png-antialias=0 --export-filename=icon-export/cryo_sprayer_icon_editable.png
   ```

4. Check the exported PNG at 64×64 and at the interface’s 48- and 24-pixel icon sizes. Preserve transparency and inspect the complete silhouette, narrow gaps, and small highlights.
5. After reviewing the change, replace the corresponding PNG and let Godot reimport it. Keep the existing item ID, filename and `[0, 0, 64, 64]` icon region unless intentionally updating its binding too. Recheck the icon in shop, inventory and purchase-forecast views.

Make future visual changes in the SVG, then export again. Reference images—including AI-generated references—are not editable masters and should not replace these source shapes.
