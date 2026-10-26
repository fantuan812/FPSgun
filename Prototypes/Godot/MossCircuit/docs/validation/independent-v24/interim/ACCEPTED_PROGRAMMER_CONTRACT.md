# v24 proposal — honest per-weapon readouts

Scope: correct an existing build/shop presentation gap. No new content, combat values, catalog ordering, transactions, RNG calls, art, or mode policy. Accepted v23 remains immutable. Tag-synergy progress is recorded but deferred.

## Evidence

The current generic DERIVED STATS panel displays `stats.damage` and `stats.fire_interval` computed from the starter player base. Shared weapon authority instead uses each weapon's catalog damage/interval. With no bonuses, Rail Lance therefore deals 30 primary damage at a 1.15 s scheduled attack interval, while the only generic panel values are Damage 15 / Fire interval 0.4. Weapon cards contain name/description but no measured numeric readout. This is initially a static-path finding, to be reproduced by a finite current-source probe before correction.

## One calculation, two consumers

Extract the existing expressions without algebraic change into pure, deterministic Rules helpers: primary weapon damage; scheduled attack interval; effective reach; spread projectile count. Combat and the read-only presentation use those same helpers. Preserve multiplication/order/type casts and the existing 0.09 s interval floor. Never call firing, simulation, RNG, transactions or effect mutation from the view.

- Damage: catalog weapon damage × (1 + global weapon damage bonus), then × (1 + electric bonus) only for electric weapons, then × (1 + melee bonus) only for melee weapons, matching current operation order.
- Interval: max(0.09 s, catalog interval / (1 + additive attack-rate bonus)). This is a scheduled interval with valid targets, not guaranteed sustained firing or DPS.
- Reach: Orbit's unchanged radius; all other shipped behaviors use catalog range × (1 + range bonus). No second application.
- Pellet count: catalog projectiles plus extra_pellets only for spread behavior, with the existing integer conversion. Other behaviors are not falsely described as pellet weapons.

A presentation-only adapter supplies labels and formatted values. The stat helpers remain independent of UI and mode. Runtime authority preservation will be checked, not assumed from the refactor.

## Where and what is shown

- Shop weapon cards: explicitly `BASE WEAPON STATS`, with unmodified catalog values. A short note says current build bonuses and purchase/replacement-triggered synergies are not included; this is NOT a post-purchase preview.
- Equipped weapon cards (build, shop inventory, result): explicitly `CURRENT WEAPON STATS`, derived from current equipped build. No historical in-flight snapshot or already-fired projectile promise. Existing descriptions are explicitly labeled BASE BEHAVIOR because they contain base values such as five pellets or 900 travel; do not change catalog descriptions or let those appear to contradict current numbers.
- Core readout: primary damage with a behavior-specific unit, scheduled attack interval in seconds, and behavior-specific reach in world pixels. Spread also shows pellet count. No inferred DPS, total volley damage, secondary/proc damage (including weapon-derived Arc chain and fixed shatter), average damage, critical chance or bounce gain.
- Generic DERIVED STATS must not print raw `damage` or `fire_interval` as universal weapon values. Keep useful existing stats, label global `damage_bonus` as weapon-damage bonus and `haste` as additive attack-rate bonus. Explicitly direct readers to individual weapon cards for their damage/interval.
- Keep first actionable BUY visible at 960×540. Use concise core rows with extra explanatory detail collapsed where needed; preserve keyboard navigation and opaque modal contrast.

## Behavior labels and boundaries

- Rivet / Rail: damage per projectile contact; effective acquisition/range limit. Rail's pierce rules stay in the existing description; damage is not multiplied by targets.
- Scrap Shotgun: damage per pellet contact plus actual pellet count. Do not multiply those into guaranteed per-shot damage.
- Orbit Saw: damage per target per sweep; radius unaffected by Focus Lens. No projectile count/pierce/range-bonus claim.
- Return Disc: damage per target contact; acquisition/outbound reach, NOT total round-trip distance. Existing each-leg hit eligibility and finite lifetime remain unchanged.
- Shock Mortar: damage per target inside a detonation; acquisition reach, NOT the fixed blast radius. Existing 0.6 s delay and 85 px radius remain in its description, no new duplicated authoritative constants.
- Cryo Sprayer: damage per target in instant cone; cone reach. No projectile/pierce bonus claim; chill and fixed Fracture secondary damage remain separately described.
- Bankshot Driver: damage per primary contact; acquisition reach AND one total path budget (same value, scaled once). Not per-leg range; max 2 field-boundary reflections and capped per-leg hit quota remain in the description. Guide changes direction only, no damage/range gain.

## Acceptance and stopping condition

1. Preserve a baseline reproduction of the misleading generic values versus actual Rail and Bankshot primary hits/clocks.
2. All 8 behavior readouts: base/current, no bonus and relevant modifiers, mixed loadout, repeated weapons, interval floor, Orbit range exception, pellet count, boss reward and fixed-secondary exclusion. Check read-only idempotence and no source/build/RNG mutation.
3. Exact old catalog/numeric definitions and existing combat outcomes/ordered traces preserved; explicitly permit only helper extraction and read-only view/UI additions.
4. Native controlled UI at 960×540 and 1280×720 in both modes: useful numbers/units readable, first BUY visible, details/focus/scroll intact, buy/replace/sell update the correct slot readouts without changing transaction behavior.
5. No full campaign by default. Final cold regression and one exported exact-readout smoke if a runtime artifact is deliberately delivered. Any newly discovered issue is reported before widening scope.
