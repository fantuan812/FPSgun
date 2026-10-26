# Read-only advertised-compatibility findings

2026-10-25; exact accepted v21 production, after its immutable package gate. Expectations were frozen in `EXPECTATIONS.md` before execution.

**84/84 controlled matrix assertions passed in both modes. Two inherited wording discrepancies were reproduced. No new Cryo combat-authority defect was found.** This is finite pairwise coverage, not all-combination balance or native GUI certification.

## 1. Power Coil overstates its scope

Current catalog description: `+15% all damage`.

One stack changes Cryo primary damage from 9 to 10.35. With an existing mixed build, powered Rivet primary deals 17.25 and Fracture still adds **fixed 16**, not 18.4. Powered Rivet with Echo Chamber deals 17.25 primary plus **fixed 12**, not 13.8. The same Echo result is reproduced in old v20, so this is not a regression introduced by Cryo.

Suggested clarification: **Weapon damage +15%; fixed module damage unchanged.** Do not change the fixed secondary amounts to fit the old wording. Arc Relay derives its secondary amount from the primary hit and therefore does benefit indirectly; the matrix confirms 40% of 10.35 = 4.14. This distinction belongs in current compatibility documentation.

## 2. Rapid Circuit describes interval reduction instead of attack-rate gain

Current earned-upgrade description: `Fire interval -15%`.

The actual `main._take_upgrade(index, generation)` path increments the build's haste level; the shared controller schedules `weapon.interval / (1 + haste)`. The probe uses this real chooser and real `CombatRuntime.step`, not the legacy unused `Rules.apply_upgrade` helper.

- Cryo: actual 0.65/1.15 = **0.5652173913 s**; literal advertised interval reduction would be 0.65×0.85 = 0.5525 s.
- Old Rivet: actual 0.4/1.15 = **0.3478260870 s**; literal advertised value would be 0.34 s.
- Independent v20 and v21 old-Rivet probe outputs are byte-identical, including this value and fixed Echo damage.

Suggested clarification: **Attack rate +15% (additive).** Preserve the existing timing rule. Cooling Fan's existing attack-rate wording already matches its 0.65/1.12 scheduling result.

## Other bounded compatibility outcomes

- Focus Lens expands the cone radius to 218.5; angle and chill duration remain unchanged.
- Electric, orbit and shotgun-pellet bonuses do not change Cryo; those item descriptions already name their restricted scope. Split Capacitor does not alter the instantaneous cone; all in-cone centers already receive one hit independently of projectile pierce.
- Echo counts each primary target hit, Arc Relay uses its shared 0.6 s cooldown, Blood Valve uses its 1 s cooldown, and a dash-charged Phase Capacitor consumes only once on the first eligible hit.
- Cryo primary kills create Kill Cell energy; fixed Fracture kills do not. Secondary effects do not create recursive hits/marks/heals.
- The real resin hazard supplies its independent slow; the stronger 0.55 multiplier wins rather than multiplying with chill's 0.65. Consuming chill preserves the resin timer and movement slow until its own expiry.
- There are no shipped crit/bounce entries or supported stats to test. Return Spool and Blast Fuse explicitly describe returning-disc/mortar triggers; no generic compatibility was promised.

The current v21 contract already documents cone modifier exclusions. Explicitly calling Cryo an instantaneous non-projectile cone in its visible description, and Fracture fixed/unscaled, would make those semantics easier to discover without changing mechanics.

## Reproduction and status

Run `compatibility_matrix.gd` externally with a cold/imported v21 source project. It accepts an optional output JSON path and passes without one. Run `inherited_modifier_probe.gd` against separately imported v20 and v21 sources. Both use controlled fixture state in headless source integration; no ordinary or Windows play is claimed. Logs retain exact engine outcomes.

All 233 previously tested v21 inputs remained unchanged. No production file, accepted export or v21 report was edited. Any copy correction belongs to a separately authorized candidate, followed by exact description diff, regression and native shop/inventory/upgrade layout checks. The two discrepancies are **confirmed, not yet fixed** by this investigation.
