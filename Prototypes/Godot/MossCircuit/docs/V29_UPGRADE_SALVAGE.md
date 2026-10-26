# v29 candidate — trade one stat choice for scrap

**ACCEPTED WITHIN THE FINITE SCOPE BELOW.** The exact accepted predecessor is v28. True cold author import, 147 focused author checks, existing reservation 520 and UI structure/intent checks pass. Independent cold-source runtime 294 and UI 901 checks, unchanged 40-case no-salvage projection, and bounded controlled native UI review pass. Final source, exact pack and finite ordinary native gates now pass, with the limits recorded below.

## One deliberate trade-off

Each earned choice still draws three of the same six permanent upgrades. A separate optional resolution forfeits that one stat choice for **10 scrap**. Earned level/XP stay. Scrap is credited immediately, but spending still depends on reaching a shop under the existing mode policy; no shop is opened or guaranteed. Ten is experimental tuning, not a broad balance conclusion.

The ordinary initial SELECT focus and existing automation remain unchanged. There is no seventh upgrade, reroll, refund, item, discount or automatic choice. Reserved offers remain unowned stock; extra scrap may make the existing price affordable later.

## Authority and UI boundary

- `Rules.UPGRADE_SALVAGE` is the single fixed ID/whole-integer amount/copy definition. `upgrade_salvage_definition()` returns a deep copy; `_upgrade_salvage_view()` adds current scrap for presentation only.
- `_salvage_upgrade(generation, resolution_id)` requires an actual integer current generation, actual String ID, upgrade state, nonempty page and positive pending count. It returns false without mutation for invalid/stale requests.
- The new `salvage_upgrade {id,generation}` intent passes raw values, not coercions. Extra caller metadata is ignored and cannot override the fixed reward. No client amount is read.
- `credit_upgrade_salvage(build)` adds the fixed whole integer directly to coins, preserving an existing fractional-credit remainder exactly. Existing `Rules.credit` and all ordinary income paths are untouched; coin bonus does not apply.
- `_resolve_upgrade_choice()` contains only the existing clear/decrement/next-page/normal-shop/resume tail. The existing stat branch retains its derive/heal order. The salvage grant does not revise the build, recompute stats, heal, sync effects, clear physical effects or draw RNG. A legitimate next page/shop still uses its normal RNG and context boundary.
- `show_upgrade(options,generation,salvage={})` keeps two-argument callers compatible. The fourth resolution is a separate footer beneath the three-card scroll, not another random card. Its button emits only ID and generation.

## Planned bounded acceptance

See the [frozen contract](V29_UPGRADE_SALVAGE_CONTRACT.md). Author checks in `tests/test_upgrade_salvage.gd` pass 147. The first authored test had a missing return in its recursive button collector and failed parsing before running; that harness-only rejection and one-line correction are retained. No production revision was needed.

Independent runtime 294 and UI 901 tests are promoted unchanged into `tests/independent_salvage_runtime.gd` and `tests/independent_salvage_views.gd`, with optional output arguments. The external no-salvage trace has 40 controlled both-mode cases; the complete 559,100-byte old-state output matches v28 exactly. It includes queue/stat selection, stale callbacks, normal shop continuation, held offers and legal mixed builds, not a claim of every possible combat trace.

Controlled native review at actual 960×540 and 1280×720 in both modes accepted the separate footer, exact forfeiture/amount, default ordinary SELECT, Tab/Space and mouse salvage, third-card scrolling, and legacy two-argument layout. A controlled 32-scrap held-Rail case salvaged to 42 then purchased for 42, ending 0; a mixed salvage/health/salvage queue reached 52 and the already-pending shop. These are labeled injected setup with actual CUA UI inputs, not ordinary acquisition evidence.

QA's first candidate scripts were mistakenly launched before asynchronous cold import completed, so missing imported-resource errors invalidate those outcomes even though some assertions printed pass. The original logs are retained; clean reruns waited for import termination. A disabled-simulation native fixture also needed presentation-only weapon-rig synchronization after dismissal; its correction is separate from the unchanged production source. Final engine runs include 90 standalone checks plus reused-cache import; all 601 inputs stay unchanged. The independent wrapper initially recognized too few success formats and scored 18 clean old logs as failures; retained raw results and an explicit reconciliation show all 91 engine executions exit 0 with no engine errors. No unchanged tests were rerun simply to repair the wrapper score. Python safety 3, independent pack resources 837, packed runtime 294 and packed UI 901 all pass.

The ordinary exact-Linux Rooms seed-128 route uses automated CUA inputs and tactical pauses, with no injected state: after the first real encounter, the first choice shows 66 scrap; Tab/Space salvage opens the already-earned next page at 76; default Return selects Repair Plating, then the normal shop retains 76. Rivet remains at primary 15/global damage bonus 0%; HP/max HP 120 follows the separate ordinary Repair selection, not salvage. No purchase, full campaign or balance conclusion is claimed. The window is closed externally by terminal Ctrl+C and its absence confirmed; executable/PCK before-after hashes match. Inherited ALSA dummy-audio and unsupported-VSync diagnostics remain, without new script errors. Windows and audio are not accepted.

The parallel knowledge lane released its exclusive window before these checks; subsequent game checks are coordinated serially. No unrun check is called a pass. No new art, catalog data, encounter data or executable is planned. Delivery uses GitHub-only source/evidence plus the exact verified complete PCK using the existing restoration helper and manual backup/replacement. Windows and cloud audio limits remain separate.
