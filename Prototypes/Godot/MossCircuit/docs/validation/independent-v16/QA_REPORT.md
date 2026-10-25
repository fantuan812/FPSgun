# MossCircuit v16 r2 — independent QA

Date: 2026-10-25 UTC. Disposition: **accepted for the tested prototype scope**, with the remaining UX work below explicitly open.

## Source identity and cold regression

- Frozen source: `moss-v16-candidate-r2`, 1,173 files including `MANIFEST.json`.
- Source `MANIFEST.json` SHA-256: `40fc6ff639be1a7d14b2e07cb8f4f35b0d3e886883d56bafea26bb145f0fbaab`.
- Independent copy: `/workspace/shared/moss-qa-v16-r2`. All 1,172 manifest entries verified; no differing source bytes. Copy had no `.godot` before cold import. See `source-verification.json`.
- Independent cold import and **all 51 standalone entry points passed**. The aggregate records 52 passes because import is included. Every test had its required success marker, exit 0, and no ERROR; input hash changes were empty. See `regression/result.json`, `summary.json`, `input-hashes.json`, and individual logs.
- Focused examples: Warden charge 2,510 checks, charge assets 83, telegraph readability 97, exact action contract 361. These automated checks do not substitute for graphical inspection.

## Actual graphical environment and ordinary play

Actual Godot 4.6.3 cloud Linux desktop, OpenGL compatibility / Mesa llvmpipe. Project logical viewport is 960×540. Native window captures below are 1,180×812 including the game's letterboxing. This is actual graphical execution, **not headless or Windows testing**.

Using ordinary mouse/keyboard inputs on the exact r2 copy (no automation flag, forced victory, health change, or fixture):

1. Launched the normal main scene, edited seed to `874205`, opened Settings, and returned with Escape; the seed remained intact.
2. Started Rooms, moved, and observed automatic attacks, kills, and the fully readable room objective below the HUD.
3. Changed actual OS application focus away from live play, returned through the game dock icon, and observed the game still paused. Explicit Escape resumed it; focus gain did not auto-resume.
4. Completed all three rooms through upgrade and shop states. Deliberately chose upgrades with numeric keys. Final screen: **CIRCUIT COMPLETE, room 3/3, LV 3, kills 13, seed 874205**. This run retained only the starter Rivet Gun; no purchases were needed to establish completion.

Earlier GUI work on the isolated input/HUD candidate also verified: project-manager import → editor → F5; movement + Space dash and visible cooldown; paused Settings → Escape stays paused; inventory open/close; seed survives Field Guide; both Arena and Rooms objectives; purchase Cooling Fan (66→46 scrap), shop inventory return, ordinary seed 240102 three-room victory, and Retry Same Seed clearing the previous module. Those earlier captures included desktop surroundings and are deliberately **not distributed** here. They are supporting history, not evidence that every flow was repeated after every final art change.

## Controlled Warden visual inspection — separate from ordinary victory

`fixture/qa_warden.gd` and `.tscn` are external QA-only additions, not the shipping main scene. The harness boosts player HP to 10,000, disables ordinary spawns/player weapons, spawns a Warden, steps real source AI/render time, and permits hurt triggers and player repositioning. It hides the boss HUD only to make room for a clearly labeled QA caption. All 174 production paths used by this fixture were byte-identical to r2; see `fixture-runtime-hashes.json`.

Inspected live rendered phase stepping and native stills, including warning → charging → recovery 12/13/14/15 → walk, both horizontal facings, hurt interruption → current charge frame 9, fixed facing after the player crosses committed aim, original blast action, and warning readability in Arena and Rooms.

- First candidate was rejected despite its passing headless suite: the opaque warning rectangle hid the face/fist, and final recovery → walk visibly relocated the body horizontally.
- r2 translucent fill plus same-footprint outline leaves face, fists, and ground readable while retaining the visible warning region.
- r2 authored recovery registration correction removes the whole-body terminal snap in both directions. Recovery stills show coherent braking/rising, stable feet baseline, and no crop/scale pop. The art worker independently inspected the native captures and concurred.
- Hurt return shows the current charging phase rather than restarting its first frame. Original blast remains visually distinct.

This is phase-stepped/live-render and still-image acceptance, **not a recorded continuous-motion review, human timing/feel acceptance, or an unassisted boss victory**. Fixture labels are not shipped game UI.

## Safe screenshot inventory

**Every PNG in this package was captured directly from the native game window. No unrelated browser, editor, desktop, or dock pixels are included.** The exact file list and hashes are in `EVIDENCE_SHA256.json`. Initial full-desktop captures and their earlier report are intentionally excluded.

Ordinary final-r2 evidence:

- `screenshots/final-title.png` — normal title.
- `screenshots/final-seed-preserved.png` — edited seed retained after Settings.
- `screenshots/final-rooms-hud.png`, `final-room2-progress.png` — readable room objective and normal combat.
- `screenshots/final-refocus-paused.png` — still paused after actual application refocus.
- `screenshots/final-room1-outcome.png` — initial shop density limitation.
- `screenshots/final-room2-deploy.png` — pending-XP upgrade appears immediately after Deploy.
- `screenshots/final-rooms-victory.png` — exact-r2 ordinary-input completion.

Controlled comparison evidence:

- `warden-warning0.png`, `warden-recover15.png`, `warden-walk.png` — **rejected first snapshot**, not final visuals.
- `warden-r2-recover15.png`, `warden-r2-walk.png`, `warden-r2-mirror15.png`, `warden-r2-mirror-walk.png` — corrected terminal handoffs.
- `warden-final-warning.png`, `warden-final-rooms-warning.png` — final readable tell, both modes.
- `warden-final-recover12.png` through `warden-final-recover15.png` — final recovery progression.
- `warden-final-hurt.png`, `warden-final-hurt-return.png`, `warden-final-locked-facing.png`, `warden-final-blast.png` — interruption, locked aim, original attack separation.

All Warden paths above are relative to `screenshots/`.

## Open work and explicit limits

- **Confirmed usability follow-up:** the initial shop pane is dominated by probability/explanation copy; Buy buttons require scrolling. Transactions work, but offer-first layout remains queued separately.
- **Confirmed ordering surprise:** settlement collects XP without accruing levels, so next-room Deploy can immediately present another upgrade. Exact r2 reproduced this with mouse-only Deploy. A prior movement+Space span seemed to accept a default choice, but same-event leakage was **not proven**; do not report that mechanism as established.
- Not tested here: Windows export/runtime, full ordinary-input Arena six-wave victory, continuous video motion quality, human difficulty/balance/fun, or audio.
- No permission denial is blocking this QA. No runtime source was edited by QA; all fixtures, screenshots, reports, and generated regression state stayed outside the frozen candidate. QA performed no publication.

## Reproduction

Cold copy the frozen source, then run `python tests/run_regression.py --project <copy> --output <outside-log-directory>`. Launch `godot --path <copy>` for ordinary input testing. For controlled visual reproduction, copy the two fixture files to a separate source copy and launch `godot --path <fixture-copy> res://qa_warden.tscn`; read the explicit control/cheat label before interpreting its output.
