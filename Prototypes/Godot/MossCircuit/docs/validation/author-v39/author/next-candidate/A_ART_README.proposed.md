# A weapons/modules — editable formal artwork

The seven `svg/*.svg` files are the formal, editable sources: two separate 128×64 held weapons and five 64×64 inventory/module icons. Named groups and `data-palette` attributes expose their geometry and colors; no raster image is embedded. Runtime PNGs are deterministic exports, not generated-image reference files.

## Edit and reproduce

From the project root:

```sh
cd art_source/build_expansion_A
python export_assets.py
```

The exporter resolves all paths relative to its own file. Tested renderer: Inkscape 1.4 (e7c3feb100), `--export-png-antialias=0`; measurement/review uses Python 3 and Pillow 12.3.0. It creates local `assets/items/`, `assets/weapon_mounts/`, `manifest.draft.json`, and `svg-review.png` beneath this source directory. It does **not** silently overwrite the project's runtime assets. Compare the fresh exported PNG SHA256/alpha bounds with the manifest, then deliberately copy the matching seven PNGs to the same paths under the project root's `assets/` directory. Keep world grip/muzzle/full-canvas geometry and inventory crop metadata consistent with the actual export; re-run affected validation after any edit.

`build_svg.py` is the original semantic geometry/palette authoring recipe. Running it replaces the SVG files with its baseline shapes; do not run it after manual SVG edits unless this replacement is intended. `export_assets.py` renders the current SVG files without regenerating their geometry. Different renderer versions are not claimed to reproduce identical bytes.

The source manifest uses relative editable-source paths and `res://assets/…` runtime mapping. The held muzzle between Tether's front prongs is a deliberate virtual emission axis. Formal game geometry lives in the world-weapon manifest, not in a preview image.

This integrated directory intentionally contains no AI reference PNGs, internal tool IDs, HTML preview, or preview-builder script. Separate author staging previews/references are not required to reproduce the runtime PNGs. The SVGs themselves remain directly editable. New A artwork is only one part of the game's gradual legacy-art migration; do not infer that unrelated legacy images are SVG-backed or that asset export alone proves gameplay/native acceptance.
