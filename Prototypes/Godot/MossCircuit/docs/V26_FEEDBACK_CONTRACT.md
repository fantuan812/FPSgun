# v26 Feedback Diode contract

Base: accepted v25 source in commit `0b5ebcd486103f659406cf324dd02cb63f6ef257`.
This is a bounded new module, not a change to dash immunity or projectile physics.

## Catalog

- ID `feedback_diode`, name **Feedback Diode**, rare, price **28 scrap**, unique maximum **1**, tag `mobility`.
- Fixed `feedback_damage: 24`, independent of weapon damage, electric/melee bonuses, attack rate, range, pierce or projectile count.
- Existing eight weapons and 28 modules retain their definitions and order. Append this one module; catalog content version becomes 5.
- One affinity link and complementary mechanism pair with `pulse_boots`: **CROSSCURRENT**. A dash pushes nearby enemies and can counter one hostile shot. No additional multiplier or hidden effect is introduced by the pair.
- Expanded shop offers may differ for the same seed; determinism is within the same content version. Filtered old-pool behavior must remain exact.

## Arming and lifetime

- Only a successful actual CharacterMotor dash start while the module is equipped arms one allowance. Holding a key without a successful dash, buying/rebuying, recomputing stats, `sync`, or `invalidate` never arms it.
- Eligibility uses the existing post-CharacterMotor `stats.dash_time > 0` window. Dash duration/cooldown, input, movement and immunity are unchanged.
- The allowance is consumed by the first valid feedback contact only. Later shots in that dash cannot counter. There is no separate cooldown or stacked charge.
- Dash expiration and removing the module clear the allowance. Run/title/retry/stage/result transient reset clears it. Pause/inventory/settings freeze combat time and preserve an unspent allowance, without rearming it on return.
- Existing event epoch/sequence guards reject stale or duplicated events. The allowance is internal run state, not a saved preference or persistent inventory charge.

## Exact contact and ordering

- Use the unchanged hostile-projectile collision predicate: distance from the player's current position to the projectile's existing swept segment is **strictly less than 12 world pixels**. Equality and near misses do not count. Do not add a radius or sweep the player's earlier dash path.
- An initially expired projectile does not count. A positive-life segment that reaches its lifetime endpoint follows the same existing contact handling. A zero-delta overlap follows existing collision behavior and still cannot exceed one allowance.
- The contact must occur during that dash and name a currently living enemy owner still present in the shared enemy array. Invalid, removed or dead owners cannot receive damage or consume the allowance. Already removed dead-owner bullets remain removed by the existing owner filter.
- Preserve existing reverse-array hostile-bullet processing order; this is **not** geometric first-time-of-impact sorting. The first eligible owner in that order consumes the allowance.
- At an eligible projectile contact, resolve feedback before the existing `hurt` call, then retain that call and the existing shot expiration/removal. Existing dash immunity causes `hurt` to return, so Mirror Shell and hurt invulnerability timers are not consumed or changed.
- Melee contact, blast areas, dash near misses, ordinary hurt invulnerability outside dash, and other player/secondary projectiles do not counter.
- Feedback has no additional range, line-of-sight or travel phase: it is an immediate fixed hit on the living original owner. The short return line is visual feedback, not a homing projectile or a new collision authority.

## Damage and death ownership

- Apply one 24-damage secondary command to that owner, with `last_source = feedback`. No primary `hit` event is emitted.
- Do not activate Echo, Arc, Fracture, Blood Valve, Return Spool, Phase charge consumption or further feedback. Fixed feedback damage is not a weapon hit and cannot recursively proc.
- A feedback kill uses the existing deferred death path, secondary depth, normal XP/scrap drops and normal boss reward handling. It does not create Kill Cell energy orbs or Blood Mines healing. Standard boss reward healing remains standard, not feedback lifesteal.
- Do not change AI clocks, owner projectile cleanup order, enemy resistance, collision geometry, mode rules or RNG when the new module is absent.

## Presentation and validation

- One original item icon; use existing rendering infrastructure for a small violet armed-dash cue and a brief low-opacity return line/owner impact. No filled screen effect; reduced-flash mode remains readable and boss orange tells stay dominant.
- Item details disclose actual-contact, living owner, once-per-dash and fixed secondary damage. The complementary pair does not imply an extra proc.
- Independently test both modes, contact boundaries, ordering, lifetime/reset boundaries, actual dash-start and damage/death pipelines, malformed catalog values, transactions, old-content authority and filtered-old shop preservation.
- Native controlled checks cover both modes and practical window sizes. A finite ordinary exact-runtime acquisition/contact attempt is separate evidence; no full-campaign, Windows, audio or balance claim is inferred.
