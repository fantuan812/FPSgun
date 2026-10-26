# Read-only v23 baseline and expected weapon-card semantics

Scope: one existing-UI clarification; no new weapon/item, balance, catalog, RNG, projectile/proc/transaction/affinity change. Tag-synergy progress display is deferred.

## Confirmed source/UI gap

`ui/moss_ui.gd:244-252` renders weapon name/description only. `363-367` uses those cards for equipment. `389-393` displays generic derived dictionary values, including unqualified Damage and Fire interval. `scripts/rules.gd:165-167` derives those two fields from player base damage15 and interval0.4, whereas `scripts/gameplay/weapon_combat.gd:22-24` applies bonuses to each weapon's own damage and `combat_runtime.gd:22` uses each weapon's own interval.

Thus an unmodified Rail-only equipment view would show generic15 and0.4, while actual fire/clock are30 and1.15. This is a static actual-path inference, not a newly executed runtime repro. Existing accepted native `arena-960-inventory-left.jpg` confirms weapon cards lack comparative numeric values.

Independent icon metadata audit: exact8 weapon +28 module IDs all covered by distinct atlas path/rect entries; zero missing/extra IDs, no merge conflicts, all source regions in bounds with nonempty alpha. No item-art gap found. Catalog's three old tag-synergy descriptions/thresholds are not displayed by UI; useful but deferred, not a combat defect.

## Frozen authority baseline (v23)

| Weapon | Base primary damage unit | Base attack interval seconds | Reach semantics | Other semantics to preserve |
|---|---|---:|---|---|
| Rivet Gun |15 per projectile contact|0.4|500 acquisition/player-centered reach|1 projectile; base0 extra pierce targets|
| Scrap Shotgun |9 per pellet contact|0.85|300 acquisition/player-centered reach|5 base pellets; pellet bonus applies; not guaranteed45 damage per attack|
| Rail Lance |30 per projectile contact|1.15|650 acquisition/player-centered reach|1 projectile; base3 extra pierce targets|
| Orbit Saw |20 per target per sweep|0.65|105 sweep radius, unaffected by range bonus|No projectile/pellet/pierce bonus; melee damage multiplier applies|
| Return Disc |18 per target contact per leg|0.9|330 acquisition/outbound reach, NOT total round trip|Each target once per leg; fixed2.5s projectile lifetime; no pellet bonus|
| Shock Mortar |36 per target in blast|1.5|500 acquisition reach; separate fixed85 blast radius|Fixed0.6s detonation delay; not projectile/pierce/pellet bonus|
| Cryo Sprayer |9 per target in instantaneous cone|0.65|190 cone reach,60 degrees|Mark1.2s; normal movement0.65, bosses mark-only; not projectile/pierce/pellet bonus|
| Bankshot Driver |18 per projectile contact|0.85|900 acquisition and900 single total path budget, each scales once|1 projectile; quota min6,max1,(1+base pierce+global pierce) per leg; up to2 reflections; no pellet bonus; budget never resets|

Damage formula preserves original evaluation order: weapon.damage*(1+damage_bonus), then *(1+electric_bonus) if electric tag, then *(1+melee_bonus) if melee tag. Interval is max(0.09, weapon.interval/(1+haste)); attack-rate percent is not interval-reduction percent. Reach is weapon.range*(1+range_bonus), except Orbit's actual sweep remains fixed weapon.range.

BASE offer values are raw catalog/no-build values, NOT a post-purchase synergy forecast. CURRENT equipment values are current controller-derived primary values. Existing fixed-number descriptions must be clearly labeled base behavior when an equipped value differs. UI must not implement alternate authority math or mutate state. Do not label these numbers DPS or total volley damage.

Fixed secondary module outputs are excluded from primary damage: Fracture16, Echo12, Phase12, Thorns18, Mine24, scorch6/tick, resin8/tick. Arc Relay is different:40% of actual triggering weapon damage; do not incorrectly claim every secondary is fixed/unscaled.

## Independent finite validation proposal

1. All8 weapons at zero bonuses: exact base values above; BASE offers and CURRENT equipment agree numerically but are differently labeled.
2. Per weapon,2 Power Coils +1 Cooling Fan +1 Focus Lens: damage*1.3, interval/1.12, reach*1.15 except Orbit remains105. Assert no fixed secondary included.
3. Rail +2 Capacitors:3 electric tags -> electric bonus0.7 ->51 primary. Orbit +2 Saw Gears ->34 per target. Shotgun +2 Pellet Pouches ->8 pellets (5+2+1 synergy), still9 damage/pellet; not72 guaranteed attack damage.
4. Rapid upgrade level100 -> haste15: interval floor0.09 for7 weapons, Mortar remains0.09375. This is controlled edge validation, not normal progression claim.
5.3 Focus Lenses: Orbit105; Cryo275.5; Bankshot1305 acquisition and1305 total path, TTL1305/470. Return478.5 outbound, not957 guaranteed round-trip.
6. Pierce upgrade beyond5 caps global bonus5: Bankshot quota6/leg; Rail8 extra targets; Cryo/Orbit/Mortar unaffected. Do not confuse extra pierce with total contacts.
7. Same build, repeated view/card calls and modal navigation must not change stats/build/RNG/clocks/projectiles. BASE offer must not change just because candidate would activate a tag threshold after purchase.
8. Actual native controlled UI: all8 weapon cards, clearly distinguishing Rail base/current example, source-of-truth modifiers,960x540 and1280x720 readability, shop BUY/REPLACE still at top, inventory scroll/back intact. No new full campaign.
9. Finite pre/post authority trace on identical v23 inputs and extraction arithmetic order; compare actual fire damage and shared runtime clock, not only helper-to-helper agreement.

Accepted programmer contract SHA256951c715598e4d50720e5a852a478904efbb6919ea0a55ef3fab9827f2c296726. Contract inspected before implementation. No runtime launched for this audit. Pending actual baseline reproduction, candidate and native verification.
