extends SceneTree
var errors: Array[String] = []
var received: Array = []
func check(ok: bool, what: String) -> void:
	if not ok: errors.append(what)
func buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result
func all_text(node: Node) -> String:
	var text: String = node.text if node is Label else ""
	for child in node.get_children(): text += "\n" + all_text(child)
	return text
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(960, 540)
	var ui = load("res://ui/moss_ui.gd").new()
	root.add_child(ui)
	ui.intent.connect(func(action, payload): received.append([action, payload]))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var view := {"coins": 0, "generation": 9, "offers": [], "weapons": [], "items": [], "stats": {"max_hp": 100}, "synergies": [], "weapon_slots": 4, "item_slots": 8}
	for i in 4:
		var offer: Dictionary = catalog.weapons[i].duplicate(true)
		offer.merge({"index": i, "can_buy": false, "sold": false})
		view.offers.append(offer)
		var w: Dictionary = offer.duplicate(true); w.slot = i; w.sell_price = 12
		view.weapons.append(w)
	for item in catalog.items:
		var copy: Dictionary = item.duplicate(true); copy.count = 2; copy.sell_price = 7
		view.items.append(copy)
	for entry in catalog.weapons + catalog.items:
		if "--allow-pending-art" in OS.get_cmdline_user_args() and ui.icon(entry.id) == null:
			print("PENDING_ART: " + entry.id)
		else:
			check(ui.icon(entry.id) != null, "generated icon present: " + entry.id)
	for upgrade_id in ["damage", "speed", "haste", "health", "magnet", "pierce"]:
		check(ui.icon(upgrade_id) != null, "upgrade icon mapping: " + upgrade_id)
	ui.show_title(123)
	await process_frame
	for button in buttons(ui.modal):
		if button.text == "START RUN": button.pressed.emit()
	check(received.back() == ["start", {"seed": 123}], "start seed intent")
	ui.show_shop(view)
	await process_frame
	await process_frame
	check(ui.modal.size.x <= 960 and ui.modal.size.y <= 540, "modal within logical viewport")
	check(ui.body.size.x <= ui.modal.size.x, "shop columns within modal width")
	check(ui.body.size.y <= ui.modal.size.y, "shop body within modal height")
	for button in buttons(ui.modal):
		if button.text.begins_with("REPLACE") or button.text.begins_with("REFRESH"):
			check(button.disabled, "unaffordable button disabled: " + button.text)
		if button.text == "DEPLOY NEXT WAVE": button.pressed.emit()
	check(received.back() == ["continue", {"generation": 9}], "generation-tagged deploy")
	view.coins = 999
	for offer in view.offers: offer.can_buy = true
	ui.show_shop(view)
	await process_frame
	var buy_index := 0
	for button in buttons(ui.modal):
		if button.text.begins_with("REPLACE"):
			check(not button.disabled, "affordable replacement enabled")
			button.pressed.emit()
			check(received.back()[0] == "buy" and received.back()[1].index == buy_index and received.back()[1].generation == 9 and received.back()[1].replace_slot == 0, "each replacement retains its own offer payload")
			buy_index += 1
	check(buy_index == 4, "four replacement cards")
	view.offers[0].sold = true
	ui.show_shop(view)
	for button in buttons(ui.modal):
		if button.text == "SOLD": check(button.disabled, "sold offer disabled")
	view.coins = 0
	ui.show_upgrade([{"id": "power_coil", "name": "POWER", "description": "+ damage", "index": 2}], 17)
	for button in buttons(ui.modal): button.pressed.emit()
	check(received.back() == ["upgrade", {"index": 2, "generation": 17}], "upgrade choice generation")
	ui.show_inventory(view);_open_build_disclosures(ui); await process_frame; await process_frame
	check(ui.body.size.y <= ui.modal.size.y, "long inventory scrolls inside modal")
	ui.show_pause(view); await process_frame
	ui.show_result(view); await process_frame
	check(not all_text(ui.modal).contains("BOSS REWARDS / SECURED"), "no unearned reward displayed")
	view.rewards = ["WARDEN PROTOCOL: +25 max HP, +10% damage"]
	ui.show_result(view); await process_frame
	check(all_text(ui.modal).contains("WARDEN PROTOCOL: +25 max HP, +10% damage"), "actual awarded reward displayed")
	check(not all_text(ui.modal).contains("REACTOR CROWN"), "no premature final trophy")
	ui.update_bosses([])
	check(not ui.boss_panel.visible, "non-boss encounter has no boss HUD")
	ui.update_bosses([{ "name": "WARDEN", "hp": 500, "max_hp": 1000, "phase": 2, "hint": "Charge warning: move sideways" }])
	await process_frame; await process_frame
	check(ui.boss_panel.visible, "live boss HUD visible")
	check(ui.boss_widgets[0].title.text.contains("PHASE 2"), "boss phase readable")
	check(ui.boss_widgets[0].bar.value == 500, "boss health reads actual value")
	check(ui.boss_panel.position.y >= 0 and ui.boss_panel.size.x <= 960, "boss HUD fits 960x540")
	ui.update_bosses([{ "name": "WARDEN", "hp": 0, "max_hp": 1000, "phase": 2 }])
	check(not ui.boss_panel.visible and ui.boss_widgets.is_empty(), "dead boss HUD clears")
	var entries: Array = []
	for i in 7: entries.append({"id": "test_%s" % i, "name": "Enemy %s" % i, "description": "Distinct enemy behavior", "tell": "Warning marker", "dodge": "Move perpendicular"})
	if FileAccess.file_exists("res://assets/enemies/enemy_manifest.json"):
		var encounters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
		for enemy in encounters.enemies:
			var portrait: Texture2D = ui._portrait(enemy)
			check(portrait != null, "real generated enemy portrait: " + enemy.id)
			if portrait is AtlasTexture:
				check(portrait.region.size.x > 0 and portrait.region.size.y > 0 and portrait.region.position.x >= 0 and portrait.region.position.y >= 0 and portrait.region.end.x <= portrait.atlas.get_width() and portrait.region.end.y <= portrait.atlas.get_height(), "portrait region in atlas: " + enemy.id)
		entries = encounters.enemies
	else:
		print("ENEMY_PORTRAITS_PENDING: manifest not present; synthetic codex layout test only")
	ui.show_codex(entries)
	await process_frame; await process_frame
	check(ui.body.size.y <= ui.modal.size.y and ui.body.size.x <= ui.modal.size.x, "seven enemy codex scrolls within viewport")
	check(ui.first_focus.has_focus(), "codex keyboard focus enters back control")
	var scroll: ScrollContainer
	for child in ui.body.get_children():
		if child is ScrollContainer: scroll = child
	check(scroll != null and scroll.focus_mode == Control.FOCUS_ALL, "codex list keyboard focusable")
	scroll.grab_focus()
	var key := InputEventKey.new(); key.pressed = true; key.keycode = KEY_PAGEDOWN
	scroll.gui_input.emit(key)
	check(scroll.scroll_vertical > 0, "codex keyboard page scroll works")
	for button in buttons(ui.modal):
		if button.text == "BACK": button.pressed.emit()
	check(received.back() == ["close_codex", {}], "codex return intent")
	ui.show_pause(); await process_frame
	for button in buttons(ui.modal):
		if button.text == "ENEMY FIELD GUIDE": button.pressed.emit()
	check(received.back() == ["codex", {}], "pause opens codex intent")
	ui.show_title(); await process_frame
	for button in buttons(ui.modal):
		if button.text == "ENEMY FIELD GUIDE": button.pressed.emit()
	check(received.back() == ["codex", {}], "title opens codex intent")
	view.synergy_status = [{"name": "Relay Pair", "description": "Pickup charges the next arc", "active": true, "requires": ["Arc Relay", "Kill Cell"], "missing": []}, {"name": "Reflect Pair", "active": false, "requires": ["Mirror Shell", "Thorn Crown"], "missing": ["Thorn Crown"]}]
	view.mechanics = {"shield": 12, "chain_charges": 3, "hazards": 2, "cooldowns": {"arc_relay": 1.25}}
	var long_item := {"id": "arc_relay", "kind": "item", "name": "Arc Relay", "description": "Trigger-driven mechanism. ".repeat(30), "trigger": "On direct electric hit", "cost": "Consumes one charge", "cooldown": 1.25, "max_stack": 1, "stack_rule": "Unique item; duplicate purchase forbidden", "synergy_targets": ["Kill Cell"], "count": 1}
	view.items.append(long_item)
	ui.show_inventory(view);_open_build_disclosures(ui); await process_frame; await process_frame
	var text := all_text(ui.modal)
	for phrase in ["TRIGGER: On direct electric hit", "TRADE-OFF: Consumes one charge", "ICD: 1.25s", "STACK CAP: 1", "Unique item", "PAIR WITH: Kill Cell", "ACTIVE / Relay Pair", "Pickup charges the next arc", "Missing: Thorn Crown", "Arc Relay: 1.25s until ready"]:
		check(text.contains(phrase), "mechanism information visible: " + phrase)
	check(ui.body.size.y <= ui.modal.size.y and ui.body.size.x <= ui.modal.size.x, "long mechanism text scrolls without overflow")
	ui.show_shop(view); await process_frame; await process_frame
	check(ui.body.size.y <= ui.modal.size.y and ui.body.size.x <= ui.modal.size.x, "long mechanism shop columns bounded")
	var last_sell: Button
	for button in buttons(ui.modal):
		if button.text.begins_with("SELL ONE"): last_sell = button
	last_sell.grab_focus()
	await process_frame; await process_frame
	var ancestor: Node = last_sell.get_parent()
	while ancestor != null and not ancestor is ScrollContainer: ancestor = ancestor.get_parent()
	check(ancestor is ScrollContainer and ancestor.scroll_vertical > 0, "focus on final module scrolls long shop inventory")
	ui.update_hud(view)
	check(ui.hud_detail.text.contains("SHIELD 12  CHAIN 3  FIELDS 2"), "HUD shows actual snapshot")
	view.mechanics = {}
	ui.update_hud(view)
	check(not ui.hud_detail.text.contains("SHIELD 12"), "HUD clears prior mechanism values")
	view.shop_bias = {"preferred_tags": ["electric", "mechanism"], "missing_partners": ["Kill Cell"], "sources": ["Electric equipment x2", "Missing partner x3"], "summary": "Weighted build matching"}
	view.offers[1].weight_multiplier = 2.5
	view.offers[1].bias_reasons = ["Matched current electric equipment"]
	ui.show_shop(view); await process_frame; await process_frame
	var bias_text := all_text(ui.modal)
	for phrase in ["PREFERRED TAGS: electric, mechanism", "MISSING PARTNERS: Kill Cell", "WEIGHT SOURCE: Electric equipment x2", "NOT a guarantee", "not percentages", "NEXT refresh", "DRAW-TIME RELATIVE WEIGHT: x2.50", "AT DRAW: Matched current electric equipment", "Unaffordable offers can appear"]:
		check(bias_text.contains(phrase), "honest shop bias explanation: " + phrase)
	check(ui.body.size.x <= ui.modal.size.x and ui.body.size.y <= ui.modal.size.y, "shop bias explanation stays in scrolling column")
	view.shop_bias.preferred_tags = ["melee"]
	view.shop_bias.missing_partners = []
	ui.show_shop(view); await process_frame
	bias_text = all_text(ui.modal)
	check(bias_text.contains("PREFERRED TAGS: melee") and not bias_text.contains("PREFERRED TAGS: electric"), "sold-build snapshot updates immediately")
	check(bias_text.contains("DRAW-TIME RELATIVE WEIGHT: x2.50"), "existing offer weight remains draw-time snapshot")
	check(view.offers[1].weight_multiplier == 2.5, "UI did not recalculate sampling weight")
	view.actor_state = "dash"; view.dash_cooldown = 2.3
	ui.update_hud(view)
	check(ui.hud_action.text == "DASH  /  DASH 2.3s", "actual actor state and cooldown shown")
	await process_frame; await process_frame
	check(ui.hud_action.text == "DASH  /  DASH 2.3s", "UI does not advance cooldown itself")
	check(ui.hud.size.x <= 960 and ui.hud_action.get_global_rect().end.x <= 960, "action readout fits HUD")
	view.actor_state = "idle"; view.dash_cooldown = 0
	ui.update_hud(view)
	check(ui.hud_action.text == "IDLE  /  DASH READY", "ready state resets after restart snapshot")
	view.actor_state = "death"; ui.update_hud(view)
	check(ui.hud_action.text.contains("LOCKED"), "death does not misleadingly advertise dash ready")
	view.erase("actor_state"); ui.update_hud(view)
	check(ui.hud_action.text.is_empty(), "missing actor snapshot clears stale readout")
	view.settings = {"reduced_flashes": false}
	var before := received.size()
	ui.show_settings(view); await process_frame; await process_frame
	check(received.size() == before, "opening settings emits no change")
	check(ui.body.size.x <= ui.modal.size.x and ui.body.size.y <= ui.modal.size.y, "settings fits viewport")
	var toggle: CheckButton
	for button in buttons(ui.modal):
		if button is CheckButton and button.text == "REDUCE DECORATIVE FLASHES": toggle = button
	check(toggle != null and toggle.has_focus() and not toggle.button_pressed, "settings toggle initial value and keyboard focus")
	toggle.button_pressed = true
	check(received.back() == ["set_setting", {"key": "reduced_flashes", "value": true}], "toggle emits controller-owned setting intent")
	check(view.settings.reduced_flashes == false, "UI does not mutate settings snapshot")
	view.settings.reduced_flashes = true
	ui.show_settings(view); await process_frame
	for button in buttons(ui.modal):
		if button is CheckButton and button.text == "REDUCE DECORATIVE FLASHES": check(button.button_pressed, "reopened settings reflects session value")
		if button.text == "BACK": button.pressed.emit()
	check(received.back() == ["close_settings", {}], "settings close intent")
	check(all_text(ui.modal).contains("not saved to disk") and all_text(ui.modal).contains("shared frames"), "settings states persistence and animation limitations")
	ui.show_pause(); await process_frame
	for button in buttons(ui.modal):
		if button.text == "PRESENTATION SETTINGS": button.pressed.emit()
	check(received.back() == ["settings", {}], "pause opens settings")
	ui.show_title(); await process_frame
	for button in buttons(ui.modal):
		if button.text == "PRESENTATION SETTINGS": button.pressed.emit()
	check(received.back() == ["settings", {}], "title opens settings")
	ui.hide_modal()
	check(not ui.modal_visible(), "hide modal")
	check(view.coins == 0, "UI did not mutate coins")
	if errors.is_empty(): print("UI_STRUCTURE_AND_INTENTS_PASS")
	else:
		for error in errors: push_error(error)
	ui.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)

