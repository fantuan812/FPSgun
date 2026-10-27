# Equipment16 editable atlas — independent QA scope

This is an asset-only candidate derived from accepted v39-A, not the B module expansion. Its 16 equipment icons are derived from editable SVG artwork. Five previously accepted A icons are unchanged. Other still-active legacy raster assets are not claimed migrated by this delivery.

## Source and actual package

- Initial 886 inputs: relative to the tested A869 base, 19 additions, 2 removals and 2 changed paths. Gameplay code/data remain identical. Cold import added exactly two import sidecars, giving the externally pinned 888-input candidate; the inherited MANIFEST is a checkpoint, not the 888 input authority.
- Actual source UI: 240 checks, 21 observations, comprising the 16 atlas icons and five unchanged A icons. The merged UI contains 43 icon IDs.
- Original export run stopped at phase 5 of 8: four preceding phases succeeded, but the PCK inventory test incorrectly required a complete source `.import` file to survive export unchanged. Its strict failure is retained. The remaining three phases were not run in that attempt.
- Independent extraction identified the precise affected record: `assets/items/equipment_atlas_editable.png.import`. The 212 exported bytes equal the original remap section, stripped trailing newlines, followed by one LF and one NUL. Importer/type/UID/path/metadata bytes are retained; source deps/params are absent. The corrected oracle applies only to this exact record, not arbitrary import files.
- No second export: four bounded continuation routes read the original PCK. Complete 254-record payload/MD5/path/privacy/old-resource-absence audit, source fingerprints, generic resource checks (968; 78 exact files, 69 PNG textures, 28 actions, 308 frames) and packed UI240/21 all passed.
- Both preset PCKs are identical: 42,250,592 bytes, SHA256 `fac259f0e5406c8b3ab56f21c4b7bf5113ae58d50fdc02344fbc09b8b273f23d`. This is not Windows runtime execution.

## Pixel identity boundary

All 21 source-imported texture observations and their packed counterparts agree exactly. Source PNG raw RGBA is recorded separately: transparent RGB may change on import. Visible-pixel comparisons normalize RGB only where alpha is zero, preserving all nonzero-alpha RGB and all alpha values. No claim of raw PNG-RGBA equality is made.

## Native UI

- The unchanged 178-check A UI fixture passed on this new PCK, with 16 original captures. This is not reuse of a result from the prior A PCK.
- The first new card route stopped at 79 checks with two failures after displaying 12 cards. It incorrectly tested the local child Panel's `visible` property as effective modal visibility. Production `hide_modal()` hides the parent shade; the existing public `modal_visible()` reports that effective state. The original failed run remains intact.
- A fixture-only correction changed three queries to the public API and added read-only close/reopen telemetry. The 145 original predicates, GUI inputs and expectations were retained. Only the card route was executed again, not the already-passed178 route.
- Corrected route: 145 checks, 21 card observations/images and three legal build groups. Actual BUILD clicks, wheel scrolling, AtlasTexture identity, full target card visibility, fixed BACK, forward/reverse Tab isolation, BACK click and reopen/Escape passed. Telemetry confirms playing/effective-hidden/local-Panel-visible after closing, and inventory/effective-visible when reopened.
- Native card rendering uses logical 960×540 at requested OS960. The reused A178 route also exercises requested OS960/1280 with the same logical960 canvas; these are not two logical layout widths.
- An independent reviewer directly inspected all 21 corrected original PNGs. QA additionally directly inspected the lens, Orbit Saw and Recoil Plate captures. No new missing/swapped icons or fixed-BACK obstruction was observed. Neighboring cards clipped at scroll boundaries are expected; each target card was brought fully into view.

## Retained limitations

No new full gameplay regression or ordinary playthrough is claimed for this asset-only package. Gameplay bytes are unchanged from A; A's original149/151 failure and separate corrected finite gates remain separate historical evidence. This candidate does not inherit a fictional new151/151 result or old A packed17 result. Native scripts use controlled legal builds and viewport events, not natural acquisition or physical mouse input. Audio teardown proves bounded internal cleanup/fresh silence with Dummy, not physical sound output.

Fontless SVG export evidence retained its explicitly allowed Pango/Gtk tool warnings; no blanket warning exemption applies to Godot. The early terminal typing API rejection occurred before command input/target launch and was not a game retry. Publication/delivery checks and any final presentation-only file differences require their own actual receipts; this report does not assert future upload success.
