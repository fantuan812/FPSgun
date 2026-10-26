# v20 independent HUD readability and exact-export QA

## Verdict and identity

**PASS for this bounded presentation change.** The previously observed opaque HUD masking is resolved in the controlled matrix and the sampled ordinary Linux-export run. This is not a new balance certification, a complete campaign replay, or Windows runtime acceptance.

- Tested source snapshot: `v20-candidate`, 1,940 files including `MANIFEST.json`; manifest SHA256 `5d31d9d53b05d1e8a0a055931a599620f3c62e315be50ee384e53c76593ca641`.
- All manifest paths and bytes independently verified before a fresh cold copy; no pre-existing import cache.
- All 103 production paths compared with accepted final v19 source. The sole production difference is `ui/moss_ui.gd`, SHA256 `f28f27ced473d0e91d69fadf10a8a4b82a30dac561244f77de580c43703ae77c`. World geometry, collision, movement, damage, AI, input, scenes and art inputs are unchanged.
- Controlled GUI copies match all 102 production runtime paths of their respective baseline/candidate. The export-only preset is intentionally absent from these presentation copies. All 178 recorded inputs in each copy remain unchanged after GUI use.

## Independent regression and authority checks

- Cold import plus **60 standalone Godot entry points: 61/61 PASS**, explicit success markers, zero engine `ERROR:` lines and no changes to the 221 tested inputs. See `regression/result.json`, `summary.json`, per-test logs and before/after hashes.
- Python export-tool negative tests: **3/3 PASS** (`python-tools.log`).
- Independent execution of the author's fixed-step authority harness: **1,600 steps per build**, Arena/Rooms × Warden/Core, lower/upper positions, primary hits and actual boss AI warning/charge/blast/ring/summon/recovery. Baseline/candidate traces are byte-identical, SHA256 `5d077c028cb873b1b71a9521723390a7529047c7ad07c613f1396c62ca3b77cd`.
- `parity/authority-trace.json.gz` is a lossless, deterministic compression of that shared trace; `comparison.json` and the exact harness are included. This trace uses controlled state setup and fixed steps; it is not ordinary play or GUI evidence.

## Actual rendered-window A/B matrix

48 original game-window-only captures: **24 baseline + 24 candidate**. Both Arena and Rooms were inspected at actual native **960×540**, **1280×720** and **1000×750**. The last is letterboxed; logical gameplay remains 960×540. Capture names use native width, for example `hud/candidate/captures/rooms-1000-case3.jpg`.

| Case | Controlled setup | Result |
|---|---|---|
| 1 | Lower-edge player, Warden blast | Candidate restores player and full on-screen circular boundary hidden by baseline bottom panel. |
| 2 | Lower-edge player, Core ring | Candidate restores player, lower roots and on-screen ring. |
| 3 | Two live boss rows | Compact names/phase/HP/hints remain readable; bodies and both warning circles remain visible instead of being covered by a growing opaque rectangle. |
| 4 | Reachable upper-edge player, Warden charge lane | Player, boss and on-screen charge footprint are distinguishable through the main HUD. Header, counters, bars and objective remain readable. |

QA inspected all 48 captures. The art reviewer independently accepted 8 candidate and 6 baseline samples, including both modes and all three sizes; the programmer separately inspected two candidate samples. These are not claims that every reviewer inspected every capture.

### Fixture scope and reproducibility

`hud/hud_fixture.gd` and `.tscn` instantiate the real main scene, disable simulation, set seed 2020, place real-scale actors and generate real telegraph geometry. Only the normal HUD update is allowed each frame so measured UI layout settles. Cases use normal actor silhouettes, not a boss-animation phase certification. Rooms boss/two-boss layouts are stress fixtures, not claims that ordinary Rooms spawns these bosses.

To reproduce, use separate baseline/candidate project copies; copy the two fixture files into each copy's project root and run `godot --path . res://hud_fixture.tscn`. Keys 1–4 select cases, O changes mode, F6/F7/F8 request the three native sizes, R resets. Record actual window dimensions rather than assuming the requested dimensions were honored. Use isolated writable HOME/XDG directories outside each project.

