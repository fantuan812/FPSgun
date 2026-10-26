# Replaying the bounded checks

Use a **separate copy** of the frozen v23 source and Godot4.6.3, not a shipped release folder. The source/test scripts under `regressions/` are already promoted in `tests/`. Their optional output argument is not required. `regression/result.json` and individual logs record the actual independently run suite.

From the separate source copy, use writable isolated profile directories as documented in the source README. `tests/run_regression.py --project . --output ../independent-logs` creates its own isolated profile and runs the cold import plus standalone checks. Do not reuse a populated import cache when claiming a cold import.

The additional `focused/independent_bankshot_catalog.gd` can run as an external `--script` against that source. Its optional user argument names a result JSON. The two old-content trace scripts require one output JSON argument, and the preservation checker requires explicit baseline-root, candidate-root and output arguments. The baseline must be accepted v22 with its exact old7+27 catalog; normal v23 offers must not be compared without the declared filtering. Decompress `preservation/baseline-*.json.gz` to compare trace bytes. Gzip decompression is lossless; original content hashes are in the comparison receipt.

For controlled native presentation only, copy the four `native/qa_bankshot_fixture*.gd/.tscn` and `qa_bankshot_corner.tscn` files into a disposable source copy, then launch the desired scene. `qa_bankshot_fixture.gd` and the explicitly versioned v2 file contain identical tested bytes; the scene references the unversioned filename. Keys1–7 select cases; F mirrors; O changes mode; R toggles reduced flashes; N invokes one0.04s step; F6/F7 set960×540/1280×720; Q quits. The corner scene adds key8 and injects projectile geometry. **These are not ordinary gameplay tests.** Do not add them to the shipped main scene or exported PCK.

The ordinary exported test used only the unmodified ELF/PCK and standard controls. Seed86 was selected through the separate offline shop planner. A clean profile was used; only CUA keyboard/mouse actions earned XP/scrap, selected upgrades, purchased the pair and moved toward the boundary. Do not attach an external script or inject a build when reproducing that claim.

All screenshots included here are unchanged game-window capture bytes. No screenshot is an authoritative damage/proc oracle by itself. Native audio-device fallback and V-Sync limitations are retained rather than removed from logs.
