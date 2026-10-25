# v17 final engineering QA

Date: 2026-10-25. Baseline: published v16 commit
`453960ffd8f3354cee0d0ca8b0abc762ad8b91a0`.
Tested frozen v17 source: 1,342 files; MANIFEST SHA256
`2d4c9d8f465cf1863a2da6dee5b5304b654fbb3a298672dbab14e8e73859bc7f`.
Delivery adds reports/evidence only, so its complete manifest differs while all
tested runtime inputs remain byte-identical.

## Automated checks

Author and independent fresh-copy cold import plus **all 55 standalone entry
points passed**, exit zero, explicit summaries, no ERROR/SCRIPT ERROR and no
runtime input hash changes. `final-author/` contains author logs and exact hashes;
`../independent-v17/` records independent results and additional edge coverage.

- Settlement ordering: 20 author checks; the original source failed 12. Covers
  floor XP, multiple thresholds, pending choice completion, both modes, repeated
  completion, direct Deploy and terminal-level reporting without post-win UI.
- Shop visibility/disclosures: 160 author checks over all 32 first-offer catalog
  cases. Independent edge coverage adds full-slot replacement, unaffordable/sold
  actions, disclosure read-only behavior and inventory return.
- Core summon: 2,510 checks including actual 165.3-world-pixel Boss height, true
  phase/release selection, child caps, untouched ring and 2,400 finite authority/
  RNG trace steps across both modes and health phases.
- Source/atlas: 78 Core summon checks. Exact action set now contains 25 clips.
- All existing reaction, weapon, economy, mode, HUD and v16-input tests remain.

Only `run_flow.gd` changes gameplay flow; its new ordering is intentional rather
than asserted as old-settlement trace parity. Enemy AI/combat rules, costs, XP
thresholds and old ring source bytes are unchanged. The v16 presentation selector
is reused without adding a new timing authority.

## Actual native-window acceptance

Actual cloud Linux Godot 4.6.3 OpenGL/Mesa graphical execution, separate from
headless checks. Exact source fingerprints are in the independent report.

- Normal CUA input Rooms seed874205 used the final flow/UI files on v16r2; the
  three Core presentation files were tested separately in the final fixture. This
  is not described as a complete normal run after every art integration.
  Both earned room1 choices appear before shop;
  Deploy enters room2 combat directly. First BUY is visible at initial scroll.
- Keyboard draw/item disclosures expand/collapse without reroll or spending;
  purchase Shock Mortar66→20 and inventory→Escape preserve state and coins.
- Ordinary three-room victory: room3/3, LV4, kills15, Rivet+Shock Mortar, zero
  modules. Terminal collected XP is reflected without an inaccessible upgrade.
- Controlled actual-scale Core inspection: warning0/4/6, release7, recovery15→walk
  in both facings, hurt→current recovery12, locked facing and retained ring4.
  Root-cradle/seed summon is visibly distinct from radial ring. No cropped roots,
  root-following body bob or major terminal relocation was observed. The art worker
  independently accepted these native captures; no metadata revision was needed.

Core source-centroid residual drift remains numerically disclosed in its art
record. This is stepped-phase/still-image acceptance, not continuous-video motion
or human timing/feel acceptance. Controlled fixtures are not unassisted Boss wins.

## Historical evidence and corrected estimate

The copied `v16-arena-supplement/` establishes normal CUA-controlled six-wave v16
victory, both Boss rewards and ordinary equipment/upgrades; it is explicitly
historical, not a claim that v17 Arena was fully replayed. The full v16 published
readback receipt verifies all1,317 exact-commit GitHub file bytes by SHA256 and Git
blob SHA. Neither item rewrites the immutable v16 release.

The earlier v16 rough10-world-pixel Warden defect estimate was too low. Its actual
31-source-pixel correction equals approximately22.194 world pixels at height148.2
and reference207. The source measurements, correction bytes and accepted GUI
result remain valid. The precise erratum is included with Core art documentation.

## Limits

No Windows export/runtime, human balance/fun acceptance, continuous-motion video,
audio/save/network implementation or full dungeon is claimed. New art tests and
finite traces do not prove every possible gameplay/input sequence. The independent
report states remaining visual limitations and exact controlled-test boundaries.

Reproduce with a fresh extraction:
`python3 tests/run_regression.py --project . --output /tmp/moss-v17-checks`.
