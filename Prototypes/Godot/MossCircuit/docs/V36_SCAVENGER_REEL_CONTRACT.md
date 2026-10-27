> Historical design checkpoint: the DESIGN ONLY/unexecuted statements below describe the original contract freeze, not current implementation status. Current finite results are in V36_SCAVENGER_REEL.md. Technical C2 clauses are retained without gameplay changes. Original C2 SHA2561189f9778046550b7964c000c5af7fa1df582af81297d06885b39e495af2eb79.

# v36 Scavenger Reel — frozen design contract C2

Design only. No implementation, target execution, balance result or release claim is made. The v35 source and runtime remain immutable while their acceptance proceeds.

## 1. Player feature and exact data

Add one unique item `scavenger_reel` (Scavenger Reel): price 28, rarity rare, max_stack 1, tags `[returning, salvage]`, ordinary `effects: {}`. Initial authored fields are `return_pickup_radius: 18.0`, `return_pickup_limit: 3`, and `pickup_sources: [normal, energy]`.

A Return Disc launched while this item is owned can immediately collect at most three eligible ground-pickup objects touched by its returning path over that projectile's lifetime. It does not carry loot or wait for arrival. Outbound travel, other weapons and medical pickups cannot use this mechanism. The normal physical pickup path remains available for every pickup source.

The item has no damage, damage-resistance, range, attack-rate, projectile-count, XP or scrap multiplier. Existing damage/return-hit healing and existing item effects remain authoritative. New unique item, icon, one Return Disc affinity link, one `SCAVENGER RETURN` mechanism description, shop/build details and projectile quota presentation are the entire content scope. No new weapon, character, starter, game mode, audio, persistence or external downloaded asset is included.

Catalog validation accepts radius only as a finite number in `(0, 64]`, and quota only as a finite integer-valued number in `[1, 8]`: an actual int or an integral float from the existing JSON loader is accepted; booleans, fractional values, NaN, infinity and nonnumeric types are refused. Validation precedes conversion, and the launch snapshot `maximum` and `remaining` are actual ints. Do not change the generic JSON loader or historical numeric rules. Max_stack must be exactly one. Sources must be exactly the two distinct strings `normal` and `energy`; duplicates, medical, unknown strings, nonstrings and missing fields are refused. The new row is optional for historical catalogs: absence must preserve the old disabled path rather than invent defaults or reject the old catalog.

## 2. Launch snapshot and ownership

Only `return_disc` launches with the item currently owned and a valid profile get new per-projectile metadata: an independent radius, remaining quota, maximum quota and accepted-source snapshot. No new metadata is inserted into ordinary legacy bullets or Return Discs launched without the item. Each actual spawned disc gets its own quota; snapshots must not share a mutable remaining counter.

Buying/syncing during an existing flight cannot add the feature to that flight. Selling the module does not retract a valid already-launched snapshot, and never resets/refills a remaining quota. Weapon replacement, order/tempering transactions or run transitions retain the existing projectile-preservation/clearing rules. Tempering gives no collection multiplier. Two weapon copies provide two independent launch streams; merging them naturally reduces the number of streams while retaining the existing primary-damage tradeoff.

There is no pickup ownership transfer, carried-item array, delayed reward, extra pickup entity ID or persistent acquisition queue. A ground object stays in `world.pickups` until the single pickup stage removes and credits it. Identical-valued pickup dictionaries at identical positions remain distinct objects; never deduplicate by dictionary equality or position.

## 3. Authoritative return geometry

The existing `advance_disc` integration remains authoritative: existing launch/hit behavior, outbound/return split, lifetime clipping, player-directed return velocity, per-leg enemy-hit reset and arrival retirement are unchanged.

For an eligible disc, emit a transient pickup sweep only for an actually executed nonzero returning displacement, using the exact pre-advance and post-advance positions of that returning `advance_bullet` portion. Do not use rendered interpolation, draw geometry, the whole old-to-new position across an outbound/return split, or weapon reach as a substitute for the actual segment.

- Life already exhausted at entry: no sweep.
- Zero dt or exact zero displacement: no sweep.
- Outbound-only advance, including expiry before the turn: no sweep.
- Turn reached during this step: only the executed returning suffix is eligible.
- Already within the existing `< 14` arrival threshold before moving: retire without a sweep.
- A valid last returning segment remains eligible for the current pickup stage even if the disc retires afterward on arrival, life exhaustion or the existing hit budget. The existing movement-then-hit algorithm defines its endpoints; this feature does not introduce a different continuous first-collision retirement model.
- No extrapolation beyond the distance/lifetime actually advanced. No sweep survives into the next step.

