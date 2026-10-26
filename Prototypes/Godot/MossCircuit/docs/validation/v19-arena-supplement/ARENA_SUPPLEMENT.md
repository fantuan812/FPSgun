# Native exported Arena — supplemental ordinary-control run

2026-10-25 UTC. Separate from the already frozen v19 bounded release receipt. **Full finite Arena progression observed on the same immutable exported Linux ELF/PCK.** This is not human-play or balance certification.

## Identity and method

- Linux ELF SHA-256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.
- Companion PCK SHA-256 `d454fba8eb3b6ceff3686303b4ad7e4ac2c176659af8c4bf85de610d57af7298`.
- These are the exact initial artifacts selected for the v19 platform release. All four Linux/Windows artifact hashes were checked after this run; see `artifact-post-run.json`. No source or artifact was modified.
- Launched the release ELF through the cloud Linux desktop, with adjacent PCK and separate writable HOME/XDG data. Actual native window, Godot 4.6.3 OpenGL compatibility/llvmpipe. No editor-run scene, fixture, cheats, health override, in-game automation flag or programmatic game-state injection.
- Automated CUA mouse/keyboard supplied ordinary movement, direction+Space dash, pause/resume, upgrade selections and one purchase. This is **not a human player**. Native captures are unmodified game-window JPEGs, not desktop/editor screenshots.

## Observed outcome

Entered Arena seed **874205** and completed all six waves. Terminal screen: **CIRCUIT COMPLETE, wave 6/6, LV22, kills348, seed874205**. Build: Rivet Gun plus one Shock Mortar, zero modules. Both **WARDEN PROTOCOL** and **REACTOR CROWN** were secured. See `captures/outcome.jpg`.

The only shop purchase was Shock Mortar after wave1, **122→76 scrap**. Subsequent shops were used only to deploy; no additional weapons, modules, refreshes or sales. Earned choices favored damage, fire interval and piercing, with ordinary repair upgrades later. Settlement choices appeared before shops; final earned levels are reflected on the terminal screen without inaccessible post-victory choices.

Actual combat captures include crawler/flanker/spitter/charger/brood visuals, Warden with blast warning, and Core with ring warning. They show visible live instances, not a controlled presentation fixture. Warden and Core were defeated through the normal auto-fire/build mechanics. The run did **not** capture every action/phase, in particular Core summon, so it adds no new native summon-phase or continuous-motion certification.

The artist independently accepted the Warden still's silhouette, alpha, sampling and visible pose as free of an observed export-specific art fault. The exported Core ring capture is separately supplied for inspection. No export-specific script/resource/scene error was observed. The retained runtime log contains the known unsupported VSync warning and ALSA initialization error with dummy-audio fallback; total-log-error-free/audio acceptance would be false. No Windows execution occurred.

## Inherited usability finding for a later patch

`captures/warden.jpg` is an ordinary run at wave3, simulation time64s, Warden434/950 HP. After deployment and approximately D1.8s then S1.8s, the boss panel occupies native y610–722 and visibly hides a large part of the blast-warning circle near the lower arena boundary. The player is not visible at that moment, consistent with its lower-edge position behind the panel. The artist independently confirmed circle masking and absent player visibility. This is an inherited HUD occlusion issue, **not damaged art or an export regression**, and does not alter v19 bytes or the bounded receipt.

Source diagnosis: `ui/moss_ui.gd` creates an opaque bottom-wide boss panel with offsets -104 to -12. `scripts/gameplay/field_layout.gd` clamps the camera near map edges; `character_motor.gd` permits the player within24 world units of the lower boundary. Thus the panel overlays reachable combat space. The nearby `wave4.jpg` capture without the boss panel shows the player visible near that lower edge. A future presentation-only remedy should preserve readable status while avoiding opaque masking of the player and actionable tell; this report does not prescribe a gameplay boundary/AI change.

No claim of exact deterministic reproduction from these coarse timed CUA controls is made: wall-clock/tool latency varies. The screenshot, seed/build/time/health and source location provide the concrete evidence for a focused repro fixture or subsequent ordinary-control check. The issue has been sent to the parent/programmer as next-scope work; no frozen release was edited.

Closed the native game normally after the terminal result. `EVIDENCE_SHA256.json` indexes this report, the log, identity receipt and 13 native captures; local launcher/home data are omitted.
