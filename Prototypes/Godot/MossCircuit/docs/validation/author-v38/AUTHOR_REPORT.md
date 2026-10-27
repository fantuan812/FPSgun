# v38 engineering evidence: support behavior and editable-art migration

## Gameplay authority

Stitch Drone is a finite support enemy, not a damage-immunity aura. A living source selects one eligible wounded ordinary ally, warns for 1.2 seconds and repairs up to 10 HP only after all required final checks. Source HP loss interrupts; nonlethal target damage does not itself prevent repair. Bosses, support sources and spawned children are excluded. Repair never resurrects a dead or removed actor. Shared runtime phases, per-channel identity tickets, bounded recovery/retry and explicit cleanup preserve the existing damage, reward and RunFlow settlement authorities.

The narrowly declared encounter additions are an Arena wave-4 pool entry with a living-support cap and one placed support in each of two Rooms stages. Old encounter/Rooms data are recovered only after strict exact-addition validation. Candidate old-encounter six-transaction and 24-combat traces match the retained executed baseline bytes; this does not claim unchanged seeds for expanded encounter pools.

The design C1/C2/C3 files are historical preimplementation checkpoints. C3 explicitly distinguishes actual existing damage sources from defensive fault injection at late kill/pickup event seams: the old effects implementation did not provide immediate kill/pickup enemy damage procs. No such new proc is claimed as gameplay.

## Original failures remain failures

- First author cold import passed. The first smoke fixture omitted the existing combat-frame area binding: 18 checks, eight failed assertions and six engine errors. Only that fixture setup was corrected; the subsequent corrected author plus seven previously unexecuted focused routes passed. The original first run is not rewritten as a passing aggregate.
- A later independent real late-projectile death control exposed a production cleanup defect: removed source dictionaries retained channel metadata even though there was no repair or resurrection. Both mode failures remain. A new candidate adds support-only disposal immediately before the unchanged death removal; independent cold import and the five bounded routes passed. This is a lifecycle defect, not evidence of a memory leak.
- The original complete 138-command run ended with 135 passes and three rejections: the single-process audio authority exceeded 180 seconds, two short-clip playing-state assertions failed in settlement coverage, and the old actor fixture did not account for the new support profile. The old runner did not capture partial timeout streams. Earlier engine output and last completed phase are therefore NOT_CAPTURED, not retrospectively clean.
- The one instrumented settlement diagnostic passed its original 960 checks and 204 observations, but did not reproduce the historical failure. Its cause remains unresolved; natural expiration or environmental timing is not asserted as proven. The later observer contract replaces 204 indefinite-playing assumptions with forwarded explicit-stop-call observations and adds 204 real-stop positive controls. Existing decision/outcome assertions remain; playing flags remain telemetry. The resulting 1164-check fixture is a changed oracle, not a relabelled old pass.

## Accepted historical gameplay source gate

The new 772-input candidate retains the 139 production inputs. Its source audio gate is explicitly different: original resource97 plus Arena338 gives 435, and Rooms338 runs in a separate process. Each has a 180-second cap; combined maximum is 360 seconds rather than the rejected original single-process 180 seconds. All original cases/order/assertions are preserved, and the original 773 script remains historical test support.

The standard runner also gains exact partial-timeout-stream preservation and dispatch for the second partition. Synthetic timeout controls retain invalid UTF-8 stdout/stderr bytes. These changes do not turn native124 or engine errors into success. All original rejected artifacts remain available.

The new complete 139-command run passed with unchanged 772 source inputs, followed by a separate exhaustive read-only review of its original logs. Execution was coordinated by the QA worker; that audit is not another full execution and this bundle does not claim the implementation author ran it. The initial new-directory import was cold; aggregate import reused that cache.

## Editable SVG supersedes generated art for the formal candidate

The old generated-art source/full-suite, packed, native and ordinary evidence remains bound to those old bytes. Original four AI images are retained under `reference-only/` solely as historical references; they are not the authoritative source for the redraw or runtime assets.

Four new semantic SVG sheets and their editable geometry/palette sources produce the new runtime PNGs. There is no embedded raster or pixel-autotrace. Independent fresh exports, alpha/crop/Atlas identity and the new asset-only source gate are distinct from the old gameplay full suite. The 783-input staging candidate imported exactly four SVG sidecars; a presentation manifest refresh yields the final 787-input freeze. Scripts/UI/data/scenes remain byte-identical to the accepted 772 gameplay source.

For the new 787 candidate, actual source import plus assets120/actor418/animation35 passed. Two resource-only preset PCKs match at 42,955,492 bytes and SHA-256 `795ce7c1761766f73d23c5feec620c5f2d59d7ed005eb1cdfe33a6e8d54815d1`. Export verification has seven commands, including 916 packed-resource checks; Windows execution is not tested. The unchanged Linux executable has SHA-256 `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.

Dedicated actual-new-PCK assets121/actor418/animation35 passed. New controlled native evidence covers four mode/size combinations and 28 real Runtime steps, with 29 original stills and native exit0. The extra late corpse-removal still is not another gameplay case. The older ordinary run is not replayed or transferred to new SVG pixels. Warnings and finite observation boundaries remain in the independent report. No full139 rerun on new art, physical listening, Windows, exhaustive seeds/campaign or broad balance certification is claimed.

The actual new PCK's 219 directory entries and their payload checksums were inspected: no docs/reference-only path or original-four-reference PNG payload appears. New imported pixel identities are separately checked against the source import. Reference-only evidence is protected by `.gdignore` and both runtime presets exclude `docs/*`; this is supported by actual PCK inspection, not settings alone.

## Public derivation and limits

This is a documentary evidence bundle. `COPY_PROVENANCE.json` records original/public byte hashes, sizes and every neutral path/coordination-text transformation. Original numerical results, failures, timeouts and gate scopes are not changed. Binary float captures, invalid UTF-8 timeout streams and reference images retain exact bytes. Rebased documentary scripts and patches are not asserted to be directly runnable from their public location.

Profiles, caches, private recovery archives, credentials, executable/PCK binaries and internal handoffs are excluded. Current public source is assembled separately, only after review. Historical proposal language is not current implementation status; local acceptance is not a claim of a new GitHub source commit. The separately discovered inherited modal-focus issue is tracked for a later UI revision and is not silently patched into this frozen v38 candidate.
