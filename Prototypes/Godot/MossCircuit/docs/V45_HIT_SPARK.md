# v45 — editable hit spark

**Local validation complete; publication pending.** The bounded source, resource-pack, controlled desktop and delivery-file checks below are complete. This note does not announce remote publication.

## Artwork and unchanged behavior

The hit-spark sheet now comes from a new self-contained geometric SVG master, guided by the earlier raster reference. It is not a recovered original master or pixel-identical restoration. Nine separately drawn stages form a radial progression: ignition, four rays, a hot star, an expanded peak, an open broken ring, fragments and diminishing embers. They are not nine scaled copies of one shape or a reused directional muzzle silhouette.

The existing rendering contract is unchanged:

- **1254 × 1254** transparent sheet, **3 × 3** full **418 × 418** cells; all nine remain nonempty.
- Center anchor **(0.5, 0.5)** in every cell; no cropping, recentering or independent frame resizing.
- **27 fps**, **one third of a second**, **32 × 32 world units**, nearest filtering and alpha-mix blending.
- A neutral core with the existing module tint multipliers; reduced flashes retain **0.4 opacity**.

Runtime timing comes from `data/vfx.json`. The historical manifest recommendation of 30 fps is not the runtime setting. The muzzle flash and other four effect sheets are unchanged, as are production code, hooks, damage, source cooldowns, pooling, random streams and the compact BUILD interface.

[Edit and export the full SVG sheet](../art_source/hit_spark_v45/AUTHORING_SCOPE.md). The runtime texture remains `assets/vfx/hit_spark.png`.

## Completed checks

| Check | Actual bounded scope |
| --- | --- |
| Imported source | **129 checks** on the new sheet and nine frames, including fixed regions, transparency and visible pixels. |
| Actual resource pack | **129 checks** comparing imported sheet/frame pixels with actual source observations, plus the existing **1,068-check** resource/integration smoke gate. |
| Documented BUILD entry | The existing **14 routes**, unchanged test bodies and warning policies, passed from the current merged source. |
| Controlled desktop hit observation | **470 checks**, **30 original captures**, **17 controlled setups** and **15 post-intent presentation-authority guards**. |
| Direct visual review | The author inspected all **30** originals; QA independently inspected **16** selected originals. These were agent visual reviews, not a claimed human playtest. |
| Local resource-pack delivery | **10 controls**: two positive and eight negative cases, plus actual replacement and rollback with the existing executable preserved. |

The production baseline contains **991 source inputs**. The tested source-plus-test-wrapper tree contains **1,023**, with the wrapper separate from the production export. From the imported project root:

```sh
python3 tools/run_build_ui_checks.py
```

See [BUILD validation instructions](BUILD_UI_VALIDATION.md). This command is the finite BUILD entry, not the external hit observer or a new full-suite certification.

### Exactly what the desktop matrix shows

**18 timeline captures** cover frames 0–8 in normal and reduced-flashes states. Actual effect-layer advances check just-before/at frame boundaries and expiry, fixed center/size, full-cell texture binding, nearest/mix and noncumulative opacity. This is **fixed-step validation of configured 27 fps timing**, not measured real-time FPS, a continuous animation recording or an ordinary-play-duration test.

**Four normal-opacity captures** observe zero-based **frame 3**, the radial peak:

- A real Rivet shot advanced through its first projectile contact.
- Actual player hurt with positive damage.
- Actual player hurt with **zero HP loss**. The existing spark precedes damage application; this is not redefined as positive-damage-only behavior.
- A controlled primary-hit event through Arc Relay with one living secondary target.

**Eight further normal-opacity peak captures** use the existing module event/command paths:

| Module | Controlled entry used |
| --- | --- |
| Feedback Diode | Equipped active-dash precondition, then hostile projectile-contact event. |
| Fracture Coil | Cryo and Rivet owned, shipped chill helper precondition, then non-Cryo primary-hit event. |
| Medic Seed | Actual player hurt accumulating 30 HP loss. |
| Kill Cell | Primary-kill event through the existing command engine. |
| Echo Chamber | Five primary-hit events through its existing counter. |
| Blast Fuse | Real Mortar firing and pending-blast release. |
| Scrap Mine | Normal-pickup event. |
| Dash Resin | Dash event. |

These are bounded real entry-point observations with controlled conditions, **not a complete natural acquisition, collision or proc-combat matrix**. Source labels, existing tint colors, positions and command outcomes were checked. Reduced tint and normal reset were checked **numerically** for these eight cases; there are no additional reduced-opacity module or hook screenshots.

A separate bounded check exercised the existing **0.08-second per-source visual cooldown**: same-source suppression before its deadline, acceptance at the deadline, different-source independence, caller-option preservation and sprite tint reuse. A same-seed Rivet-contact comparison with hit visuals enabled versus disabled checked the selected damage and gameplay/loot/shop random-state outcomes. It is not a global RNG or combat certification.

Firing, damage, events, settings and clock changes were intentional setup actions; presentation guards began afterward. Settings used the controller API, not physical menu clicks. Production event ordering is inherited from unchanged code, not intercepted callbacks. The unchanged full-pool, pause and restart mechanisms were not replayed wholesale from the earlier muzzle suite.

## Visibility limits

At the controlled **960 × 540** viewport, the standalone peak and early radial progression are readable. Sparse late remnants—especially reduced-opacity frames—can blend into the textured floor. Nonempty frame data does not guarantee that every final ember can be recognized independently by eye.

Actual entry views also contain overlapping gameplay presentation: player hurt and Resin coincide with the avatar; Blast overlaps the larger unchanged explosion; other cues coexist with pickups, rings or fracture/feedback lines. Full-cell viewport containment is **not** a claim that every ray is unobstructed or visually isolated. Similar purple/gold tint families and the shared Scrap/Dash color do not uniquely identify all eight modules.

The size is in world units, not a guarantee of identical physical pixels under arbitrary camera, window or OS scaling. No all-weapon, all-proc, other-effect-art, inventory/UI geometry, Windows, CI or full-game regression claim is made.

## Retained failure and delivery boundaries

The initial strict pack comparison stopped on generated scene metadata. Its specific difference was verified before the same pack's remaining checks continued; the original failure is retained, not relabeled as an initial complete pass. Source and packed observations, native execution and direct visuals remain distinct scopes.

The BUILD run retained its exact historical warning allowance, and the native run its specific known display-warning allowance. Neither is described as warning-free, and new errors are not silently ignored. Local delivery checks replaced the previous resource pack with this pack and rolled back to the previous pack while preserving the existing executable. This is file-restoration acceptance, not a new delivery-executable launch, Windows or CI test. Remote publication remains separate and pending. Follow the [delivery instructions](DELIVERY.md) for restoration.
