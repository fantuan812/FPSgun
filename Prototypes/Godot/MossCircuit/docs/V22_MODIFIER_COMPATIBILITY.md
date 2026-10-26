# Modifier wording clarification — separate candidate

This candidate corrects two demonstrated inherited UI wording defects and makes Cryo/Fracture compatibility explicit. It does not change damage, timers, RNG, rules, weights, transactions, tags or art. Immutable v21 source and delivery history remain separate. Only the four description fields listed in `V22_MODIFIER_COPY.json` may differ; whole-definition byte identity is not claimed.

## Actual rules, now described accurately

- Power Coil adds 0.15 to weapon damage bonus. A Cryo hit is 9×1.15=10.35 and a Rivet hit15×1.15=17.25. Arc Relay derives40% of actual primary damage. Fixed module values such as Fracture16 and Echo12 do not gain this multiplier. The previous “all damage” wording was too broad.
- RAPID CIRCUIT adds0.15 attack rate per upgrade, additively with Cooling Fan0.12 per copy. Firing interval is `max(0.09, base_interval / (1 + total_attack_rate_bonus))`. One Rapid therefore yields Cryo0.65/1.15≈0.565217s or Rivet0.4/1.15≈0.347826s, not a15% interval reduction. The unused legacy `Rules.apply_upgrade` helper is unchanged; actual play uses build levels and `Rules.derive`.
- Cryo is an instantaneous60° cone, not a projectile. Generic weapon damage, attack rate and reach apply. Projectile-only bonuses, shotgun pellets, electric and melee tag bonuses do not change its cone or mark. A Focus Lens increases radius190→218.5; angle and1.2s mark duration are unchanged.
- Fracture's16 secondary damage is fixed. A different recognized weapon type must produce a surviving primary hit on a live Cryo mark; spending the mark also spends its chill slow. The original primary can trigger existing on-hit effects, but fracture cannot recursively proc them.
- Existing resin and chill remain separate; the stronger ordinary-movement factor applies. Consuming chill does not erase resin. Boss mark-only and committed movement/timers remain as documented in v21.

No crit or wall-bounce modifier is currently shipped, so this correction does not invent one. Projectile speed is not a purchasable generic bonus in the current catalog. Return Spool and Blast Fuse retain their specific disc-return/mortar triggers.

## Evidence and acceptance boundary

The pre-correction independent matrix was frozen before execution and passed84 intended-mechanic checks in both modes. The two displayed promises disagreed with actual values. Actual old-Rivet probes pass6 checks on both v20 and v21 and produce identical results, establishing that these are inherited wording defects rather than a new Cryo authority regression. See `validation/independent-modifier-audit`.

Final author and independent cold import plus65 standalone entries pass (66 total), with236 declared test inputs unchanged; Python negatives3 pass. A105-check test verifies the four exact descriptions, strict field-only preservation, actual shared card labels and first purchase visibility. Independent native source windows at960×540/1280×720 in both modes verify readable cards, upgrade, inventory/scroll and repeated purchase/details navigation. No PCK was rebuilt for this source-only correction. No new campaign, balance, Windows or audio claim follows from this small correction. Historical receipts are retained unchanged.

The promoted84-check compatibility script remains byte-identical to the frozen pre-correction probe. Its hardcoded `advertised` observation records the OLD v21 wording as a baseline comparison, not the live v22 label. Current descriptions are independently checked by the105-check UI test and native captures.
