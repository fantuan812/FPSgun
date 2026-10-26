# Bankshot / Bounce Guide — independent acceptance matrix

Status: pre-implementation expectations, not test results. Final accepted contract SHA256: `6ab8d52ce84e092fe90bc1a80f97d0510c6bd39230d4873db975ae4a18b30ba6` (accepted status and cumulative-progress clarification incorporated; prior reviewed text `0c3f584d…`). The earlier `EXPECTATION_MATRIX.md` is retained as proposal history and is superseded by this document where wording differs.

## Frozen interpretation

- Add only `bankshot_driver`, `bounce_guide`, and their `banked_vector` pair. Initial tuning: 18 damage, 0.85 s interval, one projectile, base quota 1, 900 center-based acquisition and 900 total traveled distance, price 42; Guide price 26, unique max 1. This is not a balance endorsement.
- Only the shared rectangular field boundary is reflective. There are no arbitrary wall colliders or interior obstacles. Edge positioning is the intended tradeoff; center-field return payoff is not promised.
- Damage, speed, distance, quota and Guide ownership snapshot at launch. Current speed is 470. TTL is budget / speed in combat time, never refreshed. Existing damage/rate/range/pierce apply; pellet/electric/melee bonuses do not. Range scales the acquisition radius and single travel budget once each. Quota is clamped to 1..6 per leg.
- Two reflections create at most three damage legs. A third boundary encounter absorbs. A spent leg continues visibly but cannot damage. A genuine separated return can hit the same enemy again; within one leg it cannot.
- Clamp an outside muzzle without a damaging launch bridge. Zero aim uses RIGHT. On a positive advance, an initial outward boundary contact is resolved before damage. dt <= 0 is inert. Invalid/nonfinite movement is rejected or safely expires.
- For a positive segment, enemy-circle first contacts are ordered by distance then ID through the endpoint, before any tied boundary event. Recheck living status after prior effects. At travel-budget exhaustion, endpoint hits occur, then expiry without a free reflection or Guide attempt.
- Exact corners combine both axes as one reflection. Spatial epsilon is 0.0001 world units. After a reflection, a new boundary encounter requires cumulative positive travel since that reflection greater than epsilon; otherwise absorb before new-leg damage on that insufficient-progress segment. This is not a per-frame minimum: small valid time subdivisions must not spuriously terminate a shot.
- Carry only IDs damaged on the just-ended leg that still overlap the reflection point, plus already blocked overlapping IDs. Untouched overlaps remain eligible. A block consumes no quota and releases when strictly outside its current circle with tolerance. Frozen poses during an advance permit skipping a start-inside blocked circle until segment exit; no continuous moving-target solver is promised.
- Guide makes one direction choice at the first reflection only, including an initial permitted zero-time reflection. Search current living, unblocked centers strictly inside the field, reachable with remaining distance, and strictly inward on all contacted axes. Distance then ID ties; no candidate means ordinary reflection and opportunity consumed. No homing, extra damage, extra projectile or RNG.
- Actual contacts emit ordinary primary hit events. Existing on-hit/on-kill cooldowns, secondary-depth rules and Cryo/Fracture ownership apply. Secondary effects never spawn ricochets or boundary events.

## Finite independent gates

| Gate | Cases | Evidence required |
|---|---|---|
| G1 Geometry | Arena 1440x960 and Rooms 960x640; all sides, exact corners, distinct near corners; inward/outward/tangent and clamped launches; large and subdivided dt | Analytic no-enemy trajectory vectors plus actual helper/shared-runtime outputs; no out-of-field damage, no loop |
| G2 Lifetime | Exact budget endpoint enemy/boundary; just-inside/outside; range bonus once; zero dt; invalid values; third boundary | Travel and TTL monotonic, no reset/free endpoint reflection; controlled early absorption labeled |
| G3 Quota/order | Quota 1 and 6; spent continuation; up to 18 contacts; center-distance vs circle-entry ordering; exact ID tie; proc-killed later candidate | Recorded primary events and remaining quota; no fake event for skipped target |
| G4 Overlap | Hit circle spanning boundary; untouched overlap; existing blocked overlap; leave then genuine return; dead/moved target; corner/tiny-progress guards | No zero-travel repeat proc; untouched target not suppressed; quota unchanged by exclusion |
| G5 Guide | Absent/present; nearest and ID tie; no candidate; center at/outside edge; unreachably far; blocked target; corner inward condition; empty first but valid second | One actual direction selection, fallback consumed, no continuous retarget; RNG unchanged |
| G6 Snapshot | Change damage/speed/range/pierce and add/remove Guide after firing | Existing projectile unchanged; newly fired projectile reflects current build |
| G7 Interactions | Real Cryo mark then Bankshot primary/Fracture; Echo/Arc/Valve/Kill Cell; lethal primary vs secondary; existing cooldown/depth | Actual shared event pipeline, not just fabricated effect calls; no recursive projectile production |
| G8 Transactions | Buy, full-slot replacement, unique Guide, sell, retry/new seed/mode reset; pair inactive/active states | Actual transaction authority and UI snapshots; stale callbacks rejected; projectiles reset |
| G9 Preservation | Exact old IDs + two additions; exact old definitions except approved v22 four-field copy; old filtered shop and finite combat/RNG traces | Strict allowlist, declared old-schema projection, not broad field masking; expanded unfiltered offers may differ |
| G10 Native presentation | Both modes at 960x540 and 1280x720; armed/spent/contact/corner/Guide cue, field limits, enemy tells, reduced flashes; actual small icons/mount | Unedited game-window captures and bounded live observations; injected layouts labeled controlled |
| G11 Final export | One final immutable Linux ELF/PCK, ordinary acquisition and observable boundary interaction | Exact artifact hashes, normal automated CUA controls; no injected build/source substitution. Windows artifact-only without a host |

## Stop conditions and limits

Report reproducible discrepancies immediately and preserve rejected inputs/logs. Do not quietly change expectations to fit implementation. Candidate revisions require new fingerprints and rerunning affected gates. Frozen-enemy geometric time subdivision does not imply complete moving-AI/proc-clock partition equivalence. No full campaign, balance/fun certification, every build combination, Windows execution, or audio claim is required by this bounded batch. Source/artifacts from prior versions remain immutable.
