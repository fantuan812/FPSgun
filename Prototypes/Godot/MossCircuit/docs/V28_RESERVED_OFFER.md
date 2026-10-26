# One reserved shop offer — v28 development

## Decision and shared policy

The shop now lets a player preserve one desired component instead of losing it to the next draw. RESERVE is free and can be used while unaffordable or equipment slots are full. RELEASE is explicit: no silent switching or toggle-by-stale-double-click. The reserved card is labeled NOT OWNED, retains its original draw-time weight/reasons, and grants no inventory, tag, mechanism-pair or affinity benefit.

`ShopReservation` is a pure helper; `RunSession.reserved_offer` owns one detached record with ID, original integer price, preferred slot, stable token and original offer metadata. Main shop handlers validate current generation; release also validates the stable original token. New action payloads reject non-integer indices/generations/tokens. Successful reserve/release each advance generation once but never change currency, build revision, RNG or combat state.

No hold uses the original four-draw path. A valid hold excludes its ID before three fresh weighted selections and reinserts the original offer at its preferred position. A synthetic short pool has no empty placeholders. A changed catalog identity/price or reached max-stack clears only before the next successful draw, with a precise notice. Full slots alone do not invalidate. Purchases still use the authoritative existing transaction; the stored price is a guard, never an override.

Deployment, stage settlement, upgrades and paused menus retain the hold. Title, retry/new run, defeat and victory clear it. Generic combat transient cleanup does not clear it. No mode is forced to open another shop. Refresh cost, ownership caps, replacement destruction, resale, rewards and six level choices remain unchanged.

## Presentation and bounds

BUY/REPLACE and RESERVE/RELEASE share a compact action row. A held card distinguishes retained metadata from a new chance; the collapsed shop header states three new plus one reserved. Explanation lives in existing disclosures. Existing keyboard/mouse and default Godot UI focus/accept mappings are the scope; no physical controller gameplay certification or new art is claimed.

## Early validation status

Initial cold editor import and the standalone `tests/test_shop_reservation.gd` author check pass (520 assertions). The first test launch failed because the author shell used the wrong working directory; no test file had been created, and no product finding resulted. That rejected launch is retained privately. Independent old-behavior replay, reservation transaction/lifecycle tests, full regression, native 960/1280 UI and exact exported-pack acceptance are still pending. This document must not be read as final release acceptance.

Independent R1 testing reproduced one malformed-record edge: changing only the held ID could bypass the purchase guard on its original visible card. The R2 association helper recognizes both the record ID and detached original offer ID, so existing validation rejects the purchase and RELEASE remains reachable. Author regression passes; independent replay is pending. Ordinary immutable catalog/run data does not generate that corruption.