Both endpoints, pickup position and radius must be finite. Exact zero-length segments are excluded. Eligibility is strict `distance(pickup_position, closed_segment) < radius`: a tangent at exactly the radius is outside. Axis-aligned exactly representable boundary cases and non-axis tests with explicit margins will distinguish the contract from floating-point tolerance claims. The design is not a proof of arbitrary floating-point geometry or arbitrary malformed combat state.

Transient sweep rows are local to one `CombatRuntime.step` invocation, not a persistent CombatState field. A row can retain the disc dictionary only until the current pickup stage to debit its remaining quota, including a valid retiring last segment. It must never retain an uncollected pickup or carry reward authority across calls.

## 4. Exact pickup stage, positions and ordering

Keep the existing step order: player weapons/mortars/hazards, hostile actions, projectiles, enemy deaths/drops, then ground pickups. WeaponCombat reports geometry/quota association only; it must not perform XP, currency, healing or pickup-effect settlement.

At the start of the existing ground-pickup loop, use its existing reverse index range, from the then-current last pickup to index zero. Thus all drops/energy orbs created by the preceding death pass are eligible in this same pickup phase, even though the returning geometric sweep occurred earlier in the discrete step. This is a deliberate discrete-phase policy, not a claim that the pickup existed at an exact continuous sub-tick time. Pickups appended by an event during this pickup loop are outside that original range and wait until a later step.

For each pickup, preserve the original operations in order:

1. Save `distance_before_move` from its current position to the player.
2. If that distance is inside the original pickup_radius, apply the original `move_toward(player, dt * 260)` exactly once.
3. If `distance_before_move < 14`, execute the old physical-player pickup path. It wins and consumes no disc quota. Its event position remains the pickup's current, possibly magnet-moved position, exactly as before.
4. Otherwise consider the new remote path. Use the pickup position AFTER that original magnet movement. Do not recheck player contact using its moved position, do not apply magnet movement twice, and do not use its spawn/original-frame position.
5. Source is `normal` only when the source field is absent; otherwise it must be an actual allowed string. Medical/unknown/malformed sources are not remote eligible. This does not change or repair the historical physical-player path for malformed data.
6. Consider sweeps in the same order in which the existing projectile loop advanced their discs: descending original bullet-array index. Within a disc use actual return-piece order. Choose the FIRST eligible sweep whose associated disc has positive remaining quota; no nearest-pickup sort, nearest-disc sort, RNG draw or dictionary iteration chooses a winner.
7. Debit that disc once, call the same `RunFlow.collect_pickup`, emit the same one source-preserving pickup event at the current authoritative pickup position, and remove the pickup once. A pickup cannot also credit another disc or the player in that iteration. No failed/medical/outbound candidate consumes quota.

Only the active playing simulation can use the new remote branch. It may not award from UI rendering, pause/inventory/shop callbacks, elapsed wall time, retired sweeps or terminal-state calls. The supported controller's existing early returns on player death remain unchanged.

## 5. Existing effects and progression are not reimplemented

`RunFlow.collect_pickup` remains the sole pickup reward authority: its existing capped healing, XP addition and fractional-bank currency calculation are reused unchanged. Existing `RunFlow.accrue_levels` placement after CombatRuntime remains unchanged; there is no new immediate mid-projectile level-up pass.

Remote pickup events retain normal/energy source and current pickup position:

- Normal pickup can place an existing Scrap Mine at that collected position, subject to its existing one-second cooldown, four-mine cap and other rules. This is remote mine placement, not bonus mines or lightning damage.
- Energy pickup can charge the existing Arc Relay + Kill Cell combination; it does not become a normal pickup and cannot place a normal-pickup mine.
- Medicine is excluded remotely; existing local healing still works.

Hazards were already advanced earlier in the current step. A mine created in the pickup stage cannot detonate retroactively during that earlier phase. Likewise a chain charge acquired here cannot retroactively modify a weapon hit already processed in the step. Existing source/depth/epoch and anti-recursion gates remain unchanged.

## 6. Lifecycle and field transitions

The only persistent state introduced is the launch snapshot/quota on an existing disc. Local sweep rows disappear when Runtime.step returns, including early returns. No new persistent queue needs draining during cleanup.

