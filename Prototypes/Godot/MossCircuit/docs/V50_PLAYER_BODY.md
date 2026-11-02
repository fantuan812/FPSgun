# v50 — editable player body

**Source, resource-pack, bounded desktop and local restoration validation complete. Publication and remote-dependent assembly pending.** This is not a published-release announcement.

## Five masters, unchanged registration

The new SVGs contain **45 articulated poses across five 1254 × 1254 sheets**: walk, attack, dash, hurt and death. Idle reuses walk frame 0; horizontal mirroring supplies the existing left-facing behavior, not another directional frame bank. Weapons are separate assets. The effective attack output remains `assets/weapon_mounts/clean_hero_attack.png`; the inactive historical baked attack sheet is not replaced or used as a fallback.

The redraw preserves the connected helmet/torso/backpack design and fixed runtime registration. Walk keeps its original per-frame crop and padding within a logical 418 × 418 canvas at scale 64/418. That does **not** mean the visible body is 64 pixels tall. Actions retain their 418 × 340 source windows, nonuniform row origins, reference heights, anchors and sockets. Newly measured art bounds do not replace those fixed crops or change display scale. Foot and grip positions remain important to both presentation and authoritative firing origins.

Production code, action priorities, timing, hitboxes, collision, damage, invulnerability, random streams, UI and all other artwork are unchanged. Use the [five-master editing guide](../art_source/player_v50/AUTHORING_SCOPE.md) for output paths, fixed-registration rules and export instructions.

## Completed finite validation

| Check | Actual scope |
| --- | --- |
| Imported source | **Five separate 125-check reports**, each covering its sheet, nine runtime frame crops, padding/logical size, imported pixels and formal PNG provenance. |
| Actual resource pack | **Five corresponding 125-check reports**, each compared with its own actual source-imported observations, plus the existing **1,068-check** resource/integration smoke gate. Packed observations are imported texture data, not a claim to read original PNG file bytes from the pack. |
| Documented BUILD entry | The existing **14 routes**, with unchanged test bodies and warning policies, passed on the current source-plus-test-wrapper tree. |
| Corrected desktop observer | **678 checks**, **51 original captures**, **six controlled setups** and **51 post-entry presentation-authority guards**. |
| Direct visual review | The author agent inspected all **51** originals; independent QA inspected **16** selected originals. Neither is represented as a human playtest. |

The accepted local production tree has **1,006 source inputs**; the separate source-plus-test-wrapper tree has **1,038**. These are local validation inventories, not publication counts. From the imported project root, run `python3 tools/run_build_ui_checks.py`; see [BUILD validation instructions](BUILD_UI_VALIDATION.md). This entry does not replay the separate player observer or certify the full game.

### What the 51 views cover

- **45 normal frame samples:** walk frames 0–8; warning frames 0–2 and release/recovery frames 3–8 from the attack sheet; all nine dash, hurt and death frames.
- **Five selected body mirrors:** walk 0, attack 3, dash 4, hurt 3 and death 8. These are controlled body-facing probes, not five newly fired leftward shots. In the mirrored attack view, the existing target and held-weapon aim remain rightward.
- **One reduced-flashes comparison:** hurt frame 3. No complete reduced-state or weapon-by-pose matrix is claimed.

All 45 normal frames also receive both-facing numerical grip/body socket and foot-registration checks. Thirty-seven before/at frame-boundary pairs, idle alias, reaction endpoints, retrigger/priority rules, pause, noncompounding settings refresh, death hold/result delay and restart cleanup are bounded numerical checks. Walk selection remains 9 fps; the attack reaction uses frames 3–8 over 0.28 seconds, with the existing dash/hurt/death durations of 0.16/0.27/0.72 seconds. These fixed-step observations are not a real-time frame-rate measurement.

Selected entries use the actual combat warning path, primary Rivet release, character-motor plus dash-event entry, surviving hurt and lethal hurt. One offhand Scrap Shotgun firing-origin check is numerical only. Inputs and clocks are controlled; this is not physical-input playback or full combat replay. State/random-stream guards begin **after** intentional setup or events. No assets-disabled comparison is used, because sockets affect firing origins.

The screenshots show actual Director presentation with gameplay frozen. Its standalone white hurt flash is **not** a claim about every final gameplay frame: a separate bounded main-step observation confirms the existing main-loop orange hurt tint. Logical canvas bounds are derived from the actual texture and transforms, not intercepted draw calls or pixel-exact silhouette measurements.

## Visibility, retained failures and release limits

At the controlled **960 × 540** viewport, the connected body remains readable, the low dash and collapsing death poses are distinguishable, and death views have no held weapon. Fine gait, antenna and late eye details are subtle or merge at native size. Fixed gloves and held weapons overlap part of the face in some anticipation, recoil and hurt poses. Existing rings, sparks or projectiles can overlap the body. These limits do not justify silently moving crops or sockets.

The first native attempt remains a strict failure. Its external fixture used an invalid weapon identifier, aborting eight planned lifecycle checks, and its walk-boundary arithmetic selected the preceding frame at one floating-point threshold. Only the fixture was corrected to the real catalog identifier and direct frame-index division; the same unchanged resource pack then passed all 678 checks. No production timing or geometry tolerance was relaxed.

The initial strict pack comparison also stopped on generated scene metadata. That exact difference was reviewed before continuation on the same pack; acceptance is not an initial all-phases pass. Existing BUILD warning allowances and the native observer's specific display-warning allowance remain explicit, not a warning-free claim.

Local restoration passed **10 controls: two positive and eight negative**. Actual resource-pack backup, replacement and rollback restored the exact previous local ground pack while preserving executable bytes and permissions. These are local file-restoration checks, not a delivery-executable launch or installation test. Publication and remote-dependent source/history composition remain pending. No delivery-executable launch, Windows execution, installation, physical-audio, CI, all-weapons, all-scales or full-game certification is claimed. World/logical sizes are not guaranteed physical pixels under arbitrary scaling.
