# v48 — editable dash trail and chain arc

**Source, resource-pack, controlled desktop and local restoration validation complete. Publication and remote-dependent assembly pending.** This is not a published-release announcement.

## Two new masters, unchanged mechanics

The dash wake grows behind a fixed leading point, then fragments. The chain link develops angular branches between fixed contacts, then separates into sparse segments. Each new self-contained SVG has nine distinct stages rather than nine scaled copies. These are new semantic redraws informed by the earlier raster references, not recovered masters or pixel-identical copies.

Both transparent sheets retain **1254 × 1254** pages with a **3 × 3** grid of full **418 × 418** cells, all nine nonempty. Runtime timing remains **24 fps / 0.375 seconds**, with nearest filtering, alpha-mix blending and reduced-effect opacity **0.4**. Cells are neither cropped nor independently recentered.

- **Dash:** full-cell display **72 × 32 world units**, anchor **(0.76, 0.52)**. Ordinary dash follows its supplied direction; the separate Pulse Boots trail keeps its existing mint tint and default angle of zero. Both emissions remain present during Pulse Boots dash.
- **Chain:** nominal display **100 × 28 world units**, center anchor, fixed contacts **(0.14, 0.54)** and **(0.87, 0.54)**. For the tested nonzero endpoint distances, the whole-cell width is **rounded endpoint distance ÷ 0.73**, with height **28** and rotation toward the destination. Padding extends beyond the contacts; this is not full-width stretching.
- **Requested zero-length chain:** the engine normalizes horizontal scale to **0.00001**, producing an approximately **0.00418-unit** full-cell width and **0.0030514-unit** rendered contact separation. The requested endpoints remain equal; rendered contacts are not perfectly coincident. No readable zero-length effect is promised.

Production code, movement, damage, target selection, energy charges, cooldowns, event hooks, pooling, random streams and UI are unchanged, as are the other four effect sheets. [Edit and export the two complete SVG sheets](../art_source/dash_chain_v48/AUTHORING_SCOPE.md); runtime textures remain `assets/vfx/dash_trail.png` and `assets/vfx/chain_arc.png`.

## Completed finite validation

| Check | Actual scope |
| --- | --- |
| Imported source | **129 checks for each sheet**, including its nine frame regions, transparency and visible pixels. |
| Actual resource pack | **129 checks for each sheet** against its corresponding actual source-imported observations, plus the existing **1,068-check** resource/integration smoke gate. |
| Documented BUILD entry | The existing **14 routes**, with unchanged test bodies and warning policies, passed on the current merged source. |
| Corrected controlled desktop observer | **566 checks**, **40 original captures**, **10 controlled setups** and **eight post-intent presentation-authority guards**. |
| Direct visual review | Author review of all **40** originals and independent QA review of **16** selected originals. These were agent visual reviews, not a claimed human playtest. |

The accepted local production tree has **998 source inputs**; its separate source-plus-test-wrapper tree has **1,030**. These are not remote publication counts. The wrapper is not the production export. From the imported project root:

```sh
python3 tools/run_build_ui_checks.py
```

See [BUILD validation instructions](BUILD_UI_VALIDATION.md). This finite entry is not the external dash/chain observer or a full-game suite.

### Timeline and selected routes

**36 timeline captures** cover frames 0–8 for both effects in normal and reduced states. Explicit effect-layer advances check just-before/at frame boundaries, the final nonempty frame, expiry and recycling, full-cell binding, anchors, transforms and noncompounding opacity. This is **fixed-step validation of configured timing**, not measured real-time FPS or continuous animation playback.

The other **four captures are normal-only route peaks**: dash at zero-based frame **3**, chain at **2**.

| Controlled route | Selected actual observation |
| --- | --- |
| Ordinary dash | Actual character-motor step and existing event entry use a diagonal direction and the pre-move origin. One ordinary trail appears; selected player displacement and dash state are checked. |
| Pulse Boots | An upward motor/event entry retains the ordinary directional trail and adds the mint, zero-angle trail. The actual selected target is pushed without HP loss. |
| Arc Relay | A controlled primary-hit event selects two eligible targets, applies the existing secondary damage and emits two links from the original hit position. |
| Charged Arc Relay | An actual energy-pickup event with legal Arc Relay/Kill Cell grants one charge. The controlled hit consumes it and produces four original-origin links, not a sequential target-to-target chain. |

These are controlled motor/event-entry observations, not physical-key input, full projectile collision, acquisition or proc-combat replays. The selected cohorts check exact-distance ID tie ordering and exclude the original victim, a dead target and an out-of-range target; they do not establish every target-selection boundary.

Each route also underwent **numerical** normal→0.4→normal settings checks. These are not four additional reduced caller screenshots or physical menu clicks. Separate numerical chain probes cover horizontal, vertical, diagonal and requested-zero transforms; the 220-unit stretch probe is not a gameplay range-boundary test.

One same-seed combined parity pair compares selected motor/push, charged-hit, cooldown, charge, effect-sequence and random-stream outcomes with these two presentation effects enabled versus disabled. It uses a fresh legal target cohort after the deliberate push setup. This is bounded parity, not global combat/RNG certification. Intentional gameplay, settings and setup changes precede the relevant read-only presentation guards.

Ordering is inherited from unchanged production code, not intercepted callbacks: ordinary dash follows motor start; Pulse emits before push; secondary target damage precedes chain emission. Generic pool, pause/restart, other effects, inventory/UI and full combat suites were not replayed wholesale.

## Visibility and interpretation limits

At the controlled **960 × 540** viewport, normal dash and chain peaks are recognizable. Early dash ignition, late fragments and reduced remnants can blend into floor detail or become indistinguishable by eye. Nonempty frame data is not a contrast guarantee.

The ordinary diagonal wake and simultaneous vertical/mint Pulse wakes are visible, but avatar and weapon imagery overlap their near ends. Existing circles, hit sparks and line effects coexist; they are not all pixels from the new sheets. In the charged fanout, the two rightward branches are collinear and overlap. Their separate count is established by actual sprite observations, not by visually counting four unobstructed links in that still.

Frozen game processing means dictionary movement checks do **not** demonstrate enemy-sprite resynchronization or displacement animation. Timeline samples alone do not prove gameplay emitter alignment. Sizes are world/logical units, not guaranteed physical pixels under arbitrary camera or OS scaling. No all-directions × all-states visual matrix or tiny zero-length legibility claim is made.

## Retained failures and release boundary

The original **565-check** observer failed two numerical expectations at the requested-zero chain probe: it assumed zero rendered width and coincident rendered contacts. Rotation and viewport containment were already correct. The corrected observer distinguishes the request from the engine's existing minimum scale and separates width from containment, giving **566 checks** on the same resource pack. Nonzero formulas, tolerances, routes and all 40 capture cases were unchanged. The original failure remains a failure; no production or artwork fix was needed.

The initial strict pack comparison also stopped on generated scene metadata. Its specific difference was verified before continuation on the same pack; this is not an initial all-phases pass. The BUILD entry retained its exact historical warning allowance and the native observer its specific known display-warning allowance; neither is called warning-free.

Local restoration passed **10 controls: two positive and eight negative**. An actual resource-pack backup, replacement and rollback restored the exact previous local shield pack while preserving executable bytes and permissions. These are local file-restoration checks, not a delivery-executable launch or installation test. Publication of preceding local releases and this candidate, and remote-dependent source/history composition, remain pending. No delivery-executable launch, Windows execution, installation, physical-audio, CI or full-game certification is claimed.
