# Independent QA reproduction

The five geometry audit scripts read source assets and only write the QA output directory. They open Blender files but do not save them. Run Blender processes **serially**; concurrent rendering has previously exhausted memory.

The recorded source root is `/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement`. If relocating, change each script's single `R=pathlib.Path(...)` source assignment to the relocated Batch08 folder; retain sibling Batch07 and Batch06 folders. The original packaged scripts retain the exact tested path and their hashes. Use a separate output directory to avoid overwriting signed evidence.

```sh
export B08_DESIGN=Config/design_v04.json
export B08_FREEZE=QA/reference_freeze_v04.json
export B08_QA_OUTPUT=/tmp/b08_independent_repeat
for script in audit_scene.py audit_intersections.py audit_parts.py audit_support.py audit_crossing_heights.py; do
  blender -b -t 4 --python-exit-code 1 --python "$script" || exit 1
done
```

`audit_scene.py` opens baseline/current scene and all standalone assets, reproduces the inherited finite ray/route suites, and emits detailed ray evidence (large raw file intentionally omitted from compact delivery; regenerate as above). It depends on Blender's installed numpy and the author's frozen `Scripts/analytic_geometry.py`.

Independent GLB structural parsing does not require Blender:

```sh
B08_ROOT=/path/to/NuclearPlant/Batch08_Refinement B08_QA_OUTPUT=/tmp/b08_independent_repeat python3 audit_glb.py
```

The author runs `python3 Scripts/check_rebuild.py` in a temporary isolated project, which runs the public `python3 rebuild_all.py`, compares scene geometry signatures and exact GLB bytes, and records logs. The independent reviewer inspects these actual outputs and hashes; this is distinguished from a second independently executed replay. No UE import/runtime test is implied.
