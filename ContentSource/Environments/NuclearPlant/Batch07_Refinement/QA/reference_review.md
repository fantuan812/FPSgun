# Initial v01 pre-model reference review — historical, superseded by v02–v04

Reviewed actual PNG pixels before Blender modeling, 2026-10-21 03:28 UTC.

- Standard FRONT (-Y), RIGHT (+X), TOP (+Z) projections use the same metres-to-pixels scale within each sheet and are analytic projections from the design JSON, not post-model renders.
- Five module sheets and three region sheets plus the full site placement plan are present. The large east region intentionally includes two disconnected yards; separate device detail is readable on module sheets.
- Added separate hidden-roof / hidden-tarp structure sheets for transformer, logistics canopy and cargo. These are explicitly labelled supplementary construction views, not ordinary opaque-top visibility.
- Corrected tarp bands to follow the draped surface and corrected paired rack placements before the initial model build.
- Former shed footprint rear/left/right solid walls are retained to 2.4m. Existing route screens are untouched; open pipe racks and cargo are NOT certified ballistic cover.
- Upper-angle protection changes when the original 4.5m walls and complete roofs become shorter screens. This is not equivalent cover for every elevation and will be reported separately from ground-level line-of-sight sampling.
- Approximate module descriptions are informational; exact bounds will be measured from design vertices and written to ALL_MODULES.json.

Frozen input manifest: `reference_freeze.json` (27 hashes, includes design generator and analytic geometry source). Build aborts if a frozen hash differs.

## Final revision note
The above is the unchanged historical scope of the first design review, not the final accepted cover state. V02 restored original 4.5m side/rear solid wall height with supported upper screens; v02–v04 restored solid service cabinets after independent tests. V02 sheets corrected dimensional titles to measured analytic envelopes. The final active design is Config/design_v04.json, with the explicit v04 narrow-cabinet sheet; all four reference-freeze records remain verifiable. Final results and limitations are in README.zh-CN.md and the independent final review.
