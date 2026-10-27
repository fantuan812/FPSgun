# v38 Stitch Drone — current portable package and exact history

## Final portable resource package and retained packaging rejections

The current complete PCK is **42,955,188 bytes**, SHA-256 `b8f648cc2f9378dfffc162375e105dd2e5ccd21044cb6496e4ebe39027a38740`. Both presets match. Linux ELF remains `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0`.

The earlier SVG pack `795ce7c1…` passed its functional checks but **failed public-package privacy scanning**: its non-runtime measured-art JSON contained eight absolute staging paths. Source-document rebasing alone could not change those already exported bytes. That package and the first assembly rejection remain preserved, not delivered as the final pack.

A separate portable 787-input candidate changes exactly measured metadata, the export recipe's recorded command strings and MANIFEST. The actual export invocation, SVG geometry, runtime PNGs, gameplay/UI/data and imported pixels are unchanged. Isolated recipe regeneration reproduced four SVGs and eight repeat PNG exports; only the eight recorded command paths became relative. A new seven-step resource-only export passed.

The first strict all-record comparison also **failed**: besides the intended metadata record, the packed main scene differed. Independent inspection found only four bytes at offsets508–511 in its684-byte resource. Actual engine decode confirmed eleven bundled keys, with only the one-element `node_ids` array changing106410627→707380806; all other bundled values and680 scene bytes are identical. Official Godot4.6.3 source documents this stored scene-ID field. A separately authorized, exact-pair exception is limited to these pinned bytes/IDs—not arbitrary scene differences or general serialization tolerance. Under that new finite gate, all219 paths match,217 payloads are byte-identical, the metadata differs in exactly eight strings, and only that exact scene-ID field is excepted. The original strict gate remains FAIL.

Both final PCKs pass whole-byte private-prefix scanning. Actual new-PCK asset121 checks passed against the unchanged imported-pixel/Atlas oracle. One bounded normal native main/title launch used the unchanged release ELF and adjacent final PCK; it exited0 after the fixed frame limit. QA directly observed the1180×812 title window, but no local title screenshot was retained. A private after-exit terminal image is not title evidence and is excluded. Unsupported VSync warning remains.

This final packaging gate is **not another28-step gameplay run, ordinary run or full139 suite**. Earlier generated-art139/ordinary evidence and the preceding SVG source120/actor418/animation35, packed121/418/35 and controlled28/29-still evidence remain bound to their actual checkpoints. Exact resource/pixel comparison and the new finite package checks connect the portable revision without rewriting those histories. Subsequent local delivery checks passed10 total cases with74 historical rows retained,76 total rows,15 chunks and18 exact payloads. Actual v37→v38→v37 file backup/replacement/rollback passed with original executable/modes preserved. This is not gameplay rollback or a remote-download proof; remote publication still requires an actual commit and readback.

## Preserved preceding functional-art checkpoint

The following original presentation describes the previous SVG functional checkpoint and its earlier history. Its795ce7c1 pack is superseded for public delivery by the portable package above; its then-current statuses are not new final-pack executions.

---

# v38 Stitch Drone — behavior, editable source and verification boundaries

Stitch Drone is a visible, interruptible enemy support interaction, not a new player multiplier. Base HP34, move speed30, contact damage6, XP7; normal encounter HP scaling still applies. It chooses one living wounded ordinary enemy within150px by HP fraction, then distance, then stable ID. It cannot repair itself, another support enemy, a boss or summoned child. A1.2s channel repairs up to10HP; any actual source HP loss interrupts. Target nonlethal injury alone does not. Recovery is.7s, cooldown5s, no-target retry1s. The cyan dashed tether/four-notch progress and success-plus/broken-tether markers are authority-derived, with Reduced Flashes support.

Selection happens after all normal enemy movement/clamping/child spawning. Final eligibility and repair happen after the old projectile/death/pickup phases; dead enemies are not revived and the old death loop is not repeated. Fresh per-channel identity tickets reject fabricated/stale/duplicate completions. Heal updates the next hurt baseline without restarting the target animation. Death/terminal disposal clears ephemeral source fields without a visual burst; pause freezes channels instead.

Only Arena wave4 adds this enemy to its existing three-kind pool, with at most one normally spawned living drone. Position draws remain old order; there is one kind draw on the filtered pool, no retry. Rooms CROSSFIRE and BROOD each append one at normalized[.5,.18], retaining all four original entries. These introduced encounters intentionally alter seeded trajectories. Exact old-encounter controls are a separate claim, not whole-run new-encounter seed parity.

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

## Presentation-only source metadata

The public `art_source/stitch_drone/metadata/measured_assets.json` command paths are rebased from private absolute staging paths to `source/...` and `exports/...`, relative to that art-source directory. Create the export directory when reproducing those documentary commands. Exactly eight string fields change; source, settings, hashes and measured pixels do not. Original/public hashes and the field-level mapping are retained. This is a presentation-only derivative, not a target rerun.

The complete139 source run retained48 filled-rectangle-width warnings. New SVG native used Dummy and retained its VSync warning. Original frames are not enhanced or silently replaced. The extra29th native still observes later corpse removal, not a new case or a proof of a particular animation final frame. Delivery-helper/remote closure remains a separate subsequent gate at this checkpoint.
