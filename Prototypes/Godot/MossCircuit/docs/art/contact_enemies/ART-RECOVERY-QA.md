# Enemy reaction art recovery — fresh QA, 2026-10-24

## Provenance and scope

Recovered four original PNG objects from the public FPSgun Git API (JSON base64), without credentials, permission changes, remote writes, or raster regeneration. All four Git blob hashes match the supplied originals. Exact URLs, byte counts and SHA-256 values are in `recovered-png-provenance.json`. The PNG files are byte-for-byte originals. No old lost-work QA was reused. The earlier connector UTF-8 limitation was not retried; the documented public Git API was a separate supported binary recovery route.

No image generation was needed for this recovery; original generation prompts/tool receipts are unavailable and are not invented here. Read-only Pillow analysis computes alpha bounds and hashes; its in-memory crop calls do not save or modify any raster.

## Visual inspection performed

Inspected all four full PNGs and the actual recovered v12 references `assets/beetle_walk.png` and `assets/enemies/flanker.png`. Crawler retains rust-red rounded shell, moss and short mechanical legs; flanker retains blue/gold pointed limbs and moss. Hurt recoils then returns toward locomotion. Death progressively lowers/folds the same body. No external impact sparks, projectile flashes, gore or extra attack/telegraph assets are baked in.

Original death sheets have slight rise at row transitions if played row-major. The new metadata deliberately reorders distinct existing poses to a monotonically descending silhouette height. It does not duplicate frames, reverse back to standing or alter pixels. This is a visual sequencing choice, not a claim that source row-major is animation-ready.

## Fresh metadata

- `crawler_action_manifest.json`, `flanker_action_manifest.json`: install beside each character's two unchanged PNGs as `assets/actions/<kind>/action_manifest.json`.
- Hurt: 9 unique poses / 0.27 s. Death: 16 unique poses / 0.72 s. These are this beat's counts, not a nine-frame technical limitation.
- Every pose has logical canvas 512 × 400, anchor (0.5, 0.8), ground anchor y=320. Visible feet retain their original within-row height offsets rather than being individually forced to the anchor.
- Region bounds are determined at alpha ≥8 and expanded by four source pixels. Low-opacity outlying matte noise beyond the regions is not sampled; PNG alpha itself is unchanged.
- Integer `AtlasTexture.region` plus `margin` gives a shared canvas. Metadata never rescales individual poses. `reference_height` is fixed once per action from its first upright pose: crawler hurt 260, death 215; flanker hurt 222, death 178. ActorDirector normalizes this first-pose height against the walk baseline and preserves its existing foot anchor.
- All 50 source pose crops have independent hashes within their action; all regions stay in bounds with four pixels of padding. Horizontal registration uses each nominal source-column center, never the individual alpha-bbox center. Vertical registration uses one common baseline per source row (maximum alpha≥8 foot y), preserving within-row leg lifts and posture offsets. There is no per-frame rescaling or automatic per-frame recentering in this final metadata. Source row/column partitions are explicit, not assumed uniform for the death sheets.
- Crawler death heights: 215, 212, 206, 197, 190, 186, 181, 169, 169, 162, 154, 148, 142, 136, 119, 101.
- Flanker death heights: 178, 163, 159, 144, 136, 132, 120, 117, 108, 107, 95, 94, 86, 73, 66, 53.

`build_metadata.py --output historical-temp/moss-art-qa` reproduces metadata next to the original source PNGs, or `python build_metadata.py --project /path/to/MossCircuit --output historical-temp/moss-art-qa` reads the installed PNGs and writes metadata outside that project. It never writes raster data or project assets. Source cell centers, row baselines and actual foot trajectories are recorded in `fresh-art-qa.json`. The initial draft used per-frame bbox centering/grounding; this was rejected during review and replaced before final delivery with fixed column/row registration. Full image preview and static checks are complete; Godot playback, state-machine timing, hit interruption, real-world scale transitions and reduced-flash runtime QA remain with the programming/review agents. The duration metadata is descriptive; ActorDirector's config must set the runtime durations.

## Final source registration measurements

- `crawler_hurt`: common source row baselines [370, 755, 1142]; preserved visible foot y range [316, 320].
- `flanker_hurt`: common source row baselines [384, 778, 1152]; preserved visible foot y range [317, 320].
- `crawler_death`: common source row baselines [303, 569, 837, 1070]; preserved visible foot y range [314, 320].
- `flanker_death`: common source row baselines [378, 672, 981, 1209]; preserved visible foot y range [308, 320].
