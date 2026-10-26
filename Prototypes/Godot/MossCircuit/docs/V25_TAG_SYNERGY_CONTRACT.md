# v25 proposal — existing tag-synergy progress

Scope: expose the current ownership progress and exact meaning of the three existing tag rules. No new synergy, item, art, balance, catalog order, RNG, transaction or mode change. Accepted v24 is immutable. This contract is agreed before production edits; copy/import/export waits for approved cache cleanup.

## Fixed rules, not a new generic engine

The runtime remains pinned to the existing ordered rules: ARC GRID/electric/threshold3 adds0.20 to electric_bonus; SAW RIG/melee/threshold3 adds0.20 to melee_bonus; SCATTER RIG/spread/threshold3 adds1 to extra_pellets. Each applies once at >=3, not again per threshold multiple. Do not silently let arbitrary new catalog rows, tags or thresholds create combat behavior.

Extract the current owned-copy counting and these exact rule definitions into shared pure Rules helpers. `derive` and the read-only view use the same count/activation result; no second UI formula or duplicated threshold/effect constants. Existing catalog IDs/tags/thresholds must agree with the three pinned runtime definitions; constrain validation rather than broaden configuration semantics. Display the corresponding unchanged catalog description plus a concise runtime-scope qualifier. Shop affinity weighting/order remains untouched and must preserve exact results.

## Counting and activation

- Count each equipped weapon copy, not unique weapon IDs.
- Count each actual owned item stack; do not multiply by max_stack or assume every item can stack.
- A multi-tag entry contributes its owned count once to each listed tag. Shotgun's ballistic+spread does not count twice toward spread; unrelated families do not combine.
- Show unclamped counts (e.g.4/3), current threshold, ACTIVE/INACTIVE and the rule name.
- Use current equipment only. An offer is not owned until its transaction succeeds; no post-purchase forecast.
- Purchase, sell-one, full weapon replacement and run reset update the view from existing authoritative ownership. Drawing/toggling/scrolling never mutates build, stats, clocks, effects, shop offers or RNG.

## Honest effect semantics

- Electric/melee bonuses add0.20 to their existing matching-weapon modifier, not multiply final damage by1.20. Rail + Capacitor2 is30×(1+0.50+0.20)=51, not54; other global modifiers remain separate.
- Only matching tagged primary weapons benefit from those direct damage modifiers. Fixed module damage is not scaled by this rule; weapon-derived procs retain their existing upstream relationship, not a new claimed fixed-proc boost.
- Scatter adds one pellet to spread attacks only; it stacks with Pouch's existing additions. Shotgun+Pouch2 fires8 pellets, not6 or7, and does not add projectiles to Rivet/Cryo/Orbit.
- A rule can legitimately be ACTIVE without a currently benefiting weapon: Capacitor3 and Gear3 are valid examples. Do not label this a missing activation prerequisite or deactivate it. Say that the rule is active but no equipped matching weapon currently benefits. Pouch3 is not a valid shipped stack; do not invent that scenario as ordinary content.
- Current catalog has no hybrid electric+melee weapon. Synthetic validation cases, if any, must be labeled as such rather than shipped-content coverage.

## UI boundary

Replace the existing ACTIVE TAG SYNERGIES inventory section with current progress for exactly these three rules, using the existing modal/scroll style. Each row shows rule name, state, count/threshold, the catalog description and concise additive/matching-weapon/spread-only/once qualifier. Keep the existing mechanism-pair section distinct and unchanged. Do not add combat-HUD clutter, a new progression system or purchase preview.

At960×540 and1280×720 in both modes, text/units must be legible, scrolling/keyboard notes intact, and first BUY/REPLACE action visibility preserved. This is a finite controlled source-native UI check, not a full campaign.

## Acceptance

Pin actual v24 baseline counts/derived stats/primary outputs before refactor, including0,1,2,3,4+ counts, repeated weapons, stacks, valid no-benefiting-weapon activation, unrelated/multi-tags and simultaneous rules. Preserve all numeric outcomes, existing synergy ordering and filtered/current shop outputs. Test actual successful/failed/stale buy/sell/replace/reset ownership transitions and read-only idempotence. Catalog bytes/order/weights and all prior content stay exact. Native final PCK smoke is bounded to this display if a new runtime is delivered; no repeated full campaign or Windows/audio claim.

Source recovery uses a slim overlay and a full logical reconstruction manifest against exact durable v24 (itself reconstructed from fullv23 + v24overlay), without duplicating historical source/evidence in each working copy. Any archive or runtime update must separately pin its exact base and accepted bytes.
