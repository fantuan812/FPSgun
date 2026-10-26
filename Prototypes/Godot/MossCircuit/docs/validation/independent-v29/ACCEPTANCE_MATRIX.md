# Frozen independent acceptance — upgrade-to-scrap decision

Expectations frozen against contract SHA256 383822e1eb49ac915fb2e7edbec574a4534678a79258577e102850ec0daa4841 before implementation. This is design acceptance, not implementation acceptance. Accepted v28 is the baseline. Heavy execution awaits the parent serial-validation window.

## Proposed decision

Resolve the current earned upgrade choice by either taking one of its existing three stat upgrades, or permanently forfeiting that one stat pick for a fixed 10 scrap. This is an immediate equipment budget versus lasting power choice, complements a held shop offer, and does not add an item, reroll, extra choice, XP, or save system. All earned-XP and authored settlement choices are treated identically. Finite mode progression already bounds opportunities; no artificial per-mode allowance is proposed.

10 is proposed tuning, not a balance-certified exchange rate. It equals two current refresh costs and does not alone buy most weapons. Do not call the existing mandatory-pick design a bug. At capped speed/pierce, or on a build that currently does not benefit from pierce, players may prefer budget; future compatibility still belongs to the player rather than automatic filtering.

## Semantics to freeze before code

- On a valid current upgrade page, salvage consumes exactly one pending choice, grants exactly 10 integer scrap (not coin-bonus scaled), leaves coin_fraction, XP, level, build.levels and owned equipment unchanged.
- No RNG draw for the salvage operation itself. If another choice remains, the existing next-choice generation legitimately consumes its normal loot RNG; if a shop is next, its existing stock draw legitimately uses shop RNG. Compare at declared transition boundaries rather than claim all RNG forever unchanged.
- Old select-one-of-three behavior and no-salvage seeded streams remain byte/projection-identical. Existing automation still selects a stat and must not silently salvage.
- Resolve once through current state + choice_generation; stale/duplicate/malformed inputs fail atomically. Old page callbacks cannot consume the next pending choice, a later run or grant double scrap.
- Apply the same queue tail as a stat selection: next pending choice, then authored shop if pending, otherwise resume. Never force a new shop/choice or allow a post-victory choice.
- Currency income leaves build revision unchanged, matching existing income convention; no recompute/reset or new effect event. Preserve combat clocks, in-flight shots, HP/dash/shield/effect state and held shop record while paused, except any existing explicitly shared transition effect.
- Salvaging a reward is not reducing the already earned level. Stat growth is omitted only for this pick, no refunds later and no held-card auto-purchase.
- UI must make the permanent sacrifice and exact fixed amount explicit, show enough current budget context, retain all three stat buttons and native960/1280 usability. Native keyboard/mouse + existing ui_accept only; no new joypad mapping or physical-controller claim.
- Use one fixed shared Rules resolution definition, not a seventh upgrade or item. The client sends only its exact resolution ID and current integer generation, never the credited amount. Existing weapon/item/encounter prices and rewards stay exact. Fixed integer credit should preserve coin_fraction bit-for-bit rather than pass through fractional-income arithmetic.

## Independent acceptance matrix

1. Strict old content/data preservation and finite no-salvage choices/queue/shop/RNG replay against v28, both modes. Declare expected new config field only.
2. One normal earned choice: exact coins+10, unchanged fraction/XP/level/owned IDs/build.levels/stats, pending-1, proper return state. Currency bonuses do not multiply it; high/zero starting coins and fractional credit retained.
3. Multiple pending choices: salvage→stat, stat→salvage, salvage→salvage, differing generations, stale original callbacks after each transition; no extra choice/free reroll. Quantify normal next-page RNG draws separately.
4. Stage boundary: actual floor-XP settlement plus authored reward choice, reserved card survives, shop drawn exactly once with unchanged owned-build affinity, no held-card purchase. Modes with no shop do not gain one; terminal settlement queues none.
5. Lifecycle: pause/dead/won/shop/title requests rejected, title/retry/newseed invalidate old callbacks; failed/malformed action has zero state/RNG/currency/revision effect. No UI redraw changes authority.
6. Combat-sensitive paused choice: existing in-flight ordinary and Bankshot shots, pending blasts, dash/effect cooldowns and health survive currency-only action consistent with resumed state. Do not run an unrelated full campaign.
7. Read-only UI/card/focus callbacks at960×540 and1280×720 in both modes; all three upgrades remain selectable, salvage visibly states lost stat pick and fixed scrap. No false DPS/level-loss/coin-bonus language.
8. One finite exact-export ordinary early choice: capture before/after budget and queued flow, then optional natural shop purchase if needed to establish functionality. Offline seed planning disclosed, automated CUA/tactical pause allowed, no injected build/economy. Controlled tests cover rare edges; victory/Windows/balance not required or implied.

Programmer contract independently accepted; implementation and test execution remain subject to parent scope and serial-validation authorization.
