# v36: Scavenger Reel return-path collection

## Player-facing build content

Scavenger Reel is one rare, unique module, priced at 28 scrap. Equip it with Return Disc: each disc launched while the module is owned immediately collects up to three normal/energy ground pickups touched by its returning path, within 18 pixels. Outbound movement and other weapons cannot collect this way; medicine remains a physical-player pickup. The data defines radius and quota, and item/build text reads those validated values.

This is not extra damage, an XP/scrap multiplier, cargo storage, or a reward on arrival. A disc's collection budget never refills. Two actual discs have separate budgets. Buying the module does not upgrade already-flying discs; selling it does not retract or refill a valid launch snapshot. Existing equipment transaction clearing rules still apply.

Normal pickups may trigger the existing Scrap Mine at the actual collected position, with its existing cooldown and cap. Energy can feed the existing Arc Relay + Kill Cell relationship but does not become a normal pickup or create a normal-pickup mine. No mine or charge retroactively affects the earlier hazard/hit phase. Existing Return Spool healing and primary-hit damage are unchanged.

One distinct original vector reel icon, actual-prerequisite SCAVENGER RETURN status, and small remaining-quota pips identify the build. Empty pips mean collection budget exhausted, not projectile damage exhausted. A bounded pickup ring respects Reduced Flashes and adds no audio. Title/won/dead hide the quota presentation.

## Exact simulation policy

WeaponCombat reports only the actual nonzero returning movement segment. CombatRuntime holds those sweeps locally for its current step, then consumes pickups in the existing reverse pickup-index order; the first eligible sweep uses the existing reverse bullet-index order. Valid last segments can collect in that current phase even when the disc retires afterward. Zero movement, life exhausted at entry and arrival without movement produce no sweep.

The old magnet move happens once. Physical collection uses the saved pre-move distance and wins without consuming quota; remote collection uses the post-move pickup coordinate. The existing death pass precedes pickups, so pickups dropped in this tick can be collected in its pickup phase. Pickups appended by a pickup event itself wait until a later step. This is a defined discrete simulation policy, not a continuous-time claim that every drop existed earlier along the projectile's path.

RunFlow.collect_pickup remains the only pickup reward authority. A successful remote collection debits one quota, calls that same reward path, emits one source-preserving pickup event at the current coordinate, and removes the object once. Equal-valued pickup dictionaries are separate objects; no value-based deduplication is used. There is no persistent sweep queue and no delayed cargo to settle twice.

## Data and historical compatibility

The optional catalog row validates a finite positive radius no greater than 64, and a finite integer-valued quota from 1 to 8. Integral floats from the existing JSON parser are accepted only after validation; launch remaining/maximum are actual integers. Booleans, fractions, invalid numbers and malformed source lists are rejected. Sources are exactly normal and energy, and max_stack remains one. The old catalog does not need this row.

The new returning/salvage tags use existing counting and shop-affinity behavior. They add no new threshold reward: the existing stat thresholds remain electric/melee/spread. One affinity link prefers the missing Return Disc/module partner; it never guarantees an offer. Enlarging the shop catalog deliberately changes fixed-seed offer sequences. Old-catalog replay parity and new-catalog combat-without-module preservation are separate tests, not a claim of unchanged offers in the expanded catalog.

## Evidence status

The initial source passed author cold import and four focused routes, including 48 Scavenger checks. A separate exact-copy cold import and independent authority178, events46 and views132 checks passed with 703 source inputs unchanged. These are finite focused results, not the final aggregate, exported resource, native observation or balance acceptance. The original C1 catalog actual-int wording was corrected before target execution because the existing JSON loader represents integral numbers as floats; C2 preserves actual-int runtime quota. Original design and unexecuted fixture revisions remain recorded.

The generic export image fingerprint currently covers PNG resources, not the new SVG. Dedicated source-imported versus actual packed texture identity subsequently passed; it is separate from generic PNG fingerprint coverage. No physical listening, Windows runtime, all-build balance or complete-campaign claim follows from this content unit.

## Final local verification and retained failures

The first final714-input aggregate terminated117/125, eight fixtures/13 failures from historical catalog counts and projections. R2 changed only eight old fixtures plus an explicit test declaration/history projector: exactly three validated new append blocks reproduce held v35 raw317a and original post-tempering8800 hashes; historical indices/copy assertions remain. Eleven deliberate structured/raw corruptions are rejected. Production131 paths are unchanged. A true cold import froze717 inputs;13 focused tests plus import passed; then the mandatory complete124 standalone scripts+import passed125/125. Independent exhaustive raw audit verified all125,104 cleanup fixtures/111 observations, all717 hashes and original semantic counts. This is not an independent second whole-suite run.

ExactPCK resources858 and independent feature authority178/events46/views132/settlement30 passed. Mixer236/views168, dedicatedSVG pixel identity, PCM38 and export safety3 passed. The initial SVG fixture's JSONfloat/intArray comparison failure remains; its test-only numeric correction did not change production. Generic images remainPNG-only; dedicatedSVG and loadedWAV sample checks provide their own identities.

The original packed audioauthority single-process180s gate timed out, permanentlyFAIL. One unchanged-assertion timing diagnostic completed773/0 in178.371s;137 make_game calls consumed170.438s elapsed wall versus174 snapshots1.199s. This localizes measured work, not CPU/I/O cause or a performance guarantee. It is diagnostic only. A formally new mode-partitioned gate kept all original case/assertion/order/cleanup logic: Arena435 includes the one-time97 resource checks, Rooms338, total773. Each ran once under180s; new aggregate maximum360s explicitly differs from original180s. Arena79.960s and Rooms77.627s passed, and combined72 observations match sourcefull. The earlier timeout is never relabeled.

Four controlled actualPCK native cases (Arena/Rooms,960×540/1280×720) provide18 original captures: realUI buy/deploy and supplied disc/pickup geometry showed quota3→0,coins72→75,XP0→3,medical retained. One ordinary unchangedELF defaultseed240102/Rivet/Arena run reached firstshop124scrap,8 captures, no reset/reroll/injection; Reel was not acquired. Actual ordinary window1180×812 differs from requested960×540. Both processes closed0 and windows disappeared; VSync/llvmpipe warning retained. Dummy audio is not physical listening; Windows/campaign/balance/performance remain unverified.

Both preset PCKs equal41,450,052 bytes, SHA-256 ea994144d3ae76926b29fad6467cb4bd36bfce73fcc96683694eb31c18caaba5. ELF unchanged2c789193…. Local recovery helper10 cases and actual file-only v35→v36→v35 rollback passed. Full original logs, failed records, reversible patches, raw captures and attribution are in [independent evidence](validation/independent-v36/QA_REPORT.md). Local preparation does not establish GitHub publication.
