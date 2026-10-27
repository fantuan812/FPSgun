# v33 author fixture/oracle corrections — retained evidence

These initial failed author runs are NOT reported as passing, and are not hidden by later success. Source acceptance remains separate from focused tests.

- `logs/tempering-r1.log`: 372 pass / 25 failed, plus one draw error. The fixture used 8 occupied module kinds before attempting to buy a ninth; corrected by freeing a kind in that specific nonweapon-eligibility test. A synthetic trail omitted its draw-required radius; corrected with the existing radius70 field. The authored profile comparison used deep dictionary equality against int1 while Godot JSON parses numeric1 as float1; changed to scalar numeric value assertions. No product rules were changed for these failures.
- `logs/combat-r1.log`: 286 pass / 4 failed. The observer intercepted WeaponCombat effect calls, but existing Mortar resolves through EffectRuntime directly. The primary damage and all8 brace numerics already matched.
- `logs/test_tempered_combat-r2.log`: 286 pass / 4 failed. Revised oracle counted only one Mortar event; existing Mortar emits one hit plus one mortar event. Corrected to its two-event sequence, not a production behavior change.
- `logs/test_weapon_tempering-r2.log`: 397 pass / 0 failures.
- `logs/combat-r3.log` and `logs/tempering-final-focused.log`: final focused 290 and397 pass, no engine errors.
- A small pre-gate UI wording correction ensures one-copy temper eligibility says it needs another STANDARD copy rather than inheriting the reorder helper’s wording. No gameplay change.

The existing no-temper six-route transaction and24-case combat outputs match the pinned baselines byte-for-byte; see FOCUSED_PARITY.json. Ordinary gameplay/native/packed proof is still pending independent work.

## First complete aggregate (retained)

`full-suite/` completed 101 standalone entries + import:100 passed,2 failed, no input changes. The only failures were one assertion each in `independent_reservation_records.gd` (old whole catalog SHA) and `test_modifier_copy.gd` (old complete catalog projection), both intentionally affected by the frozen top-level v33 profile. Their original failed logs remain in this folder.

The candidate updates these two expectation boundaries narrowly: exact current catalog SHA317a2d34…, exact old88002883… bytes after removing only the literal authored profile block (exactly once), and exact profile equality before removing only that key from the older v21 projection. No old fixture/golden data or production behavior changed. Independent QA reviewed this scope. A fresh complete rerun, not a hidden/stitched pass, follows.
