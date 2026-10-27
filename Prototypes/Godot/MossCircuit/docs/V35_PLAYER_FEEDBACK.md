# v35: bounded player-feedback sound completion

## Authority and scope

Only the two existing resolved `main._hurt` branches request audio. Genuine `before_hurt` block retains shield/effect/.25 clock order, then requests `shield_block`. Positive finite `CharacterMotor.apply_damage` loss retains animation/VFX/hurt-effect/.75 clock/possible finish order, then requests `player_damage`. The lethal event is the same hurt cue submitted after cleanup, not a death sound or later dead-state permission. Generic `hit_spark`/`shield_impact`, healing, enemy hits and secondary effects do not generate these cues. Original synthetic damage arithmetic is not repaired here.

The controller has no world/build/effect reference, gameplay RNG, async gameplay callback or queue. Two fixed one-voice players use gain0.5 and existing Master routing. The original standard-library generator produces exactly24,784 WAV bytes:7056 and5292 signed16 mono samples at44100Hz. Weighted DC removal, finite envelope and distinct chirps are pinned in the contract. Imported resources explicitly disable compression/trim/normalize/loop/resample. Runtime availability checks type/metadata/count; byte identities are acceptance checks, not runtime hashing.

## Lifecycle and settings

Session mute defaults off and survives title/retry within the same process only. Mute and named modal/settlement boundaries stop/discard, never pause/resume old streams. Accepted direct-stage settlement and Rooms clear are covered, not only UI buttons. Invalid fresh-build or ignored settlement keeps its previous behavior. Focus-out directly stops even a permitted lethal tail in dead state, then retains old pause behavior. A just-started nonlethal cue can be deliberately truncated at a following modal boundary. Mixer buffers may drain after stop; exact instantaneous device silence is not promised.

Presentation Settings adds a connected mute checkbox while retaining Reduced Flashes. Status/view construction requests no sound and performs no repair. Dummy is identified as no physical output; another backend name is not proof of working speakers. No slider, sound-test menu, music, downloads, microphone, persistence, new licensing waiver or OS/bus-volume operation is introduced.

## Chronology and verification boundary

The original engineering design was pinned as SHA-256 23bdca56bcce0c19ed1934a4f9803f28b1a3def635e42759578f1d1b3f0f01f6 before implementation. The public technical contract omits procedural preparation wording, with original/derived hashes recorded. A separate, single2.621s QA capability probe passed on Dummy using a test tone and fresh frames: post-stop drain included old nonzero samples, then a new4096-frame window was zero with no discards. It did not test these production clips or establish listening quality.

Author execution and independent verification remain separately attributed. Initial automatic WAV import used compression2; its metadata is preserved privately and corrected to explicit PCM mode0 before resource acceptance. A rejected author fixture used nonexistent `thorn_circuit` rather than catalog `thorn_crown`; only the fixture changed. Consecutive setup epoch origins are normalized for enabled/muted comparative snapshots while actual epoch deltas stay checked. Legacy UI expectations were narrowly updated for two checkboxes and the approved settings label; original failed evidence remains preserved.

Final acceptance must separately prove source RIFF bytes, actual imported/exported PCM and actual engine-mixed nonzero/silent frames with no overflow. Counters alone cannot prove playback, and empty captures cannot prove silence. Physical audibility, human cue discrimination/comfort, device latency and Windows execution remain UNVERIFIED. One finite ordinary observation may supplement controlled proofs; no complete campaign or repeated clean-story attempt is promised. Local source/pack verification is recorded below; no remote-publication claim follows.


## Retained failed attempts and separate corrections

The first author full regression was rejected: 112 standalone checks plus import, 109/113 clean commands. Four checks reached their semantic success marker but still emitted resource-at-exit errors. These are failures, not a green run. A separate local diagnostic observed deferred AudioServer playback/resource release after owner disposal. Only four affected test fixtures gained a 250 ms post-disposal settling interval; no gameplay delay, audio timing change, error filtering or resource-warning allowlist was added. A dedicated test separately observes both voices active, actual mixer drain, fresh silent frames and weak-reference release. This is a finite local observation, not an all-backend cleanup deadline.

Independent checks also exposed a pre-existing malformed settlement validator bug. A String or other non-boolean value could reach an unsafe terminal/shop comparison. A separately reviewed one-condition type guard now refuses malformed values before settlement mutation. Valid boolean policy combinations and previous numeric guards remain unchanged. Its regression uses nonempty gameplay state and verifies unchanged world/session/effects/RNG and current audio on rejected settlement. This is a separate baseline correction, not an audio feature or a change to valid reward policy.

