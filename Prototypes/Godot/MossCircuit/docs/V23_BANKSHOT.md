# v23 — Bankshot Driver and Bounce Guide

This content version adds one weapon and one unique module to the shared combat system. Arena and Rooms keep their existing encounter rules and rectangular field interface. The previously reviewed v22 modifier wording is included in this runtime source; it does not retune damage or attack rate.

Bankshot Driver costs 42 scrap, deals 18 base primary damage every 0.85 seconds, and travels at the snapshotted projectile speed (470 world units/second by default). One shot has a single 900-unit total path budget, not 900 per bounce. Range bonuses scale acquisition reach and that total path once each. The shot reflects at most twice from the rectangular field boundary, allowing three armed legs. Each leg can hit 1 + pierce targets, capped at 6. A spent leg continues dim without damage until a real reflection re-arms it.

This is positioning-dependent: from the center of the large Arena, reaching the first boundary can spend most of the budget. Move near a field edge to make bank shots useful. Interior artwork is not a collider, and the weapon does not bounce from enemies. Pellet bonuses do not add Bankshot projectiles. Damage, additive attack rate, projectile speed, range and pierce retain their stated scopes.

Bounce Guide costs 26 scrap, occupies one module slot, and requires Bankshot Driver. At the first reflection only, it redirects once toward the nearest eligible living target inside the field and within the remaining travel. It does not home, add damage, add a shot, or reset range. With no eligible target it reflects normally and spends the opportunity. Overlap-blocked targets cannot be selected. Later equipment edits do not mutate existing shots; stage/run cleanup still removes them.

Each genuine hit is primary damage and uses the established proc pipeline, including Cryo/Fracture. Fixed secondary effects remain fixed and do not spawn ricochets. The exact endpoint, corner, overlap carry, budget and tie rules are in `V23_BANKSHOT_CONTRACT.md`.

The expanded content pool intentionally changes actual seeded shop offers. Determinism is evaluated within content version 4. Preservation tests separately pin all previous 7 weapons and 27 modules, their definitions and filtered shop behavior; they do not falsely claim the expanded pool produces old offers.

## Acceptance and limits

Author and independent cold suites each pass 70 standalone entries plus import (71 total), with 251 declared inputs unchanged. Independent analytic234, contact/Guide62, real integration96 and catalog347 checks pass; Python safety3 and source-art27 pass. All115 production inputs match the immutable source candidate. Independent source-imported fingerprints match the build oracle, and the exact PCK passes823 checks without source fallback.

The initial helper passed a narrow suite but missed a floating-point boundary endpoint: it delayed an exact reflection until another tiny tick. A shared spatial-tolerance snap fixes this without adding travel or granting reflection at exhausted range. Another new-weapon edge case aimed toward a synthetic distant point for a coincident target; the final measured-mount fallback produces exact RIGHT in every slot/facing. Malformed new-entry numeric fields now reject safely. Rejected results and the independent tiny-step oracle timing clarification are retained, not called final passes.

Controlled native fixtures cover both modes, actual960x540/1280x720 sizes and both facings: armed/spent/reflection/Guide feedback, original enemy tell hierarchy, reduced-flash sample, shop/inventory and unique-module transactions. These use explicitly injected setups. Artist independently inspected14 representative stills.

Separately, ordinary CUA input on the exact exported Linux build used planned seed86, earned122 scrap after wave1, bought Guide26 then Bankshot42 leaving54, and retained Rivet. Wave2 showed an actual top-boundary contact followed by successive outgoing positions into the field and BANKED VECTOR ACTIVE. Ordinary automated CUA keyboard/mouse inputs and tactical pauses were used, with no injected build/currency or programmatic game-state control; the finite run stopped around40-42 combat seconds, returned to title and closed with unchanged artifact hashes. Eight exported stills were independently reviewed for appearance parity. The amber contact does not establish guided retargeting, numerical damage or kill attribution. This is not a full campaign or all-combination balance test.

The PCK is a8ef8b7720ac374f10e5d5378bd413b5d415e845a35495bb89399a4ee5f3864a. The ELF/EXE retain verified official-template bytes; no silent rebuild followed native review. Linux cloud VSync and ALSA-to-dummy-audio diagnostics are explicit in the unedited native log. Windows PE/resource artifacts were inspected but not executed. Audio, human balance, target-hardware performance and continuous-animation feel remain unverified. Remote Git publication is a separate permission/readback gate.

