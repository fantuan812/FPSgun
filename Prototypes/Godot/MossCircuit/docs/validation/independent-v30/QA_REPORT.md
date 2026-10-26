# v30 independent QA — shop weapon order

**PASS for the bounded source, exact exported Linux runtime, UI and delivery scope below.** This report does not certify every build, seed, platform or balance outcome. Publication and exact reachable-byte review are separate later receipts; this bundle does not itself claim a GitHub ref exists.

## Tested identity and preservation

- Frozen contract: `ba1958ef08a8eed1d6b19ec9057f10a2cbb11d09a212dfb38a00e8cb85195366`.
- Final engineering candidate: 611 exact non-cache inputs, manifest `9da97ead5b745e3612c3cd8ed218a30d932be4f7d0e9317b44aa8ae005ac28e6`. The 119-path engineering fingerprint includes `ui/README.md`; its declared final wording cleanup is documentation only. All 118 runtime/art/data paths are identical to the controlled native R1 review. Catalog, tuning and art were not changed by this feature.
- Exported pack: 41,368,536 bytes, SHA256 `c7485c5a423312fac0c064e5a5a2815cc36284f6018a020c9c54e64b6dcec894`.
- Adjacent Linux executable: unchanged accepted 71,075,864 bytes, SHA256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.
- Both preset PCK outputs are byte-identical. This is not Windows execution. The release executable was launched normally beside the pack, not via `--main-pack` and not with a source fallback.
- All 611 QA source inputs and both runtime files were rehashed unchanged after ordinary native closure.

## Independent engine gates

The unmodified shipped regression runner completed **93 standalone scripts plus import = 94/94 PASS**, with no changed declared inputs. The original R1 QA copy had a genuinely cold import. Final added-tests/docs import was **reused-cache revalidation**, not falsely described as a second cold import. Exact production parity carries forward the original cold result.

- Standalone order mechanics: **837/837**. UI/actions: **512/512**. Both also pass without optional output arguments and are promoted byte-identically into the final candidate.
- Python export-safety negatives: **3/3**.
- Independently regenerated imported-source oracle equals the author oracle, SHA256 `bbcd6fdb65bcb30483b581bcc35bde0f325690400deee80571b959358d4726e5`.
- Exact resource-pack reader: **839/839**, 59 exact files, 58 imported RGBA textures, 25 action manifests / 281 frames. The independent mechanics **837** and views **512** checks also pass from an empty reader directory against the same PCK. Editor pack inspection is controlled validation, distinct from the ordinary release executable run.

The mechanics matrix includes all eight pinned weapon IDs, both modes, 2–4 equipped copies, equal IDs and clocks, positive/zero/negative finite clocks, strict raw types, stale generations and IDs, bounds, malformed arrays, atomic rejection before lazy rig sync, copy-specific rig state, reservation/refresh equivalence, stale and fresh sale/replacement callbacks, real outstanding Rivet/Return/Bankshot/Mortar rejection, and actual shared settlement flight clearing. The UI matrix covers 960×540 and 1280×720, one to four copies, default purchase focus, scroll reachability, unavailable reasons, real signal callbacks and synthetic `InputEventAction(ui_accept)`; it does not assert a joypad binding or physical-controller support.

## Existing-authority non-regression and honest timing

A 24-case accepted-v29 versus candidate no-reorder old-state projection is byte-identical: 2,207,907 bytes, SHA256 `e7d93a1fcf01345c540bf9f868632310fd3e85572dbe431dbe12d43bf19212ec`. It covers both modes, three seeds, all eight weapons across four loadouts, actual combat, shops, reservation, refresh, purchases, sales, three upgrade pages including salvage, and three RNG streams. It excludes new UI metadata and presentation object identity. One losslessly compressed trace and its equality receipt are included rather than duplicate multi-megabyte traces.

Eight actual shared-runtime timing cases pass 36 assertions and remain byte-identical to v29. With a fresh surviving target at 90 units, no bonuses and both clocks ready, Cryo→Orbit Saw plus Fracture deals 45 and consumes chill; reverse order deals 29 and leaves chill. At the next aligned cycle both deal 45, while reverse order reapplies chill. A later Rivet projectile consumes chill in either slot order. These illustrate conditional ready-processing order, **not** a sustained-DPS improvement, a guarantee that projectiles hit in slot order, or automatic cooldown alignment.

## Controlled native presentation

23 game-window-only captures and the actual UI intent log are indexed separately. An external QA fixture deliberately supplied builds, coins, clocks and frozen cases; native keyboard/mouse actions were automated through CUA. This is not ordinary acquisition. Both modes and both tested resolutions pass the bounded visual/layout matrix: free adjacent swaps, duplicate-copy clocks, full-slot replacement access, disabled outstanding-flight controls, actual keyboard focus/Space activation, shop-only editing, both-facing attached hand/side mounts, and read-only ordinary inventory. Normal scrolling exposes buttons initially intersecting a scroller edge. No new sprite, input mapping or art asset was required.

## Ordinary exact-export route

One finite **Rooms seed 128** route used ordinary automated CUA keyboard/mouse with tactical pauses and **no programmatic game-state control**. The seed was selected from the already-known natural first-shop Rail route; that planning did not inject stock, equipment or currency.

1. Seed and mode were visibly confirmed before starting; starter Rivet cleared room 1 through normal combat.
2. Settlement showed **66 scrap**. Overcharge and then Repair Plating were selected on two separately observed earned pages; salvage was not used.
3. The natural Rail Lance offer cost **42**. Purchase left **24** and two weapons.
4. The actual owned Rivet **MOVE LATER** action produced the confirmation “Rivet Gun moved to SLOT 2”; Rail became **SLOT 1** and scrap remained **24**.
5. The reordered build deployed into room 2. A game-window capture shows actual combat and attached mounts. A subsequent paused, read-only inventory shows Rail SLOT 1 and Rivet SLOT 2. Rail's 37.50 primary readout and 120 HP reflect the separately selected upgrades, not the order operation.

Twelve game-window-only screenshots are indexed with exact hashes and captions under `ordinary/`. This was not extended into a campaign or a Cryo/Orbit acquisition test. The run closed using external terminal Ctrl+C; a fresh window inventory confirmed absence. This is not a graceful in-game quit test.

## Delivery and limitations

The unchanged published restoration helper is tested against the final v30 direct-PCK catalog: literal verify-only and restore, existing-output refusal, unsafe-path and hash/order negative cases, followed by isolated backup/manual replacement/rollback using the exact accepted v29 pack and unchanged executable. Exact old catalog records and non-PCK installation files are retained. The detailed receipt is `delivery/DELIVERY_VERIFICATION.json`. No automatic installation, extraction or executable launch is hidden in this gate; Windows/NTFS execution is not claimed.

One initial UI oracle rejected eight cases because it concatenated BUY and REPLACE groups rather than respecting real document order. The original rejected script/log/result are preserved, and only the oracle was corrected; unchanged product UI then passed all 512. Controlled fixture input timing and one delayed observed transaction are recorded in the interim report, not presented as production defects. That historical report intentionally retains its then-pending gates; this final report supersedes those statuses.

The environment emitted inherited unsupported-VSync and ALSA `ERR_CANT_OPEN`, then used dummy audio. No audio acceptance. One source-native batched close call timed out, but capture bytes and game absence were subsequently established before continuation; the ordinary final close returned normally. No Windows runtime, physical controller, all-seed/all-build balance, full campaign, general performance or continuous-motion certification is claimed. Only explicitly selected logs, scripts, captures and receipts enter this public evidence bundle; generated profile/config/cache and runtime/reconstruction files remain excluded.
