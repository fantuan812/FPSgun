# NuclearPlant repository storage — Batch01–07

The current complete map is `Batch07_Refinement/site_refined.blend`. All Batch01–06 assets remain at their existing paths. Batch07 adds seven reusable module families plus one independent narrow-cabinet variant, three region files, the current complete Blender scene, frozen v1–v4 pre-model drawings, scripts/configuration and final rendered evidence.

Run `python restore_assets.py` then `python verify_delivery.py`. The exact large historical scenes/exports are retained in their existing independent ZIP-LZMA archives. Large Batch07 SVG sources use independent standard ZIP-DEFLATE archives. Every archive restores one original file to its exact path and verifies SHA-256; there are no split volumes, empty LFS pointers or private download dependencies. Current scene/module Blender files are directly available without extraction.

`RESTORE_ASSETS.json` contains both archive and restored hashes, byte counts and original Git blob hashes. `REPOSITORY_MANIFEST.json` covers the physical Git layout; `CUMULATIVE_MANIFEST.json` covers the complete restored delivery, excluding the two manifest files and checksum list to avoid self-reference. Previous root documents/scripts are retained byte-for-byte under `RepositoryVerification/Batch01-06_RootSnapshot/`. `verify_delivery.py --baseline` checks historical byte preservation only; it is not a rerun or re-dating of historical geometry tests.

`python rebuild_current.py` rebuilds Batch07 from the immutable neighboring Batch06 baseline after restoring drawings. `python export_current.py` exports Batch07 modules to GLB only. The full-site GLB/FBX retained under Batch06 are explicitly older baseline exports; `--batch06` regenerates that older full-site export when deliberately requested.

Repository restoration/reopen/rebuild evidence for this increment is in `RepositoryVerification/Batch07/`; earlier `RepositoryVerification/summary.json` concerns the original baseline. This is not UE runtime, collision/nav, Manny mesh or final baked-material acceptance.
