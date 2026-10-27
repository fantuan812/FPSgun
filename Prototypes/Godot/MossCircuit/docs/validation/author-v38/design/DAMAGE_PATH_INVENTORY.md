# Pre-contract v37 actual HP-loss path inventory

Read-only baseline, not executed test evidence. All writes below target an enemy Dictionary's hp, not VFX. No existing enemy HP increment/heal path was found in scripts; spawn initializes/scales HP only. Proposal excludes source drone from all new heals, making channel-start HP a monotonic loss witness under supported gameplay.

| Actual seam | Channels to cover in runtime oracle |
|---|---|
| weapon_combat.gd:39 | Orbit primary, after PrimaryDefense.resolve |
| weapon_combat.gd:91 | Cryo cone primary, resolved loss separately from chill |
| weapon_combat.gd:114 | Shared segment: bolts/pellets/rail/return outbound/return inbound, after resolve |
| weapon_combat.gd:176 | Bankshot callback, after resolve |
| effect_runtime.gd:165 | Delayed mortar, after resolve |
| effect_runtime.gd:38 | Feedback command direct HP subtraction |
| effect_runtime.gd:49 | Fracture command, after can_fracture and chill consumption |
| effect_runtime.gd:74 | Chain command each living selected enemy |
| effect_runtime.gd:82 | Echo command direct 12 |
| effect_runtime.gd:89 | Phase command radius, direct 12 |
| effect_runtime.gd:108 | Thorns command radius damage |
| effect_runtime.gd:144 | Mature mine blast direct 24 |
| effect_runtime.gd:153 | Scorch tick6 / trail tick8 (two kinds, one write) |

Interruption means positive actual loss of **source drone HP** after its channel-start snapshot. Target ally damage alone does not interrupt: surviving wounded ally can still be repaired. Lethal target damage invalidates repair; no resurrection. A visual hit, missed shot, zero resolved loss, mere chill/slow, pull or push without loss does not constitute damage interruption. Pull/push may separately invalidate distance at the defined final observation. Damage before this channel's start is not retroactive. New source may never heal itself or another support source, including via simultaneous support intents.

The existing death loop can emit kill procs and pickups can emit later procs. Therefore source/target living identity and source HP witness must be rechecked after both loops, not only at AI warning expiration. Existing older attack/death ordering is not changed or claimed globally fixed.

Oracle matrix must exercise real loss seams, not inject only VFX or rely solely on the new pure policy; equivalent shared projectile paths may use separate concrete weapons with original hit assertions. The snapshot assumption is intentionally limited to current enemy-health authority. Future enemy regeneration would require a loss counter or explicit damage event before broadening this contract.

C3 scope correction: the earlier phrase 'death loop can emit kill procs' describes the event seam, NOT an existing damaging kill proc. Actual effects.gd kill emits orb/player heal and pickup charge/new mine; neither immediately damages enemies. Late kill/pickup HP-loss controls must be explicitly fault-injected via a test-only engine into real EffectRuntime, separate from genuine currently configured damage routes. No new production proc is proposed. Existing pickup mine maturity remains unchanged.
