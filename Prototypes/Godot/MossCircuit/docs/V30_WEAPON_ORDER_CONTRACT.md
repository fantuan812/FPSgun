# v30 proposal — shop-only adjacent weapon ordering

Status: FROZEN DESIGN CONTRACT, accepted by independent QA and parent. No implementation or validation claim yet. Accepted v29 remains immutable. The learning lane released at 14:13:29 UTC; game validation may resume under parent scheduling.

## Existing gap and useful decision
- `CombatRuntime.step` visits equipped slots in ascending order. `WeaponCombat.fire_chill` and the Orbit Saw branch apply primary hits immediately, before delayed projectile/mortar advancement.
- Cryo Sprayer and Orbit Saw both have a base 0.65 s interval. With both ready, a fresh surviving target in both footprints, and Fracture Coil owned, Cryo-before-Saw can apply then consume one mark in that tick. Reversed order can leave the newly applied mark instead. This is a conditional existing interaction, not a new proc or guaranteed DPS improvement. With no bonuses, the first fresh-target cycle can be 45 damage/consumed mark versus 29/retained mark; on the next aligned cycle the reverse order can consume the previous still-live mark and reapply it, reaching 45 while keeping slow between cycles. Reordering never forces clocks into alignment. These numerical examples require independent actual-path confirmation before published claims.
- Current shop exposes buy/replace/sell, but cannot reorder retained weapons. Acquisition order therefore fixes slot order without selling/rebuying. Slot 1 is also the hand mount and the other slots have distinct existing offsets.

## One bounded action
- Add free `MOVE EARLIER` / `MOVE LATER` actions to each owned weapon card in the shop only. One press swaps that copy with its adjacent slot. No arbitrary drag/drop, module reordering, battle action, new item, discount, or automatic ordering.
- Payload carries `slot`, `step`, `generation`, and `id`. The first three must be actual integers; `step` must be -1 or +1. `id` must be an actual String exactly matching the current source-slot weapon ID. No coercion of booleans, floats, strings, containers, or null.
- Require current shop state and current shop generation, a valid existing source and adjacent target, 2-4 owned weapons within the existing configured slot cap, recognized weapon IDs, and exact clock-array length equal to owned weapon count with every entry finite numeric (not bool). Reject invalid requests before any mutation, including presentation lazy synchronization.
- A copy is identified by current shop generation plus source slot, not by weapon type. Duplicate weapon types remain distinct slot copies; swapping identical IDs still swaps their potentially different clocks and presentation records.
- Every successful move increments shop generation once and build revision once. It redraws shop and announces the new slot. This invalidates old buy/replace/sell/reserve/release/refresh/deploy and move callbacks. Failed/invalid-step/boundary/wrong-state requests change nothing, including message/generation/revision/RNG. A valid adjacent duplicate-copy swap succeeds even when both IDs and clocks happen to be equal; it is not treated as a no-op.
- Moving repeatedly is intentionally free, not a reward: it grants no scrap, refund, stat, extra choice, free attack, or timer reset. There is no caller-provided price or benefit.

## Copy state and safe flight boundary
- Swap exactly the two weapon IDs and their exact corresponding cooldown values. Negative/zero ready values stay ready; positive remaining time follows its copy. Do not normalize, refill, synchronize, decrement, or reset clocks.
- `RunFlow.settle` already clears all player bullets and pending mortar blasts before opening every normal shop. The new action additionally requires BOTH arrays to be empty. If a synthetic/future shop contains either, disable/reject reorder with a precise unavailable explanation in the view; never destroy, retarget, edit, rebind, or resume those objects.
- This restriction deliberately avoids changing existing Return Disc's slot-index display ownership or introducing persistent projectile instance IDs. It is not a new projectile-cleanup policy. Non-shop in-flight actions are also rejected unchanged.
- The presentation rig first uses its existing lazy loadout synchronization against the pre-move IDs if needed. Then its two copy records (including aim/recoil age) follow the swap, their slot indices update, and only their cached poses clear for recomputation at the new mounts with existing geometry. Do not reset other rig records, visible clock, or rig generation when the existing rig is aligned. Historical last-shot diagnostics are not rewritten into a new shot. The next normal pose update shows the moved hand/side mounts; no sprite/art change or gameplay RNG.
- Do not call `_recompute`, effects sync/reset/invalidate, fire, damage, pickup/credit, or encounter-transition paths for reorder. No proc command/event is emitted.

## Preserved state and explicit differences
- Coins/fraction, HP/dash/hurt state, all numeric derived stats, module counts, tag counts/bonuses, upgrade levels, pending upgrade queue, reserved offer/token/slot/price/metadata, current offers/sold flags, RNG states, encounter clocks, and effects counters/epochs/cooldowns stay exact.
- Catalog, prices, weights, six upgrade choices, art, enemy behavior and existing sale/replacement semantics are unchanged. Reorder does not grant ownership or alter the multiset of equipped weapons.
- Current weapon-card order, mount assignment, and subsequent ascending-slot fire order intentionally change. Lists that enumerate owned weapons may reflect the new order; numerical affinity and the resulting weighted pool/draws must remain equivalent for the same RNG state.
- Without using the new action, old gameplay/shop/upgrade/reservation/salvage traces and RNG must be byte-identical on the declared old-state projection. No persistent global IDs or new state fields are required on the unused path.

## UI / lifecycle
- Show one-based slot numbers, short free-reorder/cooldown-preserved guidance, and disabled boundary buttons. No reorder actions in ordinary inventory, pause, upgrade, title, result or gameplay.
- Existing first purchase/default focus, replacement controls, three-stat-plus-salvage flow, scrolling and reservation usability must remain reachable at actual 960x540 and 1280x720 in both modes. Reordering is explicit, never the default activation.
- Copy explains: ready weapons process by slot; actual contact timing still matters. Projectile travel and delayed Mortar hits prevent a generic 'earlier weapon always hits first' or guaranteed shatter claim.
- Existing new-run/retry/title behavior remains: fresh starter loadout and clock state, not the prior run's ordering. Stage continuation retains the chosen order.
- Input scope is actual native keyboard/mouse and synthetic `ui_accept` action dispatch. No physical-controller mapping or new binding claim. No new raster assets.

## Finite acceptance plan
1. Old no-action shop/upgrade/reservation/salvage and controlled combat/RNG traces versus exact v29; unchanged catalog/encounter/art inputs.
2. Both modes, 1-4 copies, all adjacent directions/boundaries, duplicates with distinct positive/zero/negative clocks, strict payload/malformed-state/stale generation and queued-command atomicity.
3. Exact allowed-state diff, involution (move then reverse restores IDs/clocks apart from documented counters/message), held offer and sold/replacement behavior, identical future weighted draws after permutation.
4. Existing Return Disc/Bankshot/ordinary bullet/Mortar states: reject unchanged; no silent cleanup/remap. Normal real settlement clears these before successful reorder.
5. Actual shared-runtime synchronized-ready Cryo/Saw plus Coil demonstrates the conditional order difference; reversed test and delayed-projectile counterexample prevent overclaim. No combat formula change.
6. Controlled native both modes/sizes: owned cards, duplicate labels, keyboard/mouse swaps, stable controls/focus/scrolling, deploy and mounts in both facings. One finite ordinary exact-pack route acquires a second weapon, swaps, deploys and displays the new order; no full campaign required.
