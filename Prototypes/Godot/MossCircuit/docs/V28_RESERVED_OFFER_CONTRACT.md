# v28 — one reserved shop offer

Accepted base: v27 source/runtime commit `b9eee1b8a15cd8cc35a612858225ddd5d418b552`; indexed delivery head `50d572acb8d6d77b28470ed63edb6d5785033804`.

## Purpose and bounds

The current shop replaces all four offers on refresh and each new shop. Build affinity improves odds but cannot preserve an unaffordable desired component. Add one meaningful planning decision: **reserve at most one current unsold offer**, free of charge, keeping it through paid refreshes and later shops in the same run. The opportunity cost is one occupied stock slot: only three fresh offers are drawn while the reservation remains valid, for the unchanged refresh price. No discount, deposit, refund, new item, new upgrade, new stat, new art, save system or combat behavior. All 8 weapons, 29 modules, six level choices, catalog order/prices/weights, stage rewards and mode policies remain unchanged.

## Identity, eligibility and action tokens

A run-owned reservation stores a detached deep copy of the original offer metadata, its recognized catalog ID, its original integer catalog price, a preferred original slot 0–3, and a stable reservation token. It stores no Control/resource reference and is not part of equipment ownership.

A successful reserve requires shop state, the current shop generation, a valid current offer index, an unsold recognized offer below its ownership max-stack, and no existing reservation. Insufficient scrap or full weapon/module slots do NOT prevent reserving. Reserving an already reserved card is not an unlock toggle; another card cannot silently replace it. Explicitly unlock first.

Reserve and unlock cost no scrap, draw no random number, change no build revision, inventory, stats, equipment clocks, proc state or affinity. Each successful action increments `shop_generation` once to invalidate all old buttons. The reservation token is that newly issued generation at initial reserve; it remains unchanged through future refreshes, sales and shop generations. Unlock requires BOTH the current shop generation and that exact stable token. Rejected/stale/duplicate/wrong-state/index/token actions do not change state, generation, currency or RNG (a human-readable message may change).

Unlock removes the reservation only. The current unsold offer remains in place with its original draw metadata; it is NOT redrawn and no free fourth offer appears. The next actual stock draw uses the ordinary four-slot path.

## Stock draws and price

Without a reservation, run the existing four-offer weighted draw path exactly, preserving its RNG calls, pool/order, prices and metadata. Merely adding the feature or viewing buttons must not change no-reservation outcomes.

With a valid reservation, draw at most three offers from the current ordinary weighted pool with the reserved ID excluded before selection. Insert a deep copy of the held offer at its preferred original slot. All four current IDs remain distinct. For a synthetic short pool, insert at `min(preferred_slot, fresh_offer_count)` without empty placeholders; keep the preferred slot unchanged for later complete draws. The shipped legal pool has enough candidates for four offers.

The held card retains its ORIGINAL draw-time weight/reasons; it is not a new weighted draw or a current probability. Current build affinity still uses owned equipment only. Holding a missing partner does not activate a synergy or give its tag count/weight bonus. New unheld offers use current owned-build weights normally.

Catalog configuration is immutable during a normal run, so the authoritative catalog price remains the original price. No UI-supplied price or discount override is accepted. The stored price is an identity guard, not an alternative transaction price. If a stored ID becomes unknown, its recorded price no longer matches, or ownership reaches that entry's max-stack, clear the invalid reservation with an explicit notice immediately before the NEXT SUCCESSFUL stock draw and then perform the ordinary four-slot draw. Merely full equipment slots do not invalidate it. Preserve that notice instead of overwriting it with generic “New stock.”

Failed refresh (wrong state/generation/insufficient scrap) does not deduct, draw or invalidate a reservation. The existing refresh price and one build-revision increment on a successful paid refresh remain unchanged. Stock generation advances once per draw as before; invalidation does not add a second generation bump.

## Purchase, replacement and lifecycle

All purchases use the existing authoritative transaction and replacement rules. A successful purchase of the reserved ID clears the reservation, marks that current card SOLD and advances generation through the normal purchase path; it does not replace the sold card or draw extra stock. Successful full-slot weapon replacement consumes the matching reservation and still destroys the old weapon without refund. Buying a different offer leaves the hold intact.

Failed purchase/replacement (unaffordable, max-stack, full module slots, invalid replacement, stale/sold offer, or invalid held identity/price) preserves coins, build, held state, sold flags, generation and RNG. Invalid held identity/price must never silently charge a different amount; normal cleanup happens on the next successful stock draw or explicit unlock. Selling equipment follows the existing rules and does not itself release or redraw a held offer.

Reservation survives deployment, normal stage settlement, earned level choices, pause/inventory/settings/guide visits and a stage policy that temporarily skips shops. It does not force any mode to open another shop. If a future shop occurs, its first stock draw honors the hold. Clear on title, new run/same-seed retry/new seed, defeat and victory. Do NOT attach this reset to generic transient combat cleanup used between stages. No automatic refund/reward exists; no reservation is saved to disk.

## Presentation and inputs

Use existing text/buttons/card icons only. Show the held card and its original draw metadata distinctly, plus “not owned” and the one-slot opportunity cost. Reserve/unlock remain usable for unaffordable/full-slot offers; other reserve buttons explain the one-at-a-time restriction. A currently max-stack/invalid offer is not eligible for a new hold. Do not pretend a reserved component completes a build.

At native 960×540 and 1280×720 in both modes, keep the first BUY or replacement selection/action visible and the hold control reachable without hiding it under long descriptions. Preserve keyboard focus ordering and the existing default Godot `ui_accept`/focus actions. Actual native keyboard/mouse and synthetic `InputEventAction(ui_accept)` dispatch are tested separately. The observed stock mapping is Enter/KP Enter/Space, with no joypad A binding; no mapped-controller, physical gamepad gameplay or new controller subsystem is claimed.

## Acceptance and preservation

- Pin exact 37 catalog entries/order/numeric definitions, six upgrade definitions, weights/economy rules, v27 encounter behavior and all art. No-reservation seeded full-shop/transaction and old combat projections must match v27.
- All four hold positions, synthetic short pools, excluded ID uniqueness, changed owned affinity, original metadata versus fresh metadata, free lock/unlock and unchanged refresh cost; holding is not ownership.
- Generation and stable-token stale/duplicate/wrong-state tests, read-only detached views, failed payment/replacement, full slots/max-stack distinctions, successful buy/sale/replacement and invalidation notice.
- Both mode controllers' actual settlement/shop transitions, pending upgrade queue, skipped-shop policy, pause/inventory and all terminal/retry/new-seed resets; no reward/refund duplication.
- Native both modes/two sizes, keyboard/mouse and synthetic default UI-action dispatch; exact new PCK resource/handler checks with the unchanged accepted executable. One bounded ordinary two-shop attempt may demonstrate hold/refresh/carry/purchase, without forcing victory or injecting state. Controlled setup and ordinary observations remain separate.
- Keep accepted v27 immutable. Use a slim v28 candidate, early explicitly unverified Git recovery checkpoint, then independently accepted GitHub-only source/evidence and direct PCK delivery. No new production work until parent and QA accept this contract.

## Input-scope clarification

The original accepted mechanics contract SHA-256 was `64a6dec913b4c16fe866c0e5d2d994a8702e8acc977a44221b9a0a3b939dd842`. Independent inspection of both v27 and v28 found no default joypad binding for `ui_accept`; the earlier controller-mapping assumption was incorrect. The parent-approved clarification above changes the evidence claim only, not input bindings or reservation mechanics. The original contract and rejected mapping probe are retained in validation history.
