# Editable equipment atlas — independent candidate

Sixteen accepted semantic sources are copied unchanged from L1-C2 (four weapon inventory icons) and L2 (twelve items). `layout.json` pins each source, old rect, proposed rect and source package. `compose_atlas.py` creates a 256×256 SVG with sixteen named ID groups and an entirely inline HTML/CSS preview. `export_atlas.py`, only inside an agreed heavy window, renders one PNG and verifies every 64×64 cell's full RGBA bytes against its accepted standalone PNG. There is no imagegen, raster embedding, auto-tracing or gameplay code change.

`preview.html` palette controls mutate editable SVG fill attributes and save SVG XML. No local fetch/XHR/external resources; browser interaction remains unverified.

Source composition alone is not acceptance. See `INTEGRATION_PLAN.md`: the main manifest must be replaced explicitly, not added as a non-overriding extra; old image/.import/remap/cache references must be excluded and actual PCK enumeration must demonstrate absence. Production integration/cold/native gates are not performed here.

`validation_inputs/accepted_png/` holds exact accepted independent derivatives for self-contained cell-identity verification, not old AI imagery or runtime resources. It is `.gdignore`-marked and must also be explicitly excluded from delivery. No absolute workspace dependency remains in the export script/layout.
