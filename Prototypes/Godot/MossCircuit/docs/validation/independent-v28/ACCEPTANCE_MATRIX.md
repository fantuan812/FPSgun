# v28 independent acceptance — one reserved shop offer

Status: acceptance expectations frozen against contract SHA256 `64a6dec913b4c16fe866c0e5d2d994a8702e8acc977a44221b9a0a3b939dd842`, independently accepted before implementation. This is not implementation acceptance. Baseline is exact accepted v27.

## Player decision

Keep one unaffordable or strategically desired existing offer for later, in exchange for one of four shop slots no longer revealing fresh stock. This is an offer reservation, not ownership, a fifth slot, a discount, a guarantee of future income, or an extra shop. No new item/art/stats. Prefer this over a generic level-choice reroll because it enables an intentional multi-encounter build purchase plan without changing existing prices/rewards.

## Frozen contract summary

- At most one unsold eligible offer. Free reserve/unreserve; require explicit unreserve before switching. Unaffordable/full equipment slots do not prevent reserving.
- Keep original slot and draw-time weight/reasons across paid refresh/later shops. Current preference header may change; retained historical reasons must not be relabeled a fresh probability.
- No-reservation calls retain the exact old four-draw path. With a reservation, remove its ID before drawing the other three with current owned-build weights, without replacement. Reservation toggles consume no RNG. Using the feature intentionally changes subsequent shop RNG/stock.
- Successful reserve/unreserve invalidates old shop callbacks via generation, not currency/build revision. Failed/stale/repeated actions are inert. Failed purchases do not release the reservation.
- Successful purchase clears reservation and keeps the current card sold. Existing weapon replacement, prices, module caps and sell rules remain authoritative. Full slots alone are not an invalid-reservation condition; unknown ID, changed recorded price or max-stack ownership clear immediately before the next successful draw with explicit notice.
- Stage progression, inventory and pause retain it. Title/new run/death/victory clear it. Clearing ordinary combat transients must not accidentally remove it between shops. No reservation contributes to tags, synergy, stats or preference.

## Independent matrix

| Area | Inputs / observed outcome |
|---|---|
| Strict preservation | All 8 weapon +29 module IDs/definitions, prices, weights, affinity links,6 upgrade definitions, stage rewards and combat inputs exact. No-lock v27/v28 finite shop/transaction/RNG trace equality; full existing suite retains strict ID sets. |
| Reservation authority | Each of4 slots; weapon/module; funded/unfunded; duplicate press/current vs stale generation; second reservation refused without silently replacing first; invalid state/index/type inputs fail closed. Currency, revision, stats, ownership and three RNGs unchanged by toggles. |
| Weighted refresh | All4 original slots × several valid owned builds × fixed seeds. Reserved record exact; exactly3 fresh IDs, none equal held ID; expected weights from current actual ownership, no duplicate. No-lock exact4draw path. Failed insufficient-funds refresh leaves every state/RNG unchanged. |
| Retained metadata | Reserve, buy/sell another tag source, inspect repeatedly, refresh; reserved draw-time reasons retained while fresh offers use new preference. No false percent/guarantee and no reserved-item ownership contribution. |
| Purchase / replacement | Reserved module purchase, full module slots then sell/retry, full weapon slots with explicit replacement, invalid replacement slot, insufficient funds, sold offer, old callback double click. Success clears once; failure retains; no free ownership/negative currency/slot leak. |
| Cross-stage lifecycle | Actual Rooms and Arena settlement to next shop retains same offer/slot; stage with no shop does not create one. Pause/inventory/settings preserve where supported. Actual title/newseed/retry/result clearing; old tokens cannot reserve/buy on a later run. |
| Invalid held record | Unknown ID, changed recorded price and ownership at max-stack: preserve on failed refresh/buy, clear with retained explicit notice before a successful draw. Short pools insert at min(original slot, fresh count), retain original preferred slot. Full equipment capacity is distinct from max-stack eligibility. |
| Presentation read-only | Repeated view/render leaves state/RNG unchanged. Both modes at960×540 and1280×720; first BUY/REPLACE remains visible; reservation count/state and unlock-first instruction legible; keyboard/scroll works. No new raster needed. |
| Export / ordinary use | Exact PCK/source parity, one finite normal-control shop reservation→refresh or nextshop→purchase/cancel route. Automated CUA/tactical pause disclosed; no injected build or economy. Controlled tests cover unavailable ordinary edges; no full campaign required. |

## Baseline facts already inspected

`main._roll_offers` replaces all four via `Rules.draw_shop`; there is no reservation. Offers carry `id`, `sold`, draw-time weight and reasons. `shop_generation` protects existing transactions. Shops use `shop_rng`, level choices use separate `loot_rng`. Rooms grants one settlement choice in addition to XP levels; extra choice pages are intended, not a newly claimed defect. Three-of-six level choices currently have no alternate conversion, but that separate mechanic is deferred rather than bundled.

## Pinned edge clarifications

- Stable reservation token is the generation issued at reserve time; later refresh/sale generations do not rewrite it. Unlock checks current generation AND stable token.
- Stored price is an identity guard, never a transaction override. Invalid held identity/price makes its purchase fail atomically until explicit unlock or deferred invalidation.
- Full slots are not max-stack ownership. Reservation is allowed at full weapon/module slots and without funds.
- Invalidating a held record does not add a second generation bump or erase its notice with generic New stock.
- A successful purchase clears the matching reservation only; no replacement stock is drawn. Unlock leaves the current card unsold and visible.
- Native keyboard/mouse and controlled Godot default ui_accept/focus input events are separate evidence; no physical gamepad gameplay certification.
- Reservation does not save to disk, modify any catalog data, create a stage/shop, or reset between ordinary stages.
