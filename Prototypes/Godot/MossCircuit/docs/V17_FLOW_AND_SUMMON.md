# v17 · Settle earned upgrades, show offers first, distinguish Core summon

Baseline is v16 commit `453960ffd8f3354cee0d0ca8b0abc762ad8b91a0`, complete
release MANIFEST SHA256 `6ddcdb69083e6455d7abaacc9a85ee5fbbe64c05e3d703b4ea68c69eb075d408`.
The v16 source/ZIP are immutable; this batch is a separate fork.

## Encounter settlement ordering

Previously, end-of-stage settlement collected floor XP but only the next live
simulation tick accrued levels. Deploy could immediately show another upgrade
modal. This was reproduced independently with XP 11/12 plus 2 floor XP.

Settlement now accrues all earned levels immediately after collecting floor
pickups and before queuing the stage reward/shop. Every earned choice and the
stage-granted choice must resolve before the shop. This applies to both Arena and
Rooms and to policy-selected nonadjacent stages. The first next-stage tick does
not replay this already-accounted XP. Repeated completion remains idempotent.

Terminal settlement includes final collected XP in the displayed level/remainder,
but queues no inaccessible post-victory choice or shop. No XP threshold, coin,
healing amount, enemy rule or item price changed. This deliberately changes flow
and final-level reporting; it is not claimed as full settlement trajectory parity.

A suspected held-Space input leak was **not reproduced** in the independent actual
viewport press/echo/release test. Only a fresh press/release selected a choice;
there is no speculative input suppression in this batch.

## Offer-first shop

The shop now shows purchase/replacement actions directly below the offer name.
Replacement's destructive/no-refund warning and chosen slot remain immediately
above its button. Initial probability explanations are collapsed behind a
keyboard-focusable `SHOW DRAW DETAILS`; item mechanics and per-offer relative
weights have their own read-only disclosures. Names, prices, availability and
purchase actions remain visible. Detailed text is retained, not replaced by
probability claims or removed.

Expanding/collapsing is local presentation state, never a purchase, reroll, seed
change or generation update. Existing purchase/sale/replace guards and full
inventory details remain unchanged. Focused checks cover first actions for all
32 catalog entries at 960×540; independent edge checks cover full slots,
unaffordable/sold offers and disclosure/navigation behavior.

## Core summon attempt

Only the actual Core `summon` attack uses the new 16-pose root-cradle animation:
warning0–6, release7, recovery7–15. Old `ring` keeps its original nine-frame source
and event-driven timing. `ActorDirector` reuses the v16 attack-only variant
selector; this batch adds no new presentation timing authority.

The real phase-2 third-attack cadence, locked aim, .7-second recovery and live-child
caps remain unchanged. Release means **attempt**: zero children may be created if
caps are full. Hurt cannot delay/replay the attempt; death is terminal. The game
uses the real Core height165.3 world pixels, not a thumbnail assumption.

Source pixels and measured hover/orb registration are documented in
[Core summon art](art/core_summon/README.md). Final true-scale GUI acceptance is
recorded separately; headless count/geometry checks alone do not establish motion
quality or a seamless handoff.

## Documentation erratum

The v16 prose estimate of roughly10 world pixels for its rejected Warden snap was
incorrect. The accepted correction remains31 source pixels; at the real Warden
height148.2 and reference207 this is approximately22.194 world pixels. Source
measurements, correction bytes and native-window acceptance were correct. This
erratum does not rewrite immutable v16 evidence. See the exact conversion table
in [scale estimate erratum](art/core_summon/SCALE_ESTIMATE_ERRATUM.md).

## Verification and limits

Focused author results before final freeze: settlement20 checks; all32 initial
shop offer/disclosure scenarios160 checks; Core true-scale/phase/caps/ring/finite
RNG authority2510 checks; Core source resources78 checks. Final aggregate and GUI
acceptance belong to the final validation report, not these preliminary counts.

The separate v16 Arena extension established ordinary CUA-controlled six-wave
victory, both Boss rewards and normal purchases/upgrades. It is historical
supplemental evidence, not a claim that all v17 flows were already replayed.
Windows, human balance/fun, continuous-video motion review, audio, saves and full
dungeon exploration remain outside this prototype acceptance.
