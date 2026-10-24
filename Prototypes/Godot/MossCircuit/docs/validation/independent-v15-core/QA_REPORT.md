# Core v15 — independent reaction-layer closure review

## Candidate results, 2026-10-24

Baseline is published v14 `51a6f3ce4ae91e08212c7675df9a9f21620fee9f`. Candidate was copied into an isolated QA directory with no import cache, not executed concurrently against engineering's import cache.

- Godot4.6.3 cold headless import passed without engine/script errors.
- **43 executable SceneTree test entry points passed**, including UI and both new Core tests.
- **403 independent Core assertions passed**: both modes, phase1/phase2 scheduling, true every-third phase2 summon rule, crossing50% HP during warning, real8/12 ring counts under hurt, actual summon and parent-local cap0..4 with unrelated children, release owner/speed/damage, recovery not frozen/replayed, lethal interruption across warning/recover/move, parent projectile cleanup vs child survival,100-coin/trophy reward without Warden repair, reentrant award/death, mode-specific clear/terminal policy, pause/reset/final corpse frame/recycle, all frame indices, logical hover anchors in both facings, initial height and reduced-flash pose continuity.
- **26 cases /27,600 frames exactly match v14** for full authoritative dictionaries/events and three RNG streams, with only the two new Core assets enabled/disabled. Both independently produced raw trace outputs are byte-identical; identities are retained. This finite matrix is not an exhaustive proof for every possible play state.
- All27 audited runtime/authoritative-data/old-Core-attack files remain byte-identical. Actor config differs exactly by two Core reaction mappings and one extra manifest. Existing seven-archetype hurt/death mappings all resolve to authored PNG resources; see coverage table.

## Static image and registration review

Both new source sheets were visually compared with the actual old Core: bronze/moss ring, cyan-green nucleus, purple side accents and trailing roots retain identity. Hurt remains a hover/recoil; death dims and tilts into low wreckage. No new attack-ring, explosion or summon creature is baked into reaction art. These are high-resolution raster sprites, not native low-resolution pixel art.

Independent pixel audit confirms25 distinct poses, safe integer regions with4px visible-alpha padding,512×400 canvas, fixed scale/reference_height per action, fixed source-column centers and explicit whole-row Y offsets. Core has no physical feet: base_foot is only the inherited logical registration. The death cyan-color area-centroid proxy descends from approximately177.3 to264.4 logical pixels; cross-row upward noise is0.012px. Final cyan-region luminance proxy is81.87 versus156.19 initially (~52%). These pixel-derived proxies support static inspection, not semantic landmark or live-GPU claims.

The first draft introduced a visible center shift relative to the old hover sprite. A noncentral-anchor idea was rejected before final integration because fixed offsets would not mirror safely under flip_h. Final metadata keeps anchor(.5,.8) and uses one fixed action-wide source registration offset: hurt X=-12, death X=-16 pixels. It does not recenter or resize individual poses. Under a consistent pixel-center convention, first-pose cyan-centroid X residual is±0.203 world pixels for hurt and±0.035 for death across both facings (<0.25); Y differences are1.19/2.07 world pixels of hover-pose variation. Full method and reference hash are in core-first-pose-continuity.json.

## Closure and limits

This completes authored hurt/death coverage for the seven **existing enemy archetypes**, not the whole game or every attack animation. Old Warden charge/blast and Core ring/summon still reuse their existing attack clips. No runtime gameplay, new attacks, balance, room rosters or reward policies changed. Live GUI playthrough, human feel/readability, Windows exports, sustained performance and live accessibility comfort remain unperformed; see MANUAL-ACCEPTANCE-REMAINING.md.

## Reproduction and final delivery gate

Set writable XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME. Cold import an isolated project with `godot --headless --path PROJECT --editor --import --quit`, then `python3 run_suite.py PROJECT OUTPUT`. Run independent_authority_trace.gd with `-- OUTPUT.json` against baseline/candidate and compare_traces.py. verify_core_pixels.py takes the source-art directory. Final immutable-ZIP CRC/manifest/history/fresh-import/tests/trace acceptance is recorded externally after packaging, not claimed completed by this pre-package report.
