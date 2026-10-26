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

## Source-native checkpoint / remaining gates

Initial true cold import and173 author checks passed, with legacy mode42 / weapon-order837 / UI structure checks. Independent R3 source checks pass977 authority and544 UI/stale-callback assertions; the24-case default-path trace and36 existing timing checks are byte-identical to pinned accepted v30 outputs. Source-native both modes at960/1280 confirms the three initial choices, keyboard/mouse selection, seed/menu retention and truthful origin/retry behavior. This includes controlled setup; it is not ordinary exported acquisition.

Two candidate UI issues were fixed before final freeze. Retained new title START and mode callbacks could dereference a freed seed editor; WeakRefs and new-context generation guards now reject expired or stale callbacks. The initial layout hid all cards below the fold; compact3-across choices precede long detail now, with unchanged fonts and fixed START. Six strength/limitation strings were shortened without altering any numeric/identity data. Legacy two-argument title and generation-free callers retain their existing paths. Original failing evidence is preserved. A separate author test parse annotation and QA card-label spacing oracle correction were harness-only, not gameplay fixes.

Final full suite, exact packed-resource validation, two bounded ordinary alternative starts, helper restoration and GitHub publication remain pending. No Windows/audio/controller/full-campaign/balance certification is claimed. No new raster, executable, save, unlock or account system is introduced.
