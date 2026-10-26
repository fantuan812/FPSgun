# v31 starting loadouts — UNVERIFIED development candidate

The accepted v30 source/runtime is preserved. This candidate adds three starting loadouts for the same hero, using existing equipment and art:

| Loadout | Starting weapon | Starting scrap | Decision |
|---|---|---:|---|
| Rivet Starter (default) | Rivet Gun | 35 | Accurate frequent fire and the most spare scrap; basic shots do not spread or pierce. |
| Scatter Starter | Scrap Shotgun | 23 | Close-range spread, less spare scrap and a longer interval; individual pellets can miss. |
| Rail Starter | Rail Lance | 17 | Long piercing shots, least spare scrap and the slowest interval of these starters. |

Each currently has weapon purchase value plus scrap of59. That is a tuning rationale, not a claim that the loadouts are equally strong. Scrap is fixed in the registry rather than recomputed from prices. All start with normal100 HP/base movement, one weapon, no modules or permanent upgrades. Existing sale/replacement/affinity rules apply; choosing a loadout is not a purchase or refund.

Selection is title-only and draws no RNG. The selected loadout persists through this process's title/mode/guide/settings round trips; a fresh process defaults to Rivet. The run records its origin separately from current gear. Same/new-seed retry uses that origin after gear is bought, sold or reordered. `STARTED WITH` labels origin, not items still owned. Different starting tags can intentionally change normal shop affinity, so seed alone does not promise equal offers across different loadouts.

New title actions use current generation, exact known ID and actual integer seed; malformed/stale actions reject before resetting a run. Legacy one-argument start and the pure build factory remain the old Rivet path. See the frozen [contract](V31_STARTING_LOADOUT_CONTRACT.md).

## Pending acceptance

Author cold import/focused tests, independent default-path preservation, registry/lifecycle/title/native checks, exact packed-resource validation, two bounded ordinary alternative starts, helper restoration and GitHub publication are not yet complete. No Windows/audio/controller/full-campaign/balance certification is claimed. No new raster, executable, save, unlock or account system is introduced.
