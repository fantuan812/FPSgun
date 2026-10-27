# C3 independent pre-implementation hand oracle

Pinned contract 34cbe2d6acf95deb68fd4acf40c7e72989957d7c5276c9dee71bd26256e328d2; source v36 source717 map442c736b, catalog91bb4fba. No v37 target has been implemented or executed when this oracle is frozen. This is hand-written expected evidence, not target output, and not an executed PASS.

## Explicit arithmetic
Primary array for [Rivet, Shotgun, Rail, Saw, Return, Mortar, Cryo, Bankshot] with two Coils (+.30), two Capacitors (+.50), two Gears (+.50): [19.5,11.7,66.3,44.2,23.4,46.8,11.7,23.4]. Rail/Saw each supplies the third electric/melee count, adding .20 once: 30*1.30*1.70=66.3; 20*1.30*1.70=44.2. Tempered copies multiply primary by1.60. Two Fans divide scheduled base intervals by1.24. Two Lenses multiply non-orbit reach by1.30; Saw remains105. Second Pouch changes shotgun6→8 because it contributes +1 pellet and activates the three-count Scatter threshold once. No pellets field for other behaviors.

Rail plus two capacitors tier1→replacement STANDARD:81.6→51.0. Other tempered slots stay unchanged. Rail with three→four capacitors: tagcount4→5, both already active, primary58.5→66.0 (not a second threshold). Three capacitors without electric weapon activate ARC but leave Rivet unchanged and matching_weapons empty.

## Hand relation identities / order
Reel buying with Return: index11 enables,200→172. Buying Return with Reel and Rivet: index4 needs Return Spool, index11 enables. Removing last Return disables11; removing one of two does not. Cryo-only buying Fracture: index8 needs other weapon. Rivet append activates8 even though not in explicit requires. Replacing last Rivet with Cryo disables8. Full status rows must preserve old five-key schema and optional-ID legacy catalogs.

## Failure and alias controls
Exact two-key failures, unknown-ID precedence before strict slot grammar; invalid negative/out-ofrange/bool/float/string/null slots; item slot disallowed; funds/cap/fullbag/fullmodules; malformed tier empty/boolean/outofrange/string rejects weapon but permits item with unavailable numeric readouts. Nested mutation of report names/readouts/prerequisites must leave inputs and separately generated reports unchanged.

## Remaining separately frozen routes (not implied covered here)
Controller state/generation/index/sold/held/tier guard combinations, deep full world+RNG purity, exact mechanism/tag full records with same-name/no-ID compound legacy catalogs, real purchase on separate instances, per-view and dropdown local update/focus/scroll, native 960/1280 and actual PCK. These will have separate pre-execution scripts and finite scopes; this core hand oracle does not certify them. No single-run global count asserted before execution.
