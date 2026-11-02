# v47 — editable shield impact

**Source, resource-pack, controlled desktop and local restoration validation complete. Publication and remote-dependent assembly pending.** This is not a published-release announcement.

## Artwork, not new shield mechanics

A new self-contained SVG master replaces the shield-impact effect's raster-only authoring source. A compact contact grows into a tall right-hand crescent, breaks into upper/lower pieces and decays into sparse shards. The nine stages have distinct geometry, not nine scaled copies. This is new semantic artwork informed by the earlier reference, not a recovered original master or pixel-identical restoration.

The rendering contract stays fixed:

- Transparent **1254 × 1254** sheet, **3 × 3** full **418 × 418** cells, all nine nonempty.
- Center anchor **(0.5, 0.5)**, without cropping or recentering. The painted crescent is intentionally asymmetric, not a full shield bubble.
- Actual runtime **18 fps / 0.5 seconds**, nearest filtering and alpha-mix blending. The old art recommendation of 24 fps / 0.375 seconds is not runtime timing.
- Default **56 × 56 world units**, healing override **32 × 32**, and reduced-flash opacity **0.4**.
- Radius callers use square side **radius × √2**, not diameter. Gravity's visual radius **100** is distinct from gameplay pull radius **150**; Thorns uses visual radius **130**, Recoil **100**. Painted bounds do not redefine gameplay geometry.

The neutral cream core, green edge and warm contact accents retain the five existing color multipliers: white, healing green, gravity lavender, thorns coral and recoil pale green. Multiplication does not make every pixel uniformly colored. Existing circles and contact effects are separate presentation.

Production code, shielding/healing eligibility, damage, movement rules, event hooks, timing, cooldowns, pooling, random streams and UI are unchanged, as are the other five effect sheets. [Edit and export the complete SVG sheet](../art_source/shield_impact_v47/AUTHORING_SCOPE.md); the runtime texture remains `assets/vfx/shield_impact.png`.

## Completed finite checks

| Check | Actual scope |
| --- | --- |
| Imported source | **129 checks** on the new sheet and its nine frame regions, transparency and visible pixels. |
| Actual resource pack | **129 checks** against actual source-imported sheet/frame observations, plus the existing **1,068-check** resource/integration smoke gate. |
| Documented BUILD entry | The existing **14 routes**, with unchanged test bodies and warning policies, passed from the current merged source. |
| Controlled desktop shield observation | **375 checks**, **25 original captures**, **11 controlled setups** and **nine post-intent presentation-authority guards**. |
| Direct visual review | Author review of all **25** originals and independent QA review of **16** selected originals. These were agent visual reviews, not a claimed human playtest. |

The accepted local production tree contains **995 source inputs**; its source-plus-test-wrapper tree contains **1,027**. These are not remote publication counts. The wrapper is separate from the production export. From the imported project root:

```sh
python3 tools/run_build_ui_checks.py
```

See [BUILD validation instructions](BUILD_UI_VALIDATION.md). This finite entry is not the external shield observer or a full-game suite.

### Timeline and seven source cues

**18 timeline captures** cover frames 0–8 in normal and reduced states at the default size. Actual effect-layer advances check just-before/at boundaries, final nonempty frame and expiry, full-cell binding, anchor, scale, filtering and noncompounding opacity. This is **fixed-step validation of configured timing**, not measured real-time FPS or continuous playback.

The remaining **seven captures are normal-only peaks at zero-based frame 3**, covering five existing emitter branches:

| Source cue | Controlled entry and selected actual outcome |
| --- | --- |
| Mirror Shell | A zero-damage hurt call still consumes the available shield before HP changes; HP remains 100. The direct cue does not acquire an invented positive-loss requirement. |
| Return Spool | A controlled returning Return Disc primary-hit event at full HP emits the actual healing cue even though capped HP stays 100. |
| Blood Valve | A controlled primary-hit event at HP 35 applies the actual low-HP heal to 38. |
| Blood Mines | A controlled mine-source kill event with the legal Valve/Mine pair emits the heal while HP remains capped at 100. |
| Gravity Anchor | A controlled mine-detonate event moves a living target from distance 140 to 80, demonstrating the existing 150-unit pull range rather than the 100-unit visual radius. |
| Thorn Crown | A real hurt call reduces player HP to 90 and the actual Thorns command damages a nearby target by 18. |
| Recoil Plate | A real hurt call causes positive surviving HP loss in a valid arena. A sole in-range boss does not move, but the cue still appears. |

The event-input cases are controlled observations, not full projectile flight, acquisition, mine-kill or proc-combat replays. Each cue also underwent **numerical** normal→0.4→normal checks through the existing settings controller. These are not seven additional reduced caller screenshots or physical menu clicks.

Two no-image follow-ups deliberately remove living targets and advance controlled time after the earlier presentation guards; Gravity and Thorns still emit their cues without further HP/position changes. One same-seed Recoil pair compared selected HP, nonboss displacement, cooldown and random streams with shield presentation enabled versus disabled. This is bounded parity, not global combat/RNG certification. Intentional commands, HP changes, settings and time inputs are outside read-only presentation guards.

Event order is inherited from unchanged code, not intercepted callbacks: block occurs before HP application; healing cues follow capped HP updates; pull/thorns cues precede their application; Recoil applies movement before its valid-area cue. Generic pool, pause/restart and source-cooldown suites were not replayed wholesale.

## Visibility and interpretation limits

In the controlled **960 × 540** viewport, early growth, the crescent peak and split are distinct at normal opacity. Late normal fragments and reduced decay can blend into the floor; reduced late frames are not reliably distinguishable by eye. Nonempty frame data is not a contrast guarantee.

The three small healing cues overlap the avatar and weapon, so the complete 32-unit arc is not independently unobstructed. Larger warm contact shapes also obscure part of the player. Existing block/pull/thorns/recoil circles, hit sparks and weapon imagery coexist; they are not all pixels from the new texture. A full-cell containment check does not imply every painted detail is visible.

Gravity/Recoil position changes are actual gameplay-data observations. With game processing frozen for these captures, the stills do **not** prove enemy-sprite resynchronization or a visible displacement animation. Display sizes are world/logical units, not guaranteed physical pixels under arbitrary camera or OS scaling. Static editing previews round fractional sampling into image envelopes; native geometry checks use the floating sizes.

No new full-combat/proc, all-effects, inventory/UI geometry, full-suite, physical-audio, Windows execution, CI or delivery-executable launch result is claimed.

## Retained failure and release boundaries

The initial strict pack comparison stopped on generated scene metadata. Its specific difference was verified before continuation on the same pack; the original failure remains a failure, not an initial complete pass. Source/packed identity, native execution and direct visual review remain separate scopes.

The BUILD run retained its exact historical warning allowance and the native run its specific known display-warning allowance. Neither is called warning-free. Local restoration passed **10 controls: two positive and eight negative**. An actual resource-pack backup, replacement and rollback restored the exact previous local pack while preserving executable bytes and permissions. These are local file-restoration checks, not a delivery-executable launch, installation or Windows execution test. Remote publication of the preceding hit-spark and explosion releases and this shield-impact release is also pending; source/history assembly must wait for the actual preceding publication outcome rather than assume a new base.
