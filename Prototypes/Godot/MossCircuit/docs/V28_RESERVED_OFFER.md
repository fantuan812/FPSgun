# One reserved shop offer — v28 development

## Decision and shared policy

The shop now lets a player preserve one desired component instead of losing it to the next draw. RESERVE is free and can be used while unaffordable or equipment slots are full. RELEASE is explicit: no silent switching or toggle-by-stale-double-click. The reserved card is labeled NOT OWNED, retains its original draw-time weight/reasons, and grants no inventory, tag, mechanism-pair or affinity benefit.

`ShopReservation` is a pure helper; `RunSession.reserved_offer` owns one detached record with ID, original integer price, preferred slot, stable token and original offer metadata. Main shop handlers validate current generation; release also validates the stable original token. New action payloads reject non-integer indices/generations/tokens. Successful reserve/release each advance generation once but never change currency, build revision, RNG or combat state.

No hold uses the original four-draw path. A valid hold excludes its ID before three fresh weighted selections and reinserts the original offer at its preferred position. A synthetic short pool has no empty placeholders. A changed catalog identity/price or reached max-stack clears only before the next successful draw, with a precise notice. Full slots alone do not invalidate. Purchases still use the authoritative existing transaction; the stored price is a guard, never an override.

Deployment, stage settlement, upgrades and paused menus retain the hold. Title, retry/new run, defeat and victory clear it. Generic combat transient cleanup does not clear it. No mode is forced to open another shop. Refresh cost, ownership caps, replacement destruction, resale, rewards and six level choices remain unchanged.

## Presentation and bounds

BUY/REPLACE and RESERVE/RELEASE share a compact action row. A held card distinguishes retained metadata from a new chance; the collapsed shop header states three new plus one reserved. Explanation lives in existing disclosures. Actual keyboard/mouse and synthetic InputEventAction(ui_accept)/focus dispatch are the scope. Baseline and candidate have no default joypad A binding, so no mapped-controller or physical controller gameplay certification is claimed. No binding or raster was added.

## Early validation status

Initial cold editor import and the standalone `tests/test_shop_reservation.gd` author check pass (520 assertions). The first test launch failed because the author shell used the wrong working directory; no test file had been created, and no product finding resulted. That rejected launch is retained privately. Independent old-behavior replay, reservation transaction/lifecycle tests, full regression, native 960/1280 UI and exact exported-pack acceptance are still pending. This document must not be read as final release acceptance.

Independent R1 testing reproduced one malformed-record edge: changing only the held ID could bypass the purchase guard on its original visible card. The R2 association helper recognizes both the record ID and detached original offer ID, so existing validation rejects the purchase and RELEASE remains reachable. Author regression passes; independent replay is pending. Ordinary immutable catalog/run data does not generate that corruption.

The first complete author regression run passed all 84 standalone entries plus import revalidation (85 total), with no engine errors or tested-input changes; Python export safety checks passed 3/3. The unchanged external no-reservation trace exactly matches v27 for 80 shop/transaction/menu cases and 800 seeded draws. These are author checks, not a replacement for independent final/native/export gates. All 161 art-source/assets/data files are byte-identical to v27.

Independent source checks on R2 pass: actual reservation/runtime 901, malformed-record/data preservation 285, and UI geometry/callback/synthetic ui_accept 3,170. The three portable scripts are promoted unchanged and also pass with no output argument. Native pixel/keyboard/mouse review remains in progress; an action-dispatch test is not physical-controller evidence.

## Final bounded acceptance

The exact 593-file candidate passed a true-cold author run of 87 scripts plus import and an independent initial-cold/final-reused-cache revalidation of the same 87 entries. Tested inputs did not change. Both preset resource packs are byte-identical: 41,361,216 bytes, SHA-256 `5db5ded8a5b18eb6ac391b58a261e245588aa52cd7dbc65575f5101fb5828f69`. The unchanged accepted Linux executable was launched with the adjacent pack; no executable or art was rebuilt. Pack-reader 837 and independent packed handler 901 checks pass from an empty reader directory.

Native controlled setup covers both modes at 960/1280, keyboard/mouse reserve/release, disabled unaffordable BUY with usable RELEASE, retained metadata, full-slot replacement, inventory non-ownership and invalidation. The one ordinary seed-128 Rooms route earned 66 scrap, reserved Rail in slot 1, bought Power for 18, refreshed twice for 5 each to 38, then naturally reached the second shop at 73. Buying held Rail for 42 left 31, equipped Rail in SLOT2 (34.50 current primary damage), marked its card SOLD and cleared reservation. This is finite ordinary acquisition/carry/purchase, not a full campaign, physical-controller or long-term balance certification.

The observed default input map has no joypad A binding. Synthetic ui_accept dispatch is explicitly distinct from actual keyboard/mouse and does not certify a controller. R1 malformed-ID purchase and the incorrect mapping assumption remain documented in independent evidence; neither is hidden as a clean first attempt. Known native ALSA/VSync limitations and closure method are recorded separately. Final evidence and current delivery metadata were appended after the tested runtime was frozen; only current documentation and root manifest changed.
