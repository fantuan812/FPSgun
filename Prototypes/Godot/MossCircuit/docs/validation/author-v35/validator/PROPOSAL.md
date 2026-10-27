# Separate bounded validation correction — proposal only

Historical proposal before candidate source editing. Current v35 R2 and accepted v34 `run_flow.gd` are identical SHA256 `8a0fe9f8fdb3843a2505e9e365cdddf6649cca82d27b05af1cd2064c204334f7`.

## Concrete failure

Independent v35 negative testing supplied a String-valued `terminal`. `validate_resolution` records its type error, but its final cross-field expression still compares that String with `true`. Godot reports an incompatible String/bool comparison before the function can return its error array; the caller can then continue into unrelated missing-field errors. An invalid String-valued `shop` has the same unguarded-comparison seam when `terminal` is true. This is a pre-existing malformed-policy robustness defect, not evidence that ordinary built-in Arena/Rooms decisions are invalid.

## Exact smallest correction

The separate unified patch changes only the final cross-field condition: require `terminal is bool` before reading its truth value; require `shop is bool` before reading that truth value. Keep the existing actual-integer upgrades guard and all existing per-field type/bounds checks unchanged. `RunFlow.settle` already returns `invalid` before its first mutation when validation returns errors; no transaction redesign, coercion, defaults, repair or normalized replacement is added.

For every accepted policy, booleans evaluate identically and the compound terminal/shop/upgrade restriction remains unchanged. For malformed booleans, the already-recorded field errors now return normally. No audio hook, asset, range, RNG, reward amount, valid mode decision, lifecycle or UI changes are in this patch.

## Proposed acceptance

- Reproduce and preserve the original String/bool failure separately; restore that exact fixture after correction rather than dropping its case.
- Pure `validate_resolution` matrix: actual true/false terminal and shop, missing/null/String/int/float/array/dictionary alternatives; upgrades0/positive/negative/int versus wrong types. Input dictionaries remain unchanged. Preserve all existing type/bounds error entries and valid-policy outcomes.
- Actual `RunFlow.settle`: malformed terminal and malformed shop plus schema-valid negative numeric decisions return `invalid` before any world/session/effects/pickup/economy or RNG mutation. Include non-vacuous world/build/pickup/shield/queue state; no equality against an empty fixture.
- Actual controller `_complete_wave`: rejected decisions do not stop an already-active feedback voice or mutate run/stage; accepted direct next-stage and victory still stop at their existing pinned boundaries.
- Existing run-flow/mode/source authority tests and the independent originally failing negative fixtures pass with strict engine ERROR rejection. Re-run current old6/24 gameplay traces exactly and include the new check in the final aggregate; no full campaign or balance claim.
- Keep this correction's declared diff/evidence separate from unchanged audio R2 validation. Do not silently rewrite the baseline.
