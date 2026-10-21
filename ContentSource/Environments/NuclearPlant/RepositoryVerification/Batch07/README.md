# Batch07 incremental repository validation

These reports apply to the frozen current Batch07 source and its independent relocated restoration/rebuild. The prior baseline reports one directory above keep their original Batch01–06 scope.

- restoration_check.json: all 147 author files and 29 restored archives match exact SHA-256.
- blender_open_check.json: 12 new/current native files independently reopened; no missing images or external libraries.
- rebuild_fingerprints.json: actual one-command rebuild matches evaluated geometry/transforms, material-node parameters/links, lighting/color management and camera/render settings.
- export_regeneration_check.json: eight module GLBs regenerated and parsed with no external URI; not a full-scene GLB/FBX test.

Reproduce on a disposable restored copy: `python rebuild_current.py --threads 2`, then invoke the supplied Blender scripts with root/output/baseline-root arguments as shown in the saved reports. Rebuilding changes output bytes and build timestamps, so perform delivery checksum verification before rebuilding.
