extends SceneTree
var checks := 0
var failures: Array = []
var received: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func nodes(node: Node) -> Array:
	var result: Array = [node]
	for child in node.get_children(): result.append_array(nodes(child))
	return result
func texts(node: Node) -> Array:
	var result: Array = []
	for child in nodes(node):
		if child is Label or child is Button or child is RichTextLabel: result.append(child.text)
	return result
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(960, 540)
	var ui = load("res://ui/moss_ui.gd").new()
	root.add_child(ui)
	ui.intent.connect(func(action, payload): received.append([action, payload]))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var offer: Dictionary = catalog.weapons[0].duplicate(true)
	offer.merge({"index": 0, "price": 46.0, "can_buy": true, "sold": false}, true)
	var module: Dictionary = catalog.items[0].duplicate(true)
	module.merge({"count": 2.0, "max_stack": 3.0, "sell_price": 7.0}, true)
	var view: Dictionary = {"coins": 100.0, "generation": 9, "offers": [offer], "weapons": [], "items": [module], "weapon_slots": 4.0, "item_slots": 8.0, "refresh_price": 5.0, "stats": {"attack_speed": 1.25}, "mechanics": {"cooldowns": {"phase_coil": 1.5}}}
	for full in [false, true]:
		view.weapons.clear()
		for i in range(4 if full else 1):
			var weapon: Dictionary = catalog.weapons[i].duplicate(true)
			weapon.merge({"slot": i, "sell_price": 23.0}, true)
			view.weapons.append(weapon)
		var before: String = JSON.stringify(view)
		ui.show_shop(view)
		await process_frame; await process_frame
		var labels: Array = texts(ui.modal)
		var action_text: String = "REPLACE  /  46 SCRAP" if full else "BUY  /  46 SCRAP"
		for expected in ["SALVAGE EXCHANGE  /  100 SCRAP", "WEAPONS  %d / 4" % view.weapons.size(), "MODULES  1 / 8", action_text, "SELL  +23", "SELL ONE  +7", "REFRESH  /  5 SCRAP", str(module.name) + "  x2 / 3"]:
			check(expected in labels, "whole-number label: " + expected)
		var cap_labels: Array = labels.filter(func(value): return str(value).contains("STACK CAP:"))
		check(not cap_labels.is_empty() and cap_labels.all(func(value): return str(value).contains("STACK CAP: 3\n") and not str(value).contains("STACK CAP: 3.0")), "integer module stack cap details")
		check("Attack Speed: 1.25" in labels, "fractional derived stat preserved")
		check("Phase Coil: 1.50s until ready" in labels, "fractional cooldown preserved")
		var buy: Button
		for child in nodes(ui.modal):
			if child is Button and child.text.begins_with("REPLACE" if full else "BUY"): buy = child; break
		check(buy != null and not buy.disabled, "affordability unchanged")
		if buy:
			buy.pressed.emit()
			check(received.back() == ["buy", {"index": 0, "generation": 9, "replace_slot": 0 if full else -1}], "transaction payload unchanged")
		check(JSON.stringify(view) == before, "formatting does not mutate numeric input")
		view.coins = 0.0
		view.offers[0].can_buy = false
		ui.show_shop(view)
		await process_frame
		for child in nodes(ui.modal):
			if child is Button and (child.text.begins_with("REPLACE") or child.text.begins_with("BUY") or child.text.begins_with("REFRESH")):
				check(child.disabled, "unaffordable action still disabled")
		view.coins = 100.0
		view.offers[0].can_buy = true
	view.items[0].erase("max_stack")
	ui.show_inventory(view);_open_build_disclosures(ui)
	await process_frame
	var inventory_labels: Array = texts(ui.modal)
	check(str(module.name) + "  x2 / ?" in inventory_labels, "unknown stack cap remains question mark")
	check("WEAPONS  4 / 4" in inventory_labels and "MODULES  1 / 8" in inventory_labels, "inventory uses same whole-number counters")
	ui.queue_free(); await process_frame
	print(JSON.stringify({"discrete_ui_checks": checks, "failures": failures, "scope": "presentation-only integer-valued JSON floats; fractional stats/cooldowns and transaction intents preserved"}))
	quit(0 if failures.is_empty() else 1)

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
