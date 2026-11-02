# Spore Reactor / Core — editable body sheets

These five SVG files are newly authored semantic vector masters for the existing Core creature PNG paths. They are not recovered original masters. The design preserves a floating mint orb, segmented bronze ring, attached purple canisters, moss, copper hoses, articulated hanging roots, and a dim tilted ring over a low root mound in death. This is not a biped or a turret.

## Files and frame counts

| Editable master | Runtime PNG | Frames | Sheet pixels |
| --- | --- | ---: | --- |
| `boss_core_walk.svg` | `assets/enemies/boss_core.png` | 9 | 1254 × 1254 |
| `boss_core_attack.svg` | `assets/actions/boss_core_attack.png` | 9 | 1254 × 1254 |
| `boss_core_summon.svg` | `assets/actions/boss_core/boss_core_summon.png` | 16 | **1312 × 1199** |
| `boss_core_hurt.svg` | `assets/actions/boss_core/boss_core_hurt.png` | 9 | 1254 × 1254 |
| `boss_core_death.svg` | `assets/actions/boss_core/boss_core_death.png` | 16 | 1254 × 1254 |

All masters live beside this guide under `art_source/core_v57/`. The `.gdignore` and export exclusions keep the authoring files outside the runtime payload. Runtime code continues to load the original PNG paths; do not add a second enemy fallback or change a resource path.

The 59 frames use **identity source order**. The generic base-attack records retain `source_frame`; summon, hurt and death retain `source_pose_index`. There is no Warden-style hurt swap or death permutation. The source windows have no overlaps, but they are not interchangeable uniform cells: action windows, offsets, margins and reference heights are the existing authored registration.

## Registration is not the painted bounding box

Keep the neutral world reference height **165.3** and base foot **82.65** unchanged. The live walk crop comes from `assets/enemies/enemy_manifest.json` region plus XYWH `alpha_bbox`, not a Core override in `art_source/alpha_bounds.json`.

| Clip | Logical canvas | Reference height | Draw scale | Logical anchor | Sprite offset |
| --- | --- | ---: | --- | --- | --- |
| Walk | 418 × 418 | 218 | 1653 / 2180 | (209, 398) | (0, −80) |
| Base attack | 418 × 340 | 231 | 551 / 770 | (209, 328) | (0, −42.5) |
| Summon | 512 × 400 | 246 | 551 / 820 | (256, 320) | (0, 3) |
| Hurt | 512 × 400 | 278 | 1653 / 2780 | (256, 320) | (0, 19) |
| Death | 512 × 400 | 248 | 1653 / 2480 | (256, 320) | (0, 4) |

Walk Atlas margins include half-pixels; action margins are integral. Preserve every current frame region, margin, source-order field, anchor and reference height. Summon, hurt and death already embody their original horizontal and row corrections: do not apply those corrections a second time. Do not fit, recenter, rescale or recrop from the new paint's alpha bounds.

The four runtime manifest authorities are the enemy manifest, generic `assets/actions/action_manifest.json`, Core `action_manifest.json` for hurt/death, and Core `attack_manifest.json` for summon. Whole `art_source/alpha_bounds.json` and `data/actor_actions.json` remain separate unchanged runtime authorities. Preserve all unrelated entries.

## Editing and exporting

- Edit the semantic groups in the SVG, retaining unique IDs, frame translations and connected ring/canister/root construction. The accepted design uses separately articulated roots and an independently drawn oblique death silhouette, not a global vertical squash of the live body.
- Keep the 12 representative keys recognizable: walk 0/5; base attack 3/4/8; summon 6/7/12; hurt 3; death 6/10/15. Review all 59 frames before shipping, not only those keys.
- Keep the base-attack anticipation, outward root release and compact recovery distinct. Summon braces at 6, opens a root cradle at 7 and returns to a hanging-root recovery by 12. Death keeps the bright initial orb, then dims and tilts into the low mound.
- Local seed glow, rays and wisps are named **decorative** groups. Their visual location does not define a projectile muzzle, child-spawn socket, target footprint or damage marker. Do not paint a new world telegraph into the body sheet.
- Export each SVG at its original page dimensions, with no fitting or resize. The validated art export used Inkscape 1.4 with `--export-type=png --export-area-page`, the sheet's exact width/height, and `--export-png-antialias=0`. Preserve binary alpha and transparent background.
- Compare new and existing frames using the actual crop + margin + anchor + scale + offset transform at 1×. Include selected horizontal mirrors. A larger image can help inspect joints, but cannot replace the registered comparison.
- Keep the first export immutable and perform a fresh bounded repeat to check PNG bytes and decoded RGBA equality. Preserve warnings and first failures rather than silently retrying or replacing evidence. Accepted art exports had classified tool warnings; they were not clean-log runs.
- After a deliberate artwork change, update current PNG byte identities and distinct SVG identities truthfully, then measure the new paint separately. Cold import and source/packed/native consumer checks belong to their own validation steps; a static SVG or repeat export alone is not runtime proof.

## Lineage and measurements

`source_sha256` and the existing generic base-attack `sha256` mean **current PNG bytes**. `source_svg_sha256` means SVG bytes. Walk frame `pixel_sha256` means the full 418 × 418 source-cell ART RGBA, not the imported Atlas crop. Imported texture bytes can differ from formal PNG decoding and must be observed separately.

The complete old selected manifest records remain in `art_source/provenance.json` under each current derivation's `prior_raster_manifest_record`. Old statements that original PNG bytes were unmodified describe that prior raster only; they do not describe these new SVG exports. New source-window-local alpha bounding boxes and clearance are current QA/provenance facts, **not new live crop or scale authority**. Existing walk `alpha_bbox`/minimum-clear-margin and action measurement fields retain historical provenance.

## Gameplay boundaries and visual limits

The artwork does not change the phase-2 **ring, ring, summon** sequence, warning/recovery timing, collision radii, projectile or child-spawn origins, cleanup, rewards or any other gameplay code/data. Ring projectiles originate at the actor position; child spawns use the existing actor-relative logic, not the decorative seed or canisters. The separate warning circle remains a runtime effect, not a body-sheet hit region.

The accepted static style is more planar/concentric than the shaded historical reference: the orb glow is flatter, the ring more uniform, the roots more ribbon-like, and attack flare quieter. Hover, hurt and late-death changes are subtle at actual scale; tiny moss, bolts and capsule details merge. Static pages and selected mirrors demonstrate pose readability and registration, not continuous cadence, gameplay synchronization, every mirrored pose or complete combat coverage.
