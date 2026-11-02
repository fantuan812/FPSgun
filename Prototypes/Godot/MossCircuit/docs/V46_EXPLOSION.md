# v46 — editable explosion

**Source, resource-pack, controlled desktop and local restoration validation complete. Publication and remote-dependent assembly pending.** This note does not announce a published release.

## Artwork and unchanged behavior

A new self-contained geometric SVG replaces the explosion's raster-only authoring source. It follows the earlier reference's ignition, expanding radial peak, hollow flames, moss-green smoke and diminishing embers. The nine stages have distinct geometry; they are not nine scaled copies. This is newly authored artwork, not a recovered original master or pixel-identical restoration.

The existing rendering contract is preserved:

- Transparent **1254 × 1254** sheet, **3 × 3** full **418 × 418** cells, all nine nonempty.
- Fixed center anchor **(0.5, 0.5)**; no cropped, recentered or independently resized frames.
- **18 fps / 0.5 seconds**, nearest filtering, alpha-mix blending and a default **64 × 64 world-unit** display.
- Reduced flashes retain **0.4 opacity**, with unchanged timing and frame progression.
- Radius-based callers use a whole-cell square whose side is **radius × √2**, not the diameter. The square's corners meet the gameplay radius; its painted pixels do not fill the circle. The separate gameplay ring is unchanged.

The Phase Capacitor's existing tint remains a color multiplier rather than baked-in artwork. Warm and green pixels can become muted blue or olive, not uniformly saturated blue. Production code, damage, event hooks, delays, cooldowns, pooling, random streams and UI remain unchanged, as do the other five effect sheets, including hit spark and muzzle flash.

[Edit and export the complete SVG sheet](../art_source/explosion_v46/AUTHORING_SCOPE.md). The runtime texture remains `assets/vfx/explosion.png`.

## Completed checks

| Check | Actual bounded scope |
| --- | --- |
| Imported source | **129 checks** on the new sheet and nine frame regions, transparency and visible pixels. |
| Actual resource pack | **129 checks** against actual source-imported sheet/frame observations, plus the existing **1,068-check** resource/integration smoke gate. |
| Documented BUILD entry | The existing **14 routes**, with unchanged test bodies and warning policies, passed from the current merged source. |
| Controlled desktop explosion observation | **386 checks**, **26 original captures**, **12 controlled setups** and **10 post-intent presentation-authority guards**. |
| Direct visual review | Author review of all **26** originals and independent QA review of **16** selected originals. These were agent visual reviews, not a claimed human playtest. |

The production baseline has **993 source inputs**; the tested source-plus-test-wrapper tree has **1,025**. The wrapper is separate from the production export. From the imported project root:

```sh
python3 tools/run_build_ui_checks.py
```

See [BUILD validation instructions](BUILD_UI_VALIDATION.md). This is the finite BUILD entry, not the external explosion observer or a full-suite certification.

### Exactly what the desktop matrix covers

**18 timeline captures** observe frames 0–8 in normal and reduced states at the default size. Actual effect-layer advances check just-before/at frame boundaries, the final nonempty frame and expiry, fixed center/full-cell binding, nearest/mix and noncumulative opacity. These are **fixed-step checks of configured 18 fps timing**, not measured real-time FPS or continuous animation recordings.

**Eight caller captures** observe zero-based **frame 3**, the radial peak, in both normal and reduced states:

| Caller | Controlled real route | Radius |
| --- | --- | --- |
| Shock Mortar | Actual firing creates one fixed pending blast; actual release follows the controlled 0.6-second delay crossing. | 85 |
| Scrap Mine | A normal-pickup event creates a real mine; actual hazard arming and a living target cause detonation around 0.3 seconds. | 70 |
| Phase Capacitor | A dash event arms the actual charge; real Rivet firing/contact consumes it and applies the existing tinted splash. | 95 |
| Warden blast | A controlled due blast cycle goes through the real enemy warning logic and combat dispatch, including in-radius player hurt. | 105 |

These use legal current builds and bounded controlled conditions, not complete natural pickup acquisition, player movement, proc-combat or boss-encounter replays. The selected damage, charge/pending/hazard outcomes, source labels, tint, positions and exact floating radius-derived dimensions were checked. Existing rings were checked separately at the same position/radius and above the decorative effect.

A same-seed Mortar pair with explosion visuals enabled versus disabled compared the selected damage, player HP, random streams and pending-shot outcomes. This is bounded parity, not global RNG or combat certification. Firing, damage, events, settings and timer changes were intentional actions; presentation-authority guards began afterward. Settings used the controller API, not physical menu clicks.

Event ordering is inherited from unchanged production code, not intercepted callbacks: the Warden cue precedes conditional player hurt; Mortar emits after primary-hit events and before the mortar proc/removal; Mine emits after damage and before its detonation event/removal. Shared pool, pause/restart and generic source-cooldown checks were not replayed wholesale from earlier effect suites.

## Visibility limits

At the controlled **960 × 540** viewport, the early progression, radial peak and hollowing are distinct. All four caller peaks remain visually centered inside their separate rings in both states. Reduced opacity makes them substantially dimmer; late smoke and embers can blend into the mossy floor. In particular, reduced late frames are not consistently distinguishable by eye. Nonempty frame data is not a guarantee of persistent contrast.

Caller views contain other presentation. The reduced Phase view has a brighter central contact mark; Warden's blast overlaps the player, and its feet have separate existing glows. Muzzle, dash, hit and ring visuals can coexist. Neither the entire central mark nor every bright pixel is attributed to the new explosion, and full-cell viewport containment does not mean every detail is unobstructed.

Display sizes are world/logical units in the controlled capture, not identical physical pixels under arbitrary camera or OS scaling. Static editing previews sample fractional radius sizes into integer image envelopes; the native checks use the actual floating geometry instead. No all-combat, all-proc, other-effect-art, new inventory/UI geometry, Windows, CI or full-game regression claim is made.

## Retained failure and release boundaries

The initial strict pack comparison stopped on generated scene metadata. Its specific difference was verified before the same pack's remaining checks continued. The original failure remains a failure, not an initial complete pass. Source/packed identity, native execution and visual observations remain distinct scopes.

The BUILD run retained its exact historical warning allowance, and the native run its specific known display-warning allowance. Neither is described as warning-free; new errors are not silently ignored. Local restoration testing separately passed **10 controls: two positive and eight negative cases**. An actual backup, replacement with the new resource pack, and rollback to the exact original resource pack preserved the existing executable bytes and permissions. This is local file-restoration acceptance, not a delivery-executable launch, Windows execution or publication result. Both the preceding hit-spark release and this explosion release remain pending remote publication; remote-dependent source/history assembly is deferred until the preceding release actually closes.
