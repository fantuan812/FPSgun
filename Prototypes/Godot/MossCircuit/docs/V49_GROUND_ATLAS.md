# v49 — editable ruined-garden ground

**Source, resource-pack, bounded desktop and local restoration validation complete. Publication and remote-dependent assembly pending.** This is not a published-release announcement.

## Nine static variants, unchanged play

The new self-contained SVG retains the **1254 × 1254** page and **3 × 3** arrangement of full **418 × 418** cells. All nine cells are opaque static variants, not animation frames. Quiet soil and dominant dirt sit alongside clustered moss, fractured stone, amber pebbles, buried paving, grass tufts, buried cable and mossy stones. These are new semantic redraws informed by the earlier raster, not recovered masters or pixel-identical copies.

Full cells still draw at **80 × 80 world/logical units**, using nearest filtering and the existing RGB multiplier **(0.65, 0.75, 0.72)**. The separate one-unit dark joint lines remain; the artwork is not advertised as seamless tiling. Cracks, paving and cables are decoration, not new obstacles.

Production code, map-cell selection, conditional random consumption, arena dimensions, movement, collision, camera, draw order, UI, gameplay and all other artwork are unchanged. [Edit and export the complete ground master](../art_source/ground_v49/AUTHORING_SCOPE.md); the runtime texture remains `assets/ground_atlas.png`.

## Completed finite validation

| Check | Actual scope |
| --- | --- |
| Imported source | **73 checks** for the sheet and nine ordered full-cell regions, actual imported pixels, opacity, nonuniform tile content and formal PNG provenance. |
| Actual resource pack | **73 checks** against the corresponding actual source-imported observations, plus the existing **1,068-check** resource/integration smoke gate. The packed check observes imported texture data; it does not claim to read original PNG bytes from the pack. |
| Documented BUILD entry | The existing **14 routes**, with unchanged test bodies and warning policies, passed on the current source-plus-test-wrapper tree. |
| Controlled desktop observer | **83 checks**, **three original captures**, **three controlled setups** and **three post-intent presentation-authority guards**. |
| Direct visual review | Author and independent QA agents each directly inspected all **three** originals. This is not a claimed human playtest. |

The accepted local production tree has **1,000 source inputs**; its separate source-plus-test-wrapper tree has **1,032**. These are not publication counts, and the wrapper is not the production export. From the imported project root:

```sh
python3 tools/run_build_ui_checks.py
```

See [BUILD validation instructions](BUILD_UI_VALIDATION.md). This entry does not replay the separate ground observer or certify the full game.

### Three actual views

1. **Controlled nine-tile patch:** a diagnostic 3 × 3 arrangement of indices 0–8 is drawn by the actual game renderer, below the HUD and away from the hero. Only this fixture-local map is deliberately arranged; it is not presented as natural seeded output.
2. **Seeded Arena:** the actual **18 × 12 / 216-cell** generated map is retained, with a bottom-right clamped camera view, normal hero/HUD and one staged existing pickup/telegraph pair.
3. **Seeded Rooms:** the actual **12 × 8 / 96-cell** generated map is likewise retained and viewed at the bottom-right clamp. This is not a room transition or encounter replay.

The complete 216/96 placement tables are **derived from actual maps/configuration and the unchanged drawing formula**, not intercepted draw calls. Only the captured viewport pixels were visually inspected. Exact tint and joint values are inherited source constants, not a claimed framebuffer color-sampling test.

Numerical camera probes cover center, top-left and bottom-right positions. The selected views also observe the existing ground, hero, UI and telegraph layering. Pickup and telegraph placements are controlled presentation inputs, not acquisition or combat outcomes.

### Bounded determinism and movement checks

After each intentional run start, gameplay random streams are snapshotted. Same-seed field generation is repeated and independently traced in row-major order: one random fraction per cell, followed by a random tile-index draw only when the fraction is below **0.38**; otherwise index 8 is selected. The tested field-generation/draw probes leave combat, loot and shop random streams unchanged. This is bounded deterministic-map evidence, not global RNG certification.

Nine non-dash character-motor probes at the diagnostic tile centers produce equal selected rightward displacement without changing HP, map or random streams. These are controlled API probes, not physical input, full-map traversal or a comprehensive collision test. Arena's retain-field and Rooms' refresh-field flags are observed; their stage-transition behavior and the partial-edge drawing formula remain inherited unchanged code, not new transition or fractional-edge test matrices.

Each presentation guard begins after deliberate map, player, camera and overlay setup. No gameplay or UI action is attributed to a read-only capture interval.

## Visibility and release limits

At the controlled **960 × 540** viewport, the nine diagnostic motifs remain distinguishable, and the inspected natural Arena/Rooms views retain readable hero, HUD, pickup and ring contrast. Tiny grain and moss marks merge at 80-unit display. Intentional visible joints are not a seamless-texture defect; decorative features do not establish collision geometry.

These three stills do not establish all-seed coverage, offscreen pixel correctness, every overlay combination, live movement, all camera/OS scales or room/stage transitions. World/logical sizes are not guaranteed physical pixels under arbitrary scaling. No animation, reduced-opacity, full combat, unrelated VFX or broad UI matrix was added.

The first art-export run failed strict observation because its external pixel observer emitted a deprecation warning. A supported equivalent observation accepted the same unchanged PNG without rerendering it; a later separate repeat export reproduced that PNG. The first source check also failed strict logging because of its external PNG-loading method. Only that fixture was changed to checked byte-buffer decoding; the accepted source check still has 73 checks and unchanged asset expectations. Both original failures remain failures.

The initial strict pack comparison stopped on generated scene metadata. That specific difference was verified before continuation on the same pack; this is not an initial all-phases pass. Existing BUILD warning allowances and the native observer's specific display-warning allowance remain explicit, not a warning-free claim.

Local restoration passed **10 controls: two positive and eight negative**. Actual resource-pack backup, replacement and rollback restored the exact previous local dash/chain pack while preserving executable bytes and permissions. These are local file-restoration checks, not a delivery-executable launch or installation test. Publication of this candidate and remote-dependent source/history composition remain pending. No delivery-executable launch, Windows execution, installation, physical-audio, CI or full-game certification is claimed.
