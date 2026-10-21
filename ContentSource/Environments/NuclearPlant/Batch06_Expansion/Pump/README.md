# East pump service block

`bash Pump/rebuild.sh` (from any cwd with correct path) rebuilds region, exports standalone modules, and runs static QA + preview. Uses Blender 4.3 and only local `reuse.blend`. Entry API: `build(config)` in `build_pumps.py`. Coordinates in metres. Origin translates the fixed regional template; pumps, tanks, screens, gantries, palette and interface use JSON inputs. This is a configurable template, not an arbitrary-layout solver.

Output: `../Regions/pumps.blend`, collection `B06_Pumps`. Port `(42,4,6.8)` radius `.22`, west entry `(42,8,0)`. Bounds x42..68 y-8..26. Continuous main aisle y6..10; north header axis3.2m clears hall access route (56,8)→(57.5,9)→(57.5,18.5)→(56,20); service hall opening x53..59, height4m. `module_index.json` lists isolated local-origin modules.

## Reference chronology
`References/*orthographic*.png` and `zone_overview.png` are AI styling references. Tank and gantry received one targeted retry; gantry TOP remains invalid. These are **not claimed as exact orthographic specifications**. The `*_technical.svg` files are independent deterministic 2D projections from `dimensions_spec.json`, made before corrected Blender rebuild, and govern dimensions. `technical_provenance.json` records this. `Scratch/pumps_pre_reference.blend` is earlier trial only, not compliant deliverable.

`reference_manifest.json` records reference/source/output hashes and UTC timestamps. `check_report.json` is 687 static vertical ray samples including a sampled H2.1/r.5 envelope on the hall route, not gameplay certification. No UE collision/NavMesh validation. Conservative team clearance envelope: H2.1m/r.5m, not an official measured Manny skeletal mesh.

## Design
Four reused pumps in two separated banks, linked headers and buffer tanks; solid maintenance hall plus three fire/acoustic screens provide meaningful cover. Low-saturation steel/concrete with red safety bands. No random barrels/crates, outside roads/terrain or region world lights.
