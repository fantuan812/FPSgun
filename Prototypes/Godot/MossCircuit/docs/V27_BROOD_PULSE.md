# v27 — Broodkeeper hollow pulse

Status: accepted within the finite source, controlled native and exact-resource-pack scopes below. Remote publication is established separately by immutable version records and byte readback.

This is one encounter behavior extension, not a new roster or global combat system. See [the frozen contract](V27_BROOD_PULSE_CONTRACT.md) for authority and limits. Only the existing Broodkeeper opts into `brood_cycle`; the old `summon` branch remains supported. Every alternate attack now creates an inward-safe pocket or an outward escape choice instead of another summon. It remains possible for other attacks or contact after recovery to hit inside that pocket.

## Implementation

- `enemy_ai.gd` selects pulse/summon from the existing attack index, consumes that turn at warning start and retains one-transition-per-tick timing.
- `combat_runtime.gd` pins the pulse center once after its ordinary field clamp. A pulse event attempts the existing hurt path once against the player's release-time center. It is not a hostile projectile and cannot trigger Feedback Diode.
- `annulus_geometry.gd` contains finite checked geometry and the shared 0.0001 world-pixel boundary tolerance. Telegraph fill is 96 band-only quads with the same center/radii; both boundaries are outlined. The inner hole is never painted as a filled explosion.
- The warning span informs ActorDirector progress; the existing 16-frame brace pixels, frame regions, scale and anchor remain untouched. Existing summon timing is still 0.65 s warning / 0.7 s recovery.
- The 0.2 s impact echo has no ticking damage. Death/result cleanup must not reconstruct the warning from a retained corpse-scene actor; paused menus retain frozen combat warnings.
- Field-guide copy describes both dangerous edges and the fact that other enemies still hit. No catalog, room layout, wave pool or RNG changes.

## Test preservation

Two older summon-specific fixtures explicitly choose attack index 1 to preserve their original child-limit, orphan, death and room-clear assertions. The older authored-versus-fallback art fixture explicitly uses the retained legacy summon behavior on both sides, preserving its original child-count and death assertions. New tests separately exercise the natural first pulse and subsequent summon; this is not an assertion that Broodkeeper's old full trajectory is identical. Unaffected-actor traces and the full unchanged shop pool are compared to v26.

## Development findings retained

- An initial author import rejected an undeclared reduced-flashes variable; fixed to the existing settings object before the held QA snapshot.
- An initial author test used the wrong telegraph member name; corrected test access, not product behavior.
- Independent QA found a real terminal presentation defect: a living keeper warning could be reconstructed after player death. The narrow fix suppresses only annulus warning rendering in dead/won states; authority, pauses and old telegraphs are unchanged.

## Bounded acceptance

- Author final source: 83 standalone entries plus import, no tested input changes. Independent production first cold import and final reused-cache revalidation are distinguished; final 83 plus import pass with all 581 source inputs unchanged. Python safety 3/3.
- Independent actual shared runtime: 948/948; exact masked roster/type validation: 45/45. Full unchanged shop pool 800 draws and 3,200 unaffected-actor/build steps equal v26. Broodkeeper trajectory intentionally changes.
- Packed resource reader: 835 checks. The new author/independent mechanism scripts also execute against packed `res://` from an empty reader directory; no source fallback. Both platform preset packs are byte-identical, using the unchanged previously accepted executable.
- Controlled native: both modes, actual 960×540/1280×720, 32 geometry views plus 13 phase/hurt views and two guide views. Fixtures are injected setups, not ordinary acquisition. The empty hole, fixed displaced-center tell, overlap and reduced-flash scopes are explicit.
- Ordinary exact Linux pack: one seed 2701 Rooms run, automated CUA keyboard/mouse and tactical pauses, no build/currency injection or programmatic state control. First hollow warning observed in room 3; afterward player outside at 140/140 HP. Starter Rivet kills the keeper before a clearly captured second summon. Direct CIRCUIT COMPLETE, Room 3/3, LV 4, 11 kills, one Rivet/no modules. No ordinary exact 11-damage or complete-cycle attribution inferred.
- Returned to title, then external terminal Ctrl+C; window absence and artifact hashes verified. This is not an in-game graceful-quit claim. Native ALSA ERR_CANT_OPEN/dummy audio and unsupported VSync remain explicit; no XServer BadValue in this run. No Windows runtime, audio, long-term balance or all-hardware guarantee.

PCK SHA-256: `dae99ca5e7b967a6cc7d6493f7a662cd8927f4009fd17049619983a846cfde89`, 41,352,052 bytes. The earlier v26 artifact remains distinct and unchanged. Independent consolidated evidence and author/export receipts are under `docs/validation/independent-v27`, `author-v27`, and `export-v27` respectively.
