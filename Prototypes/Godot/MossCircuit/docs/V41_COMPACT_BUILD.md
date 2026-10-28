# Compact BUILD, responsive shops and editable L4 icons

## What changes

Press I to inspect the paused BUILD snapshot. Weapon/module counts and concise current statuses appear first; explicit groups reveal status details, weapon cards, module cards and synergy/cooldown/stat details. A status-details group appears when an equipped B module supplies status rows; it does not require all three B modules. Full costs, conditions and cards remain accessible. Shop and result views retain their existing noncompact presentation.

The underlying readouts and gameplay rules are unchanged. Pin still needs two distinct equipped weapon types and a second hit on the same marked target. Salvage charge and active-field counts remain distinct. Winch counts normal combat pickups—not “normal-mode-only” pickups—and retains its medical-pickup requirement, one-pull-per-batch limit and no-direct-healing/creation/collection wording in full details.

Card icons keep their textures, crops and logical 48/24-pixel sizes, but align at the top beside their complete identifying names. Narrow shops stack the two existing scroll areas instead of extending beyond the panel. Wider shops remain side-by-side. BACK and the shop footer remain fixed outside scrolling content.

Resizing preserves the existing controls, selection and focus. Layout may scroll the already-focused control into view; it does not rebuild inventory or issue a refresh/purchase action. There are no price, RNG, item-mechanic or controller-intent changes.

## Editable artwork

These five inventory icons have editable SVG sources in [the L4 source directory](../art_source/legacy_inventory_L4/):

| Item | Editable SVG | Runtime PNG under `assets/items/` |
|---|---|---|
| Cryo Sprayer | `cryo_sprayer_icon.svg` | `cryo_sprayer_icon_editable.png` |
| Fracture Coil | `fracture_coil.svg` | `fracture_coil_editable.png` |
| Bankshot Driver | `bankshot_driver_icon.svg` | `bankshot_driver_icon_editable.png` |
| Bounce Guide | `bounce_guide.svg` | `bounce_guide_editable.png` |
| Feedback Diode | `feedback_diode.svg` | `feedback_diode_editable.png` |

Edit the SVG rather than painting over the exported PNG. Keep the transparent 64×64 canvas, runtime names and existing icon bindings when exporting a replacement, then reimport in Godot and run the current source-verification entry. Artwork changes still require their own resource/consumer review; a source-test pass alone is not visual acceptance. Existing held8 redraws are preserved. This is not a claim that every legacy artwork file has been redrawn.

## Narrow-screen limits

The checked layouts use 960×540 and 640×360 logical views. At 640, long cards and actions require scrolling; the tested card top and tail may be separate views. Icons and their complete identifying labels must be visible together in each designated icon observation—not split across screenshots or shortened to fit.

The resize checks change both the real window and its matching logical viewport. Existing viewport stretch is unchanged. Logical 48/24-pixel icon sizes are not guaranteed physical pixel sizes when only the OS window is resized.

See the [standalone validation summary](V41_VALIDATION_SUMMARY.md) for actual finite results, retained failure history and exclusions. It is authored release documentation, not a relocated test log or runtime provenance bundle.
