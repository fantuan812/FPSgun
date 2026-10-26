# v24 — honest weapon readouts

This corrects an evidenced presentation defect, not weapon balance. The old generic panel showed starter-derived Damage 15 / Fire Interval 0.4 even with Rail Lance, whose actual primary hit and scheduled clock are 30 / 1.15 s. Independent controlled baseline checks reproduced both Rail and Bankshot mismatches in both modes.

Shop offers now say **BASE WEAPON STATS** and exclude build bonuses; they are not post-purchase previews. Equipped cards say **CURRENT WEAPON STATS** and use the same pure damage, interval, reach and pellet-count helpers as actual combat. The old descriptions are labeled **BASE BEHAVIOR** because their numbers are unmodified definitions. The generic panel retains useful modifiers instead of pretending one damage/interval applies to every weapon.

Numbers describe primary contacts/targets, not DPS or combined proc damage. Shotgun damage is per pellet with a separate count; Orbit radius ignores Focus Lens; Mortar reach is acquisition rather than blast radius; Return reach is acquisition/outbound rather than total round trip; Cryo is an instant cone; Bankshot has one total travel budget across all legs. Fixed module damage and weapon-derived chain damage are not added to the primary readout. Current values are not retrospective changes to already-fired snapshots. Exact contract: `V24_WEAPON_READOUT_CONTRACT.md`.

## Scope and final bounded acceptance

No catalog, numeric definitions, ordering, weights, art, modes, transactions or RNG changes. Shared helper extraction preserves the original arithmetic/order and 0.09 s interval floor. Independent interim actual-authority comparison passed 96 cases / 517 checks with byte-identical outputs against v23; independent view/readout checks passed 465. Controlled native all-eight-weapon cards, both modes and actual 960×540/1280×720 windows, plus purchase/sale/replacement/notes/scroll were accepted. These fixtures inject setup state and are not ordinary campaign evidence. Final independent cold checks passed 73 standalone scripts plus import, with 255 tested inputs unchanged; Python safety checks3 also passed. Both existing preset exports produced the same PCK, independently verified825/825 (55 exact files,57 imported images,25 actions/281frames), without source fallback. On that exact pack the unchanged accepted Linux executable completed a finite ordinary automated-CUA/tactical-pause seed128 Arena first-wave/shop test:122 scrap, Rail42 then Power18, CURRENT Rail45→49.50 at1.000s while BASE remained30/1.150s. Inventory/notes/back/title worked; Rooms reset showed starter15/.400. No injected build or currency, and no full campaign, balance, Windows or audio claim. Final evidence: `validation/independent-v24/QA_REPORT.md`.

Source recovery is an overlay on the exact full v23 source; runtime recovery is the existing verified v23 executable plus a deliberately tested new PCK. There is no new Windows executable build, signing or Windows runtime test. The initial native build harness incorrectly used --main-pack, which the accepted release template rejects; the same unchanged pack passed normal adjacent loading. That harness failure and correction are retained, not called a game defect. The prior v23 full bundles and all historical evidence remain independent. No full campaign is required for this narrow UI correction. Tag-synergy threshold/progress display is a separate known gap and is not included.

Focused standalone checks:
```sh
godot --headless --path . --script tests/test_weapon_readout.gd
godot --headless --path . --script tests/independent_weapon_authority.gd
godot --headless --path . --script tests/independent_weapon_readouts.gd
```
Use isolated writable HOME/XDG paths as described in README. Headless success is not a substitute for native card readability.
