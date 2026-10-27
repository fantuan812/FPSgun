# v32 Amber Ram frontal brace — bounded contract

Status: contract specification frozen before implementation, not gameplay acceptance. Root confirmation is required before production edits. Base: accepted v31 final041b18785f18f745469ff157e0d1c686bc35ad40, immutable source4cc3c74a. One restored slim base at moss-v31-base; no import or production edits yet.

## 1. One existing encounter, no new roster or timer
- Only existing `charger` / Amber Ram opts in through `brace_degrees:120.0` and `brace_multiplier:0.5` in encounters.json. Update only its description/tell/dodge copy accordingly. All old numeric enemy fields, other records, waves/Rooms spawns, rewards, catalog, starting kits, economy and RNG formulas remain unchanged.
- Brace is active only for a living Amber Ram with valid opt-in data, `ai_state == "warning"` and `attack == "charge"`, using its existing locked `aim`. Existing warning0.65 s, charge0.6 s, recovery0.8 s and cooldown3.2 remain untouched. No new immunity, stun, animation timer, reflection, projectile, lingering hazard or damage source.
- Front is the full2D locked aim, not sprite horn/mirror direction and not the player's latest location. Movement, displacement, hurt-pose interruption, Cryo/resin and pause retain existing authority. Displacement moves the brace center with the enemy without retargeting aim.
- Side/rear, move, charging, recovery, invalid facing, absent data, other enemies and bosses take unchanged primary damage. Waiting for the opening or repositioning is the intended counterplay; no extra rear-damage bonus.

## 2. Exact geometry and fractional damage
- Shared pure resolver runs only at existing accepted primary-contact sites, after old range/collision/target eligibility. It neither discovers hits nor changes collision bounds, sorting, lifetime, pierce, per-leg quota, hit sets or return state.
- Existing target collision radius is `16 * scale`. A source point STRICTLY inside `radius - 0.0001` world units bypasses the brace. Exact circle boundary and the surrounding tolerance strip remain directional; this avoids turning a split-at-entry ordinary segment into a full-damage exception. This is a named strict-interior policy, not a vague overlap/center-only rule.
- Direction vectors must have finite components and length greater than `0.000001` world units; invalid/zero vectors fall back to full nominal damage, without events or exceptions. Invalid target geometry/facing/brace fields likewise fall back to legacy damage and cannot display an active brace.
- Outside the strict interior, normalize the target's locked aim and the attack's direction TOWARD its source. The closed front sector is ±60 degrees: reduced if `dot >= cos(deg_to_rad(brace_degrees/2)) - 0.000001`. The dot tolerance is separate from the spatial/direction tolerances. Exact angular edges count as front; tests include rotated edges and clearly outside offsets.
- Resolved nominal damage is existing primary damage after existing weapon/stat multipliers, multiplied by0.5 once for a guarded contact. No integer rounding, floor, minimum damage, HP clamp or additional scaling. Fractional HP is already supported. Preserve old overkill nominal-damage semantics.
- Never mutate a projectile's stored damage or a pending blast's damage: each target resolves independently. A piercing shot hitting a guarded enemy must still deal full nominal damage to a later unguarded enemy.

## 3. All eight weapon approach definitions
| Weapon | Source point for strict-interior test | Direction toward source outside interior |
|---|---|---|
| Rivet Gun | Actual current `hit_segment` start, including existing mount→muzzle launch bridge | Negative actual nonzero segment travel vector |
| Scrap Shotgun | Each pellet's actual segment start | Negative that pellet's actual segment travel |
| Rail Lance | Actual current segment start for each pierced target | Negative actual segment travel; Rail is an existing projectile, not a beam |
| Return Disc | Actual current outbound/return segment start | Negative current segment travel, including newly aimed return direction, never original launch direction |
| Bankshot Driver | Current leg segment start (`b.pos` before existing contact callback) | Negative current `(dx,dy)` for that reflected/guided leg, never original launch/player direction |
| Orbit Saw | Current player center when the immediate attack resolves | Player center minus target center |
| Cryo Sprayer | Current player center when the immediate cone resolves | Player center minus target center |
| Shock Mortar | Existing fixed blast center at explosion | Blast center minus target center, not launcher/muzzle position |

- A zero-length ordinary segment is full damage; its existing hit eligibility is unchanged. Ordinary advance_bullet(b,0) can still process a nonzero mount→muzzle launch bridge (Return also uses it), so dt0 is not a global no-damage rule. Bankshot already ignores nonpositive dt/zero-distance damaging segments and that remains unchanged. A positive segment beginning strictly inside the body is full by the rule above; exact boundary is directional.
- Point attacks whose source lies in the strict interior defined above (including coincident center) are full; exact boundary/tolerance strip stays directional. Direct-center mortar therefore bypasses the frontal brace, while an off-center blast can be reduced according to its center. No blast-radius or targeting change.
- No source position/angle is inferred from visual sockets, sprite flips, latest player position for in-flight shots, or another weapon's launch.

