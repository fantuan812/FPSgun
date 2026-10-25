# v19 desktop exports — final independent acceptance

2026-10-25 UTC. **PASS within the explicit Linux GUI, source regression and archive/resource scope below. Windows runtime and audio remain untested.**

## Exact source and production association

- Frozen source snapshot `v19-frozen-candidate`, root manifest SHA-256 `fb908a9d33a5399e346d889ec5fde86704f4b29cb6824aa424ba79f60c623f01`.
- Independently cold-copied all 1,722 manifest-listed files; no missing, extra or mismatched source files before testing, no listed-file hash changes afterwards. The copy initially had no import cache.
- All 103 initial-export production fingerprint paths match the frozen candidate. These comprise 102 existing production paths unchanged from accepted `v18-release-r2`, plus the export preset. Runtime source, source artwork, scene and configuration remain unchanged from v18. See `production-parity.json` and `source-verification.json`.

## Independent checks

- Cold Godot import plus **59/59 standalone entry points: 60/60 total PASS**, no `ERROR:` and no input hash changes. Full logs, explicit success markers and before/after input hashes are under `regression/`.
- Offline Python export-helper safety negatives **3/3 PASS**: refuse existing output without modification; missing templates do not start a build; corrupt cached archive is not extracted. These tests perform no download.
- Independently regenerated source-imported fingerprints from the cold QA copy, then read the exact delivered PCK with the Godot editor reader from an empty directory with no source fallback: **761/761 PASS**. Coverage includes 48 exact script/JSON files, 51 imported RGBA textures, 25 actions/281 atlas frames, main scene structure/project settings, dynamic enemies, both modes, shop/inventory and excluded source-only directories. This controlled resource test is not native gameplay or Windows runtime acceptance. See `packed-resource-report.json`.
- Imported RGBA, not raw PNG transparent-border RGB, is the comparison baseline. No source pixels or import settings were altered. No bit-for-bit rebuild reproducibility claim is made.

## Exact packaged artifacts

Both ZIPs were independently read member by member. Each contains nine expected files: no duplicate, unsafe, symlink, missing, extra or differing member. Internal checksums cover every other file and match sizes/hashes/modes; Linux ELF executable mode is 0755. Instructions, Godot license/third-party notices and unsigned/Windows-only-inspection limits are included.

| Archive | Bytes | SHA-256 |
| --- | ---: | --- |
| `MossCircuit-v19-Linux-x86_64-2026-10-25.zip` | 62,312,880 | `f9d57da027736cafb74e14cff82389effdc5ba915acd4d5b484394993e111477` |
| `MossCircuit-v19-Windows-ExportOnly-x86_64-2026-10-25.zip` | 71,082,894 | `a3250cc9f66a9b87a7066df18a9de79e483e9f5876ffadc76b3e498062b3333c` |

Packaged executables/PCKs are byte-identical to the initially tested artifacts. ELF `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`; common PCK `d454fba8eb3b6ceff3686303b4ad7e4ac2c176659af8c4bf85de610d57af7298`; Windows EXE `91724f15024a3a545e28ccd83134403d31ce2323a38e51c95e4dfa282f732ab6`. No rebuild replaced the GUI-tested runtime. See `platform-archive-verification.json`.

## Native Linux GUI acceptance retained unchanged

`native-initial/` is a byte-identical copy of the frozen initial report/evidence, including its own index and 17 unmodified game-window JPEG captures. It proves ordinary automated CUA controls, not human play, with no cheats, fixtures or game-state injection: seed 874205 Rooms progression, title/settings/guide seed preservation, movement/dash, actual OS focus pause, purchases/details/inventory, direct deploy, **room 3/3 victory, LV4, kills12**, and retry reset. No editor/source scene was used to run that native release ELF.

The initial report correctly predates final packaging; this report closes its source-association, resource and exact platform-archive gates. Its historical statement that the pack oracle was not yet independently rerun remains intact; the separate independent rerun above now supplies that coverage.

Cloud llvmpipe reports unsupported VSync control and ALSA output-device failure followed by dummy audio. The original runtime log is retained: no observed script/resource/scene error, **not zero total engine errors**, and no audible-output acceptance. Windows received PE32+ x86-64 GUI-subsystem/unsigned structure inspection plus common-PCK checks only; no Windows host or Wine execution occurred.

An optional ordinary Arena run and any inherited HUD usability findings are supplemental next-scope work, not a condition or expanded claim of this bounded release receipt. No full-game balance, human-feel, all-motion, target-GPU performance, Windows behavior or legal/security certification is implied. Source delivery ZIP and remote commit/readback are later publication gates, not asserted here.

`EVIDENCE_SHA256.json` indexes all files in this evidence package except itself. Evidence is game-window-only and uses repository-relative paths/stable snapshot labels; launchers and local runtime data are omitted.
