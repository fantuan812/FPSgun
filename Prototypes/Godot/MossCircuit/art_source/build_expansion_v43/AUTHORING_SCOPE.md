# Build-expansion icon masters

These eight icons are new geometric redraws, not recovered historical masters or pixel-identical copies. The earlier painted atlas was a visual reference only. The editable source is each self-contained, transparent 64 × 64 SVG in `art_source/build_expansion_v43/`; its named groups describe the parts, and `data-palette` names describe material and light roles. There are no embedded bitmap images, fonts or external dependencies.

| Master | Main identity |
| --- | --- |
| `return_disc.svg` | Three swept blades and a cyan ring hub |
| `shock_mortar.svg` | One inclined, hollow mortar tube on a braced base |
| `return_spool.svg` | Green recovery cable between broad spool flanges |
| `blast_fuse.svg` | Copper-banded canister, curved fuse and orange spark |
| `echo_chamber.svg` | Two unequal violet resonator mouths |
| `gravity_anchor.svg` | Hanging eye, violet core and separated hooked claws |
| `medic_seed.svg` | Diagonal red-capped seed capsule with a green sprout |
| `phase_capacitor.svg` | Horizontal cyan/violet chambers and a top phase arc |

Edit the SVG geometry directly, or use a vector editor that preserves the 64 × 64 page. Keep the charcoal outlines, cream casing, copper joints and sparse moss readable before adding small surface details. Emissive colors distinguish the mechanisms. The pixel-aligned shapes intentionally simplify the high-resolution reference; tiny scratches, soft glow and photographic texture are not reproduced.

Export the full transparent page rather than cropping to the drawing. For example:

```sh
inkscape art_source/build_expansion_v43/return_disc.svg --export-type=png --export-area-page \
  --export-width=64 --export-height=64 --export-png-antialias=0 \
  --export-filename=assets/items/return_disc.png
```

Use the same renderer version and options when checking reproducibility. Inspect the PNG at 64 px and at the actual 48 px card / 24 px forecast sizes with nearest-neighbor display, on both dark and light backgrounds. Check the complete silhouette and readable feature separation, not just a magnified vector preview.

The eight PNGs use matching filenames in `assets/items/`. Each inventory binding uses the full `[0, 0, 64, 64]` image; the earlier painted atlas is not a source master for these redraws. Keep the filenames, IDs and full-page dimensions stable when editing. This artwork concerns inventory cards and purchase forecasts, not held-weapon or projectile geometry; prices, stack caps, equipment limits and game behavior are separate and should not change when editing an icon.

Open `preview.html` beside the masters to inspect the shipped PNGs at 64, 48 and 24 px on dark and light backgrounds. The preview is an editing aid, not an in-game test.
