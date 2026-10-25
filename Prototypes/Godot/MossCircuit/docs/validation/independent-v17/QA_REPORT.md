# MossCircuit v17 — independent QA

Date: 2026-10-25 UTC. **Accepted for the tested prototype scope. No new release-blocking defect found.**

## Exact source and cold regression

- Frozen source: `moss-v17-candidate`, 1,342 files including `MANIFEST.json`.
- Source manifest SHA-256: `2d4c9d8f465cf1863a2da6dee5b5304b654fbb3a298672dbab14e8e73859bc7f`.
- Independent cold copy: `independent-v17-cold-import-snapshot`. All 1,341 listed entries were verified in both the frozen source and independent copy. Neither had a differing listed file. The independent copy had no `.godot` before import. See `source-verification.json`.
- Cold import and **all 55 standalone entry points passed** (56 passes when import is included), with exit 0, all required success markers, zero ERROR, and no input hash changes. See `regression/result.json`, `summary.json`, `input-hashes.json`, and the individual logs.
- The full suite includes Core summon 2,510 checks for actual Boss scale, real AI attempt/caps, original ring, and finite authority/RNG parity. This does not make the headless suite a graphical test.

## Actual GUI environment and evidence boundaries

Actual graphical Godot 4.6.3 on the cloud Linux desktop, OpenGL compatibility / Mesa llvmpipe; project logical viewport 960×540. Captures are 1,180×812 including the game's own letterboxing. **Not headless GUI evidence and not Windows testing.**

Inputs were automated CUA mouse/keyboard operations. In the normal Rooms run, “ordinary controls” means no in-game automation flag, cheats, health changes, fixture, scripted enemy kills, or programmatic game-state injection. It does **not** mean a human played or that CUA itself was not automation.

All screenshots distributed under `screenshots/` are native game-window-only captures. No desktop, Chromium, editor, dock, or unrelated window is included. The tool returned JPEG bytes; the final evidence uses `.jpg` to match those original, untransformed bytes.

## Normal Rooms run — settlement and compact shop

This GUI run used the exact v16 r2 base plus the two final v17 flow/UI files. Their fingerprints are in `v17-flow-fingerprint.json`, and both match the frozen v17 source. The only production differences from final v17 were the three Core presentation files (`data/actor_actions.json`, the new Core action manifest, and summon sheet), which were exercised separately below. This is not represented as a complete normal run after every final art integration.

Seed **874205**, normal Rooms main scene:

1. Room 1 earned upgrades were presented and accepted **before** entering its shop. Both the stage reward and collected-XP level choice were settled before deploy.
2. At zero scroll the first offer's name and BUY action were visible. Keyboard Shift+Tab/Return expanded draw details; Space collapsed them. The disclosure is read-only and the weight caveat remains accessible.
3. Bought Shock Mortar for 46 scrap: **66→20**, then expanded/collapsed item details and read the scrolled explanation. Opening inventory and returning with Escape preserved the purchased stock and scrap.
4. Deploy entered room 2 combat directly, with movement available and no delayed XP-choice interruption. Room 2 upgrades again appeared before its shop; the first BUY was visible. Deploy entered room 3 combat directly.
5. Completed all three rooms. Outcome: **CIRCUIT COMPLETE, room 3/3, LV 4, kills 15, seed 874205**, Rivet Gun + Shock Mortar, zero modules. Final earned floor XP is reflected in LV 4 without an inaccessible post-victory upgrade modal.

Native screenshots: `screenshots/v17-flow/v17-shop-initial.jpg`, `v17-shop-details.jpg`, `v17-shop-purchase.jpg`, `v17-item-details.jpg`, `v17-shop-return.jpg`, `v17-room2-deploy-playing.jpg`, `v17-shop2.jpg`, `v17-room3-deploy-playing.jpg`, and `v17-rooms-outcome.jpg`.

A separate controlled headless trace reproduced the original threshold-minus-one settlement case and now observes XP/level settlement → choices → shop → immediate deploy → first simulation frame all in the proper order. It also found **no stale Space release/echo selection** under its injected-event conditions. Do not claim a stale-Space bug from the prior ordering defect; OS key-repeat behavior is not proved by this diagnostic. See `supplemental-tests/v17-settlement-input.log` and its source.

## Controlled full-slot replacement GUI — separate from normal victory

`fixture/qa_shop.gd` and `.tscn` inject a full four-weapon build, 100 scrap, and a single Shock Mortar offer. This is explicitly a **controlled QA setup**, not a legitimately earned full build. The subsequent selector, transaction, repeat-click and navigation operations use real UI input and production code.

- With no offer-column scrolling, the destructive-replacement warning, slot selector and REPLACE action are visible together.
- Keyboard Return/Down/Down/Return selected **Rail Lance in slot 3**, not the default Rivet Gun. Tab/Return purchased the replacement.
- Observed **100→54 scrap**, generation **2→3**, four weapons retained, and slot 3 changed to Shock Mortar. The offer became SOLD.
- Two clicks on the disabled SOLD action did not charge again. Inventory showed all four weapons with the correct third slot. Escape returned to the same SOLD offer, 54 scrap and generation 3.

