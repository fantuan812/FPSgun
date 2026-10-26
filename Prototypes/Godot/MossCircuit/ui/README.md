# Moss Circuit UI

`moss_ui.gd` is a Godot 4 `CanvasLayer`, added by main before calling any presentation method. It owns no game state. Every button emits `intent(action: String, payload: Dictionary)`; the controller must revalidate money, capacity, identity and generation before executing any transaction. Never trust a button's disabled state as an economy/security boundary.

## Screens and integration

- `show_title(seed)` → `start {seed}`.
- `update_hud(view)` displays health, XP, wave, level, scrap, time and kills. Buttons emit `inventory {}` and `pause {}`.
- `show_shop(view)` offers item cards, real atlas icons, price, rarity, tags, effect, buy/replace, refresh, current build, sell and deploy.
- `show_upgrade(options, generation, salvage={})` → `upgrade {index,generation}` for the unchanged three stat cards; an optional detached salvage view adds `salvage_upgrade {id,generation}`. The controller owns fixed payout and one-choice eligibility; UI never sends a reward amount.
- `show_inventory(view)` → `close_inventory {}`.
- `show_pause(view)` → `resume {}`, `inventory {}`, `title {}`.
- `show_result(view)` reads `won` (or `victory`) and offers `retry {}`, `new_seed {}`, `title {}`.
- `hide_modal()` hides the overlay and releases GUI focus; `modal_visible()` exposes presentation state.

Main must pause simulation/input polling while in any modal state, not merely rely on Control mouse filtering. The full-screen shade stops pointer input; buttons handle keyboard activation. Tab/Shift+Tab traverse standard Godot focus, scroll containers follow focused controls. UI is designed for a logical 960×540 viewport using stretch; arbitrary smaller logical resolutions are not supported. Text/icons are retained at nearest-neighbor sampling, with no SVG/web dependency.

## View contract

Base fields: `coins,wave,level,hp,max_hp,xp,xp_max,time,kills,seed,stats,synergies,weapon_slots,item_slots`.

- `weapons`: dictionaries `{slot,id,name,description,sell_price}`.
- `items`: dictionaries `{id,name,count,max_stack,description,sell_price}`.
- `synergies`: display strings, already computed by rules.
- Shop adds `generation,refresh_price,message,offers`.
- `offers`: `{index,id,name,kind,description,price,rarity,tags,can_buy,sold}`.
- `can_buy` must reflect affordability and domain restrictions but permit full-slot weapon offers when replacement is possible. The UI requires `can_buy` for replacement too. Replacing destroys the selected old weapon **without** refund, stated next to the selector.
- Shop intents: `buy {index,generation,replace_slot}`, `sell_weapon {slot,generation}`, `sell_item {id,generation}`, `refresh {generation}`, `continue {generation}`.

Last-weapon selling is disabled to avoid leaving the player defenseless. Main should enforce the same rule. Item sell explicitly means one stack unit, not all units.

## Generated item art

The UI reads `res://assets/items/icon_manifest.json`: `{atlas:"res://...png",icons:{id:{rect:[x,y,w,h]}}}`. PNG source pixels are preserved through `AtlasTexture.region`, `filter_clip` and nearest sampling; cards show every weapon/item's unique image. Upgrade icons reuse semantically appropriate module artwork (damage→coil, speed→boots, haste→fan, health→plate, magnet→magnet, pierce→capacitor), not unrelated placeholder shapes. Icon cache is local to the UI instance.

## Validation and boundaries

Run (with writable HOME/XDG directories):

```bash
HOME=/tmp/moss-ui-home XDG_CONFIG_HOME=/tmp/moss-ui-config \
XDG_DATA_HOME=/tmp/moss-ui-data XDG_CACHE_HOME=/tmp/moss-ui-cache \
godot --headless --path . --script res://ui/test_ui.gd
```

The headless test instantiates all seven presentation states, verifies intent payloads/generation, disabled unaffordable controls, no currency mutation, and Control layout size at 960×540 including full-slot shop and long inventory. This is **not** visual screenshot approval, hands-on playtesting, audio verification or Windows export validation. GUI/Xorg execution was unavailable under current environment restrictions; no bypass was attempted.

## v3: encounter information

- `update_bosses(Array[{name,hp,max_hp,phase,hint}])` shows a dedicated bottom HUD with actual health, phase and current action hint. Empty arrays and dead/invalid-health entries remove all previous boss controls and hide the panel. The controller must send current live bosses each frame and `[]` when leaving an encounter/title. Current rules spawn one boss; the layout additionally supports two simultaneous rows.
- `show_codex(entries)` shows a scrollable field guide with `id,name,description,tell,dodge`. Title/pause buttons emit `codex {}`; Back emits `close_codex {}`. Main owns the return state and simulation pause, so opening this screen never changes combat or rewards.
- Portraits use `assets/enemies/enemy_manifest.json`, `enemies[id].path` and first `frames[].region`. Optional frame-local `alpha_bbox` crops transparent padding non-destructively. No source image is rewritten. Explicit `icon_path` and `rect` on an entry can override the manifest.
- `view.rewards` is an array of **already awarded** run reward strings. Only nonempty entries appear in build/shop/results; no anticipated reward or fake unlock progress is shown.

