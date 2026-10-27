# Authored pre-target additions declaration

No target executed. This table is a design declaration for static approval, not an expected value learned from runtime output.

New row exact identity: id stitch_drone, name Stitch Drone, behavior support_repair, boss false, color86e5ed. Base HP34/speed30/contactdamage6/XP7/scale1/desired_distance210; cooldown5/warning1.2 are compatible generic fields, actual support spans owned by six support_* fields. Required generic unused constants retain the existing ordinary row conventions: projectile_speed145, charge_speed310, charge_duration0.6, summon_limit3, phase_threshold0.5, phase_speed1.25. These do NOT grant shooting, charging, summons or a boss phase; AI exact support branch only moves, shared support phases own repair. New fields radius150/channel1.2/cooldown5/retry1/heal10/max_alive1.

Description: Channels a 10 HP repair to one wounded ordinary ally within 150 px. Cannot repair bosses, summons or support drones.
Tell: Cyan dashed tether and four-notch progress mark a 1.2 s repair; any actual damage to the drone interrupts it.
Dodge: Hit the drone, finish its ally or separate them beyond the tether. It has no damage immunity. Warning and recovery are contact-safe.

One row append only. Arena wave4 exact ordered pool charger/spitter/flanker/stitch_drone. Room stage2 and3 append {kind:stitch_drone,at:[0.5,0.18]} after their four exact existing rows. No old row, wave, boss, room reward/field/interval or other stage change. Raw room formatting retained except the two explicit append strings. Encounters original2space formatting retained except the new row and new wave4 tail. Original historical raw SHA and masked roster SHA are not replaced.
