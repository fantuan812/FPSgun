# v18 — crawler registration and discrete UI numbers

This small increment follows the verified v17 source. Its verified remote parent is v17 commit `e5176670b2f478a187f7f98b09554baa3c50a6f7`. It does not add enemies, attacks, art rasters, economy changes or game-completion claims.

## Two evidenced presentation fixes

- **Crawler hurt registration:** existing nine poses used a source-column layout that visibly reset sideways at frames 2→3 and 5→6. Fixed column X offsets `[-25,-4,26]` preserve the original PNG, source regions, vertical recoil, canvas, anchor, scale, frame order, 0.27-second reaction and all death data. The actual legacy sprite height is approximately 35.1087 world pixels. Source semantic audit, deterministic generator and both-facing native A/B review are recorded in `art/crawler_hurt_registration` and independent validation evidence.
- **Whole-number shop/inventory labels:** JSON represents integer-valued prices and slot caps as floats. Counts, stack caps, purchase/replacement/refresh prices and sale refunds now use integer presentation. Fractional stats and cooldowns remain fractional. No catalog values, affordability checks, transaction payloads or incoming view dictionaries are modified.

## Verification contract

The focused number test covers normal purchase and full-slot replacement, disabled unaffordable actions, module limits, unknown stack-cap fallback, inventory counters, unchanged input and intent payloads, and preservation of fractional stats/cooldowns. The final 34-check test exposes twenty expected-label failures on v17 and none after the formatting fix (the initial 30-check diagnosis exposed sixteen). The crawler focused test checks all nine poses in both facings at real registration height. An independent primary-hit pipeline test checks damage-triggered hurt, repeated-hit nonrestart, ongoing movement, current-phase walk handoff and lethal interruption in both modes and both sides.

Run the aggregate against a fresh extraction, with output outside the project:

```sh
python3 tests/run_regression.py --project . --output ../moss-v18-checks
```

Final aggregate and integrated GUI results belong in versioned validation reports, not in these test intentions. Stationary stepped-pose art review is not continuous-motion or real-combat GUI certification. Windows export, human play-feel/balance and a complete dungeon remain unverified or out of scope. Prior v16/v17 evidence stays historical and does not replace current acceptance.