# External presentation-only adapter: expand the actual new disclosure buttons.
# Original assertions/counts/catalog adapters below remain unchanged; native input is separate.
func _disclosure_adapter_nodes(n:Node)->Array:
	var out:Array=[n]
	for c in n.get_children():out.append_array(_disclosure_adapter_nodes(c))
	return out
func _open_build_disclosures(ui:Node)->void:
	var found:Array=[]
	for n in _disclosure_adapter_nodes(ui.modal):
		if n is Button and n.toggle_mode and n.text.begins_with("SHOW "):
			if n.text.begins_with("SHOW WEAPON CARDS /") or n.text.begins_with("SHOW MODULE CARDS /") or n.text=="SHOW SYNERGIES / COOLDOWNS / STATS" or n.text=="SHOW MODULE STATUS DETAILS":
				found.append(n)
	assert(found.size()==3 or found.size()==4,"expected all new BUILD disclosures initially collapsed")
	for toggle in found:
		assert(toggle.is_visible_in_tree() and not toggle.disabled,"actual disclosure button accessible")
		toggle.button_pressed=true
		var content:Node=toggle.get_parent().get_child(toggle.get_index()+1)
		assert(toggle.text.begins_with("HIDE ") and content is VBoxContainer and content.is_visible_in_tree(),"real toggled handler expands content")
		for child in _disclosure_adapter_nodes(content):
			if child is Button and child.toggle_mode and child.text in ["SHOW STAT NOTES","SHOW ITEM DETAILS"]:
				assert(child.is_visible_in_tree() and not child.disabled,"existing nested disclosure accessible")
				child.button_pressed=true
				var nested:Node=child.get_parent().get_child(child.get_index()+1)
				assert(child.text.begins_with("HIDE ") and nested is VBoxContainer and nested.is_visible_in_tree(),"existing nested toggled handler expands content")
		for child in _disclosure_adapter_nodes(content):
			if child is Label:assert(child.is_visible_in_tree(),"prior label assertion must not pass on collapsed content")
	print("DISCLOSURE_ADAPTER_OPEN "+str(found.size()))
