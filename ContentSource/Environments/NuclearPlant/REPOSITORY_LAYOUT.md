# Repository storage — complete Batch01–08

Current complete map: `Batch08_Refinement/site_refined.blend`. All Batch01–07 assets remain at their existing paths; no historical asset is replaced or deleted. Batch08 adds three families plus one low-step cover variant (legacy ID FLUSH) (four independent modules), two regional context scenes and the current complete scene. The index has 67 module/combination records, including historical reuse/variants, not 67 newly created families.

Run `python restore_assets.py`, then `python verify_delivery.py`. Independent historical ZIP-LZMA assets and Batch07/08 source drawings (ZIP-DEFLATE, or ZIP-LZMA for the largest over-limit drawings) restore exact original paths, lengths and SHA-256. There are no split volumes, external downloads or empty LFS pointers. Current native module/region/full-scene Blends are directly available. `RESTORE_ASSETS.json` records archive hash, original hash and original Git blob hash for every archived asset.

`CUMULATIVE_MANIFEST.json` covers the complete restored delivery (excluding both manifests and checksum list to avoid self-reference). `REPOSITORY_MANIFEST.json` covers physical Git storage. Existing Batch01–06 root snapshots and verification records retain historical scope/date. No redundant Batch07 root snapshot is added: its exact prior root documents are preserved by parent Git commit `df37461c5b71415431f3131ac1157982a4cfd2c5`. `verify_delivery.py --baseline` verifies historical byte preservation, not rerun geometry acceptance.

`python rebuild_current.py` restores source drawings and rebuilds Batch08 from unchanged neighboring Batch07. `python export_current.py` exports the four current module GLBs only; `--batch07` and `--batch06` explicitly select older module/full-site export formats. Current full-site delivery is native Blend.

Current relocation/reopen/rebuild evidence is under `RepositoryVerification/Batch08/`. Author and independent geometry/visual evidence are under `Batch08_Refinement/QA/`. No UE runtime, official Manny mesh, game performance, baked material or final art acceptance is claimed.
