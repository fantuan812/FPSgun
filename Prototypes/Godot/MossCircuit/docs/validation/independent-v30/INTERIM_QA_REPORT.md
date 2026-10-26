# v30 independent interim acceptance

**PASS for held R1 source mechanics and controlled native presentation.** Final frozen-source full regression, exact exported-resource verification, ordinary exported acquisition/swap and publication remain separate pending gates. No production defect or balance change was requested.

## Identity and preservation
- Contract SHA256: `ba1958ef08a8eed1d6b19ec9057f10a2cbb11d09a212dfb38a00e8cb85195366`.
- `COPIED_R1_INPUTS.json` pins 607 non-cache inputs. This QA copy began without an import cache; its actual cold import completed successfully before dependent tests. All 607 inputs remained unchanged through these checks/native review.
- `PRODUCTION_R1.json` pins the 119-path engineering fingerprint, which includes the non-runtime `ui/README.md`. A later declared UI documentation clarification must not be described as a runtime formula change.
- Accepted v29 baseline retained all 601 engineering inputs. The 24-case no-action trace is byte-identical on the candidate: 2,207,907 bytes, SHA256 `e7d93a1fcf01345c540bf9f868632310fd3e85572dbe431dbe12d43bf19212ec`. Its declared old-state projection includes shared combat, seeded shop/reservation/refresh/buy/sell, ordinary choices plus salvage, and three RNG streams; it excludes UI metadata and presentation object identity.

## Actual controlled checks
- `independent_weapon_order.gd`: **837/837**, both modes and all eight pinned weapon IDs. Strict raw payload types, bounds, stale callbacks, equal-ID/equal-clock copies, positive/zero/negative cooldowns, malformed loadouts/clocks, exact rig records and narrow authority changes, reserved stock and future draw equivalence, current sale/replacement, actual generated Rivet/Disc/Bankshot/Mortar rejection, and real shared settlement clearing flight state before the shop.
- `independent_weapon_order_views.gd`: **512/512**, both modes at 960×540 and 1280×720, one to four copies, all eight IDs and duplicates, real callbacks plus synthetic `InputEventAction(ui_accept)`, scroll/rectangle reachability, default focus, unavailable reasons and no paused-inventory edits.
- Both promotion scripts also exited successfully with no optional output argument. These were terminal runs, not inferred from partial logs.
- `existing_order_timing.gd`: **36/36**, eight actual shared-runtime cases. Fresh target at 90 units, no bonuses, both clocks ready: Cryo→Orbit Saw plus Coil deals 45 and consumes chill; reversed order deals 29 and retains it. At the next aligned cycle both deal 45, while reverse order reapplies chill. A later Rivet projectile contact consumes Cryo in either slot order. These are conditional timing examples, **not** a universal impact-order or sustained-DPS promise. Its result is also byte-identical to v29.

## Controlled native presentation
23 game-window-only captures are indexed in `POST_NATIVE_VERIFICATION.json` and captioned in `CAPTURES.json`. Actual native mouse and keyboard were driven through automated CUA; starting equipment, coins, clocks and safe frozen cases were deliberately injected by an external QA fixture. This is **not ordinary acquisition**.

- Arena 960: mouse move preserves 137 scrap, Rail becomes slot 1, guidance is readable, deployed hand/side mounts remain attached in both facings, and ordinary inventory remains read-only.
- Arena 1280: duplicate Cryo IDs still exchange distinct copy clocks (native intent log: 0.11/0.32 → 0.32/0.11), full-slot replacement remains reachable, outstanding real Bankshot/Mortar state visibly disables order controls, and native Shift+Tab then Space performs one swap without default-focus hijacking.
- Rooms 1280: native move, deploy and both facing mount samples pass.
- Rooms 960: four-copy cards scroll cleanly; moving the second Cryo later produces Orbit in slot 2, and moving Orbit earlier produces slot 1. Intent log preserves copy clocks at `[0.6, 0.11, 0.32, 0.9]`, with 137 scrap unchanged.
- Buttons near a scroller edge can initially be partially clipped; normal scrolling exposes their complete hit rectangles. The first offer's actual BUY/REPLACE control remains reachable. No new raster or input mapping was introduced.

## Rejected harness and environment observations
- The first UI run had eight incorrect first-purchase assertions because the oracle concatenated all BUY buttons before all REPLACE buttons, losing document order. The unchanged product passed all remaining checks. The original script/log/result are retained under `rejected-view-oracle/`; the corrected tree-order oracle passes all 512. This is not a product layout fix.
- An external fixture's 150 ms F3 pulse was not observed; after verifying no case transition/log event, a 500 ms pulse selected the case. One mouse result appeared only on a fresh subsequent observation; no duplicate transaction input was sent. Neither is claimed as a shipped gameplay defect.
- Native output retains unavailable VSync/ALSA and dummy-audio diagnostics. No audible-audio acceptance is claimed.
- The final batched CUA save/close call timed out and reset its kernel. The capture was verified on disk, and a fresh window inventory independently confirmed the game window absent after external Ctrl+C. No repeated uncertain close or graceful-quit claim.
- One later read-only exec command failed before process creation with a transport disconnect; a tiny capability check and the same read subsequently succeeded. No game/test result was inferred from that infrastructure failure.

## Limits
No Windows execution, controller mapping/hardware, full campaign, general balance/fun, continuous-motion or ordinary new-feature acquisition claim. Final exact-pack smoke and source/publication gates are still required before release acceptance.
