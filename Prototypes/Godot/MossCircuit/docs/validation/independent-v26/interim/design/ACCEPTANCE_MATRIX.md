# v26 Feedback Diode — independent frozen acceptance matrix

Baseline: accepted v25 source commit `902e2d53b813858346e5a17a3c410ba8cf465876`, final archive commit `0b5ebcd486103f659406cf324dd02cb63f6ef257`. Existing local workspaces were absent on resumption; no QA deletion occurred. Programmer owns one slim recovery. No runtime import or candidate copied yet.

Scope: one unique module giving once-per-dash, fixed secondary feedback to the living owner of a hostile projectile actually intercepted under the existing collision/immunity rules. Frozen: damage24/price28, IDfeedback_diode, unique1, mobility tag; CROSSCURRENT is complementary with Pulse Boots and adds no hidden bonus. Exact accepted contract SHA2560a49709356c610741c47cf3d22b82c17fb92cf79ef02f4b9472f0eec84dc1211. No extra immunity, projectile physics, enemy timing, audio, networking or dungeon implementation.

## A. Acquisition, state and clocks
- Arm only on an accepted CharacterMotor dash start with module owned. No movement, cooldown-blocked request, repeated held input during cooldown and module acquisition during an existing dash do not arm.
- Use exactly post-motor `stats.dash_time > 0`, the current immunity gate. Exact zero is expired; positive remainder is eligible. Existing swept hostile-shot contact is strictly distance<12 to the post-move player position; do not claim new relative-motion collision physics.
- One discharge per dash. Multiple same-frame valid contacts follow existing reverse-array traversal, not a new geometric contact-time sort. Invalid/dead-owner projectiles cannot produce a hit. Preserve prior removal behavior.
- Pause, inventory, settings and focus loss freeze the allowance/window; resume and effect epoch invalidation do not replenish it. Sale clears allowance; rebuy/sync cannot arm the same dash. New stage/run/result cleanup removes pending state and visuals.

## B. Actual shared combat pipeline
- Both Arena/Rooms: actual Shooter and Core ring bullet emission, owner IDs, segment collision, dash immunity and feedback damage. Living original owner receives the hit, not the closest enemy. Contact, Warden blast, ordinary hurt-clock immunity and Mirror Shell blocking outside dash do not trigger.
- Owner killed by earlier primary/hazard is filtered under existing rules. Feedback killing an owner uses deferred common death cleanup, removes owned hostile bullets, grants ordinary XP/scrap/kill/boss rewards exactly once, and does not mutate the array unsafely during iteration.
- Damage is fixed secondary and unscaled by weapon damage/range/rate/pierce bonuses. No new primary hit event; Echo count, Arc cooldown, Phase charge, Fracture mark, Blood Valve, Return Spool and Kill Cell must not proc from feedback. Mine-only healing must remain mine-only.
- Mirror Shell stays unspent and hurt_clock/HP unchanged by an already dash-immune interception. Simultaneous projectile, contact and blast cases retain old immunity behavior.

## C. Catalog, build and non-regression
- Exactly8 old weapon IDs and28 old module IDs remain, plus one new exact module ID. Unique cap1, correct price/slot handling, repeated buy/sell and full-slot failure are transactional/read-only where required.
- Affinity can favor the new meaningful companion, but no hidden multiplier is implied. Old pool semantics are tested after explicitly excluding the new entry/link; normal seeded offers may legitimately change.
- No-Diode old weapon/module definitions, shared combat outputs, RNG and preferably event sequencing match v25 on a finite identical trace in both modes. If only new inactive fields differ, state an explicit old-schema projection rather than claim whole-state byte identity.
- Invalid new tuning/type inputs reject safely. Existing validation/tests must not weaken exact ID-set coverage.

## D. Rendering and exact artifact
- One original module icon, distinct from cyan Fracture/amber Guide; no new weapon mount or enemy sheets. Actual native shop/inventory at960x540 and1280x720, both modes, including first BUY visibility and full-slot warning.
- Controlled native projectile interception shows a brief readable feedback link to the real owner and owner impact; ordinary orange danger tells remain dominant. Reduced-flash setting retains an understandable low-flash cue. These are explicitly controlled fixtures, not natural acquisition evidence.
- After source gates: one immutable exact Linux export, ordinary input first-shop acquisition and a directly observed feedback counter against a shooter. Offline seed planning and automated CUA/tactical pause are disclosed; no build/state injection. No full campaign required for this bounded gate. Windows is artifact-only without an authorized Windows host.
- Keep proofs compact, no duplicate full archives. GitHub-only deliverable after exact source/runtime and remote-byte checks; no user attachments.

Stopping condition: agreed mechanic implemented, finite actual-path and UI gates pass, exact exported ordinary acquisition/counter observed or a concrete blocker recorded, and approved deliverable is reachable on GitHub. Defeat is valid observed behavior, not permission to force victory or silently change balance.