Additional headless checks: non-boss HUD hidden, live health and phase, zero-HP cleanup, boss bounds, seven-entry codex bounds, keyboard focus and title/pause/open/return intent. Actual combat state restoration is tested by the main controller's integration suite. Graphical visual verification remains unavailable; do not describe these checks as screenshots or hands-on playtesting.

## v4: readable mechanism builds

All item cards now show trigger, trade-off, internal cooldown (ICD, seconds), stack cap and stacking rule in addition to the actual effect. New mechanism fields are `trigger,cost,cooldown,stack_rule,synergy_targets`. Legacy passive items fall back to passive/no-extra-combat-cost/zero ICD/additive copies, with their original description retained. Their shop price remains separate from combat trade-offs.

`view.synergy_status` is controller-owned: `[{name,active,requires:Array[display names],missing:Array[display names],description?:String}]`. The UI never infers activation from tags. Each matching item card and the build summary show ACTIVE or INACTIVE, exact missing requirements, required items and optional pair-effect explanation. The older tag synergies are labeled separately.

`view.mechanics = {shield,chain_charges,hazards,cooldowns:{item_id:remaining_seconds}}` contains a live snapshot, not UI-maintained counters. HUD displays only shield/charges/friendly-field count; exact remaining ICDs are in the scrollable build panel. Missing snapshots clear old HUD values. No timers, proc logic or economy code runs inside the UI.

New icons are read from `assets/items/mechanism_icon_manifest.json`. Its lookup is merged in memory into the old manifest without overwriting existing IDs, with each new entry remembering its own atlas path. Neither original PNG nor manifest mappings are rewritten.

Headless coverage now includes all 24 catalog icons, 20-item inventory plus intentionally long descriptions, shop column bounds at 960×540, mechanism details and cap text, actual/absent pair states, missing requirements, exact cooldown text and HUD snapshot/reset. `-- --allow-pending-art` is an explicit development-only option that prints PENDING_ART for absent textures; final acceptance is run **without** that option. No graphical visual approval is implied.

## v5: honest build-weighted shop

`view.shop_bias = {preferred_tags:Array[String],missing_partners:Array[String],sources:Array[String],summary:String}` is the controller's **current** next-refresh snapshot. It appears inside the left shop scroll column, avoiding unbounded header growth. The UI does not derive tags, calculate weights, filter the sampling pool or reroll offers itself.

Each offer may include `weight_multiplier:float` and `bias_reasons:Array[String]`, recorded at the time that offer was drawn. The card explicitly labels these **draw-time relative weights**, not final percentages. Weighted sampling without replacement changes the remaining pool between slots, so the UI never converts a multiplier to a displayed probability. Increased likelihood is not a guarantee.

Buy/sell updates the current preference snapshot immediately, affecting the **next** refresh; existing offers retain their original draw information. Max-stack filtering is performed by main/rules, full weapon slots retain the replacement selector, and unaffordable offers may remain visible with purchase disabled. Original generation-tagged intents remain unchanged.

A third read-only lookup, `assets/items/build_expansion_icon_manifest.json`, is merged in memory without replacing any original 24 icon entries. New mechanism fields use the existing detail card contract. Optional `echo_hits`, `phase_charge`, `medic_damage` snapshots appear in the build panel, not an overcrowded battle HUD.

Additional headless checks cover preference/source/partner text, explicit non-guarantee wording, no false percentage conversion, immediate changed snapshot display, retained historical offer multiplier, unchanged controller data and scroll-column boundaries. Original Boss HUD, codex, transaction and keyboard-focus tests remain in the same suite. Final validation must omit `--allow-pending-art`; GUI visual verification is still not available.

## v7: action readout and real presentation setting

HUD accepts `actor_state` (`idle/move/attack/hurt/dash/death`) and `dash_cooldown` (remaining simulation seconds) from main. A compact readout shares the HP/XP row rather than adding another HUD row. Death shows DASH LOCKED; absent actor data clears stale text. The UI never advances this timer or changes action state, so main's pause/restart snapshots are authoritative.

`show_settings(view)` reads `view.settings.reduced_flashes`. Title and pause buttons emit `settings {}`; Back emits `close_settings {}`; the focusable checkbox emits `set_setting {key:"reduced_flashes",value:bool}`. Initialization uses `set_pressed_no_signal`, so opening the screen cannot accidentally change preferences. Main owns applying the setting, storing it for the session, freezing simulation in settings and restoring title/paused return state.

This release exposes **only** the implemented reduced-flash option, not a placeholder screen-shake toggle. Its copy explicitly states that it reduces decorative brightness and hit-white flashes without changing warning telegraphs or collision timing, does not guarantee removal of every flash, and is not saved to disk. The screen also explains that some action presentation uses shared frames or procedural effects rather than independent hand-drawn sheets.

Headless UI tests cover settings entry from title/pause, initial keyboard focus, signal payload, no intent during initialization, no mutation of the supplied settings dictionary, session-value redisplay, close intent, 960×540 bounds, action/cooldown display, unchanged timer across UI-only frames, restart-ready state and death/missing-snapshot cleanup. All earlier shop, build, codex, Boss and icon tests remain active. Main integration must separately verify real rendering-setting application and simulation freeze/return. No graphical visual verification is implied.
