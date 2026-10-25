# Initial native export — independent acceptance

2026-10-25 UTC. **Linux native GUI accepted for the finite ordinary-control flow below. Windows artifact inspection only.** This is tied to the exact initial artifact hashes, not yet a final packaged/remote release receipt.

## Artifact identity

- Linux ELF SHA-256: `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`, 71,075,864 bytes; executable-bit set, ELF64 x86-64, dynamically linked.
- Linux and Windows companion PCK SHA-256: `d454fba8eb3b6ceff3686303b4ad7e4ac2c176659af8c4bf85de610d57af7298`, 35,510,564 bytes; the files are byte-identical, GDPC format3 header identifies engine4.6.3.
- Windows EXE SHA-256: `91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6`, 104,659,456 bytes.
- All four listed artifact hashes verified before the GUI run and again afterwards with zero changes. See `artifact-identity.json`.
- The provided production fingerprint records parent commit `217867b88e7225ef7c7e88b455685e5661436491` and accepted v18 release manifest `ee23bea7a2a00ca269d957c59474090b47da951d91f97956243f6eeb768e238d`. All 102 existing production file hashes independently match that v18 release. The additional export preset hash `9383bc38015cf926d4ad0a13f0ecd86d3277e9c170af1afd7ce7913f4a2dc86d` matches the inspected preset bytes. The prior 103-path GUI fingerprint also included `ui/test_ui.gd`; that non-runtime test is intentionally excluded from export. See `PRODUCTION_FINGERPRINT.json` and `export_presets.cfg`. This review does not replace the author's exported-pack oracle or pretend it was independently rerun here. The publisher selected these exact GUI-tested ELF/PCK bytes for the final runtime; accompanying package/source freeze remains separate.

## Actual native Linux execution

Launched the exact exported ELF with its adjacent PCK through the cloud desktop, using isolated writable HOME/XDG directories and a separate runtime log. No Godot editor/source main scene, external test script, injected fixture, in-game automation flag, cheats, altered health or programmed kills were used. CUA mouse/keyboard inputs are automated ordinary controls, **not human play**.

Actual release window (no DEBUG suffix), Godot4.6.3, OpenGL compatibility, Mesa llvmpipe; logical960×540, native captures1180×812 including the game's letterboxing.

Verified:

1. Title/background and Enemy Field Guide resources load. Edited Rooms seed **874205** after exposing its field; Settings and Field Guide return preserve that seed and mode.
2. Ordinary movement and auto-fire produce visible enemies, muzzle effects and kills. A simultaneous direction+Space input starts the dash and visible **2.0s** cooldown. Space without movement does not start a dash, as specified by the existing movement controller; early stationary attempts were not counted as successful dash tests.
3. Actual OS focus changed from live game to another application. The game entered **SYSTEM SUSPENDED**. Returning OS focus left it paused; explicit Escape resumed play. Native evidence captures only the game window, not the other application.
4. Completed room1, accepted earned upgrades and reached shop. Shock Mortar purchase **66→20 scrap** yielded two weapons; inventory open/close preserved stock and build.
5. Room2 deploy entered combat directly. Both subsequent earned upgrade screens were observed before the second shop. Module details expanded read-only and remained legible.
6. Bought Scrap Mine **55→27 scrap**. Inventory showed **MODULES1/8**, **Scrap Mine x1/1**, **STACK CAP1**, and **ICD1.00s**. Deployed room3 without a delayed upgrade modal.
7. **CIRCUIT COMPLETE: room3/3, LV4, kills12, seed874205**. Build: Rivet Gun, Shock Mortar and one Scrap Mine. This is finite normal-input progression, not a balance/human-skill certification.
8. **Retry Same Seed** started a fresh run; inventory immediately showed one Rivet Gun and zero modules. Closed the exported game normally; no subsequent script/resource errors appeared in its log.

## Visual review and environment limits

The art worker independently inspected six native ordinary-run captures: expected crisp sprite/icon filtering, clean transparent silhouettes, intact atlas frames/ground textures/muzzle VFX, readable inventory/guide/HUD and translucent charge tell. No export-specific rendering/resource regression was observed. Unseen Boss actions and continuous motion are not certified by these stills.

`runtime.log` is retained unedited. It contains startup environment diagnostics:

- llvmpipe cannot change the requested VSync mode.
- ALSA output-device initialization returns ERR_CANT_OPEN; the engine falls back to its dummy audio driver.

There are **no script/resource/scene errors observed**, but it would be false to call the total log error-free. Audio output is **not accepted/tested**. The game defaults were not changed to hide the environment limitation. This cloud Linux result does not establish target-GPU performance or Windows behavior.

An inherited observation is that some upper-world enemies appear partly behind the opaque HUD. No new export-specific regression is inferred from that alone; a separate ordinary-control usability probe would be needed before assigning it a concrete future gameplay defect.

## Windows: inspection, not execution

`windows-artifact-inspection.json` records DOS/PE signatures, PE32+ x86-64 architecture, Windows GUI subsystem, 12 sections, and **no embedded Authenticode certificate table**. The PCK is identical to the Linux companion. This does not verify Windows startup, input, graphics, audio, antivirus reputation or OS compatibility. No Windows runtime or Wine was used.

## Evidence and final gate

Seventeen unmodified JPEG captures under `captures/` are direct native game-window images. No desktop, browser, editor or dock content is included. Launcher scripts, local test-data directories and machine paths are excluded from this public-safe evidence subset.

Final frozen-source association, unchanged packaged artifact identity, package instructions/archive integrity and remote commit/readback remain separate release gates. If binary/PCK bytes change, assess the changes and rerun affected native checks before reusing this acceptance. `EVIDENCE_SHA256.json` indexes all files except itself.
