# Next bounded build proposal: Bankshot Driver + Bounce Guide

Status: design/QA contract accepted under the parent's conditional authorization, 2026-10-25. Production may now begin within this scope. Source base will be accepted v22's text-only clarification, restored from its pinned v21 base plus delta. All shipped v21/v22 artifacts stay immutable. No audio, save, network, interior obstacles, dungeon topology, or denied Git ref action.

## Role and initial tuning

Exactly one weapon (`bankshot_driver`, Bankshot Driver) and one unique module (`bounce_guide`, Bounce Guide), pair `banked_vector` / BANKED VECTOR. This is a positioning-dependent field-boundary re-arm projectile, not another instantaneous chain/explosion.

- Weapon: damage18, interval0.85s, one projectile, base pierce0, range900, maximum2 reflections, price42 uncommon, tags ballistic+ricochet; existing four weapon slots/copy limit4.
- Module: price26 rare, unique1, tag ricochet, existing module slot. Changes only the first physical reflection's direction; no damage, range, bounce or quota bonus.
- Weapon damage bonus and shared additive attack rate apply. Existing pierce adds one target to each leg's quota, capped at6 total; pellet/electric/melee bonuses do not apply. Speed snapshots existing bullet_speed: current shipped base is470 world units/second; no new speed modifier is introduced. The weapon emits exactly one projectile per shot; Pellet Pouch only changes shotguns, and no generic extra-projectile modifier is currently shipped. Range bonus scales the initial acquisition radius and the single total path budget once each.
- 900 is independently the player-center acquisition reach and the total traveled path beginning at the clamped muzzle. It is NOT900 per leg. From center Arena, reaching a field boundary may consume almost all the budget. Low direct DPS and field-edge-positioning dependence are deliberate tradeoffs, not a claim of balanced/all-seed viability.

## Targeting, launch and movement

Nearest living enemy center within acquisition reach selects the initial aim; distance then enemy ID breaks ties, coincident aim uses RIGHT. No eligible target means no shot. The existing mounted weapon supplies muzzle/aim geometry. Clamp the launch point to the shared field rectangle `(0,0,width,height)`; do not damage an outside-muzzle/launch bridge. The field comes from the existing combat context, not a mode ID or an inferred obstacle map. Arena is1440×960, Rooms960×640.

Snapshot damage, positive finite speed, total path budget, per-leg quota and guide possession at launch. TTL is exactly launch total_budget / snapshot speed in combat seconds. Both remaining distance and TTL decrease consistently for actual movement (elapsed travel time = distance / snapshot speed); pauses advance neither, and reflection/guiding reset neither. Later equipment/stat edits do not change an in-flight shot. Normal stage/run cleanup still removes projectiles.

Positive finite dt advances at most `speed*dt` and remaining path budget. dt≤0 causes no travel, damage or reflection. Invalid/nonfinite movement inputs safely expire or reject the shot. Actual nonnegative traveled distance is subtracted and never reset at a field boundary. On budget exhaustion, process endpoint hits, then expire without granting a free reflection/guide operation.

Each nonzero segment processes eligible enemy-circle first contacts in swept distance/ID order through its endpoint, then the boundary: enemy-before-boundary on an exact positive-segment tie. Recheck living status after earlier procs. Outward boundary starts are resolved as zero-distance boundary contacts before enemy damage on the first positive advance. A physical reflection flips each contacted axis. Exact corners within spatial tolerance count as ONE reflection and flip both axes; a distinct near-corner beyond tolerance is two successive contacts. At most2 reflections create3 damage legs; a later boundary encounter absorbs the shot without re-arm/guide. No out-of-field segment can deal damage.

