# Independent v30 acceptance matrix

Pinned design: `ba1958ef08a8eed1d6b19ec9057f10a2cbb11d09a212dfb38a00e8cb85195366`.
Baseline: accepted v29; no new action is called in the baseline trace.

1. Both modes, every adjacent direction for 2–4 copies, including equal IDs with different or equal clocks. Finite positive, zero and negative clocks travel bit-exactly with the selected copy. Success changes order, paired clocks, one build revision and shop generation, documented message and rig presentation only.
2. Strict raw slot/step/generation/id types; wrong state, stale current-page callbacks, bounds, unknown/mismatched ID, malformed clock lengths/nonfinite/non-numeric values, and nonempty ordinary/return/Bankshot bullet or pending mortar arrays are rejected before all mutation, including lazy rig sync and message.
3. All rejected operations preserve the complete declared snapshot. Successful swaps preserve money/fraction, stats/HP/dash, items/upgrades/queues, offer/sold/hold metadata, RNG and proc state. No recompute, event, firing, destruction, free cooldown alignment or projectile cleanup. A reverse move restores IDs/clocks, not the intentionally incremented counters.
4. Aligned rig record identity, sprite, aim and age follow copies, moved pose caches clear, indices update; unmoved records and rig generation/clock/historical last-shot stay exact. Existing lazy sync is allowed only after a valid transaction.
5. Fresh target, no modifiers, both weapons ready, valid overlap: Cryo then Orbit Saw with Coil should deal 45 and consume mark; reverse should deal 29 and retain mark. Second aligned cycle can deal 45 in either order while reverse retains newly applied chill. This is a conditional timing choice, not guaranteed sustained DPS. A delayed Rivet/Cryo contact case must not inherit the false universal impact-order claim.
6. Current-generation sale/replacement/buy and reservation callbacks follow updated slots; old queued callbacks are rejected. Multiset/tag counts/bonuses and same-state weighted draws remain equivalent. Stage continuation retains order; title/new run reset normally.
7. No-action old-state trace: actual shared combat, upgrades including salvage, ordinary shop, reservation, refresh, buy/sell and all RNGs match v29. UI metadata/node identity excluded explicitly; no blanket byte-parity claim beyond the projection.
8. Native controlled small/large sizes in both modes: one-based labels, duplicate copies, disabled edges, mouse and keyboard, synthetic ui_accept separately; no paused-inventory reorder or default-focus hijack, no clipped purchase/replacement/reserve controls. Actual hand/side mounts inspected in both facings after deploy.
9. Exact exported Linux: one finite ordinary early shop acquires a second weapon, swaps and deploys. No injected ordinary build; automated CUA/tactical pause disclosed. No full campaign, Windows execution, audio, controller hardware or balance certification.

Invalid baseline/output harnesses, if any, are retained separately; no test result claimed before actual process termination.
