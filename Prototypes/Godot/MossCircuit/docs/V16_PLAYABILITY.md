# v16 · Input safety, readable objectives, distinct Warden charge

Baseline: v15, GitHub commit `14ebe583f911b66f36200d05e886fe6e0176c456`.

## Changes

- Typing a run seed now retains that integer when visiting Display Settings or
  Enemy Field Guide and returning to the title. The game still uses its existing
  integer parser; this is not a new seed-validation system.
- Escape closes Display Settings to its entry screen. Settings opened from a
  paused run return to pause, not directly to live combat.
- Losing application focus pauses active combat or the room-clear transition.
  Restoring focus never automatically resumes. Existing shop, upgrade, inventory,
  title and result states remain unchanged.
- Mode objectives and room-clear badges are placed below the actual measured HUD
  rectangle. This fixes their partial overlap when font/container minimum sizes
  exceed the old authored offsets.
- Charge warnings retain their exact swept endpoints/width but use a translucent
  interior and strong outline, so the prep pose and ground remain visible.
- Warden charge now has a distinct 16-pose braced-forward animation. Blast retains
  the old two-fist slam. No enemy AI, movement, hit test, damage, spawn, reward,
  economy or RNG rule changes are part of this batch.

## Charge presentation contract

`ActorDirector` selects an optional attack-only profile from the observed enemy
`attack` while its authoritative state is warning, charging or recovery. Unknown
variants and ordinary movement use the original profile. Reaction resources are
not overridden: the existing Warden hurt/death contracts remain shared.

For charge, warning uses frames 0–5, real charging uses 6–11, and recovery uses
12–15. All progress comes from existing AI timers. The frame-6 release does not
cause movement or damage. Actual locked aim controls facing; crossing the boss
cannot flip its already-committed charge toward the player. Contact cannot restart
this phase-driven clip. Hurt masks the current pose and then reveals the current
AI phase; it does not pause, rewind or replay charge. Death remains terminal.

See [the source-art record](art/warden_charge/README.md) for fixed canvas, source
partitions, mirror-safe anchor and unmodified PNG provenance.

## Tests and acceptance boundaries

- `test_input_lifecycle.gd`: 20 checks. Before the fix, nine checks failed; after,
  all pass. Notification dispatch is not by itself proof of OS focus behavior.
- `test_hud_layout.gd`: 12 checks over Arena/Rooms and two window dimensions.
  Before the fix, six layout checks failed; after, all pass.
- `test_warden_charge.gd`: 2,510 checks including exact phases, facing, anchor,
  interruption, retained blast mapping and 2,400 finite authority/RNG trace steps
  against the original shared attack mapping in both modes and Boss phases.
- `test_warden_charge_assets.gd`: 83 source/resource checks. Existing action-set
  tests now require exactly 24 approved actions, with charge as a 16-frame clip.
- `test_telegraph_readability.gd`: 97 geometry/style checks, including eight
  directions and both modes; rendered contrast is checked separately.
- `tests/run_regression.py` checks exit codes, explicit success summaries, engine
  errors and unchanged runtime input hashes. Run its logs outside the project.

Actual cloud Linux Godot 4.6.3 OpenGL/Mesa window testing is now available; this is
separate from headless checks. Recorded GUI acceptance includes seed preservation,
settings Escape, actual application-focus pause/no auto-resume, and readable
Arena/Rooms objectives. The final QA report records the exact final-snapshot
acceptance, including charge motion. Windows export, human balance/feel acceptance
and cross-platform performance remain unverified.

## Rejected first visual candidate

The first frozen source passed all 50 headless entries, but visual review found a
roughly 10-world-pixel terminal recovery→walk snap and an opaque charge warning
that hid the boss pose. That snapshot is not the accepted final artwork. The
revised metadata explicitly corrects recovery X placement by 0/10/20/31 source
pixels over frames 12–15; PNG pixels, regions, scale and authoritative timers stay
unchanged. Reproducible neutral faceplate/shoulder pixel measurements document
this authoring correction rather than silently normalizing every frame. The
warning revision changes only fill/outline rendering.

## Next confirmed playability work

The shop's explanatory text consumes too much of the initial offer pane at the
960×540 logical viewport. Also, experience collected by end-of-stage settlement
can trigger a new upgrade only after the next Deploy. These are intentionally
tracked separately from this batch so its tested source can be frozen and
published without continuously changing the candidate.

## Reproduce

```bash
python3 tests/run_regression.py --project . --output /tmp/moss-v16-checks
```

Use a fresh source extraction for cold import. Source packages exclude `.godot`,
local homes, caches and QA-only GUI drivers.