Use one explicit small spatial tolerance (0.0001 world units) for boundary/contact containment and a separate tiny direction-zero threshold. One initial outward t=0 contact is allowed on a positive advance. After a reflection, another boundary encounter must require MORE than that spatial epsilon of cumulative positive traveled distance since the previous reflection (across frame boundaries, not merely this frame's segment); otherwise absorb safely before resolving new-leg hits on that insufficient-progress segment, without re-arm or guide. Exact-corner axes are combined into one event rather than treated as two zero-distance encounters. Progress/event loops have a hard defensive ceiling; reaching it terminates safely rather than resetting range or looping. The designed lifetime has at most2 reflection operations and18 damaging contacts (quota≤6 across3 legs), not an unlimited event system.

## Per-leg re-arm and overlap safety

Each leg can damage at most `1 + pierce_bonus` eligible targets, capped at6, once per enemy ID. When its quota is spent, the projectile continues traveling visibly dim/unarmed until an actual reflection re-arms it. Spent targets do not receive hit events and do not consume a future quota.

At reflection, clear the leg hit set and restore its snapshotted quota. Carry a separate exclusion for IDs already damaged on that leg whose current circles still contain the contact point, plus prior blocked IDs still containing it. Never-damaged overlapping targets remain eligible. Blocked IDs do not consume quota. Release a block once the projectile is strictly outside that target's current circle with the same tolerance. With enemy poses frozen during one advance, a straight segment starting inside cannot exit and re-enter the same circle: skip that target for the segment, then release after exit; release initially outside blocks before searching contacts. This avoids a general moving-target exit-event solver while preventing zero-travel duplicate/proc farming. A genuine later separated return can hit again.

## Bounce Guide

On the first reflection only, after prior segment hits and overlap carry creation, inspect CURRENT living enemy positions. Eligible centers are strictly inside the field, not overlap-blocked, within the remaining path budget, and yield strictly inward direction on every contacted axis. Choose nearest center then ID and lock that one direction. No homing afterward; moving targets or earlier intervening hits can prevent the aimed target from being hit. No eligible target means ordinary physical reflection and the guide opportunity is consumed, never deferred to reflection2. No extra RNG draw, projectile or proc event is created by guiding.

## Attribution and presentation

Every actual damaging contact is one normal primary hit from this weapon type. Existing Echo/Arc/Valve/Kill Cell and Cryo→Fracture rules therefore apply with their current cooldown/depth/ownership semantics. A secondary effect never creates another Bankshot projectile or boundary event. Fracture remains fixed16 secondary and cannot recurse. No global weapon-specific proc cooldown is added.

Show a thin field-edge cue only while this weapon/projectiles are present, distinct bright armed vs dim spent projectile, and a brief bounded actual-contact flash/direction cue. A corner produces one cue. Guided direction is shown only after the actual contact, not as guaranteed future-hit prediction. Preserve enemy tell contrast, transparent HUD, reduced-flash policy and existing art. Proposed new contact feedback cap12, short0.18s life; decorative only. New source art, when authorized, is limited to weapon icon, independent world mount and module icon.

## Acceptance, scope and stopping condition

Before implementation, QA agrees the exact edge ordering/overlap/guide semantics above. Then test both real field sizes; four sides/corners; clamped/outward/tangent/coincident launch; exact vs near-corner; equality/just-outside budgets; zero/oversized dt; third-boundary absorption; quota1/6; spent non-damage; separated re-hit vs overlap exclusions; target ties and proc-killed later candidates; guide fallback/eligibility/snapshot; actual primary/proc/Fracture ownership; transactions, unique/slot/affinity rules and reset. Frozen-enemy geometry may compare dt subdivisions; full moving-AI/proc-clock partition equivalence is NOT promised.

Preserve existing combat projection and filtered-old-pool behavior, explicitly allowing new catalog entries and the previously reviewed four text corrections. Actual offers may change with the expanded content version. Native both-mode960/1280 boundary/armed-spent/contact readability and one ordinary acquisition plus observable bounce on the final exact export are separate gates. Save an early explicit WIP source/art delta against the durable base, then a tested checkpoint. No broad balance, full-combination, Windows or audio claim.
