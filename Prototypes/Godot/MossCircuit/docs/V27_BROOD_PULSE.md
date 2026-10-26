# v27 — Broodkeeper hollow pulse

Status: development candidate; final independent source, native and exact-pack acceptance pending.

This is one encounter behavior extension, not a new roster or global combat system. See [the frozen contract](V27_BROOD_PULSE_CONTRACT.md) for authority and limits. Only the existing Broodkeeper opts into `brood_cycle`; the old `summon` branch remains supported. Every alternate attack now creates an inward-safe pocket or an outward escape choice instead of another summon. It remains possible for other attacks or contact after recovery to hit inside that pocket.

## Implementation

- `enemy_ai.gd` selects pulse/summon from the existing attack index, consumes that turn at warning start and retains one-transition-per-tick timing.
- `combat_runtime.gd` pins the pulse center once after its ordinary field clamp. A pulse event attempts the existing hurt path once against the player's release-time center. It is not a hostile projectile and cannot trigger Feedback Diode.
- `annulus_geometry.gd` contains finite checked geometry and the shared 0.0001 world-pixel boundary tolerance. Telegraph fill is 96 band-only quads with the same center/radii; both boundaries are outlined. The inner hole is never painted as a filled explosion.
- The warning span informs ActorDirector progress; the existing 16-frame brace pixels, frame regions, scale and anchor remain untouched. Existing summon timing is still 0.65 s warning / 0.7 s recovery.
- The 0.2 s impact echo has no ticking damage. Death/result cleanup must not reconstruct the warning from a retained corpse-scene actor; paused menus retain frozen combat warnings.
- Field-guide copy describes both dangerous edges and the fact that other enemies still hit. No catalog, room layout, wave pool or RNG changes.

## Test preservation

The two older summon-specific fixtures explicitly choose attack index 1 to preserve their original child-limit, orphan, death and room-clear assertions. New tests separately exercise the natural first pulse and subsequent summon; this is not an assertion that Broodkeeper's old full trajectory is identical. Unaffected-actor traces and the full unchanged shop pool are compared to v26.

## Development findings retained

- An initial author import rejected an undeclared reduced-flashes variable; fixed to the existing settings object before the held QA snapshot.
- An initial author test used the wrong telegraph member name; corrected test access, not product behavior.
- Independent QA found a real terminal presentation defect: a living keeper warning could be reconstructed after player death. The narrow fix suppresses only annulus warning rendering in dead/won states; authority, pauses and old telegraphs are unchanged.

No ordinary gameplay, Windows, audio or final remote publication claim is made by this candidate document. Final evidence will distinguish controlled setup, ordinary inputs, exact packed checks and reachable Git objects.
