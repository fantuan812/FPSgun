# v21 interim content QA — not final release acceptance

The frozen mechanic contract is one new weapon, **Cryo Sprayer**, and one unique module, **Fracture Coil**. No other content or v20 artifact was changed by QA. This interim evidence covers the programmer's r2 production inputs listed in `source-fingerprint.json` (109 paths). Final cold regression, exact exported-pack verification and ordinary exported-native acceptance remain separate pending gates.

## Independent results

- **446/446** controlled source integration assertions pass: both modes, eight cone orientations and boundary membership, nearest-target tie ordering, coincident-target fallback, no new RNG draws, mark refresh/expiry/menu freeze, six old primary fire paths, one consume per mark/no hidden ICD, known weapon-type eligibility, secondary-proc exclusion, movement/boss/committed-phase rules, removal/reset and kill attribution.
- **316/316** controlled catalog/affinity/view/transaction assertions pass: exact 7-weapon/27-module counts, pair weights, positive capped exploration, 50 seeded redraws, unique filtering, exact prices, insufficient funds, stale callbacks, four-slot replacement, sale and read-only views. Cryo+Coil alone and duplicate Cryo remain INACTIVE; a different weapon type makes the pair ACTIVE. Malformed new tuning and prerequisite fields are rejected.
- Promotion copies of both tests run successfully **without required output arguments**. Optional JSON output is supported; logs and hashes are indexed.
- Old behavior preservation: the same independent harness yields byte-identical **declared old-schema** authority traces over 12 cases × 240 steps, both modes, all six old weapon types and 24 old modules sampled in supported builds. Floats are quantized to 1e-6; this is not unqualified full-state identity. Old RNG states are included. One losslessly compressed copy is retained, with comparison hashes.
- Old shop preservation: exact six old weapon and 26 old module ID sets/definitions, weighting/affinity data, 400 seeded draws and 384 transaction probes are byte-identical after excluding the two new entries and their pair. Normal v21 shop draws may differ because the pool expanded; old seed→offer identity is not promised for that expanded pool.

## Rejected radius defect and correction

The original interim implementation used a 1e-6 world-unit radius epsilon. A mathematically 190-unit target at 315° becomes 190.000015258789 in Vector2 and was excluded in both Arena and Rooms. Independent tests reported four failures (damage and mark per mode). The programmer independently found the same defect.

The r2 shared membership/target-selection tolerance is 0.0001 world units; angular tolerance remains 1e-6. All eight orientations now pass, while targets 0.02 outside remain excluded. The rejected source, clean failing result and minimal reproduction are retained in `rejected-radius/`; they are not passing-release evidence. Separate early QA-harness mistakes (wrong `brood` ID and a missing manually populated combat-frame area) were corrected and rerun before these accepted comparisons; those failed harness runs are not product defects or claimed passes.

## Actual cloud Linux native review

Sixteen unchanged, game-window-only JPEGs document **controlled setup**, not an unassisted run or a shipped export. The fixture injects loadout, targets, health and shop offers, and freezes selected presentation states. Native sizes 960×540 and 1280×720 were observed. A short live controlled segment uses ordinary CUA movement with normal runtime combat after setup; it is still controlled, not ordinary acquisition or human-feel certification.

Observed: Cryo's compact mounted silhouette and mirrored orientation are readable; both new inventory icons are crisp; low-opacity cyan cone/target diamonds and consumed-mark shatter remain visible without hiding sampled actors or the boss's orange blast boundary. Arena and Rooms samples include both facings. Mixed-build ACTIVE and all-Cryo INACTIVE descriptions state the different-weapon requirement. The bottom white fixture caption overlaps boss status in one diagnostic sample; that caption is not shipped UI and is excluded from product-layout judgment.

Native shop controls operated on controlled offers: Cryo purchase **1000→956**, repeat SOLD click unchanged; Coil resale **+14→970**, then native Coil purchase **−28→942**. The offer's unique-item disabled state changed correctly after sale. Cards and scrolling remained readable. This supplements, but does not replace, the controlled transaction assertions. A native full-slot replacement and ordinary earned pair purchase are not claimed here.

The native log has the known cloud VSync warning and ALSA ERR_CANT_OPEN followed by dummy audio. No script/resource error appeared. No audio or Windows runtime acceptance is claimed. Source was read-only to QA except in its isolated copy; only the external fixture scene/script were added there. The native window was cleanly closed.

## Pending final gates

Final immutable source fingerprint and cold full suite; final exported dynamic-resource/texture parity; ordinary native ELF run on that exact final PCK, preferably earning and buying the pair using a reproducible seed. No human balance verdict, exhaustive build-combination coverage, natural Rooms boss encounter or continuous-motion certification is inferred from this interim batch.

`EVIDENCE_INDEX.json` covers every other file. All public paths are relative; private launchers and host-profile directories are excluded.
