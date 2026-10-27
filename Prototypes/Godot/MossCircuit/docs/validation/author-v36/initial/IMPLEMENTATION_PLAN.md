# v36 implementation preparation

Historical preparation plan: exact696-input v35 baseline was copied before production changes. C1 was superseded by independently accepted C2 SHA256 1189f9778046550b7964c000c5af7fa1df582af81297d06885b39e495af2eb79 for JSON integral-number quota compatibility only. Independent initial oracle froze before implementation; current execution results live in initial/RESULT.json, not inferred from this plan.

## Proposed seams

- Optional validated unique catalog row, ordinary effects empty; one original reel SVG icon and one Return Disc affinity link. No new stat threshold.
- Pure gameplay/scavenger_reel helper: validated profile and independent launch snapshot, finite strict closed-segment eligibility; no world reward side effects.
- Only return_disc launches with owned valid item append `scavenger` metadata `{radius,remaining,maximum,sources}`. Old bullets have no added keys.
- WeaponCombat.advance_disc returns an Array of transient `{disc,start,end}` return-only sweeps; existing motion/hit/lifetime and old ignored-return callers unchanged. Exact actual return-part endpoints recorded even when that part retires disc. Empty for expired/outbound/arrival-without-motion/zero displacement.
- Runtime.step accumulates sweeps locally in existing descending bullet-index order. Ground pickup loop retains reverse index and pre-move contact check, one magnet move and original player-contact precedence. Remote branch tests post-magnet pickup coordinates, spends first eligible disc quota, then uses original RunFlow/event/removal once. Current-step death drops eligible; event-appended pickups wait.
- Existing effect_visuals contains capped interception pulses, no pending acquisition state. Quota pips read metadata only, respecting terminal and reduced-flash presentation policy.
- Mechanism/build/shop text derives quota/radius/sources from validated data and explains Return Disc dependency, return-only immediate normal/energy collection, medicine exclusion. Tags supply existing affinity only.

## Bounded execution sequence after oracle freeze

1. Catalog/profile/snapshot validation and original icon/UI construction together with target implementation.
2. Freeze source diff; independent static audit before serial engine execution.
3. Focused launch/geometry/order/phase/effects/cleanup/presentation/validation tests, including contract paper examples and exact old-catalog transaction/combat parity.
4. Preserve every failure, diagnose without relaxed error predicates or extra timeouts; revise one declared candidate if needed.
5. Final source aggregate at unchanged standard budgets, independent targeted authority/views/native and actual pack checks. Explicitly separate old-catalog parity from deliberately changed expanded-catalog seed offers.
6. Current v35 source, pack, release, raw failure evidence remain untouched. Remote publication remains separate.