- Pause, build/inventory, settings, upgrades and shop do not progress geometry or quota. Resume uses the existing discs as preserved by the existing workflow; it does not replay old sweeps.
- Title/retry/new run use existing bullet and ground-pickup reset rules. Nothing from a prior run can grant a reward in the next run.
- Accepted wave/room settlement continues to collect remaining world pickups through existing settlement behavior exactly once, then clear projectiles. Remote-collected pickups are already absent and cannot be settled twice. Invalid/ignored settlement remains unchanged.
- Rooms clear pauses and actual field refreshes cannot carry sweep records into the new field. Do not add separate rewards in `_enter_field`, which is only layout/camera/player positioning; lifecycle remains with its existing callers.
- Defeat/win prevents new remote collection. Existing frozen projectile presentation at terminal state is not a license to settle metadata later. Quota indicators are hidden in terminal/title states.
- Equipment changes may delete discs as they already do; uncollected world pickups remain governed by existing world cleanup, never deleted as 'cargo'.

## 7. Presentation and no invented synergy bonuses

Use one distinct reel-shaped icon. Module/shop/build text must state: Return Disc required; return leg only; up to the data-defined quota; normal/energy only; immediate collection; medicine excluded. Active/incomplete mechanism status follows actual owned prerequisites, not possession of an unrelated tag.

Eligible returning discs display their remaining quota as small pips, capped by the validated maximum; exhausted pips distinguish 'cannot collect more' from damage or flight expiry. Static paused/inventory presentation may retain the frozen count, but never advances it. Hide active quota presentation in title/won/dead. Each actual interception can add a restrained bounded pulse, at most eight visual records with lifetime 0.16 s; respect Reduced Flashes and add no sound. The visual layer cannot spend quota or trigger collection.

New returning/salvage tags participate only in the existing tag counting/shop-affinity rules. The current threshold stat bonuses are electric/melee/spread; this item creates no fourth threshold rule. Do not describe existing threshold activation, item ownership or the one mechanism row as an extra damage/currency reward. A refreshed offer is a weighted preference, never a guarantee of the missing partner.

## 8. Historical parity and intentional shop changes

All previous catalog rows and numeric fields stay byte-equivalent as data values. The new row/link/description intentionally enlarge the current offer pool and can change fixed-seed offer IDs and player purchase routes. Preserve RNG ownership/draw mechanisms, but never claim global fixed-seed shop parity with the enlarged catalog.

Required separate controls:

- Old catalog + old build: accepted old transactions and combat/event/RNG traces remain exact.
- New catalog + fixed old combat setup without the item: no new bullet metadata, remote sweep effects, reward/event sequence or gameplay RNG use. Existing geometric damage/AI/order behavior remains exact.
- New catalog shopping: validate the intended new pool and affinity semantics with declared new expectations, retaining old traces as historical controls rather than rewriting their identity.

## 9. Frozen paper cases for independent oracle construction

A. Radius 18, returning segment `(100,0)->(0,0)`, player `(0,0)`, no magnet: `(50,17)` is remote eligible; `(50,18)` is not; `(120,0)` is not. `(0,17)` is eligible remotely because original player distance is not below 14. Exact zero segment is never remote eligible.

B. Player `(0,0)`, pickup `(20,0)`, pickup_radius 30, dt .05: original magnet moves it to `(7,0)`. Original physical condition uses saved distance 20, so it does not collect physically this tick. A valid return segment touching `(7,0)` may collect remotely and spend quota; absent that sweep it remains for a later original local pickup. With saved distance 13, physical pickup wins and disc quota is unchanged.

C. Pickups `[P0,P1,P2,P3]` all eligible, no local contact, one disc budget 3: old reverse pickup order consumes P3,P2,P1 and leaves P0. Two discs A index0 and B index1 each budget1: P3 uses B, P2 uses A; P1/P0 remain. Identical positions/values do not merge objects.

D. Return integration with speed100, position `(100,0)`, outward velocity right, outbound_left .01, life .2, dt .03: only the returning suffix `(101,0)->(99,0)` is a remote sweep. With life .015, only `(101,0)->(100.5,0)` is eligible and the disc can retire afterward. With life .005, expiry happens outbound and no return sweep exists. Arrival-distance10 at entry retires without a segment.

E. A normal death drop created after projectile advancement but before the pickup loop can be collected by an eligible current-step sweep; a pickup appended during pickup event handling cannot join the already-snapshotted index range. Actual original event position after magnet movement is the mine position; no 'spawn position' substitute.

F. Normal and energy intercepted at the same geometry preserve their distinct events; medical remains on the ground unless the original player-contact path collects it. Quota0, absent/malformed snapshot, outbound path, ended lifetime with no advance, pause or terminal context cannot remote-credit.

These are finite design oracles, not claims that implementation tests have already passed.
