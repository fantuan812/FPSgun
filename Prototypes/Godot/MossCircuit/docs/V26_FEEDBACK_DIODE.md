# Feedback Diode — v26 bounded acceptance

This adds one unique 28-scrap mobility module. A successful dash begun with Feedback Diode equipped arms one counter: actually touching a hostile projectile during the unchanged dash window deals 24 fixed secondary damage to that shot's living owner. Near misses, melee contact and blast areas do not count. There is no new immunity, travel projectile, weapon scaling or recursive on-hit proc. The once-per-dash allowance is spent only by a valid living owner in the existing reverse projectile-array order.

CROSSCURRENT pairs it with Pulse Boots: the existing nearby push and the new one-shot counter are complementary, not an additional damage bonus. Shop pools now include the new item; identical seeds can produce different offers across content versions. All previous item definitions/order, balance data, field geometry, mode policies and no-item combat behavior are preserved. See [the frozen contract](V26_FEEDBACK_CONTRACT.md) and [exact additions](V26_CATALOG_ADDITIONS.json).

## Readiness and presentation

The inventory distinguishes READY THIS DASH, UNARMED THIS DASH and ARMS ON NEXT DASH. Sale clears the allowance; buying, recomputing or reopening a menu cannot arm the current dash. Combat-time pause preserves an unspent allowance. A violet hollow dash marker and brief return line are presentation only; reduced-flash output remains subdued relative to orange enemy warnings.

## Rejected development findings

- The first author test found a missing title-transition reset; the transient allowance is now cleared there. Its two other per-mode failed probes were harness shots that had not reached the player, not damage failures.
- Independent malformed-catalog probes found an unguarded uniqueness comparison raising script errors for nonnumeric values. The final candidate uses the existing positive-number guard before comparing to one, with dedicated regression cases.
- Two old tests assumed their historical pair/link was the last catalog entry. They now explicitly assert and remove the exact new v26 addition before the original strict preservation comparison; they do not weaken old-definition equality.
- The first broad author run overlapped a root-manifest refresh. Its MANIFEST-only input change is recorded, not reported as immutable-source acceptance. Final frozen-source runs are separate.

## Acceptance boundary

Independent cold import and all 80 standalone entry points passed with all 569 non-cache candidate inputs unchanged. Python safety passed 3/3, art source checks 11/11, new independent runtime/shop/type checks 380/380, and packed-resource checks 833/833. The 380 new checks were also replayed against the actual PCK without source fallback. Both preset PCKs are byte-identical; the unchanged accepted Linux executable was recovered from verified GitHub bytes, not rebuilt.

Controlled native Arena/Rooms views at 960×540 and 1280×720 established icon/cue/readiness/modal legibility. Ordinary automated CUA inputs with tactical pauses and no injected build/currency earned 118 scrap on seed 433, bought Diode for 28 and Pulse Boots for 28, and observed CROSSCURRENT ACTIVE. A Spitter shot and dash attempt were observed; the short return cue was not captured, so ordinary interception success/damage ownership is not claimed. Fixed damage/proc ownership remains controlled-test evidence.

Native diagnostics retain unavailable ALSA/dummy fallback, VSync limitation and one startup XServer BadValue; rendering/input continued. Do not equate clean headless regression with zero native diagnostics. No Windows execution, audible sound, full-campaign completion or broad balance certification is inferred. Final evidence and delivery restoration checks are separately indexed.
