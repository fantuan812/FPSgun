# Independent v31 acceptance matrix

Pinned design: `FROZEN_CONTRACT.md`, SHA256 `0f731dd1a5acfe3bdc2f19bfbf4ca6f3f08b0dc5a6353faa7dd9feec61cd980f`. Subsequent accepted UI corrections preserve mechanics: external WeakRef/current-generation callbacks, compact three-card layout, six display-only registry strings.

| Area | Exact expected behavior | Evidence gate |
|---|---|---|
| Shipped registry | Exact ordered IDs rivet/scatter/rail; weapons rivet_gun/scrap_shotgun/rail_lance;35/23/17 integral scrap; default rivet. | Independent schema/negative/type/detachment checks. |
| Default | Old factory unchanged; explicit legacy start defaults Rivet even with different title draft. No RNG draw on selection/factory. | Reused accepted v30 baseline proof plus actual candidate24-case old-schema replay and36 timing assertions; named limitations. |
| Initial authority | Exactly1weapon,0modules/levels,100HP,165speed,clock0,revision0,coin_fraction0; normal weapon damage/schedule/collision, no hidden class modifiers. | All3kits×bothmodes, several seeds; actual shared runtime fire/collision. |
| Strict title actions | New selection/start actual StringknownID +actualIntcurrentgeneration andseed; invalid/stale/state mismatch reject before mutation; caller amount/weapon ignored. | Atomic full snapshots and callback lifecycle tests. |
| Title draft | Presentation-only selection; no cleanup, no ownership/affinity/coins/RNG grant before start; same-kit no-op; seed/kit retained across mode/settings/guide. | Populated controlled title and native repeated navigation. |
| Run origin | Snapshot distinct from selected title draft/currentgear; actual buy/reorder/sale cannot redefine origin; retry/newseed restore originalkit and seed/seed+1. | Controlled actual transactions then reset, plus forced gear/result native presentation followed by real Retry/NewSeed UI. No ordinary victory claim. |
| UI | All3choices visible initially at960×540/1280×720 in bothmodes; existingicons, explicitSELECTED+border; fixedSTARTkit/scrap/defaultfocus; sharedBASEprimary values/units, noDPS/45damage promise. |544 controlled layout/action checks, actual native pixels/keyboard/mouse; artist13sample review. |
| Stale callbacks | New-context START/mode safe after controlsfree; seed/mode/start inert before deferredfree when titlegeneration expires. Legacy no-generation paths unchanged. | Preserved R1/R2 reproductions and corrected R3 matrix; no ordinary crash inference. |
| Packed runtime | Exact independently regenerated imported-source oracle, bothpresetPCKequal, all new registry/helper resources, controlled allkit/UI checks from empty readercwd. | PASS:843 resource checks, packed977+544; independent oracle equality. No source fallback or executable rebuild. |
| Ordinary export | Fresh defaulttitle; Scatter/Arena and Rail/Rooms via actual UI, initial23/17scrap+gear, bounded early movement/fire, observed pause/title/close. | PASS: two finite no-injection starts, actual23/17scrap and origins; incidental early progression. See ordinary chronology/limits. |
| Delivery | ActualGitHubPCKchunks restore with unchanged helper; strict byte/readback and prior source/unrelated preservation; source/runtime only after acceptance. | Local unchanged-helper/negative/backup-rollback PASS. Remote publication/readback remains a separate subsequent gate. |

## Numerical expectations
Rivet15/contact,0.4s,500px; Scatter9/pellet contact,5pellets,0.85s,300px; Rail30/contact,1.15s,650px and existing piercing. Shared readout/math, not new balancing formulas. Current purchase-value+scrap59 is design rationale only—not equal power, resale liquidity or survival. Different owned tags intentionally influence subsequent normal shop affinity, so same seed with different kits need not give same offers.

## Scope limits
Initial true-cold R1 import, later focused/final reused-cache revalidation labeled honestly. No Windows runtime, physical controller, audio, all-seed balance, full campaign or human-feel certification. No new raster/unlock/save/account/network/dungeon work. Controlled fixture can freeze simulation and prepare altered gear/results; ordinary export routes cannot. All UI inputs through automated CUA, tactical pause allowed and disclosed.
