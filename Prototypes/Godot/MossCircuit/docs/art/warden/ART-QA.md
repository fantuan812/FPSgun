# Warden reaction art — v14 candidate, 2026-10-24

## Scope and source
Only `boss_warden_hurt` (9 poses, .27 s) and `boss_warden_death` (16 poses, .72 s). Existing attack/AI/collisions are not replaced. The count is chosen for these beats, not a general nine-frame restriction.

Both original PNGs were generated using built-in `image_gen` with true transparency requested, referenced to the actually inspected v13 `assets/enemies/boss_warden.png` (baseline commit `56a6c721850fc3ef67caa0f766661a3970eb6a59`). Also inspected the existing attack sheet for identity consistency. Full prompts and generation source/output hashes are supplied. No Python raster rewriting, resizing, compositing, recoloring or frame cloning occurred. Source generation images remain untouched; delivered files are identical copies.

## Visual review
The candidate preserves squat moss-covered olive/rust mechanical stone armor, cream rectangular head/amber eyes, unequal heavy fists, short legs and shoulder exhaust. Hurt is a brief torso flinch/rebound with arms down, not a new attack. Death folds the heavy body into a low recognizable heap; eyes dim and no detached debris is added. Neither sheet contains attack-range rings, ground shockwaves, impact sparks or projectile effects.

The generated source atlas is not treated as perfectly animation-ready row-major. Death row boundaries can return to a taller pose; explicit metadata sequence is `[0,1,4,5,2,6,3,8,7,9,10,11,12,13,14,15]`. Hurt uses `[0,1,2,3,4,5,7,6,8]` so its small rebound settles rather than double-bobbing. All 25 poses are distinct; none was duplicated to reach a count.

## Registration and fresh static QA
- One unmodified 1254×1254 RGBA PNG per action; genuine zero-alpha pixels confirmed.
- Every logical frame canvas is 512×400, anchor (.5,.8), fixed action reference height (hurt 258; death 213).
- Integer region = alpha≥8 meaningful bbox plus four source pixels. Low-opacity outlying matte noise remains untouched in the source, but is not sampled outside the region.
- X registration maps the nominal original source-column center to logical x256 using one rounded translation per column, never each pose's bbox center. Y registration uses one common source baseline per row. This preserves natural lateral posture shifts and within-row foot offsets; it is not per-frame bbox normalization.
- Source row baseline y: hurt [386,778,1162]; death [344,663,962,1209]. Death atlas second-row column split is explicitly 925 rather than an equal-grid boundary so the next pose is not accidentally included. Nominal column registration remains unchanged.
- Hurt visible feet all land at y320 because the generated poses already share each source-row baseline; this was not forced per frame. Death feet range y315..320, retaining the original small offsets.
- Death heights monotonically descend: 213,212,207,197,197,192,191,176,171,157,145,126,118,109,103,100. Logical top y monotonically descends: 102,108,111,121,123,128,129,143,149,163,175,194,202,211,217,220. It never returns to standing.
- `fresh-art-qa.json` gives full per-frame source partitions, source centers/baselines, translation, logical bbox, foot trajectory and unique pixel hashes. `generation-provenance.json` gives complete PNG SHA256/Git-blob SHA1 and reference hash.

To reproduce metadata only: `python build_metadata.py --project /path/to/MossCircuit --output historical-temp/warden-art-qa`. Without `--project`, it reads PNGs beside the script. Output must be outside the supplied project. The script writes JSON only and never alters raster/project assets.

## Integration gate
Copy the two PNGs and `action_manifest.json` into `assets/actions/boss_warden/`; configure actual hurt/death duration in ActorDirector config. Duration fields in this manifest are descriptive, not an authoritative gameplay clock. Fresh static art checks and visual sheet review are complete. Independent reviewer confirmed identity/style, all 25 unique poses, the four-pixel alpha≥8 safety border, fixed source-column/row registration, foot trajectories and monotonic death top/height on 2026-10-24. Godot playback, hurt interruption/recovery into the current authoritative phase, death removal, real-world scale and reduced-flash runtime checks remain pending the program/review agents. Do not promote these static checks to gameplay QA.
