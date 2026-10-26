# v25 independent accepted matrix — existing tag synergies

One bounded discoverability fix for ARC GRID, SAW RIG and SCATTER RIG. No new mechanics/content/art, numeric/catalog/RNG/affinity or equipment authority changes; no full campaign. Programmer contract reviewed and accepted before production edits.

## Existing authority and copy audit

`Rules.derive` counts every owned weapon slot once for each listed tag, and every owned module copy once per listed tag. These are equipment-copy counts, not unique IDs, total distinct tags, offer tags, upgrade levels or mode progress. The current catalog has six contributing IDs: Rail Lance/Capacitor (electric), Orbit Saw/Saw Gear (melee), Scrap Shotgun/Pellet Pouch (spread). Shotgun is also ballistic; one copy gives one spread and one ballistic count, not two spread. No shipped entry carries both electric and melee.

All thresholds are 3, checked with >=, and each bonus is applied once even at4+ copies. ARC GRID adds0.2 to electric_bonus; SAW RIG adds0.2 to melee_bonus; SCATTER RIG adds1 to extra_pellets. Catalog descriptions broadly match, but discoverable copy should explain additive weapon-damage bonus and spread-weapon-only pellets. No final-damage×1.2 or every-projectile claim. Fixed module damage is not directly scaled; weapon-derived chain follows its existing triggering-primary calculation. Active electrical/melee rules can exist from three modules even when no benefiting weapon is equipped; active is not proof of current effective damage.

The current UI only shows active names or a generic tag-matching prompt, after other inventory sections. No current/required counts or exact effects are exposed. This is a presentation gap, not an authority failure.

## Pinned expected cases

| Owned loadout | Relevant counts | Active | Expected derived effect / current weapon |
|---|---|---|---|
| Rivet only |0/0/0|none|all three bonuses0|
| Rail |electric1|none|30 primary|
| Rail×2 |electric2|none|30 per Rail|
| Rail×3 |electric3|ARC GRID|electric bonus0.2;36 per Rail|
| Rail×4 |electric4|ARC GRID once|electric bonus0.2;36 per Rail|
| Rail + Capacitor1 |electric2|none|bonus0.25;37.5 Rail|
| Rail + Capacitor2 |electric3|ARC GRID|bonus0.7;51 Rail, not54|
| Rail + Capacitor3 |electric4|ARC GRID once|bonus0.95;58.5 Rail|
| Rivet + Capacitor3 |electric3|ARC GRID|bonus0.95, but Rivet remains15|
| Orbit + Gear1 |melee2|none|bonus0.25;25 Orbit|
| Orbit + Gear2 |melee3|SAW RIG|bonus0.7;34 Orbit|
| Orbit×4 |melee4|SAW RIG once|bonus0.2;24 each|
| Rivet + Gear3 |melee3|SAW RIG|bonus0.95, but Rivet remains15|
| Shotgun + Pouch1 |spread2|none|extra1;6 pellets,9 each|
| Shotgun + Pouch2 |spread3|SCATTER RIG|extra3;8 pellets,9 each|
| Shotgun×3 |spread3 and ballistic3|SCATTER RIG|extra1;6 pellets per shotgun, not8|
| Shotgun×4 |spread4 and ballistic4|SCATTER RIG once|extra1;6 per shotgun|
| Rail+Orbit+Shotgun; Cap2+Gear2+Pouch2 |3/3/3|all three|electric0.7,melee0.7,extra3;Rail51,Orbit34,Shot8 pellets|

Actual mutation paths, both modes: buy completing third count; sell one module copy from threshold; sell one duplicate weapon from threshold; full-slot replacement removing one relevant tag; replacing a weapon with the same ID preserves count; stale transaction generation leaves state unchanged. Repeated view/modal rendering must not change build/stats/catalog/RNG/clocks. Unpurchased offers do not contribute. Current counts must be current ownership, not a post-purchase prediction. Existing weapon BASE/CURRENT readouts stay correct.

Native scope after implementation: all three rows at0,2,3,4+ counts; small/large windows in both modes, actual buy/sell/replace transitions, readable count/threshold/effect and no loss of first BUY access, scroll/back/notes. Controlled injected setup is labeled; no full campaign, Windows/audio or balance claim. Reuse the existing exact v24 imported copy for baseline; slim candidate only if authorized.

Accepted programmer contract SHA256: `c5a315e12793012f61e7dece5a70db1a1860763c7d900e4ad578931f2a8eefeb`. Catalog descriptions remain byte-identical, with separate concise scope qualifiers. Exactly three rows and the existing mechanism-pair section remain distinct. Active-but-no-matching-weapon is explicitly described rather than deactivated. Validation must constrain IDs/tags/thresholds to the pinned existing rules; descriptions are presentation, not a new authority engine. Runtime probes and native review are pending at this matrix freeze.
