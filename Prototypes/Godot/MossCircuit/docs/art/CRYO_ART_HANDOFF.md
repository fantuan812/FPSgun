# v21 Cryo/Fracture art patch

Scope: one weapon and one item; three new PNGs. No v20 files changed. No remote Git actions.

## Integration
- Copy the three PNGs preserving paths under `assets/`.
- Add `res://assets/items/cryo_icon_manifest.json` to the UI's extra icon-manifest lookup. It contains per-entry atlas paths and crop rectangles for `cryo_sprayer` and `fracture_coil`.
- Merge only `weapons.cryo_sprayer` from `assets/weapon_mounts/cryo_world_weapon_manifest.json` into the runtime world weapon manifest. Existing weapon entries must remain unchanged.
- Icon crops use alpha >32 bounds. World geometry uses the full image region, normalized grip/muzzle points, and 32-unit visible length. No weapon is baked into a hero.
- Cone/chill/shatter visuals are runtime procedural geometry owned by programmer; no effect sheet supplied or required.

## Evidence and limits
All three original generated sources were visually inspected. Cryo silhouette is a cold cyan reservoir and flared nozzle; Fracture is a central cracked ice crystal in a copper/cream ring. Transparent alpha and nonempty alpha bounds verified with Pillow; original PNG bytes preserved, not edited. `cryo_provenance.json` records dimensions, SHA-256 and honest origin/license notes. Full exact prompts are in `cryo_generation_prompts.json`; built-in image_gen used, no CLI fallback or third-party source art.

Images use the existing high-resolution pixel-art aesthetic, not a strict low-resolution grid. Inventory and world views vary tank placement but retain shared palette/material/nozzle identity. Near-transparent generated edge residue retained.

Native actual-size visual acceptance is delegated to independent game QA after runtime integration. Browser preview HTML is provided as a source-inspection convenience only; local headless Chromium screenshot attempt failed during startup and is NOT a passed runtime visual test. No screenshot was produced. Source PNG inspection is passed; integrated game visual QA remains pending.
