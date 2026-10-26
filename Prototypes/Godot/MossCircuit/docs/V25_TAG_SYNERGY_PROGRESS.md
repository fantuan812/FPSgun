# v25 — existing tag-synergy progress

## Scope

The build inventory now explains the three tag bonuses that already existed. This is not new content or a balance change. Every row shows its current owned-copy count, threshold, ACTIVE/INACTIVE state, unchanged catalog description and precise scope qualifier. Counts are not clamped at the threshold.

- ARC GRID: electric-tag equipment activates the existing additive electric weapon-damage bonus.
- SAW RIG: melee-tag equipment activates the existing additive melee weapon-damage bonus.
- SCATTER RIG: spread-tag equipment activates the existing extra pellet for spread attacks only.

The exact fixed rule definitions, counts and activation are shared by `Rules.derive` and the read-only progress view. Catalog IDs, tags, thresholds and order are constrained to the three shipped definitions; arbitrary new rows do not create a generalized effect engine. Catalog bytes, item effects, shop weighting, transactions, RNG and weapon calculations remain unchanged.

## What counts

Each equipped weapon slot counts as one copy. Each actual module copy counts, including multiple copies within its owned stack. An entry with several tags contributes once to each listed tag. Offers, unowned items, upgrade levels and `max_stack` limits are not ownership. Progress updates after successful buy, sell-one, weapon replacement and reset; viewing it is read-only.

Bonuses apply once when the threshold is reached, not again for every threshold multiple. Electric/melee bonuses add to the matching weapon modifier rather than multiplying final damage by 1.20. For example, Rail Lance with two Capacitors deals 51 primary damage before other modifiers, not 54. Shotgun with two Pellet Pouches fires eight pellets. This does not grant extra projectiles to every weapon or directly scale fixed module damage.

Three Capacitors or three Saw Gears can activate their rule even without an equipped matching weapon. Such a rule stays ACTIVE, with a separate explicit note that no current weapon benefits. Mechanism-pair prerequisites remain a different section; their semantics did not change. Existing BASE/CURRENT weapon readouts remain authoritative.

## Validation and limits

Final evidence pins 76 standalone source tests plus import, independent561-check authority parity and848-check status/view coverage, packed-resource825 checks and packed-view848 checks. Controlled native UI at960×540 and1280×720 in both modes and ordinary exact-pack seed128 first-shop display smoke passed. Production initially had a cold import; final added-tests/docs checks reused that cache. The preserved rejected baseline-oracle assumptions and author initial mid-run wording/hash-guard rejection are explicitly documented. No repeated full campaign, new artwork, Windows execution or audio acceptance is implied.

Source recovery uses the accepted full v23 source plus the exact v24 overlay, then the v25 overlay. The source overlay is not a PCK update. Runtime updates require the matching accepted base PCK and unchanged executable; make a separate backup before any manual replacement. No automatic installation is performed.
