# v16 final engineering QA · accepted r2

Date: 2026-10-25. Baseline: v15 commit `14ebe583f911b66f36200d05e886fe6e0176c456`.
Engine: official Godot 4.6.3. Tested frozen source: 1,173 files; source MANIFEST SHA256
`40fc6ff639be1a7d14b2e07cb8f4f35b0d3e886883d56bafea26bb145f0fbaab`.
The delivery adds reports/evidence to that source without altering tested runtime inputs;
its complete final manifest is therefore intentionally different.

## Final automated verification

Both author and independent runs began from fresh copies without `.godot`:
**cold import plus all 51 standalone entry points passed**, exit zero, no engine
ERROR/SCRIPT ERROR, explicit success summaries, and no runtime input hash changes.
Author logs and exact before/after hashes are under `final-author/`. Independent
acceptance is recorded under `../independent-v16/`.

Focused coverage:

- Input lifecycle: 20 checks; nine expected failures reproduced in the baseline.
- Measured HUD/objective layout: 12 checks; six expected baseline failures.
- Warden charge phase/mirroring/hurt arbitration and finite gameplay parity: 2,510
  checks, including 2,400 state/RNG trace steps across both modes and Boss phases.
- Corrected charge source/metadata: 83 checks; source pixels unchanged.
- Warning geometry/style: 97 checks over eight directions and both modes.
- Exact authored-action regression: 361 checks, exactly 24 accepted clips.

All 1,140 v15 paths remain. The 31 gameplay/mode authority and balance/catalog/
encounter configuration paths checked against the restored v15 manifest are
byte-identical. Presentation/controller/UI changes are explicit, not described as
full runtime byte parity; see `source-integrity.json`.

## Real rendered-window acceptance

Actual cloud Linux Godot OpenGL/Mesa llvmpipe window testing, not headless:

- Edited seed survives Settings/Field Guide visits; Escape returns Settings to
  title or pause; real OS focus loss pauses and focus gain does not auto-resume.
- Arena objective and Rooms badge/objective are fully below the HUD at the tested
  960×540 logical viewport in a 1280×720 window.
- Exact-r2 ordinary-input Rooms seed 874205 completed all three rooms (LV3,
  kills13), with native game-window evidence. Earlier input/HUD-candidate seed
  240102 also completed purchase/deploy/inventory/victory flows. These are finite
  agent-operated flows, not human
  difficulty or broad build-balance acceptance.
- Controlled Warden fixture uses the same final runtime assets/scripts, clearly
  separate from the normal-input run: corrected terminal recovery→walk works in
  both facings; recovery steps maintain the ground baseline; hurt reveals current
  charge progress; player-side crossing does not retarget the locked charge.
- New translucent charge footprint preserves a strong outline and readable boss
  face/fist/ground in both Arena and Rooms. Marker endpoints, width, timing and
  combat authority remain unchanged.

The independent report records exact window-only evidence and source hashes.
Controlled fixture state manipulation is not claimed as unassisted Boss victory.
The evidence directory contains `.gdignore`, keeping copied QA-only fixtures and
screenshots outside Godot production import/export; original evidence hashes are
retained. Phase-stepped stills are not a continuous-video motion review.

## Rejected first candidate and repair

The initial frozen source passed 50 headless entry points but was **not visually
accepted**: final charge recovery had approximately 10 world pixels of horizontal
snap, and the existing opaque warning hid the prep pose. It is retained only as
historical rejection evidence. Neutral faceplate/shoulder source-pixel analysis
established layout drift rather than a deliberate final lean. Explicit recovery
X corrections 0/10/20/31 source pixels (frames 12–15) fix that terminal registration;
source PNG, source regions, scale and AI timers are unchanged. The warning now
uses a translucent interior plus contrasting boundary, not a smaller damage zone.

## Remaining limits and next work

Windows export, human feel/balance and broad performance/platform acceptance are
NOT RUN. Existing Core ring/summon still share one attack resource in v16. Shop
explanations obscure initial offer actions; settlement XP can open a surprise
upgrade after Deploy. Those known playability issues are the next bounded batch,
not silently included in this tested release. No audio, save system, online play,
full dungeon or comprehensive end-to-end Boss balance is claimed.

## Reproduction

`python3 tests/run_regression.py --project . --output /tmp/moss-v16-checks`

Use a fresh extraction for cold import. The runner rejects in-project output,
sets writable HOME/XDG paths, requires explicit success markers and compares
runtime input hashes. Headless success cannot substitute for the GUI checks above.
