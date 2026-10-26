# v30 implementation and bounded acceptance status

Status: finite source/native/exact-pack acceptance passed. Publication identities and restoration proof are recorded separately; accepted v29 remains unchanged.

## Implementation
- Shared read-only `WeaponOrder.loadout_error` validates the current copy/clock arrays. Main owns shop state, generation and raw action guards; no new persistent instance IDs.
- `_move_weapon(slot, step, generation, id)` swaps adjacent IDs and exact remaining clocks only after all guards, then increments build revision/shop generation once and redraws. It does not call recompute or effects synchronization.
- `WeaponRig.swap_copies` carries each record's age/aim, updates slot indices and drops only the two cached poses. Historical last-shot data remains historical. No in-flight projectile is edited or discarded.
- New availability views are detached/read-only. Controls appear only on owned shop cards; ordinary purchase focus is retained and moves are never the default activation.

## Finite source and native evidence
True cold import and 321 focused author assertions pass, plus existing reservation 520, salvage 147 and rig 245 checks. Independent authority 837 and UI geometry/callback 512 checks pass. The complete 24-case no-action trace and 36 actual timing checks match accepted v29 byte-for-byte.

Controlled native keyboard/mouse review in both modes at 960×540 and 1280×720 accepted 23 window-only captures: duplicate copies, preserved clocks/rig state, unavailable in-flight moves, read-only inventory, replacement controls and deployed hand mounts in both facings. These controlled setups are not ordinary acquisition or a full campaign.

A rejected UI oracle grouped all BUY controls before REPLACE controls instead of retaining document order, misidentifying the first offer. The original script/log/result is retained; only that oracle was corrected. No production defect or correction was required. A transient execution transport failure occurred before a final preparation process started; file/process absence was checked before retrying, not treated as a game test failure.

## Honest timing example
For a fresh surviving target within both footprints, ready Cryo Sprayer then Orbit Saw with Fracture Coil gives 45 primary-plus-secondary damage and consumes the mark; reverse order gives 29 and retains the new mark. On the next aligned cycle both can give 45, while reverse order reapplies the mark. This is a burst-versus-mark/slow timing decision, not a sustained-DPS guarantee. Reordering never synchronizes clocks, and later projectile contacts can consume marks regardless of launch-slot order.

## Final exact pack and ordinary route
Author and independent shipped runners pass 93 standalone scripts plus import (94); Python safety 3 passes. Initial true cold imports are distinguished from final reused-cache revalidation. All 611 frozen source inputs are unchanged. Both preset PCKs equal SHA-256 `c7485c5a423312fac0c064e5a5a2815cc36284f6018a020c9c54e64b6dcec894`, 41,368,536 bytes; the accepted Linux executable is unchanged, not rebuilt. Independent packed resources pass 839, and packed authority 837 / UI 512 pass from an empty reader directory using independently regenerated source-imported fingerprints.

One ordinary automated-CUA/tactical-pause Rooms seed-128 run, without injected state: natural Room 1 clear, Overcharge then Repair choices, first shop 66 scrap, Rail purchase 42 leaves 24, Rivet MOVE LATER gives Rail SLOT1 / Rivet SLOT2 with 24 unchanged, then Room 2 deployment/combat and paused read-only inventory. The 37.5 Rail readout and 120 HP are explained by the selected upgrades, not ordering. This is not a campaign, sustained-DPS, all-build balance or physical-controller claim.

External terminal Ctrl+C closed the game and window absence was checked; not an in-game graceful-quit claim. Before/after executable, PCK and all source hashes match. Only inherited unsupported-VSync and ALSA/dummy-audio diagnostics were observed. Windows/audio and broad performance/balance remain unverified.

The separate delivery gate covers the unchanged restore helper, no-overwrite/hash/order/path negatives and isolated manual v29 backup/update/rollback. The final source/metadata tree and deduplicated actual-byte remote proof are independent publication gates; they do not imply GitHub CI ran.
