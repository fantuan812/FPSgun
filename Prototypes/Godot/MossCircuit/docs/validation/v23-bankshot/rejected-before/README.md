# Rejected/probe evidence, not final acceptance

`geometry-first.log` passed a narrow 32-check suite that did not cover the later independently discovered exact-endpoint precision defect. It is not the final geometry gate. The independent report preserves that defect and its corrected oracle result.

`build-first.log` is a rejected author harness: it queried a nonexistent `id` in the public synergy view (which exposes `name`), then was interrupted. This was not a game defect. The corrected final test uses the actual view contract.

`bank-validation-before.log` and `build-r4.log` reproduce unsafe comparisons on malformed new catalog fields. The guarded final validation rejects them, and the final controlled integration test includes 24 malformed-value cases.

`coincident-before.log` shows the new weapon's coincident synthetic target tilted actual shot/mount direction. `coincident-after.log` verifies exact RIGHT across four slots and both initial facings. Only that new fallback route changed; old target-solving routes remain intact.

Raw originals remain separately preserved. `PUBLIC_HASH_MAPPING.json` records exact original/public hashes and the sole path-label substitution where needed. None of these rejected logs is counted as a final pass.
