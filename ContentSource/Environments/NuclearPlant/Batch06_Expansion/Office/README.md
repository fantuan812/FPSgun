# Control-office wing — Batch06

Region file: `../Regions/control.blend`; collection: `B06_Control`.

## Reference-first revision

An early pre-reference trial was made before the user restated the strict reference-first requirement. It is retained only in `Scratch/control_pre_reference.blend` and is **not the final region**. After that instruction, modeling stopped. Four new asset AI reference sheets plus a regional orthographic candidate and overview were generated. The staircase candidate was retried as an engineering line drawing but still did not maintain exact equal pixel scale across views.

Therefore `References/*_prebuild_ortho.svg` and matching PNGs were created **before the revised model** by analytic 2D coordinates from dimension specifications. Their source is `generate_prebuild_orthographic.py`, with no Blender/model import. They are the authoritative pre-build dimensional projections. AI candidates are separately labeled style references, not measurement proof. `ai_reference_manifest.json` and `prebuild_projection_manifest.json` retain generation timestamps and paths. The regional AI overview shows extra doors and illustrative detail; exact interface locations and counts follow the authoritative regional 2D plan.

## Modularity

New reusable units: 3m-wide stair unit (run3.4m, rise2m,12 treads; three units reach6m), 4x3.6m gallery deck, 4x1.8m control island, and 2.6m-wide display panel (five panels form the display wall). Their actual standalone models, GLB exports and post-build orthographic verification images are in `Assets/`. Post-build images are **not** substituted for the pre-build references.

Walls, roof and floors reuse unchanged 4m Batch04 meshes. Console and cabinet collections reuse Batch05 assets. Packaged `Reused/` files are local standalone inputs. Small closure plates, portal headers, beams and railings are explicitly parameter-built assembly pieces, not giant non-reusable building modules. The 48x24m shell is a region assembly, not a single module.

## Interfaces and routes

- Bounds X[-24,24],Y[38,62], metres; no outside road, terrain, world or lights in `build(config)`.
- South entry(2,38,0), north ground exit(2,62,0), clear4.2m width and4.4m height.
- West elevated portal(-24,48,6),3.6m width and4m clear height; deck top6m.
- East open-head stair3m wide,36 treads, total rise6m/run10.2m; northern/western gallery route.
- Wide central control hall and equipment alcoves, not a grid of small rooms. Central island and console banks break the direct approach; a side bypass continues to the north exit.
- `office_static_checks.json` uses support/upward ray samples with2.1m head clearance. This is not a swept capsule, navmesh or UE runtime acceptance.

## Rebuild

`blender -b --python-exit-code 1 --python build_office.py`

`build(config)` is importable and creates a fresh collection without resetting the caller's scene. Bounds and interface coordinates are actual inputs. Current structural family requires dimensions on4m increments, height12m and elevated datum6m above ground; invalid dimensions fail instead of silently scaling the whole module set. Edit `office_config.json`, keeping interfaces coordinated with the parent `layout.json`.

Standalone helper `render_office.py` creates preview lights/cameras only for rendering; those are not saved into the region asset. `check_office.py` is the default-placement static checker. The original Batch04/05 sources were not overwritten.

## Final checks and reusable exports
`Assets/CTL_*/model.blend` and `export.glb` are standalone local-origin reusable assets; `front/right/top.png` are **post-build verification renders**, not the prebuild references. Index: `module_export_manifest.json`. `export_modules.py` regenerates them from the finalized region.

`office_static_checks.json`: 512 intended support/upward-clearance samples passed. Independent `../QA/office_horizontal.json`: 504 horizontal rays across the planned routes passed. These do not substitute for UE capsule sweep/navigation tests. Region GLB and round-trip check can be regenerated with `blender -b --python-exit-code 1 --python Office/export_region.py`. GLB shader appearance is approximate.

The three scripts moved into `Scratch/` are historical preparation/patch tools, not rebuild dependencies. Only `build_office.py` is the geometry rebuild entry; its `Reused/` sources and prebuild reference manifests are local to this folder.

### Preview provenance and final small revision
`control_eye.png`, `control_upper.png`, and `control_cutaway.png` are low-sample Cycles **structural draft previews**; they contain visible sampling noise and are not polished delivery renders. They were rendered before adding two small steel mounting brackets beneath the island status panel; no dimensions, passages, or interfaces changed. `Assets/CTL_Island` was re-exported and its three verification views rerendered after that fix. The final region GLB was round-trip checked (1,360 meshes, zero linked libraries). `revision_timeline.json` and `region_export_check.json` record the final source hash. Route reports precede only this isolated non-route bracket addition; final assembly QA can audit the new region.
