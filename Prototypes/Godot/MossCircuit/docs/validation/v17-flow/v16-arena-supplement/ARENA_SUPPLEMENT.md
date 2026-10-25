# Ordinary Arena run — supplemental QA, 2026-10-25 UTC

This evidence was obtained **after the v16 release package was frozen**. It does not modify or retroactively replace that package's report.

## Result

Actual graphical cloud Linux Godot 4.6.3 run on the exact independent r2 copy `v16-r2-qa-snapshot`. Frozen source manifest SHA-256: `40fc6ff639be1a7d14b2e07cb8f4f35b0d3e886883d56bafea26bb145f0fbaab`.

**CIRCUIT COMPLETE — Arena Survival, wave 6/6, LV 18, kills 326, seed 874205.** Both Warden Protocol and Reactor Crown are visibly secured on the result screen.

Normal game controls operated by the agent through CUA/Sky keyboard/mouse automation: movement, numeric upgrade choices, inventory inspection, scrolling the shop and buying one Shock Mortar (118→72 scrap), Deploy. “Ordinary input” does not mean human/manual input: CUA is automated input. It means no in-game automation flag, programmatic game-state injection, phase stepping, health/stat edits, forced kills, or fixture. Final build: starter Rivet Gun + Shock Mortar, zero modules. Earned choices favored damage, fire rate and piercing. Warden was naturally encountered at wave 3; Core at wave 6.

The ordinary victory closes the previous full-Arena progression coverage gap. It does not establish human balance/fun, continuous-video motion acceptance, Windows execution, or audio quality.

## Native game-window-only evidence

- `arena-buy-mortar.png`: purchase and exact scrap decrement.
- `arena-warden-ready.png`: naturally spawned wave-3 Warden, 950/950 HP.
- `arena-warden-reward.png`: earned Warden Protocol in inventory.
- `arena-core-ready.png`: naturally spawned wave-6 Core, 1,600/1,600 HP.
- `arena-final-progress.png`: final victory with both earned boss rewards.

All five images are direct native game-window captures without unrelated browser/editor/desktop content.

## Design observations, not broad balance conclusions

This one seed completed with only one additional weapon purchase and no modules. That is evidence of a viable simple build, not proof that all seeds/builds are balanced. The existing queued shop-density and settlement-XP ordering findings were reproduced during the run; multiple earned XP upgrades appeared immediately after Deploy. No new progression blocker was observed.

## Separate controlled input diagnosis

`diagnose_settlement_input.gd` / `settlement-input-writable.log` reproduce a room boundary with XP 11/12 plus 2 floor XP: settlement leaves level 1 / XP 13, stage reward leads to shop, and the first post-Deploy simulation frame raises level 2 / XP 1 and opens another upgrade.

Controlled headless Godot viewport events did **not** consume a pre-modal Space press, held-key echo, or release. Only a fresh press+release selected one upgrade; echo did not select the next modal. This narrows the confirmed defect to settlement ordering; it does not establish real-OS timing or same-event leakage.

The first diagnostic launch failed before the script ran because default Godot user/cache paths were unwritable. It was rerun successfully with HOME/XDG directories under this QA workspace; no permission escalation or denied-path access was requested. This environment failure is not a product regression.
