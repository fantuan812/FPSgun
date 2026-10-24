# Core reaction-only final batch contract — v15

Baseline: published v14 `51a6f3ce4ae91e08212c7675df9a9f21620fee9f`.

## Bounded scope and closing statement

Add only `boss_core_hurt`9 poses/0.27s and `boss_core_death`16 poses/0.72s plus manifest/profile integration, verification and documentation. Reuse the existing nine-frame Core attack for both ring and summon. No new attacks, phase policies, projectile behavior, reward, room roster, timing, runtime `.gd` changes or balance changes. This closes the authored hurt/death reaction coverage for the seven existing enemy archetypes; it does not complete the entire game, individual attack animation variants, live-GUI gameplay feel, export QA, or accessibility playtesting.

## Real Core authority

Core selects phase2 at HP≤50%. It maintains desired distance230 with a±30 deadband; base move speed25 becomes×1.25 in phase2. Attack cooldown is3.4 seconds, or3.4/1.2 in phase2. Neither warning0.85 nor recovery0.7 shortens.

The selection rule uses the pre-increment attack_index: phase1 always chooses ring; phase2 chooses summon only when index%3==2, otherwise ring. It is NOT a simple ring/summon alternation. At warning expiry, the then-current phase determines ring count8/12 or summon count1/2; therefore crossing50% during warning can change release count. Ring projectiles are emitted once with owner Core ID, speed145, damage15, lifetime4, and directions TAU×index/count+0.13. Summons are crawler spawn requests limited by this parent's living children to a maximum3 (global enemy capacity still applies). Unrelated/dead children do not consume the parent-local budget. No new visual callback may emit projectiles or spawn children.

## Reactions and lifetimes

Real HP loss starts hurt presentation. It may mask the warning/release/recovery visually but must not cancel, delay, freeze or replay it. Repeat hurt during active hurt does not restart the0.27s clock. On completion, show the current phase. Reduced-flash mode suppresses bright tint, not the pose sequence. Death overrides all reactions, immediately removes the parent from combat and clears that parent's hostile bullets, and leaves a0.72s presentation-only corpse. No pending ring or summon may occur after death. Repeated death/reward callbacks are idempotent.

Already-living crawlers are NOT killed when the Core parent dies. Arena wave6 still needs its time gate plus mandatory boss defeat; early death leaves children active, while normal terminal settlement clears the battlefield and wins even with living children, without waiting for the visual corpse. Rooms have no native Boss roster; manual injection is a test fixture. In rooms, surviving children remain part of the living-enemy clear guard. Core reward is100 coins plus the existing trophy and defeat flag, not Warden protocol/HP repair. Subsequent pickup/settlement awards remain separate and unchanged.

Pause and existing modal states retain their existing presentation-clock semantics; restart/title clear tails/generation. Corpses must expose their final frame before recycling, cannot double-credit kills or block clear checks, and remain under existing corpse cap.

## Hover visual contract

Core is a floating bronze/moss reactor ring with a cyan-green center, purple accents and trailing roots, not a standing machine with feet. ActorDirector.base_foot is only the existing logical registration point. Do not claim it proves physical ground contact. Keep each action on one fixed logical canvas, fixed source-column centers, fixed per-action scale/reference_height/anchor, and explicit fixed source-row coordinate offsets. Do not normalize every pose by bounding-box center/size or automatically force all tail ends to a baseline. Preserve visible hover/recoil and intentional descent; review the reactor-ring/core-center, upper silhouette and lower-envelope trajectories across source-row transitions. Death should lose power and descend/collapse to a resting wreck without attack rings, explosions, summon creatures or gameplay tell VFX baked into it.

## Gates

- Exact unchanged runtime/old-attack/balance hashes and exact profile-only additions.
- Both modes, both phases, threshold crossing during warning, actual8/12 ring and summon counts under hurt, parent-local caps, no duplicate event after hurt expiry.
- Lethal ring/summon warning, recover and move; owner projectile cleanup versus child survival;100-coin/trophy idempotence; mode-specific terminal/clear gates, pause and restart.
- Distinct9/16 poses, safe import/regions, logical anchor/first-pose continuity in both facings, reduced flashes and real frame clocks; independent static source inspection.
- Published v14 versus candidate and final ZIP deterministic state/RNG traces; final isolated cold import/full suite and ZIP CRC/manifest/history checks. GUI/Windows gameplay remain explicitly unperformed.
