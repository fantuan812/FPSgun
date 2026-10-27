# Historical generated-art provenance — reference only

The entire original checkpoint below is retained unchanged. Its assets/... paths and PNG hashes identify the superseded generated-art candidate, not the current editable-SVG runtime assets. Current formal mappings are in ../art_source/stitch_drone/SOURCE_MAP.json; current acceptance and limits are in V38_STITCH_DRONE.md. The four original images survive only in explicitly reference-only evidence, excluded from the actual new PCK.

---

# v38 Stitch Drone artwork and identity boundaries

Four original generated transparent PNG sheets, each1254×1254 in a3×3 grid, depict a cyan thread spool/needle hover drone and distinct channel, hurt and death actions. Original bytes are retained; atlas crops/margins are metadata, not raster edits. Prompts and original-file identity are in `art/stitch_drone/prompts.json` and `art/stitch_drone/provenance.json`.

| Sheet | SHA-256 |
|---|---|
| `assets/enemies/stitch_drone.png` | `39a2625999a6ac02b1cc3a96e1a0ed0f399997538620e3cc1ccc76b13ca099d8` |
| `assets/actions/stitch_drone/stitch_drone_channel.png` | `4af2efab9604bd461095d60b60d6df46ce09db6a25eeabeed09fb8813efee180` |
| `assets/actions/stitch_drone/stitch_drone_hurt.png` | `f2e8505ad992177f5b2d86e8a5b1e0cdc0c96d8f933751b87c6a165302297efe` |
| `assets/actions/stitch_drone/stitch_drone_death.png` | `3d5ab456066a67baaf357a4a7c1c2cfe389626ed44b819a148718973a4002e5b` |

The hover atlas retains whole418×418 cells. Action atlas rectangles use alpha>8 bounds, integer-centered horizontal padding and20px bottom padding on418×418 logical canvases. This threshold intentionally excludes low-alpha fringe; it is not a claim that every nonzero-alpha pixel lies inside the crop. Three original action sheets register nine frames each without replacing historical action manifests. Channel phases use warning0–5, attack6, recovery7–8 and locked warning/recovery aim.

All four source sheets were directly viewed. Independent PIL alpha/crop geometry and actual source imported AtlasTexture checks passed; those establish image identity/layout, not in-game aesthetic acceptance. Existing fix_alpha_border can alter transparent RGB, so packed RGBA identity must compare against the separately recorded actual source-imported image, not original PNG bytes. Actual PCK/native validation remains pending at this checkpoint. No asset ownership exclusivity or legal clearance beyond recorded generation provenance is asserted.
