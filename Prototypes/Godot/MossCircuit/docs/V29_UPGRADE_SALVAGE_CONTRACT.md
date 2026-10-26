# v29 — forgo one stat choice for immediate scrap

Accepted base: v28 implementation/runtime `2a922f15fffe2381ebc855095fe9e9c8dd41b09b`, final version-index head `6b1e7e5133ad8246a7fa38db8e998125f3b9fc56`.

## Player decision and scope

Each currently earned upgrade page still draws **three distinct options from the existing six permanent upgrades**. Add one explicit alternative resolution: **SALVAGE THIS UPGRADE — gain 10 scrap instead of selecting any permanent stat on this page**. This trades long-term stat growth for nearer equipment or refresh spending, including a previously reserved offer. The 10 scrap is credited immediately but can be spent only through the existing later shop policy; it does not open or guarantee another shop. Ten is an experimental fixed tuning value, not a claim of globally balanced exchange value.

The alternative is not a seventh permanent upgrade, a random offer, a reroll, a shop discount, a new item or an automatic fallback for capped stats. All existing upgrade definitions, catalog IDs/order/prices/weights, encounter data, art and ordinary income formulas remain unchanged. Every legitimate queued choice is eligible, whether earned from XP or granted by the existing stage policy; no extra choice is created.

## Identity and single resolution

Use the fixed resolution ID `salvage_upgrade` and the existing current `choice_generation`. The new intent accepts an actual String ID equal to that definition and an actual integer generation, without coercing strings, booleans, fractions, containers or null. No caller-supplied reward amount is accepted.

A successful salvage requires state `upgrade`, the current generation, at least one pending choice, and a nonempty current option page. It consumes exactly one queued choice once. Stale, duplicate, wrong-state, wrong-ID/type and empty/no-pending requests are rejected without changing coins, fractional credit, level, XP, permanent upgrade counts, pending choices, generation, RNG, equipment, reserved offer or combat/effect state. A held old button cannot resolve the next page.

One shared Rules definition supplies the immutable ID, fixed integer 10 and presentation copy. The UI receives detached metadata, never a writable authority object. The currency grant is a narrowly named shared whole-integer resolution helper: add exactly 10 to `build.coins` and leave `coin_fraction` bit-for-bit unchanged. Do not route this whole reward through the existing fractional `Rules.credit` accumulator, whose float addition/subtraction could round a previous remainder. Existing pickup/stage/boss credit logic is untouched.

Do not apply coin_bonus, resale, damage, level, mode or any module multiplier. No refund or new resource exists. Build revision stays unchanged, as ordinary income does not revise equipment; no level-count entry is added, no health repair occurs, and no `_recompute`, effect sync/reset, projectile cleanup, clock reset or artificial combat event is called by the salvage grant.

## Queue order, RNG and lifecycle

Reuse only the existing resolution tail: clear this page, decrement pending by one, then show the next already-earned page if any; otherwise open the already-pending normal shop; otherwise resume play. The normal stat-selection branch retains its exact operation order, derived-stat/heal behavior and existing RNG/state projection.

Salvage itself draws no random number and does not reroll the current page. Opening a next queued page or normal shop still consumes that existing path's RNG as usual, just as after a normal selection. This distinction must be explicit in tests and documentation. Existing automation continues to select the first ordinary upgrade; it never chooses salvage automatically.

Earned level and XP remain earned, including stage choices that were not themselves a level gain. Existing terminal settlement still queues no inaccessible post-victory upgrade or scrap. Title, defeat, victory, retry/new seed and later-page generations prevent stale payouts. The decision cannot reopen a page, force a future shop, skip another queued choice or duplicate settlement rewards.

The reserved offer remains exactly unchanged during this resolution. Its normal eligibility, price, slot/token and purchase rules still apply at a later shop. Increased scrap may make BUY affordable, but there is no direct purchase, discount, refund or reservation mutation.

## Presentation and inputs

Use existing text/card/button styling, with no new raster. Present salvage as an optional fourth resolution separate from the three random stat cards, clearly stating **forfeit this permanent stat choice, gain exactly 10 scrap; keep earned level/XP**. Show the current scrap balance from read-only run data. Keep the ordinary first SELECT as initial focus and preserve ordinary keyboard order; never default-focus or auto-activate salvage.

At actual 960×540 and 1280×720 in both modes, the alternative, forfeiture and amount must be legible/reachable without ambiguity. Validate native keyboard/mouse and synthetic `ui_accept` action dispatch only. The accepted input map has no joypad A binding; no physical-controller support or new binding is claimed.

## Bounded acceptance

- Exact old six upgrades and 37 catalog entries; no changes to encounter/art or existing income formulas. With salvage unused, old upgrade selection, reservation, shop RNG/transactions and combat projections match v28.
- One pending choice versus multiple queued choices, mid-combat level-up versus stage settlement, normal and skipped-shop policy, actual current generation/ID/type guards, stale double clicks and terminal/reset states in both modes.
- Exact +10 integer scrap with varied existing fractional remainders/coin bonuses, no revision/stat/heal/effect/clock/projectile mutation, no caller amount override, no extra RNG beyond normal continuation. Detached metadata cannot alter the grant.
- A previously unaffordable reserved offer can become affordable solely through the extra scrap; reservation and purchase remain normal guarded handlers, without duplicate payment/refund/reward.
- Controlled native both modes/sizes and one finite ordinary exact-export acquisition/decision route, clearly separated. No forced victory, injected ordinary economy or broad balance claim.
- Preserve accepted v28 and historical receipts. GitHub-only source/evidence/direct-PCK delivery after independent acceptance; unchanged executable/helper and ordinary manual backup/rollback constraints remain.
