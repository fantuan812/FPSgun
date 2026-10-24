# Independent Warden reaction review — v14, 2026-10-24

## Verified candidate

Baseline is published v13 `56a6c721850fc3ef67caa0f766661a3970eb6a59`, previously independently verified from its immutable source ZIP. Candidate was copied to an isolated QA snapshot before cold import; engineering and independent QA did not share or delete one another's import caches.

- Godot 4.6.3 genuinely cold headless import: PASS, no engine/script errors.
- **41 executable SceneTree test entry points: PASS**, including UI test and both new Warden tests.
- **942 independent Warden assertions: PASS**: both modes, two health phases, five AI phases; real HP-loss triggers; repeat-hurt suppression; phase/aim/target progression; blast under hurt exactly once; charge moves and expires at authority time; both recover windows; current phase resumed rather than replayed; lethal interruption in each tested phase; immediate combat removal, boss reward once, no postmortem blast, paused tail, frame15 before recycling; both facings, every authored frame slot, logical anchor and initial height continuity, reduced flashes.
- **26 deterministic cases / 27,600 frames exactly match v13**, with Warden reaction assets both enabled and disabled. Full combat/run/mode dictionaries, all enemy AI fields/events, and gameplay/loot/shop RNG are included in per-frame hashes. Raw outputs are byte-identical; see trace-identities.json. A finite test matrix is not proof for every possible play state.
- **27 runtime/authority/old-attack source checks unchanged**; actor config differs exactly by two Warden reaction keys and one additional manifest. Global durations, other profiles, Core, old nine-frame attack and all gameplay code remain unchanged.
- Independent static image inspection compared both new sheets to the actual v13 Warden walk identity: box head/orange eyes, asymmetric heavy fists, olive/rust armor and moss remain recognizable; no attack/blast VFX are baked into the reaction sheets.
- Independent pixel audit: 25 unique poses, safe integer crop regions, 4px visible-alpha padding,512×400 fixed logical canvas, fixed per-action reference height, fixed source-column registration and common source-row Y translation. Hurt9/.27s compresses then returns; death16/.72s descends to wreckage. Death heights213→100 and silhouette tops102→220 are monotonic. Hurt visible feet all at y320; death preserves y315..320 variation rather than forcibly grounding each frame.

## Boundaries

Only hurt/death are newly authored. Existing Warden attack9 continues to serve charge and blast; this does not distinguish the two attack clips. Hurt does not cancel, freeze or replay authority phases. Death does not delay rewards or wave completion. Native room rosters are unchanged; manual room Warden injection is a test fixture. Existing modal pause/shop behavior is preserved. Source PNGs are high-resolution raster sprites, not native low-resolution pixel art. Full static sheets were viewed, but live GUI and Windows-export playtests were not performed.

## Reproduce and delivery gate

Use writable XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME. Cold import an isolated project with `godot --headless --path PROJECT --editor --import --quit`; run `python3 run_suite.py PROJECT OUTPUT`. The trace script requires `-- OUTPUT.json`; run it against both baseline and candidate, then compare_traces.py. Pixel verifier takes the art directory containing action_manifest.json and both PNGs. The final immutable ZIP still requires independent CRC, manifest, history-retention, fresh-extraction import/tests and trace identity verification; that post-package evidence is external to avoid circular hashing and redundant raw-trace accumulation.