Screenshots: `v17-replace-initial.jpg`, `v17-replace-selected.jpg`, `v17-replace-purchased.jpg`, `v17-replace-inventory.jpg`, `v17-replace-return.jpg` under `screenshots/v17-flow/`.

Additional independent headless coverage passed **25 checks** for empty/full slots, affordable/unaffordable/sold first-action visibility at zero scroll, action-disabled state, all disclosure toggles being read-only, and inventory-return stock preservation. See `supplemental-tests/independent_v17_shop_edges.gd` and `v17-shop-edges.log`.

## Controlled Core summon GUI — actual spawn scale

`fixture/qa_core.gd` and `.tscn` are external QA additions, never the shipping main scene. The fixture uses real `_spawn_kind("boss_core", ...)` and true actor height **57×2.9 = 165.3**, with scale **165.3/246**. It boosts HP to 10,000, disables ordinary spawns/player weapons, steps production AI/render time, and permits hurt triggers/player repositioning. A visible caption labels these conditions. Only the fixture hides the boss HUD to keep that caption clear. Summoned children are not hidden.

All **103 non-sidecar production inputs** of the fixture (scripts/UI/data/scenes/assets, project settings and runtime `art_source/alpha_bounds.json`; excluding generated `.uid`/`.import` sidecars) match the frozen candidate. See `core17-runtime-hashes.json` and `gui-source-match.json`. The same production copy was used for the shop fixture.

Rendered phase-stepping and native captures verified:

- Arena summon warning frames 0, 4 and 6 → release/recovery frame 7 → terminal recovery 15 → old hover/walk.
- Roots progressively unfold while the brass ring/orb stays registered above them. The low seed cue appears at release, distinct from the old ring's radial burst. The tail is intentionally suspended rather than pinned to a ground baseline.
- Terminal recovery→walk in **both horizontal facings** shows normal hover/pulse variation, not a Warden-like whole-body relocation, crop change or scale discontinuity. Some mirrored frames contain naturally summoned children; those overlaps are not atlas clipping.
- Hurt interruption returns to **current summon recovery frame 12**, not restarted warning/recovery frame 7.
- The original ring uses the original `boss_core_attack` pose (reference recovery frame 4), visibly distinct from the new summon pose.
- Rooms warning and release remain readable. After moving the player across committed aim during warning, `flip false` remains fixed through warning and release; the Core does not turn mid-action.
- Source-level cap/no-cap summon attempts and finite gameplay/RNG parity are covered by the final suite, not claimed as an unassisted graphical cap test.

The art worker independently inspected the actual captures and accepted both-facing handoffs, root/orb registration, hurt return and distinction from ring. No further source/atlas correction was indicated.

This is **actual rendered-window, phase-stepped/still-image acceptance**, not recorded continuous-motion review, human timing/feel certification, or an unassisted Core victory. The terminal source orb difference of approximately 8.376×3.252 source pixels corresponds to **5.63×2.18 world pixels** at this true scale; the inspected handoff remained acceptable. Earlier rough Warden scale estimates must not be reused: its accepted 31-source-pixel registration correction corresponds to about 22.2 world pixels at the real Boss scale. This clarification does not alter immutable v16 source/evidence.

Core captures, all under `screenshots/core17/`:

- `core17-warning0.jpg`, `core17-warning-mid.jpg`, `core17-warning6.jpg`
- `core17-release7.jpg`, `core17-recover15.jpg`, `core17-walk.jpg`
- `core17-mirror-recover15.jpg`, `core17-mirror-walk.jpg`
- `core17-hurt.jpg`, `core17-hurt-return.jpg`, `core17-ring.jpg`
- `core17-rooms-warning.jpg`, `core17-rooms-locked-facing.jpg`, `core17-rooms-release.jpg`

## Historical full Arena progression evidence

The separate indexed `ARENA_SUPPLEMENT.md` package records an ordinary-control CUA run on **v16 r2**, seed 874205, through Arena **wave 6/6 victory, LV 18, kills 326**, Rivet Gun + purchased Shock Mortar, zero modules, and both boss rewards. It was recorded after the immutable v16 release and is supplementary historical evidence, not a claim that an unchanged long Arena run was repeated on final v17. The parent/programmer may append that existing indexed package separately; this directory does not duplicate it.

## Limits and disposition

Completed: exact cold full suite, normal three-room flow, controlled actual-scale Core presentation in both facings/modes, real keyboard purchase/replacement, repeated sold clicks and inventory returns, plus independent settlement/layout edges.

Not claimed: Windows/exported-executable testing; gamepad/touch/mobile; audio review; performance on real target GPUs; broad balance/difficulty or human reaction-time validation; continuous recorded animation review; normal full Arena rerun on final v17; every shop item combined with every build in GUI. These are remaining coverage limits, not known new failures.

No denied action is being silently retried or treated as passed. One fixture launch was initially interpreted by the desktop launcher as a filename (no process started); its visible “No such file” error was inspected and dismissed, then a normal executable command launched successfully. That is a harness-launch issue, not a game defect.

The final report and evidence are additions to a separate release copy only. Frozen v17 candidate and immutable v16 release were not edited. `EVIDENCE_SHA256.json` indexes every distributed file except itself.
