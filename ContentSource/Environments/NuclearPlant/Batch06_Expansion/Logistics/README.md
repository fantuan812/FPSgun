# Batch06 maintenance and dispatch

All units are metres. Rebuild from this directory or any working directory:

```sh
blender -b --python /path/to/Logistics/build_logistics.py
blender -b --python /path/to/Logistics/qa_logistics.py
```

`build(config)` creates world-space `B06_Maintenance` and `B06_Loading` without resetting the caller's scene. Command-line entry resets its own scene, exports `../Regions/{maintenance,loading}.blend`, `logistics_combined.blend`, and seven standalone `Modules/*.blend` indexed by `module_index.json`. No external absolute source dependency: the actual Batch04 storage rack is copied in `Reused/batch04_reuse.blend`. Offset/palette/prop-position settings live in `logistics_config.json`; structural topology is intentionally validated as one fixed-size template rather than advertising untested arbitrary resizing.

## Reference chronology and authority
`Scratch` preserves the earlier prototype generated before the newly mandatory front-loaded reference requirement. It is not compliant final geometry.

`References/*_concept.png`: image_gen styling references, five new composite modules and two regional four-panel concept sheets. AI perspective distortions, incorrect door orientation and inconsistent counting were reviewed and **not** accepted as exact engineering projections. `References/*_technical.svg` are deterministic front/right/top dimensional drawings produced before formal Blender regeneration, from `module_specs.json`, not post-render images. These drawings/specifications govern geometry. `reference_manifest.json` and `technical_drafting_receipt.json` record their provenance; formal rebuild time is in `logistics_manifest.json`.

New composite modules: maintenance portal bay, stair/landing, dock canopy bay, freight container, service workstation. Structural members, boards, hoists, rails, slabs, small pads/pallets are constituent geometry, not separately advertised asset types. Existing rack mesh is actually reused. The full shell/dock are also independently exported as convenience composites.

## Interfaces
Maintenance footprint x[-68,-42], y[-16,18], ground z0; east 6m clear gate; south 3m pedestrian gate. North bridge opening at(-54,18,6), 3m wide and 3m tall. Threshold extends to y18.2 intentionally to overlap the bridge approach. Stair clear structural tread width2.6,34 rises to6m,tread.28; guards1.1m.

Loading footprint x[18,66], y[-62,-42]; north entry x[38,46]. South dock top1.1m, west2.6m ramp and2.6m stairs both connect through a continuous landing. Grouped rack/wall at west and service shed/walls at east maintain an8m central entry lane. Cover spacing is a design goal, not tactical simulation validation.

QA caught a workstation foot intersecting the stair's right edge. Both service workstations/pads were moved1.2m east in the plan and model; threshold was also extended to eliminate a0.2m drop at the bridge wall. `qa_report.json` contains body/head centreline ray checks. Independent team's swept/support checks are in `../QA`.

Scale uses a conservative2.1m height /0.5m radius proxy. Exact UE Manny mesh, character movement, navmesh and collision have **not** been tested. The review PNGs are actual Blender model renders, not reference artwork; their temporary review lights/cameras are never saved into delivered region files.
