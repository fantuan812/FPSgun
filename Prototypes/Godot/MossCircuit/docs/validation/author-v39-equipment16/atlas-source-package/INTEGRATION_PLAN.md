# Sixteen-cell atlas: proposed integration, not performed

This independent asset-only candidate composes the four accepted L1-C2 inventory SVGs and twelve accepted L2 item SVGs. It does not touch the held-weapon geometry or either frozen source package. The primary `assets/items/icon_manifest.json` would be replaced explicitly with the new atlas path and all sixteen 64×64 rects. **Do not change global extra-manifest merge semantics.** Current `moss_ui.gd` only adds extra entries when an ID is missing; it would not override these sixteen existing IDs.

## New formal files
- `art_source/icons/<ID>.svg`: exact copies of sixteen accepted independent source icons.
- `art_source/equipment_atlas_editable.svg`: fully editable inline geometric composition; one `icon-<ID>` semantic group per ID. Child IDs are namespaced to avoid collisions. No external SVG/raster references.
- `assets/items/equipment_atlas_editable.png`: deterministic renderer derivative, after approved export.
- `assets/items/icon_manifest.json`: explicit primary sixteen-ID mapping, after export; preserves existing ID/name/category semantics. UI upgrade aliases still refer to the same IDs.

## Old dependency edges found in the frozen baseline
1. `assets/items/icon_manifest.json:atlas` → `res://assets/items/equipment_atlas_v2.png`.
2. `assets/items/equipment_atlas_v2.png.import`: uid `uid://chrklnkaqwl6m`, source path above, remap/dest `res://.godot/imported/equipment_atlas_v2.png-11b80674c2f1c7d87a11c3318433d881.ctex`.
3. `ui/moss_ui.gd` reads the primary manifest; `icon(id)` resolves per-entry atlas or the primary atlas fallback. These accesses must resolve only to the new primary path for all sixteen IDs after integration.
4. Historical `docs/art/README.md`, old import logs, and old `MANIFEST.json` reference the old name as historical evidence. They are not runtime dependencies; preserve honestly, update the new release manifest from actual source.
5. Both export presets use `export_filter="all_resources"` and `include_filter="*.json"`; current excludes do not generally exclude arbitrary new reference folders. An unused old PNG can otherwise remain exported.

## Required accepted-candidate integration actions
- Replace the primary manifest atomically with the new sixteen-ID mapping; do not leave the old primary atlas as a fallback for those IDs.
- Remove old `equipment_atlas_v2.png` and its `.import` from runtime asset scope. Preserve old source only in a dedicated reference-only tree with `.gdignore` and explicit export exclusion, or solely in historical artifacts outside the candidate.
- Never carry an old `.godot` cache into the cold candidate. A clean importer must not regenerate the old PNG `.ctex` because no runtime source refers to it.
- Explicitly exclude reference/history/development-art source paths as appropriate in each delivery preset, including `validation_inputs/*` (accepted per-icon PNG checks only; .gdignore already present in this staged folder). `.gdignore` alone is not a claim of PCK absence.
- Perform cold import/source-reference audit and actual PCK resource enumeration. Assert absence of old PNG path, old `.import`/remap and old `equipment_atlas_v2.png-*.ctex`, including the known baseline target above. Assert presence/loadability of the new atlas and primary JSON.
- Read back all sixteen IDs from the packed primary manifest, compare each crop with accepted source pixels, and visually exercise shop, inventory, build report, upgrade alias icons and other consuming UI on the native candidate.
- Only then mark old atlas dependency removed. Until those gates, this is a proposed source-map/composition migration, not runtime or full-art-migration completion.

No production source, UI code, export preset, cache, Git or GitHub has been modified by this art worker.
