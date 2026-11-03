# Medical Recovery: shop acquisition

## Change

The existing Medic Winch + Medic Seed mechanism now participates in the shop's existing missing-partner system. The catalog appends one bidirectional affinity link, bringing the link count from 14 to 15. The catalog remains 10 weapons and 36 modules; no new item, combat rule, price, refund, reward, slot limit or weighting constant is added.

With only either component owned and the default Rivet Gun, its missing partner has selection weight **3.5 instead of 1.0**: the existing base 1.0 plus the existing missing-partner bonus 2.5. The pair has different tags. A weight is not an offer probability, an exact chance multiplier or a guaranteed offer. Other owned tags can contribute through the unchanged capped weighting rules.

Buying both components removes the missing-partner status, and the unique owned items stay excluded from new stock. Selling one restores the missing-partner bias toward the sold component; selling the last component removes it. Reservations are not ownership. A held card retains its original weight/reason snapshot even if the owner is later sold; fresh cards use current ownership. This preserves the existing reservation contract.

Only catalog data changes at runtime. Prices remain 24 scrap for Medic Winch and 28 for Medic Seed. The Winch still moves existing medical pickups rather than creating or healing from an orb itself. No combat or medical-pickup behavior was changed.

## Regression contract

- `tests/test_medical_shop_affinity.gd`: 1,099 current-catalog checks, including both directions, exact raw weights, unchanged unrelated raw weights, positive exploration, maxima, deterministic distinct draws, all four held slots, unchanged neutral/completed replay, and actual shop reserve/refresh/buy/sell handlers in Arena and Rooms. Builds and seeds are controlled test inputs, not an ordinary-play acquisition claim.
- `tests/test_B_catalog_current.gd`: deliberately changes the expected affinity count to 15; all 27 existing current-catalog/profile/forecast assertions pass.
- The historical B projection strips only this exact appended link, verifies the original accepted B catalog SHA-256 and raw/structured agreement, then applies the unchanged historical inverse. Existing fixtures are not rewritten. The 24 projection and 17 historical A-link checks pass.
- Existing shop (216), reservation (520), B pickup-source (34) and historical cache (20) checks pass.
- The compact BUILD aggregate passes its unchanged 14 routes: 4,931 numeric checks plus one text-marker route. Relative to the accepted v57 validation manifest, only the catalog and historical-helper pins change. The published manifest had retained ten older Core/export dependency hashes and v56 baseline metadata; these are also reconciled to the accepted v57 manifest, with all ten live files independently matched against the published head. No old fixture is weakened. Its 48 previously specified Scavenger `draw_rect` warnings remain accepted under the unchanged exact warning policy. This is not a new full-game regression result.

Independent review separately passed 8,268 custom checks, the 1,099-check author fixture, eight existing regression scripts and a 14-check reservation supplement. The supplement verifies that unowned medical reservations grant no affinity and that maximum ownership invalidates held stock through the existing four-fresh draw path. Seeded sample frequencies are diagnostic, not advertised probabilities.

## Package verification and limits

A fresh Linux resource pack was exported and read from an empty working directory without source-resource fallback. Source/packed resource verification passed 1,068 checks; the same 1,099 medical checks passed against the PCK. The main scene also completed a bounded 30-frame headless editor-reader startup. This does not certify a native exported executable, rendered GUI, Windows, physical sound, full campaign, all seeds or balance.

The pack retains 301 payloads. Against the accepted v57 pack, 298 payloads are byte-identical; the changes are the intended catalog, the generated main-scene instance identifier and the UID cache. The UID cache adds references for the 14 existing compact test scripts and the one new test because this export uses the portable validation project. The test bodies, documentation and tools remain excluded. Main-scene structure and properties match the unchanged source scene in the resource verification.

Earlier execution failures remain distinct: an initial launch with nonwritable default HOME/XDG produced environment errors and an engine crash before tests ran; isolated writable directories resolved that setup. The first isolated author fixture had an inferred-type parse error in its test label, corrected to explicit String. Corrected source and packed runs passed. A separate extracted-scene diagnostic first used a wrong expected old identifier while adapting its test fixture. Its original failed assertion is retained; the corrected exact-pair check passes 14 assertions and identifies only the generated node_ids value as different. No package bytes changed for that correction. These failures are not production gameplay defects or first-pass successes.

CI and publication are separate from these local checks. This document makes no claim that a new commit, release or binary was published.

## Reproduce

Use Godot 4.6.3 with writable HOME/XDG directories, import the project, then run:

```
godot --headless --audio-driver Dummy --path . --script res://tests/test_medical_shop_affinity.gd
python3 tools/run_build_ui_checks.py
```

The focused test supports an external audio-teardown helper path after `--` when running through `--main-pack`, because tests are intentionally absent from exported resources. That helper observes release and internal Dummy silence; it does not certify listening.
