# Baseline v37 enemy HP mutation seams (static, not v38 coverage)

Read-only inventory. These are required coverage candidates, not completed runtime tests. A grep match count is not proof of every possible causal event chain.

| File / seam | Actual HP write | Runtime phase / boundary |
|---|---|---|
| weapon_combat.fire orbit | hp -= PrimaryDefense resolved | Early weapon-clock fire, before enemy AI |
| weapon_combat.fire_chill | hp -= resolved, then apply chill if alive | Early cone fire; chill-only control must not count as damage |
| weapon_combat.hit_segment | hp -= resolved | Player bullet/Return Disc late phase; hit-trigger procs synchronous |
| weapon_combat._bankshot_hit | hp -= resolved | Late bankshot callback; same event distinction |
| effect_runtime feedback | hp -= command.damage | Hostile projectile-contact or configured feedback event; guard targetHP>0 |
| effect_runtime fracture | hp -= command.damage | Hit proc after eligible chill, consumes chill |
| effect_runtime chain | hp -= command.damage | Generated chain command; targets iterated, can arise from kill/hit events |
| effect_runtime echo | hp -=12 | Hit/return-related command to selected target |
| effect_runtime phase | hp -=12 | Area command on configured event; alive targets only |
| effect_runtime thorns | hp -= command.damage | Hurt-related area command; player hurt can change playing state |
| effect_runtime.advance_hazards mine | hp -=24 | Early hazard pass; mine_detonate event can cause secondary commands |
| effect_runtime.advance_hazards scorch | hp -=6 | Early hazard pass; timed .35s tick |
| effect_runtime.advance_hazards trail | hp -=8 | Early hazard pass; optional slow separate |
| effect_runtime.advance_mortars | hp -= PrimaryDefense resolved | Early deferred blast; emits hit then mortar events |

Non-damage movement/status seams: pull moves targets toward center; push moves them outward; chill/slow modifies movement; hit spark/flash alone does not lower HP. Range checks should use the contract's specified current/clamped positions, rather than treating all these as HP interrupts.

Runtime death handling is one reverse traversal. kill event commands can affect an enemy at a higher index already examined. Pickup events run after that traversal and can reduce HP then. Thus present-but-dead target/source tests must use actual late events, not removal alone. No additional death flush should be inserted unless explicitly scoped as a legacy behavior change.

Source support HP snapshot can detect all actual numeric HP reductions while no path heals a source. The proposed target-only support heal therefore must categorically exclude every support source and the invariant must be tested. Event type labels and attempted damage are not equivalent to resolved positive HP loss. Healing player stats elsewhere does not invalidate the enemy-source invariant.

## Preimplementation correction after reading Effects.process in full
The earlier death-loop paragraph described a possible event-consumer ordering hazard, not a currently reachable kill/pickup damage proc. Actual baseline effects.gd kill branch emits only energyorb/playerheal; pickup emits chaincharge or creates a mine that damages on a later hazard pass. There is NO current kill-chain or immediate pickup enemy-damage command. Defensive same-step lateevent lethal tests must use an explicitly labeled test-only Effects subclass at real runtime event seams, while retaining actual EffectRuntime command execution. They must not be called existing production proc coverage or implemented as new gameplay. Original unexecuted wording preserved separately.
