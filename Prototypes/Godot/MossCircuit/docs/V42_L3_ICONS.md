# v42-L3: eight editable mechanism icons

## What changes

Arc Relay, Kill Cell, Dash Resin, Mirror Shell, Thorn Crown, Blood Valve, Scrap Mine and Pulse Boots now have individual editable SVG masters and derived PNG textures. Masters live in `art_source/legacy_inventory_L3/`; matching runtime files are `assets/items/<id>.png`.

Each transparent image has a 64×64 canvas and full `(0, 0, 64, 64)` texture rectangle, not a shared atlas crop or embedded reference bitmap. Edit shapes and palettes in the SVGs using the [source guide](../art_source/legacy_inventory_L3/AUTHORING_SCOPE.md).

The former `assets/items/mechanism_atlas_v4.png` and its import sidecar are retired. Earlier artwork retirements remain in effect; old atlas documentation is historical, not an instruction to restore it. Item IDs, names, catalog mechanics, prices, acquisition rules, gameplay code and the accepted v41 compact BUILD layout are unchanged.

The tested production set contains 964 inputs. The portable source-test counterpart contains 996: README is replaced and the existing 32-file test/tool/document/UID overlay is retained with updated asset dependencies. Additional release prose and delivery instructions are packaging, not retroactively included in those tested counts. Editable masters stay source-only; runtime exports contain the game assets.

## Actual finite results

| Area | Completed scope |
| --- | --- |
| Editable exports | All eight SVG exports matched the checked PNGs |
| Source bindings | 199 checks on eight actually imported icons |
| Portable entry | All 14 routes; 4,931 numeric checks plus one text-marker route, including the 84-check/seven-context guard |
| Packed integration | Equal Linux/Windows export-preset resource bytes; finite payload/fingerprint checks, 1,033 controlled integration checks and 199 packed icon checks |
| Native consumers | 591 checks, 68 original images, seven controlled setups and nine authority guards |
| Direct visual review | Author inspected all 68 originals; independent QA inspected 16 narrow-screen originals: all eight shop-owned cards and all eight forecasts |
| Local restoration | Two positive and eight negative controls, plus previous-package → current-package → previous-package rollback while preserving the executable file |

The 64 positive native observations cover every icon in expanded BUILD, shop-owned cards, shop offers and purchase forecasts at both 960×540 and 640×360. Card icons retain 48 logical units and forecasts 24. Real disclosure controls and wheel input expose the actual icon and complete identifying name or ADD label together; labels are not cropped to pass.

Two additional images show folded BUILD. Two narrow-screen negative cases cover sold Arc Relay and maximum-stack Kill Cell without an available forecast. Setups legally own one copy of all eight modules, or use empty module inventories with two batches of four offers. They do not demonstrate natural acquisition or completed purchases. The Kill Cell negative image shows its icon and name; its partly clipped purchase row does not itself prove unavailability—the checks establish that state.

The source entry keeps 11 disclosure-opening adapters, two unchanged fixtures and the context guard, preserving original assertions and teardown rules. Its exact policy permits 48 known historical drawing warnings, not arbitrary errors or leaks. Packed checks require empty stderr; native checks permit only the established narrow VSync warning. Audio teardown is not a listening test.

The 1,033 checks include resources and existing controlled mode/enemy/shop/inventory checks, Cryo/Fracture Coil and Bankshot/Bounce Guide, including Bankshot boundary visual feedback—not Feedback Diode behavior. Earlier 479-check consumer, 102-check BUILD and 136-check resize coverage is inherited for unchanged UI, not claimed as newly executed.

## Failures and limits

The initial strict packaging and generated-resource comparison failures remain failures. Narrow review established equivalent generated identifier mappings and one exact generated-scene metadata difference with unchanged remaining scene semantics. Separate continuation checks used the same original package. This is not a blanket exception or an all-pass claim for the original failed sequence. Earlier UI failures likewise remain historical failures.

- Window and matching logical dimensions were controlled together. Logical 48/24-unit icons are not fixed physical pixels under arbitrary OS-only stretching.
- At 640, long cards still require scrolling. The full icon-plus-identifying-label union is visible, not necessarily an entire oversized card. Bottom actions remain outside scrolling content.
- Equal export data does not prove Windows execution. File restoration/rollback does not prove a new executable launch or remote publication; final publication remains separate.
- Agent visual reviews are not human approval. No new full-165 run, all-state gameplay, weapon-replacement popup test, unrestricted ordinary play, balance certification, physical-audio assessment or CI result is claimed.

## Run the portable checks

Import with Godot 4.6.3, then run from the project root:

```sh
python3 tools/run_build_ui_checks.py
```

See the [current finite entry and options](BUILD_UI_VALIDATION.md), not obsolete commands in historical release notes. Public additions contain assets, source/test code, essential delivery instructions and authored notes; new operational logs, cache/environment inventories and raw execution/provenance bundles remain private.
