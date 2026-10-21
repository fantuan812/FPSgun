# NuclearPlant repository storage

This directory preserves the complete cumulative Batch01–06 Blender source project: all 888 original delivery files, 76 native Blender files, every module, reference drawing, configuration, assembly script and interchange export. Existing FPSgun content is unchanged.

Open `Batch06_Expansion/site_expansion.blend` directly for the current complete map. Run `python rebuild_current.py` to rebuild it with Blender 4.3+.

Some large historical native scenes and interchange exports are stored as independent standard ZIP-LZMA archives because of connector transport size limits (the two complete-site exports also exceed GitHub's individual-file limit). These are ordinary single-file archives, not split volumes or Git LFS pointers. Run `python restore_assets.py` once to restore all original native and export paths. The script uses only the Python standard library, verifies archive and restored SHA-256 hashes, and downloads nothing. Alternatively use 7-Zip or another ZIP-LZMA-compatible extractor. All 76 original native files are preserved losslessly; the current map and most modules need no extraction.

After restoration, run `python verify_delivery.py` to verify the original cumulative delivery manifest. `RESTORE_ASSETS.json` records original sizes, original SHA-256, decompressed SHA-256, archive SHA-256, and original Git blob hashes. `REPOSITORY_MANIFEST.json` records the committed physical layout (excluding its own hash).

Historical scripts are retained as delivered and may contain old absolute paths; only the current Batch06 rebuild was relocation-tested. This is not UE runtime, collision, navigation or Manny-mesh acceptance. See `ALL_MODULES.md`, `README.md` and `DeliveryVerification/` for scope and evidence. The 55 module/combination index records include explicit reuse and are not 55 newly created unique modules.

Repository-layout validation: the 888 original files were restored in a separate directory and all original SHA-256 hashes matched; all 76 native Blender files reopened with no missing images or external libraries. The current map was rebuilt from the restored project and its geometry/transform and lighting/color-management fingerprints matched the frozen delivered scene. See `RepositoryVerification/summary.json` and supporting reports.
