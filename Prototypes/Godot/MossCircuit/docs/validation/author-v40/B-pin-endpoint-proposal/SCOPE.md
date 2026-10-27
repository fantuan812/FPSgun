# B Pin / A ring discrete endpoint integration clarification
Design checkpoint accepted 2026-10-27 12:49; independent QA sequence oracle pending. Not applied to original883/894 or A.

Only successful real Pin control updates `world.new_weapon_motion[target_id].final_pos` if a motion record already exists. p0/p1/has_segment and all age/dt/radius/Geometry/A-runtime code unchanged. No record: do not create one; existing A wave fallback uses actual enemy.pos. Failed control/dead target does not update a record, and nothing revives targets.

Original A ring contact priority retained: normal P0→P1 movement can already yield a legal hit and is never undone by later control pulling the target out. Only when normal trajectory did not hit does existing per-leg actual_end gate permit endpoint-only testing. A wave/leg already expired before actual dt end cannot project a later endpoint backward into its lifetime.

Independent cases required before execution: endpoint pulled into band; endpoint pulled out with no earlier ordinary contact; control chord crosses band but endpoint does not (no sweep); expired leg rejects endpoint; dead target; multiple overdue beam pulses and only one legal Pin pull; ordinary segment hit preserved despite subsequent endpoint pull-out. Use true EffectRuntime bridge / NewWeaponRuntime ordering, not helper output as generated expected. Pure647 remains unchanged and cannot prove this integration.
