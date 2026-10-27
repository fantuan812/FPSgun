# Affected path matrix — static DRAFT, not target results

Counts are successful-path static plans checked against original A raw; FAIL history is unchanged. Overlap inventory deduplicated. New dedicated routes follow this table.

| Path | Old → planned | Domain | Change |
|---|---:|---|---|
| tests/independent_cryo_shop.gd | 320 → 320 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_feedback_shop.gd | 102 → 102 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_feedback_validation.gd | 29 → 29 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/independent_focus_combat.gd | 945 → 945 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_forecast_authority.gd | 108 → 108 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_forecast_legacy.gd | 808 → 808 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_new_weapon_caps.gd | 14 → 14 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/independent_new_weapon_policy.gd | 59 → 59 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/independent_reservation_records.gd | 300 → 300 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_reservation_runtime.gd | 901 → 901 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/independent_reservation_views.gd | 3254 → 3254 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_scavenger_events.gd | 46 → 46 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/independent_scavenger_views.gd | 132 → 132 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/independent_shop.gd | 216 → 216 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/independent_starting_loadout_views.gd | 544 → 544 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_starting_loadouts.gd | 977 → 977 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_tag_authority.gd | 561 → 561 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_ui.gd | 84 → 84 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_v4.gd | 35 → 35 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/independent_weapon_authority.gd | 517 → 517 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_weapon_order.gd | 837 → 837 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/independent_weapon_readouts.gd | 465 → 465 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/support/v36_catalog_projection.gd | support only | test adapter | Combined bridge; old A projector bytes unchanged |
| tests/support/v39_legacy_inputs.gd | support only | test adapter | Combined bridge; old A projector bytes unchanged |
| tests/test_A_catalog_links.gd | 17 → 17 | historical A | B-only input/raw inverse; original17 predicates unchanged |
| tests/test_A_profile_negatives.gd | 165 → 165 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/test_bankshot_build.gd | 114 → 114 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_builds.gd | 221 → 221 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_cryo_build.gd | 205 → 205 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/test_discrete_ui_numbers.gd | 34 → 34 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/test_expansion.gd | 571 → 571 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_modifier_copy.gd | 112 → 112 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_shop_offer_visibility.gd | 190 → 190 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_shop_reservation.gd | 520 → 520 | actual B catalog / old-only synthetic fixture | no automatic patch; strict helper rejects noncanonical synthetic dot keys; not actual B-owned coverage |
| tests/test_starting_loadouts.gd | 173 → 173 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/test_tag_synergy_progress.gd | 467 → 467 | actual B (existing narrow scopes) | unchanged; RAW_CURRENT_EIGHT.md explains static count and observations |
| tests/test_upgrade_salvage.gd | 147 → 147 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_v39_legacy_inputs.gd | 18 → 19 | actual B entry -> historical v38 | archive original18; actual36 + intermediateA33/raw67 proof; other17 unchanged |
| tests/test_weapon_order.gd | 321 → 321 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |
| tests/test_weapon_readout.gd | 411 → 411 | historical v38 (or v36 through its original inverse) | installer/helper bridge only; old assertions/goldens preserved |

## New routes / planned boundaries
- `test_B_legacy_cache.gd`:20 (10 per fresh/prior-B-run→title), 2 final audio owners. Current B entry, explicit historical cache reset, then actual historical newrun.
- Existing external current-B helper318 and independent30/349/207/61 retain exact expectations.
- Existing current-B validator63, corrected actual56, independent Pin-ring126/14observations and hooks62/2observations, UI20 retain exact expectations.
- New `test_B_catalog_current.gd`:27 exact catalog/profile/forecast/pureRules economy, helper0. `test_B_projection.gd`:24 strictinverse positive/mutation guards, helper0. Existing actual56 owns real transactions/live forecast purity; independent46icon probe pending QA literal completion; `test_B_pickup_sources.gd`:34 (17 per mode), final helper1.
- Existing A native43icon control requires B-only input to remain meaningful; separate actual46 resource proof/native20scene matrix, never assert43 means46.
- Source runner discovery must be statically enumerated from final candidate and explicit new routes; former full151 is reference only, not preset total. No launch permitted from draft.
- Two old authority routes use accepted final-r2 bytes: independent_tempering_authority903 and independent_weapon_order837, plus lifecycle124 per final-r2/PLAN.json. The separate independent_reservation_runtime901 is unchanged and must not be confused with temper. Original full149/151 failure history remains; corrected A combined evidence is not a rerun151.
