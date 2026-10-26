# Read-only v29 design baseline

No implementation acceptance or test execution is implied.

- Accepted source/runtime commit: `2a922f15fffe2381ebc855095fe9e9c8dd41b09b`.
- Final metadata head: `6b1e7e5133ad8246a7fa38db8e998125f3b9fc56`.
- Accepted source manifest: `a653eaba2b83a3dd1df5a6e7b2a17e22f5dc78527a5b0afbe5656360e051ba20`,4394 logical source files.
- Runtime PCK: `5db5ded8a5b18eb6ac391b58a261e245588aa52cd7dbc65575f5101fb5828f69`,41361216 bytes.
- 118-path production fingerprint retained verbatim in `ACCEPTED_V28_PRODUCTION.json`, SHA256 `c99253031f4b1bc38bd80ee3dd465f43c6979e7b66649d84fd703be7c65f862a`.
- Existing upgrade draw is3-of6 shuffled with loot_rng; each normal choice adds one build.levels count, recomputes stats, optionally heals30 forhealth, decrements pending, then next choice / authored shop / playing.
- Existing income credit does not increment build revision. Fixed new integer salvage should leave fractional income untouched rather than round-trip through fractional arithmetic.

Heavy test/import/export/native execution remains paused until the parent releases serial validation after learning startup diagnostics. No v28 rerun, production copy or source edit is authorized by this baseline note.
