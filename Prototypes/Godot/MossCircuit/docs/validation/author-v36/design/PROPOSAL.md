# Candidate player-content unit: Scavenger Reel

Status: read-only selection proposal; no implementation or target execution.

## Why this unit

The current game has eight weapons and twenty-nine modules. Return Disc already has a mechanically different outward/return path, but its dedicated partner Return Spool is only returning-hit healing. Ground pickup acquisition still requires the player's 14 px contact or the existing global pickup magnet. Add one unique module that makes a returning weapon into a remote salvage tool, changing routes and build choices rather than adding a flat damage multiplier.

Scavenger Reel: an equipped Return Disc can collect up to three normal or energy pickups touched by its actual returning swept segment. Credit is immediate when intercepted, not delayed until arrival. Medical pickups are excluded. Outbound travel, other weapon types and secondary effects cannot collect. The return disc's damage, piercing, range, lifetime, collision and returning-hit healing do not change.

The module creates concrete existing-system combinations:

- Return Disc + Scavenger Reel: remotely harvest a dangerous lane while moving/aiming the return route.
- + Scrap Mine: remotely collected normal pickups place the existing mine at that original pickup location, obeying its existing cooldown/cap. No extra mine multiplier.
- + Kill Cell + Arc Relay: intercepted energy orbs charge the existing chain mechanic; energy pickups still do not trigger normal-pickup mines.
- Duplicate versus tempered discs keeps its existing tradeoff: fewer separate attacks means fewer independent collection opportunities. No invented tempering bonus.

## Existing implementation evidence

- `data/catalog.json`: 8 weapons, 29 items; Return Disc is behavior `return`, 330 range, 0.9 s interval, unique Return Spool partner; data includes `mechanism_synergies`, `affinity_links` and bounded shop weighting.
- `scripts/gameplay/weapon_combat.gd:127-147`: `advance_disc` explicitly divides outbound and return portions, clears per-leg enemy hits, clips travel/lifetime and retires near the player. This is the authoritative geometric seam, not rendered position.
- `scripts/gameplay/combat_runtime.gd:85-119`: projectile advancement precedes enemy removal/drop creation and the one ground-pickup loop. The current loop moves pickups inside pickup_radius, then calls RunFlow.collect_pickup and emits one source-tagged pickup event at contact.
- `scripts/gameplay/run_flow.gd`: collect_pickup already applies capped healing, XP and fractional-banked scrap; encounter settlement collects remaining ground pickups. No second reward implementation is needed.
- `scripts/effects.gd`: normal pickup can place Scrap Mine; energy pickup charges the Arc Relay/Kill Cell combination. Existing cooldowns, caps and nonrecursive source rules must remain authoritative.
- `scripts/main.gd:744-765`: normal, energy and medical pickups already have distinct shapes, and Return Disc has a procedural ring presentation. A small collection pulse and remaining-quota pips can build on this without a new character/weapon model.
- `scripts/main.gd:775+`: recomputing changed equipment clears non-Bankshot projectiles. Launch-snapshot behavior must explicitly cover that lifecycle; no carried loot should be stored in a projectile.

## Bounded scope and data-driven contract

One new catalog item, one icon, one synergy/affinity pair and concise shop/build/weapon-readout text. No ninth weapon, character, mode, save system, generalized inventory service, new audio or external asset download in this unit.

Suggested initial data (design values, not measured balance): unique max_stack 1, price 28, tags returning/salvage; collection radius 18 px; pickup budget 3 per disc; allowed sources normal and energy. Validate finite bounded numeric values and explicit source IDs. Values live in the catalog; UI derives its description/status from the same accepted data rather than hardcoded text asserting a different radius/quota.

Snapshot possession/radius/quota at disc launch, matching the existing launch-snapshot style of Bounce Guide. Buying during flight must not retroactively grant collection. A launched eligible disc retains its existing snapshot until retired. Selling/replacing weapons keeps the current projectile-cleanup behavior. There is no cargo/pending-credit state: every collected pickup stays in the single authoritative ground array until removed/credited exactly once in the pickup stage.

Weapon simulation should report only actual return-segment geometry plus the owning disc's remaining budget. Collection and all rewards remain in the existing Runtime/RunFlow pickup stage; do not add economy/progression responsibilities to WeaponCombat. Clear transient sweep records every simulation step. Retain valid last segments when a disc retires at arrival/expiry, but never invent travel after lifetime exhaustion.

At the pickup stage, ordinary player contact has priority and does not consume the remote budget. Otherwise, eligible source + actual swept-segment proximity + remaining budget permits exactly one removal/credit. For multiple eligible discs use an explicitly frozen stable existing projectile-processing order, not RNG or dictionary iteration. Original ground-pickup order stays defined. Newly created death drops follow the pickup-stage snapshot policy explicitly; do not pretend their exact sub-tick creation time is modelled.

Adding a catalog row intentionally changes shop offer possibilities/weights. Preserve existing rows and RNG draw ownership, but do not claim old fixed-seed shops remain byte-identical after enlarging the catalog. Old combat behavior without the new module and old-catalog replay controls should stay exact.

## Player-facing deliverable

- Distinct reel-shaped module icon, not a recolored generic square.
- Shop/build card states: return leg only, maximum three normal/energy pickups, immediate credit, medicine excluded; incomplete build explicitly says Return Disc is required.
- Small three-pip quota indicator on eligible returning discs and a bounded pickup interception pulse. No permanent beam clutter; reduced-flash behavior respected.
- Mechanism overview links the real return-pickup/mines/energy interactions without claiming bonus damage or free currency.
- Controlled native captures and one finite ordinary purchase/play observation showing acquisition, return-path collection and quota exhaustion. Do not force a lucky shop seed or silently retry until a clean story appears.

## Required oracles and acceptance boundaries

1. Pure geometry/quota oracle independent of production collection implementation: outbound excluded, turn split, strict chosen edge rule, zero-length segment, final clipped segment, expired disc, dt partition on fixed pickups, radius malformed/refused.
2. Real authority integration: two discs cross the same pickup; player contact and disc overlap; pickup removed/XP and fractional scrap applied exactly once; max-three budget; normal/energy/medical distinction; multiple copies and tempered copies; late purchase/sale/restart/settlement/death/paused states.
3. Real synergy traces: remote normal pickup places at most the existing cooldown-allowed mine at original position; energy charges existing chain only, never a normal mine; medical remains uncollected remotely; no recursive creation/collection explosion.
4. Ownership/lifecycle: no projectile cargo and no pending rewards; stopping/clearing projectiles leaves uncollected world pickups intact; no rewards after terminal state; final settlement neither loses nor duplicates residual pickup value.
5. Old-build/old-catalog parity where contractually applicable, new catalog/affinity validation, ordinary GUI purchase/inspection and exact packed artifact checks. New shop possibilities are intentional, documented changes rather than an unchanged-RNG claim.

This is a proposal for one player-visible build module, not proof that it has shipped or is balanced.