The central white QA caption is fixture-only. Its slight overlap with Warden's top in case 3 is not shipped UI. An exploratory frozen-layout setup initially omitted continuous HUD updates; it was corrected identically in both copies before the accepted matrix. Exploratory captures and the caption-overlaid pause capture are excluded. Native fixture logs include cloud V-Sync/audio limitations below.

## Exact exported PCK verification

The selected final-proposed PCK was independently read with the editor reader from an empty directory, without source fallback. An independently cold-imported source fingerprint exactly matches the author's fingerprint SHA256 `4ae3268d4336865c8f66f86c42ee8f2bcb0fefdda4e4bec09006e43bc6960715`.

**761/761 checks PASS:** 48 exact script/data files, 51 source-imported RGBA textures, 25 actions/281 frames, main scene/settings, dynamic resources, controlled modes/enemies/shop/inventory and export exclusions. Texture parity correctly compares source-imported pixels, not raw PNG transparent RGB affected by Godot alpha-border import processing. This is packed-resource integration, not a replacement for native GUI testing.

| Artifact | SHA256 |
|---|---|
| Linux ELF | `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0` |
| Shared new PCK, 35,513,284 bytes | `e433dc5f3cb8a57c36e821e7dd3920783dcd8374c6e2dda8f1c849e04b110fc0` |
| Windows EXE | `91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6` |

Executables match the accepted v19 unsigned templates; the PCK is new. Both platform PCKs match. All four hashes remained unchanged after the native run. See `native/artifact-verification.json`. No bit-for-bit cold-export reproducibility claim is made.

## Ordinary Linux-export smoke

The exact release ELF and PCK above were launched through CUA on the cloud Linux desktop with isolated HOME/XDG, **not the editor and not a debug/fixture export**. Native window was 1180×812, letterboxed. CUA provides automated ordinary keyboard/mouse inputs; there was no in-game state injection, cheat, fixture or programmatic progression in this run. Seed **874205**.

- Settings/Guide return preserved the edited seed. Flash reduction toggled on and remained on within the session. Title, settings, guide, inventory, pause, upgrades and shop retained opaque, legible modal styling.
- WASD movement, direction+Space dash, autofire and inventory worked. Actual reachable upper player/enemy remained visible through HUD (`native/captures/upper-edge.jpg`).
- A real OS focus switch away paused play; returning focus remained paused until explicit resume. The immediate focus-switch screenshot preceded event processing, so acceptance uses the subsequent settled pause captures, not that transient image.
- Natural Arena settlement presented earned choices before shop; purchase of Shock Mortar cost 46 scrap, **118→72**, and showed two weapons/SOLD. Deployment and subsequent settlement remained usable.
- Ordinary Arena wave 3 at **64s, LV8, 68 kills**, Warden **594/950 HP**, warning:blast: the lower-right player and on-screen warning arc are plainly visible through the compact status area (`native/captures/warden-edge.jpg`). The old opaque bottom panel is absent. Portions extending below the physical viewport are camera clipping, not counted as HUD visibility or claimed to be visible.
- Returned to title, switched to Rooms with the same seed, started normally and traversed the upper region. Room objective, counter, player, enemies, autofire and dash were readable (`native/captures/rooms-run.jpg`). This is Rooms startup/combat smoke, not a new finite-victory claim.
- Cleanly closed the native game. The art reviewer accepted both ordinary upper-edge and Warden-edge stills for readability and observed export appearance, not full-motion or all-action certification. Four additional clean modal stills (settings, inventory, shop and guide) were also accepted by that reviewer for appearance only.

## Limits and evidence handling

The cloud graphics driver reports unsupported V-Sync changes. ALSA initialization emits `ERR_CANT_OPEN`, then Godot falls back to the dummy audio driver. Native logs therefore are **not zero-ERROR logs**; no script/resource/scene failure was observed. Audible sound is untested.

Windows was not executed; byte identity of the previously artifact-inspected EXE and resource-pack verification do not establish Windows runtime compatibility. No full Arena/Rooms replay, native Core action matrix, death/retry, restart preference reset or human-feel certification is claimed here. Earlier immutable v19 campaign evidence remains separate.

All 63 included JPEGs are original native game-window captures (48 controlled A/B, 15 ordinary export); no unrelated desktop, editor or browser image is included. Original private launchers are excluded. Public paths use repository-relative names/stable snapshot labels. `EVIDENCE_INDEX.json` records every packaged file except itself.
