# v27 Broodkeeper hollow-pulse contract

Accepted base: v26 source commit `58a1e447ba3ed1b38cb508c1b86c0c63e436c3cf`, final indexed head `6b1643188ce5c4f11807925e57d6b5a03b13deb3`.

## One enemy behavior change

Only the existing Moss Broodkeeper gains a distinct alternating behavior: **hollow pulse first, existing summon second**, then repeat by its existing attack index. No new enemy ID, module, weapon, roster, wave pool, room stage, boss action, topology or persistent hazard. The current Warden already targets a locked player position; a duplicate Lobber was rejected as insufficiently distinct.

Broodkeeper's HP 75, speed 22, damage 11, XP 12, scale 1.35, initial attack cooldown 0.8 s, attack-start cooldown 6 s, retreat movement, summon limit 3 and ordinary wave HP scaling remain unchanged. Its data behavior becomes `brood_cycle`, with only `pulse_inner_radius: 70`, `pulse_outer_radius: 180`, `pulse_warning: 1.0` plus accurate description/tell/dodge copy added. Existing `summon` behavior support remains; Core summons and every other actor retain their behavior. Pulse turns intentionally replace alternate summon opportunities: this is an encounter-content change, not a claim of unchanged Broodkeeper pressure.

## Fixed spatial and damage rule

At the start of a pulse warning, lock a ground center to the Broodkeeper's attack-start position **after the existing shared field clamp**. Subsequent player movement, Pulse Boots push, Gravity Anchor displacement or other owner movement must not drag that mark. The owner braces for 1.0 combat seconds; ordinary summon warnings remain 0.65 s. Recovery remains 0.7 s. Warning/recovery remain contact-safe under the current shared rule.

At warning expiry, emit exactly one annulus impact at that locked center. Test the player's **current center at release**, not a swept path, hit radius or prior position. The dangerous band is closed: inner 70 <= distance <= outer 180. Use the named spatial tolerance 0.0001 world pixels: `distance >= inner - epsilon && distance <= outer + epsilon`. The center and distances below 69.9999 or above 180.0001 are safe from THIS pulse only. Both boundaries are dangerous; ±0.01 outside probes must be unambiguous. Do not promise safety from overlapping actors/attacks.

Exactly one existing `_hurt(enemy.damage)` call is attempted per pulse if in the band. An unblocked pulse subtracts 11 HP capped by remaining HP; this project has no armor mitigation stat. This is ordinary enemy area damage, not a hostile projectile, new immunity or fixed unmitigated HP loss. Existing HP-loss semantics, hurt invulnerability, post-Motor dash_time>0 immunity, Mirror Shell/Thorns and hurt reactions retain their order. It never emits `projectile_contact`, consumes Feedback Diode's allowance, or creates a primary/secondary player attack proc. Positive dash_time blocks; exactly zero does not. No lingering damage tick, expanding wave or homing phase.

## Timers, ordering and cancellation

Preserve the existing shared processing order and timer model: player weapons/mortars/hazards before enemy AI, hostile shots and in-flight player bullets afterward. A keeper killed before its AI tick does not release. An in-flight player bullet killing it later in the same step does not retroactively cancel an already emitted pulse. Owner removal before release cancels naturally with its actor/state; no detached delayed job remains.

The existing attack index advances when a warning starts, not when damage or spawning succeeds. A capped/no-child summon still consumes its turn. Hurt animation and pause do not reset or advance the index. Dead/removed actors do not resume a cycle; newly spawned or reset-stage actors start at index 0, so their first attack is the pulse.

Cooldown counts from attack start using the existing 6 s timer. The first pulse starts after the existing initial 0.8 s cooldown; its 1.0 s warning is not bypassed by the attack-start tick. Preserve the existing one-state-transition-per-tick/overshoot behavior; do not introduce catch-up loops or multiple pulses for a large delta. Zero-delta does not advance a positive timer; a timer already at expiry may resolve once, then recovery prevents repeats. Cryo/resin affect movement only, not warning/recovery/cooldown clocks. Pause/inventory/settings freeze combat clocks; title/result/retry/stage cleanup clears actor/marker/impact state. No RNG draw is added by pulse selection, geometry or visuals. Changed summon cadence can intentionally change encounter outcomes; all unaffected actors and shop pools remain exact.

## Telegraph and existing artwork

Render the exact same locked center/radii as authority: two orange boundary outlines with faint **band-only** fill or hatching, an unmistakably empty inner hole, and a short 0.2 s combat-time annulus impact echo. Never paint a solid explosion disk over the hole. Do not color the hole green or imply protection from other hazards. Both normal/reduced-flash modes preserve boundary visibility and actor/ground legibility.

Reuse the existing 16-frame Broodkeeper generic squat/brace/settle action honestly; actual pixels contain no baked offspring, so no new raster is required. It is not a newly authored pulse animation or root-unfurl. Normalize the pulse warning pose against its 1.0 s span, not the summon 0.65 s span; preserve hurt/death interruption and existing actor registration. Summon retains the old ring tell/action timing. Update the field guide to explain 'enter the inner pocket OR leave the outer circle; both orange edges hurt; other enemies can still hit you'.

## Independent acceptance

- Both field modes: all 8 radial orientations, center, inner/outer exact edges and ±0.01, release-only movement, locked center after forced displacement/clamp, one-shot/timer/large-delta behavior, first-pulse/next-summon sequence, death/order/reset/pause boundaries, source contact-safe windows and no extra RNG.
- Real shared hurt pipeline: dash boundary, HP-loss/hurt cooldown, Mirror/Thorns, Feedback remains unspent, no projectile creation; actual summon children/global cap and Core/boss rewards unchanged.
- Pin the sole Broodkeeper data allowlist and unchanged stage/wave/pool/catalog/balance bytes. Compare unaffected-actor old-content traces and full shop determinism, not whole Broodkeeper trajectory equivalence after an intentional behavior change.
- Native controlled both modes at 960×540 and 1280×720: safe hole/band, inside/outside player positions, actual forced displacement, attack pose span, hurt interruption, reduced flashes, charge/Core-ring overlap and two annuli; distinguish fixtures from ordinary play.
- Final exact PCK: packed geometry/AI/hurt tests plus one finite ordinary Rooms stage 3 encounter attempt using normal inputs, not a full Arena campaign or forced victory. Do not infer damage/safety solely from screenshots; use controlled authority proofs and label any unobserved ordinary outcome honestly.
- Keep v26 immutable; GitHub-only scoped source/evidence and direct resource-pack delivery after acceptance. Early WIP checkpoint may be explicitly unverified on a separate development branch, never promoted as accepted.
