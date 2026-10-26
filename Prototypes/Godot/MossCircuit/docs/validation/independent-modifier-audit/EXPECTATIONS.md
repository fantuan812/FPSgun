# Advertised compatibility matrix — frozen before execution

Scope: read-only current v21 final production, independent controlled source tests in both modes. No production edits, full campaign, all-combination or balance claim. The frozen v21 mechanic contract is the authority; separately compare shipped wording, without silently redefining mechanics to fit a test. Where wording and contract may differ, report actual values and attribution to old behavior.

| Case | Pair / modifier | Expected behavior before execution |
|---|---|---|
| A | Cryo + Power Coil; mixed Cryo/Rivet/Fracture + Power Coil | Primary 9→10.35 at one stack; Fracture remains fixed16, no recursion. `+15% all damage` wording is a candidate clarity discrepancy if it implies fixed secondary scaling. |
| B | Cryo + Cooling Fan | Interval0.65/1.12; angle60°, duration1.2 unchanged. |
| C | Cryo + Rapid Circuit earned upgrade | Shared existing haste rule gives0.65/1.15, NOT0.65×0.85. Compare old Rivet same rule; shipped `Fire interval -15%` is a candidate inherited wording discrepancy, not a new Cryo timing bug. |
| D | Cryo + Focus Lens | Radius190×1.15=218.5;210center hit,220miss; angle and chill duration unchanged. |
| E | Cryo + Capacitor / Saw Gear / Pellet Pouch (separate setups) | No damage/pellet/angle/status change. Their current descriptions explicitly limit electric/orbit/shotgun respectively; Cryo has onlycontrol tag. |
| F | Cryo + Split Capacitor1 and5 | No cone change; multiple in-cone targets already hit once each with pierce0. Upgrade saysprojectiles; Cryo is instantaneous cone, not projectile. Audit whether this is clear in its exposed copy. |
| G | Cryo + Echo Chamber | Five eligible primary targets count as5hits, causing12secondary on fifth ordered surviving target, no recursive count. |
| H | Cryo + Arc Relay | One0.6s-global-ICD chain command per eligible batch, two other living targets, each40% actualCryoprimarydamage; secondary doesnot addprimaryhits or marks. |
| I | Cryo + Blood Valve | Below40%HP, one3HP heal per1s ICD even with multi-targetcone; fixed shatter doesnot emit an additional heal. |
| J | Cryo + Kill Cell; existingmixedFracturekill negative | PrimaryCryokill yields normalenergyorb; Fracturekill doesnot, preserves secondary attribution. |
| K | Cryo + Phase Capacitor | Actualdash event storesonecharge; firstprimarycone hit consumes once for12/95px splash; no recursive hit. |
| L | Cryo + Dash Resin/Pulse Boots; consume with existingFracturebuild | Realhazard slow remains independent, stronger0.55 vs0.65 (notproduct), consumingchill doesnot erase resin; committedcharge unchanged (alreadyindependentlycovered). |

Crit and bounce: no current catalog entry, upgrade or supported stat advertises these mechanics. Record absence; do not invent features or meaningless arbitrary-property tests. Return Spool/Blast Fuse remain explicitly disc-return/mortar-only, not generic cone compatibility promises.

Stop condition: execute this finite matrix, pin observed source fingerprint and useful claims; report concrete discrepancies with expected/current values and presentation vs authority scope. Any correction requires a separate programmer candidate; v21 stays immutable.
