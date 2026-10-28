# v44 — editable muzzle flash

**Local validation complete; publication pending.** The bounded source, resource-pack, desktop visual and delivery-file checks below are complete. This note does not announce remote publication.

## What changed

A new self-contained geometric SVG master produces the muzzle-flash sheet. Its nine separately drawn silhouettes progress through ignition, a directional tongue, a long peak, split lobes, fragments and fading embers. They are not nine scaled copies. The earlier raster supplied the visual reference; this is neither a recovered original master nor pixel-identical restoration.

The existing contract stays fixed:

- Transparent **1254 × 1254** sheet, **3 × 3** row-major cells of **418 × 418**; all nine frames remain nonempty.
- The same cell-local anchor **(0.28, 0.52)**, with full cells retained—no cropping, recentering or independent frame resizing.
- **30 fps / 0.3 seconds** configured playback, **36 × 28 world-unit** display, nearest filtering and alpha-mix blending.
- Normal opacity and the existing **0.4-opacity reduced-flashes** variant.

Only this effect's artwork and associated resource metadata change. Hit sparks and the other four effect sheets, firing hooks, weapon behavior, pooling rules, random streams, UI and gameplay code are unchanged.

[Edit the SVG master and export the full sheet](../art_source/muzzle_flash_v44/AUTHORING_SCOPE.md). The runtime texture remains `assets/vfx/muzzle_flash.png`.

## Completed, finite validation

| Check | Actual scope |
| --- | --- |
| Imported source identity | **129 checks** on the new sheet and all nine frames, including fixed regions, transparency and visible pixels. |
| Packed identity | **129 checks** against the actual resource pack, comparing its imported sheet/frame pixels with the actual source observations. |
| Existing resource integration | **1,068 checks** covering resources and the existing controlled gameplay smoke cases; not a new full combat suite. |
| Documented BUILD entry | The existing **14 routes** passed from the current merged source with unchanged test bodies and policies. |
| Controlled desktop muzzle check | **426 checks**, **28 original captures**, **15 controlled setups** and **13 presentation-authority guards**. |
| Direct visual review | The author directly inspected all **28** originals; QA independently inspected **16** selected originals. These were agent visual reviews, not a claimed human playtest. |
| Local resource-pack delivery | **10 controls**: two positive and eight negative cases, plus actual replacement and rollback while preserving the existing executable. |

The production baseline has **989 source inputs**; the tested source-plus-test-wrapper tree has **1,021**. The test wrapper is separate from the production export. The current documented entry is:

```sh
python3 tools/run_build_ui_checks.py
```

Run it from the imported project root. [BUILD validation instructions](BUILD_UI_VALIDATION.md) describe its options. It does not reproduce the separate external muzzle observation sequence or certify every game test.

### Playback, alignment and firing coverage

The **18 timeline captures** show frames 0–8 in normal and reduced-flashes states. The actual effect layer was advanced in controlled steps across frame boundaries and expiry. Additional finite checks covered zero/negative advances, fixed emitter offset and size, opacity reset without cumulative dimming, pause, clear/restart, and shared-pool capacity/oldest-entry reuse. This verifies the configured timeline through fixed-step observations, **not measured real-time 30 fps playback or a continuous animation recording**.

The remaining **10 captures** show a controlled peak frame after real firing through each of the five existing natural callers, in both flash states:

| Weapon | Chosen target direction |
| --- | --- |
| Rivet Gun | Right |
| Scrap Shotgun | Up |
| Rail Lance | Left |
| Shock Mortar | Down-right |
| Bankshot Driver | Down-left |

Alignment was checked against each actual firing pose, including rounded effect positioning; the existing pose solver can produce an angle slightly different from the nominal target direction. This is **five selected directional cases in both states**, not every direction for every weapon. A standalone timeline flash is not evidence of attachment to a firing weapon.

Post-fire checks distinguished one cue per shot from pellet count, Mortar's pending blast, and a valid Bankshot spawn. Hook ordering is inherited from unchanged production code, not from replaced callbacks. Firing and settings changes were intentional setup actions; read-only presentation guards began afterward. A bounded same-seed comparison also checked damage and gameplay/loot/shop random state with a full effect pool versus disabled effects. Settings were changed through the controller API, not physical settings-menu clicks.

### What remains faint or untested

The peak tongue and split-lobe stages remain readable at the tested small size, and the chosen natural firing views align with their emitters. Late embers are deliberately tiny. Normal final frames and especially reduced-flashes final frames can blend into the floor; the reduced ignition is also faint. Machine checks establish nonempty frame data, **not reliable visual recognition of every final spark**.

The desktop captures used a controlled **960 × 540** logical viewport. The display contract is in world units; screenshots do not establish identical physical pixel size under arbitrary camera, window or OS scaling. No all-directions, ordinary-play-duration, new weapon-geometry, inventory-art, other-effect, Windows or full-game regression claim is made.

### Retained failures and acceptance limits

An earlier source observation rejected numerically equal bounds because its external comparison treated integer and JSON numeric arrays differently. Exact checked-integer validation corrected that external fixture; the original failure remains part of the private history. An initial strict pack comparison also stopped on generated scene metadata. Its specific difference was verified before the same pack's remaining checks continued. Neither initial run is relabeled as a complete pass.

The documented BUILD run retained its exact historical warning allowance. The native run retained its specific known display warning allowance; it is not described as warning-free. These results do not imply that new errors or warnings are ignored. Local delivery checks exercised replacement of the previous resource pack with this pack and rollback to the previous pack, preserving the existing executable. This is file-restoration acceptance, not a new delivery-executable launch, Windows or CI test. Remote publication remains separate and pending. Follow the [delivery instructions](DELIVERY.md) for restoration.
