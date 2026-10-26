# v29 candidate — trade one stat choice for scrap

**UNVERIFIED DEVELOPMENT WORK.** The exact accepted predecessor is v28. True cold import, 147 focused author checks, existing reservation 520 and UI structure/intent checks pass; independent full/runtime/native/export acceptance remains pending.

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

See the [frozen contract](V29_UPGRADE_SALVAGE_CONTRACT.md). Author checks in `tests/test_upgrade_salvage.gd` pass 147/147. The first authored test had a missing return in its recursive button collector and failed parsing before running; that harness-only rejection and one-line correction are retained. No production revision was needed. Independent no-salvage state/RNG parity, strict payload/queue/lifecycle tests, both-mode native 960/1280 review, packed-resource proof and a finite ordinary exact-pack decision route are pending.

The parallel knowledge lane released its exclusive window before these checks; subsequent game checks are coordinated serially. No unrun check is called a pass. No new art, catalog data, encounter data or executable is planned. Eventual delivery remains GitHub-only source/evidence plus a verified complete PCK using the existing restoration helper and manual backup/replacement. Windows and cloud audio limits remain separate.
