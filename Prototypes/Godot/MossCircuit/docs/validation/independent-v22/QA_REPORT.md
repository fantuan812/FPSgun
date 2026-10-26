# v22 modifier descriptions — independent source acceptance

2026-10-25. **PASS for this four-field text-only source candidate and controlled native UI scope.** No new export/PCK, ordinary campaign, Windows runtime or balance acceptance is claimed.

## Exact scope and preservation

Frozen source: 2,464 files; `MANIFEST.json` SHA-256 `3fd8b2ce0dbe908f8c377e2c093938b3571f02bb764272e1e2890dcfff9c1689`. The manifest's member hashes were independently verified. `SOURCE_VERIFICATION.json` pins all 109 production inputs and the exact four before/after text fields.

Relative to immutable v21, **107 production files are byte-identical**. Only `data/catalog.json` and `data/balance.json` differ. Independently restoring precisely the three named catalog descriptions and one Rapid Circuit description makes each complete JSON object equal to v21. No whole entry, numeric field, tag, ID, weight, transaction, script, scene, UI or raster was excluded to obtain that equality.

- Power Coil now promises weapon damage rather than all damage; fixed module damage is explicitly excluded.
- Rapid Circuit now says attack rate +15% (additive), matching the existing runtime interval division instead of changing it.
- Cryo explicitly describes the instantaneous cone and supported damage/rate/reach modifiers versus projectile-only bonuses.
- Fracture explicitly describes fixed16 secondary damage that weapon bonuses do not scale.

## Independent cold regression

A fresh copy without an imported cache, isolated writable profile directories, and the same shipped regression runner passed **65 standalone scripts plus import: 66/66**. Every script returned zero, had its success marker and contained no `ERROR:`. All **236** declared test/runtime/helper inputs remained byte-identical. Python export-helper negatives passed **3/3**.

The new strict copy/preservation/actual-label/action-geometry test passed **105/105**. The promoted independent compatibility matrix passed **84/84** again. Its numeric/behavioral result projection equals the pre-correction v21 matrix, omitting only the explicitly changed Rapid description at its two mode observations (`MATRIX_COMPARISON.json`).

**Evidence-label caveat:** the promoted matrix was deliberately preserved byte-for-byte from the earlier audit. Its A-case `advertised: "+15% all damage"` is a hardcoded **old v21 comparison constant**, not a reading of current v22 UI text. The 105-check test and actual screenshots independently verify the new wording. No stale string is presented as a current defect.

The earlier read-only audit established both discrepancies using actual runtime paths: one Power Coil changes Cryo9→10.35/Rivet15→17.25 while Fracture16/Echo12 remain fixed; the actual upgrade chooser gives Cryo0.65/1.15 and Rivet0.4/1.15. The old-Rivet probes on v20/v21 were identical. This candidate fixes descriptions, not those intended inherited mechanics. Full audit expectations, scripts and limits remain separate; no all-combination or balance promise is added.

## Actual native source UI

An external controlled fixture selected actual game shop/inventory/upgrade controls with injected build/offer setup. It ran in a QA-only copy; all109 production hashes match the frozen candidate. This is **native Linux source rendering**, not a shipped-export campaign or naturally earned inventory.

All three revised equipment offer cards and the Rapid upgrade card were inspected in **Arena and Rooms at both native960×540 and1280×720**: 16 base views. Eight additional original captures cover expanded Coil details, inventory/scroll at Arena960 and Rooms1280, and repeated purchase/details navigation at Arena1280. Total: **24 unchanged game-window-only images** in `native/captures/`, with exact hashes in the evidence index.

Observed:

- All four revised texts render completely with readable wrapping; the first BUY action stays visible. The already-owned unique Coil's BUY is correctly disabled in this controlled setup.
- Cryo modifier exclusions remain readable in both the shop and inventory. Fracture's fixed-damage explanation remains readable when scrolled; normal scroll-pane clipping outside the visible pane is not a defect.
- Expanded Coil details retain primary-hit prerequisites, unique cap, consumed-slow tradeoff and ACTIVE status.
- Native Power Coil purchase changes injected1000 scrap to982. Clicking the SOLD control again leaves982. Clicking details expands the panel; Enter closes it without another purchase or losing the revised description.
- The process was closed through the window manager after the finite check.

No UI/source change was needed after these observations. The fixture is included for reproducibility, clearly labeled as injected setup rather than normal gameplay. It must not be substituted for the shipping main scene.

## Limits and next gates

ALSA output is unavailable on this cloud Linux host; the native engine uses its dummy fallback and reports the known llvmpipe V-Sync warning. These are retained in `native/native.log`; no parser, script or missing-resource error was observed. Audio is not certified.

This evidence accepts **source-only corrected wording**. The existing v21 ELF/PCK and its ordinary-run claims remain immutable; there is no new v22 PCK acceptance here. Packaging, any later export, Library delivery and remote publication require their own exact-identity gates. No new full campaign or additional content was necessary for these four text fields.
