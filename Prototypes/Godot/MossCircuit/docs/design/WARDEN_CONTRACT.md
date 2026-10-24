# Warden reaction-only contract — approved bounded v14 batch

Baseline: published v13 commit `56a6c721850fc3ef67caa0f766661a3970eb6a59`.

## Scope

Only `boss_warden_hurt` (9 independent poses, 0.27 seconds) and `boss_warden_death` (16 independent poses, 0.72 seconds), plus manifest/profile integration and tests/documentation. Existing nine-frame Warden attack is reused unchanged for charge and blast. No new AI attack variants, combat events, gameplay delay, physics, stats, phase thresholds or reward rules. Core is out of scope. Ideally every runtime `.gd` remains byte-identical.

## Authority

- Warden alternates charge then blast via pre-increment attack_index parity. Warning is 0.85 seconds. At warning start, aim and ground-blast target are captured once by EnemyAI.
- Warning and recovery are contact-safe. Move and charging can cause contact damage at distance <16×2.6+9. Contact attempt remains subject to player hurt cooldown/dash immunity.
- Charge warning ends by setting charging, charge_left=0.6. That transition tick does not move; following charging ticks move by aim×310×min(dt,remaining). Charging then becomes recover_left=0.8. No projectile/blast is emitted by charge.
- Blast warning ends by emitting exactly one blast at stored target, radius105, damage18, then recover_left=0.7. Renderer must not anticipate, delay, repeat or supplement this event.
- HP≤50% selects phase2; move speed×1.25 and the next scheduled cooldown becomes3/1.2 seconds. Warning duration, charge duration/speed and recovery durations do not shorten. Existing phase re-evaluation each tick remains unchanged.

## Reaction priority and interruption

Hurt is presentation only: it overlays move/warning/charging/recover/attack but does not freeze their clocks, position, aim or release. Repeated hurt while a hurt reaction is active does not restart it. At 0.27s it reveals the *current* authority phase; do not replay hidden warning or blast. Death immediately overrides hurt and is terminal for that actor. Existing reduced-flash option removes bright hurt tint, not hurt frames.

## Death, rewards and transitions

Combat removes a dead enemy on the authoritative simulation tick, emits kill effects/pickup exactly once, clears owned hostile bullets, grants boss reward once, and starts only a visual corpse tail. A dead Warden must not complete a pending warning, move, contact-hit, blast, or consume gameplay RNG afterward. Death art lasts0.72s on the existing presentation clock, displays frame15 before recycling, and is bounded by the existing corpse cap.

Warden reward remains protocol (+25 max HP/+10% damage),50 coins and the existing caller repair. The arena wave gate remains elapsed wave time plus mandatory boss defeat; it must not wait for corpse animation. Room mode currently has no native Boss roster; manual Warden injection is a regression fixture, not a new room feature. Stage settlement preserves existing corpse tails with clear(true,true). Existing shop/upgrade/pause states freeze these visual clocks until playing resumes; this batch does not redesign that behavior. Restart/title clears tails and prevents stale completion effects.

## Geometry and art evidence

One PNG per action, fixed logical canvas≤4096², safe integer region/margin records, fixed per-action reference_height and anchor. Fixed source-column centers and common source-row registration must preserve within-row shifts/lift; no per-frame bounding-box scale normalization or automatic pose centering. Source images, provenance and explicit registration facts must be retained. No attack VFX, damage flashes, extra weapons or blast circles baked into reaction art. Static raster inspection is not GUI playback or Windows export acceptance.

## Verification gates

1. Exact v13/v14 authority-source hashes and full finite deterministic traces (all enemy fields/events, both modes, RNG and damage).
2. Warning, charging, both recovery branches: hurt interruption at start/mid/release boundaries, with same underlying event timing and no replay.
3. Lethal interruption during warning/charge/recovery; combat removal and reward once; wave settlement independent of animation; pause/restart/death-cap safety.
4. 9/16 distinct source poses, safe imports, actual frame progression, first-pose scale and anchor continuity both facing directions, preserved source registration, reduced flashes, and no duplicated frame padding.
5. Final cold import/full tests from immutable delivery ZIP; CRC, manifest SHA, old-history retention; no GUI/Windows claim.
