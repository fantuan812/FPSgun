# v33 R2 — one ordinary full Arena attempt

## Observed result

**CIRCUIT COMPLETE — Arena 6/6, level 20, 283 kills, seed 433.** This is a fresh, single ordinary-input run on the immutable final v33 R2 Linux resource pack. The final result directly shows the Rivet starter origin, a **TEMPERED Rivet Gun in slot 1**, and a **STANDARD Bankshot Driver in slot 2**. The read-only result view also confirms one Echo Chamber and one Mirror Shell. No second attempt was started.

The terminal image is `captures/61-terminal-victory.jpg` (SHA256 `6d477916c9a2f3a898a2b6ea86c6a7a387c2ca8c7df08621c1c0f9891e59483f`). An independent reviewer personally viewed this exact still and confirmed its visible outcome and equipment; that review is not an independent whole-run or damage test.

## Exact runtime and controls

- PCK: 41,396,596 bytes, SHA256 `8ec850cc2fd8b5490ee1f945d56cdb674fa38460191c3eb75be0fdb419ee9aba`.
- Existing unchanged Linux executable: 71,075,864 bytes, SHA256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.
- Normal adjacent executable/PCK launch at 1180×812. No editor, external game script, injected build, altered economy, state API, forced hit, forced victory, or pack rebuild.
- Automated CUA mouse/keyboard input and frequent ordinary tactical pauses were used. Movement was WASD, with some Space dashes. Ordinary mouse selections resolved upgrades, purchases, fusion, deployment, and read-only result scrolling.
- Seed 433 was chosen using existing offline first-shop evidence and read-only mode-independent shop-seed reasoning, not in-run RNG/state manipulation. Actual stock and earned funds were the authority. This does not establish other seeds.

## Build and progression evidence

1. Fresh title selected Arena / Rivet / seed 433. Early live HUD and earned upgrade pages are captured.
2. First settlement showed 122 scrap. During ambiguous intervening upgrade/menu frames, an **unplanned but real Bankshot purchase for 42** occurred, leaving 80. It was not undone. A settled shop then showed the desired Rivet offer; an ordinary 24-scrap purchase left **56 scrap and three weapons**.
3. The visible temper preview named retained Rivet **slot 1** and consumed STANDARD Rivet **slot 3**, with irreversible/no-refund and copy/tag/timer-loss disclosures. The actual button produced **three→two weapons, unchanged 56 scrap**, and TEMPERED Rivet damage **24.00** at the then-current bonuses. Bankshot remained owned.
4. That same build continued into wave 2. Naturally encountered Ram brace arcs and orange charge lanes are visible in captures 20 and 22. These stills do not attribute a particular half-damage hit.
5. Second shop: Echo Chamber purchase **182→152 scrap**. Wave 3 directly showed Warden phase 1 and phase 2, including its warning/charge/recovery states and low remaining HP, followed by the earned queue and later shop. No exact killing-hit attribution is made.
6. Waves 4 and 5 are directly observed. Broodkeepers and partially clipped annular warnings appear in late-wave captures. There was no purchase in the third or fourth shop.
7. Fifth shop: Mirror Shell purchase **771→737 scrap**. Wave 6 directly showed Reactor phase 2 (787/1600 then 119/1600 HP), its ring warning and summon recovery. The last live capture shows wave 6, 184 simulated seconds, 283 kills and no boss bar; the next settled observation is the explicit terminal victory, **not an inferred outcome from a later default inventory**.
8. Terminal result: TEMPERED Rivet **44.40 per-contact primary damage / 0.211 s**, STANDARD Bankshot **33.30 / 0.447 s**, Echo ×1 and Mirror ×1. These displayed values include the actually selected ordinary upgrades; this is not a Rivet-only result or an isolated attribution of victory to tempering.

## Observation limits retained

- Captures 11 and 12 repeated an earlier upgrade page after inputs. The subsequent settled shop proves the additional Bankshot purchase, but the exact intervening upgrade/menu chronology is not fully observed. The record does not label every attempted click successful and does not infer a game bug from stale or delayed observations. Later queued choices were followed by separate settled observations before another selection.
- Some held-input batches advanced less HUD simulation time than elapsed wall time. A later ordinary titlebar focus click preceded improved observed progression. No causal performance diagnosis or timing equivalence is claimed.
- The 63 game-window-only images are selected observations, **not continuous video**. Intermediate motion, individual kills, exact proc counts, damage causality, shield consumption, and every transition frame were not captured.
- Earned level/XP and displayed HP can change at settlement. The last live frame is LV18; the directly observed terminal result is LV20. No reset or second run was used to obtain that result.
- This closes the finite ordinary integration/progression loop on **one Linux Arena seed**. It does not certify balance, difficulty, fun, all builds/seeds, Windows execution, controller hardware, audio, or a universal performance level.

## Normal close and preservation

After read-only result scrolling, ordinary window-manager **Alt+F4** closed the game. The launch wrapper recorded **exit code 0** and a fresh window inventory no longer contained the game. The immediately first inventory after Alt+F4 still listed the closing window; closure is based on the later settled inventory and exit receipt, not merely the attempted shortcut.

ELF and PCK sizes/hashes exactly match the pre-run receipt. All **649 frozen R2 source inputs** were freshly hashed against the accepted input map with **zero changes**. No source, runtime, previous report, release, or recovery archive was edited for this supplement.

The log contains the environment's unsupported-VSync warning and ALSA-device failure followed by dummy-audio fallback; no additional gameplay-script error appears in this run's log. Audio is not certified.

This is a **separate supplemental evidence record**, not a replacement for historical R1/R2 scopes and not a GitHub-publication claim. The earlier R1 ordinary run, R1 independent full suite, R2 scoped checks and author R2 full suite retain their original artifact bindings.

## Files

- `CAPTURES_AND_CHRONOLOGY.json`: ordered observation notes, image dimensions, source-capture and JPEG hashes.
- `BEFORE.json`, `AFTER_AND_CLOSE.json`, `FROZEN_SOURCE_INPUTS.json`: exact artifact and source preservation proof.
- `native.log`, `exit-code.txt`: unchanged actual process output and terminal exit result.
- `INDEPENDENT_VISUAL_REVIEW.json`: bounded independent direct view of the terminal image.
- `EVIDENCE_INDEX.json`: complete supplement file hashes and sizes (excluding the index itself).