The first independent authority attempt retained its malformed-policy errors. A separate schema-valid negative-coins fixture isolated audio behavior while the baseline correction was reviewed. The first independent mixer attempt was also rejected: installing capture before expensive scene setup discarded startup frames, and short pre-stop windows could consume old queued frames. Strong waveform correlation did not make that attempt pass. The revised external fixture installs capture after scene setup and requires new pushed frames, zero discarded frames and explicit drain before fresh silence. Both original failed scripts and outputs are retained in the evidence package.

The R3 focused validator routes and exact six transaction / twenty-four combat baseline outputs passed locally before final promotion. Final aggregate, source freeze, exported pack and native/ordinary evidence were subsequently established as separately scoped gates below; none is inferred from these focused checks.


## Independent focused R3 result before final promotion

The exact R3 candidate passed 960 independent settlement checks, 236 mixer checks and 168 GUI checks with clean native exits. All 51 mixer windows contained at least 4,096 newly pushed frames with zero discarded frames; the retained raw float samples were reopened and checked. The imported project cache was reused/reimported, not a new cache-free import. The earlier independent 773-check authority result belongs to R2; the final aggregate separately reruns the promoted test on final source. All 683 held R3 inputs remained unchanged. These are focused local results, not final packed/native/physical output certification.

## Final R4 test-only closure

The next complete aggregate still failed, 116/119: charger, game and Warden semantic assertions passed but resource-at-exit errors remained. Unchanged verbose replay identified Warden's player_damage AudioStreamWAV/PlaybackWAV; the other two original resource identities remain unknown. Separate disposal observations retained original 30/193/2510 assertions and measured release plus fresh silence. Historical failures are never relabeled from later successful observations.

A full fixture inventory then replaced final test-owner disposal in 99 fixtures with a shared bounded observer, preserving all original assertions and all non-disposal logic. Three dedicated mixer/teardown fixtures retained their own proof, and 16 non-audio fixtures remained unchanged. A test-owned WAV dictionary was explicitly cleared after its last use. The observer rejects empty/invalid ownership, unreleased nodes/resources, nonfinite or dropped samples, insufficient new/consecutive silent frames, or completion outside 150 ms to 1 s. Its 15 predicate tests comprise one positive and 14 negative deterministic states; actual owner behavior is separately executed. It introduces no production wait or error suppression. All 128 production paths, the 180-second case caps and runner failure rules remain unchanged.

R4 focused 14 scripts plus import passed with original assertion counts and 696 unchanged inputs. The complete author aggregate then passed 119 scripts plus import, 120/120. Independent audit reopened all raw logs, verified exact command discovery/order and all 106 final-owner observations across 99 adapted fixtures, and rehashed every input. This independent review is not another execution of the whole aggregate.

## Exact resource and independent packed proof

Both preset PCK files are identical: 41,438,836 bytes, SHA-256 99b5232f7d5866ab3152f78990ed6ad37ed55957cf85f1712418c056daa3638d. Linux ELF remains 2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0. Independent selected execution passed generic resources 853, packed authority 773, internal mixer 236, GUI 168 and settlement 960; PCM 38 and export-helper safety 3 also passed. Generic texture fingerprints do not cover WAV PCM; packed authority checks canonical imported sample hashes separately. All 51 mixer windows contained sufficiently new frames and zero discards. Raw floating-point files were reopened and checked.

Tests are intentionally absent from the runtime PCK. External packed fixtures only rebind their test-helper preload to a separately pinned external helper; reversible path-only differences and hashes are recorded. No QA helper is shipped as production. Source fingerprinting reused an existing independently imported cache, not a claimed fresh cold import.

## Native and ordinary boundaries

Four external controlled cases in both modes at 960×540 and 1280×720 yielded 11 original captures. Native mouse and Tab/Enter settings, real resolved block/loss requests and muted HP loss worked. Six cue requests were accepted and one muted request rejected without suppressing damage. A real application focus-out event produced pause, but its preceding voice had already naturally ended; interruption of an active voice is not proven by that native attempt. The external fixture exited 0 and its window disappeared.

The standard release ELF initially refused an unsupported --main-pack override before entering a game (exit 1). That failed command/log remains. Normal adjacent-PCK startup then ran one Arena/Rivet/default-seed 240102 attempt at actual 1180×812, with no injection/reset/reroll. Fresh settings were off, ordinary kills and earned upgrade/salvage flows reached the first shop with 164 scrap; normal close exited 0 and the window disappeared. An early stale title capture and delayed close observations are retained rather than treated as synchronous proof. Ordinary HP loss, natural Mirror acquisition/block and ordinary audio output were not established. No second run was taken to manufacture those observations.

Dummy output, explicit VSync/llvmpipe limitations, no physical listening/Windows/controller/campaign/performance certification, and prior failures remain visible in the [independent report](validation/independent-v35/QA_REPORT.md). The source release changes only declared current documentation/manifest beyond the tested 696 inputs; production 128 stays exact. Local preparation and recovery are not Git publication.
