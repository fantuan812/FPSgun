# v43: editable build-expansion icons

## Artwork and unchanged behavior

Eight existing inventory icons now have individual, transparent 64×64 SVG masters and PNG textures:

- **Weapons:** Return Disc and Shock Mortar.
- **Modules:** Return Spool, Blast Fuse, Echo Chamber, Gravity Anchor, Medic Seed and Phase Capacitor.

The SVGs in `art_source/build_expansion_v43/` are new editable geometric redraws, not recovered lost masters or pixel-identical copies of the old painted atlas. Each maps to `assets/items/<id>.png` with a full `[0, 0, 64, 64]` image rectangle. The previous `build_expansion_atlas_v5.png` and its import sidecar are retired; old atlas instructions are historical.

See the [editing guide](../art_source/build_expansion_v43/AUTHORING_SCOPE.md) and [relative artwork preview](../art_source/build_expansion_v43/preview.html). The preview displays shipped PNGs on light/dark backgrounds; it is not an in-game test. Identifying silhouettes were simplified for small display while retaining the game's dark outlines, cream casing, copper joints and distinct luminous colors.

All 46 effective catalog inventory icons—10 weapons and 36 modules—now have verified editable SVG lineage: one direct SVG binding and 45 PNG-backed bindings, using 30 distinct PNGs and 31 SVG masters. This inventory-only milestone is not a fresh export of all 46 icons and excludes world, character, terrain and VFX artwork.

Item IDs, catalog values, prices, cooldowns, stacking, equipment limits and gameplay remain unchanged. So do the accepted compact BUILD layout, held-weapon and projectile assets. The two weapons retain their four-copy caps; each of the six modules remains unique. Equipment still has four weapon slots and eight module slots.

The tested production input set contains 987 files. The portable test counterpart contains 1,019: README is replaced and the existing 32-file test/tool/document/UID overlay retained with updated asset dependencies. Release prose, editing aids and delivery instructions are additional packaging, not retroactively part of those tested counts. Masters remain source-only.

## Finite verification

| Area | Current scope |
| --- | --- |
| Art-only review | Original atlas, all eight new PNGs and their 48/24 light/dark previews directly inspected |
| Source bindings | 199 checks on the eight actual imported icons |
| Portable entry | Actual no-argument 14-route command: 4,931 numeric checks plus one text-marker route, including the 84-check/seven-context guard |
| Packed checks | Equal Linux/Windows export-preset resource bytes; finite payload/fingerprint checks, 1,068 controlled integration checks and 199 packed icon checks |
| Native consumers | Passed: 673 checks, 72 original images, nine controlled setups and eleven authority guards |
| Direct native visuals | Author directly inspected all 72 originals; independent QA directly inspected 16 selected originals. Both found no blocking visual defect; these are agent reviews, separate from art-only previews. |
| Local restoration | Passed: two positive and eight negative file-restoration controls, including actual backup, replacement and rollback with the existing executable protected |

The completed native matrix is limited to eight icons in BUILD cards, shop-owned cards, shop offers and purchase forecasts at 960×540 and 640×360: 64 positive observations. Both actual BUILD groups must open. Two folded views, two narrow-screen negatives (sold Return Disc and maximum-stack Return Spool), and four full-slot replacement forecasts for the two weapons complete the 72 images. Real selector input changes slot 0 to 1 without purchasing; added and removed identities remain separate. Controlled legal setups are not natural acquisition or completed purchases. The local delivery checks restored the prior resource pack after replacement and preserved the existing executable; they did not launch the game or run Windows. Remote publication is a separate step.

The source entry retains 11 disclosure-opening adapters, two unchanged fixtures and the context guard, preserving their assertions and strict teardown. The existing exact policy accepts 48 known historical drawing warnings, not arbitrary errors or leaks. Current packed checks have empty stderr; native checks retain the narrow existing VSync policy. Audio teardown is not a listening test.

The 1,068 checks include resources and existing controlled mode/enemy/shop/inventory checks, Cryo/Fracture Coil and Bankshot/Bounce Guide, including Bankshot boundary visual feedback—not Feedback Diode behavior.

## Failures and coverage limits

The initial strict generated-data failures remain failures. Narrow comparison established equivalent identifier mappings and one exact generated-scene metadata difference with unchanged remaining scene semantics. A later resource check also rejected a stale external expectation for the changed icon manifest. Only that expectation was corrected after comparison; the fingerprint and affected checks were then rerun on the same unchanged package. This is not a blanket metadata exception or an all-pass claim for the original sequence.

- Card and forecast sizes are 48 and 24 logical units. Controlled real-window and matching logical dimensions do not certify arbitrary OS-only stretching or fixed physical pixels.
- Targeted full icons and identifying labels share a frame within the unchanged clipping tolerance. Long cards still require scrolling; this is not whole-card or all-controls-at-once visibility. In particular, the narrow maximum-stack image clips the lower availability row, and the narrow folded image does not show all disclosure controls; their separate behavior checks are not inferred from those screenshots.
- Result screens inherit the unchanged shared inventory-card route; they are not newly tested here. Neither weapon is a current starter choice. Held/world/projectile coverage and earlier 479/102/136 matrices are not rerun for this icon-only change.
- Export-data equality is not Windows execution. File restoration is not a game launch or remote publication. Agent visual review is not human approval; no new full-165, unrestricted ordinary play, physical-audio, balance or CI certification is claimed.

Import the source with Godot 4.6.3, then run from the project root:

```sh
python3 tools/run_build_ui_checks.py
```

Use the [current finite entry and options](BUILD_UI_VALIDATION.md), not obsolete historical commands. New public additions are assets, source/test code, essential delivery instructions and authored notes; operational logs, cache/environment inventories and raw execution/provenance bundles remain private.