## 4. Preserve actual shared phase order and proc authority
- Do not reorder simulation. Immediate Orbit/Cryo and due mortars resolve before EnemyAI.tick; ordinary/Return/Bankshot contacts resolve afterward. Evaluate the target's actual state at each damage site. One dt crossing warning→charging can reduce an earlier instant hit but not a later projectile contact. Do not add catch-up hits or interpolate a new defense timeline.
- Apply resolved nominal damage, set existing last_source=primary, then retain the existing single hit event and all old sequencing. `hit.damage` is resolved nominal damage, NOT remaining-HP loss. Cryo still applies chill only if the target survives its resolved damage, before its old hit event.
- A guarded contact still counts as one normal primary hit for existing Echo/Arc/Blood/Fracture/phase and hit quotas/ICDs; no extra defense event, recursion, refund or proc immunity. Existing kill/death/reward attribution follows actual resulting HP as before.
- Secondary damage is not passed through the brace resolver. Fixed Fracture16, Echo12, Feedback24, hazards, retaliation and other secondary sources retain their existing values/depth rules. Arc remains derived: its existing40% of the initiating hit uses the now-resolved primary damage, then the chain target is NOT reduced a second time by brace. Do not call every secondary amount fixed.
- New brace outcomes can naturally change kills/progression; no same-outcome/RNG-stream promise for those altered fights. With brace absent/inactive, old authority/RNG/event projections must match exactly. No new RNG call or shop-affinity/catalog change.

## 5. Data boundary and presentation
- New fields are paired, finite numeric values (bool/string/array/object/nonfinite rejected); `0 < brace_degrees < 180`, `0 < brace_multiplier < 1`. Only current charger with behaviorcharge/nonboss may opt in; no general arbitrary-defense configuration engine. Current authored values are exactly120/.5. Missing fields retain the old path; one missing field or invalid pair fails startup validation.
- Reuse unchanged charger_charge warning frames0–3 honestly as the existing horn-first brace/anticipation pose; no new raster or animation/action manifest edit. Sprite has only horizontal mirroring, so the procedure cue is authoritative for vertical/diagonal front.
- Draw one unfilled pale steel/lavender frontal arc aligned to the same locked aim/angle, with dark outline and short end ticks. Proposed visual radius `32*scale` is a readable indicator, NOT a new collision/shield surface or projectile interception point. No filled disk, green safe side, glow wall or orange overlay that competes with the unchanged charge lane.
- Cue exists only while the living actor's brace is active; hide new cue in title/dead/won and on removal/reset. Pause/menu freezes retain the current marker without advancing timers. Existing other telegraphs remain unchanged. No new hit flash/event/state is required; reduced-flash mode keeps the same steady cue.
- Enemy guide describes the half-primary front during warning, flank/wait counterplay and existing contact-safe warning/recovery. Detailed docs explain strict-interior and derived-secondary exceptions; do not imply universal armor or all-direction damage immunity.

## 6. Finite acceptance before release
- Pin exact v31 baseline and old non-brace shared traces/shop draws. Preserve old records except two new charger numeric fields and three reviewed copy fields. Test all malformed new field types/ranges and runtime fallback inputs.
- Pure rotated geometry: front/rear/sides, exact±60 edges/outside, radius−EPS/exactradius/interior, zero/nonfinite source/facing, both modes/field sizes. Unsplit vs exactly-at-entry split ordinary contacts across8rotations; retain old Bankshot contact tolerance and test reflected/guided legs. No full moving-world dt-equivalence claim.
- Actual shared paths for all8 weapons, pierce into guarded then unguarded targets, distinct shotgun pellets, Return direction reversal, Bankshot reflected/guided direction, centered/offcenter mortar, fractional/overkill nominal events, Cryo survivor/chill, Fracture/fixed/derived Arc and primary/secondary kill attribution. Test warning→charge dt boundary at both pre/post-AI sites, pause/hurt/displacement/death/reset cleanup.
- Native both modes at960×540/1280×720: near-vertical/up/down/diagonal aim, both sprite facings, hurt→warning return, orange charge lane and other warnings overlap, reduced flashes, guide text. Source appearance review before exact PCK; no physical-controller/audio/Windows claim.
- One finite ordinary default-Rivet Rooms seed128 route toward existing Room2 Amber Ram, no spawn/state injection or forced victory. Observe actual cue if available; do not infer exact damage from stills or repeat campaigns to manufacture evidence. Controlled/packed numerical proof stays separate.
- Then exact full source/packed suites, unchanged-executable PCK, helper/manual rollback and expected-head/nonforce GitHub publication with fresh byte proofs. No attachments, full historical recopy or new subsystem.
