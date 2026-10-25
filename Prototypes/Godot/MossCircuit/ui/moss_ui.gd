extends CanvasLayer
## Presentation only. All run state and transactions belong to the main controller.
signal intent(action: String, payload: Dictionary)

const INK = Color("101e24")
const PANEL = Color("172c30")
const MOSS = Color("88b98a")
const AMBER = Color("efd18b")
var root: Control
var hud: PanelContainer
var hud_title: Label
var hud_detail: Label
var hud_action: Label
var hp: ProgressBar
var xp: ProgressBar
var shade: ColorRect
var modal: PanelContainer
var body: VBoxContainer
var first_focus: Control
var manifest: Dictionary = {}
var icon_cache: Dictionary = {}
var current_screen := ""
var boss_panel: PanelContainer
var boss_rows: VBoxContainer
var boss_widgets: Array[Dictionary] = []
var enemy_manifest: Dictionary = {}
var enemy_icon_cache: Dictionary = {}

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.theme = _theme()
	add_child(root)
	hud = PanelContainer.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 16; hud.offset_top = 12; hud.offset_right = -16; hud.offset_bottom = 90
	root.add_child(hud)
	var hv := VBoxContainer.new(); hud.add_child(hv)
	var line := HBoxContainer.new(); hv.add_child(line)
	hud_title = _label(line, "MOSS CIRCUIT", 18)
	hud_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(line, "BUILD [I]", "inventory")
	_button(line, "PAUSE [ESC]", "pause")
	var bars := HBoxContainer.new(); hv.add_child(bars)
	_label(bars, "HP", 14); hp = _bar(bars, Color("88b98a"))
	_label(bars, "XP", 14); xp = _bar(bars, AMBER)
	hud_action = _label(bars, "", 12)
	hud_action.add_theme_color_override("font_color", AMBER)
	hud_detail = _label(hv, "", 13)
	boss_panel = PanelContainer.new()
	boss_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	boss_panel.offset_left = 16; boss_panel.offset_right = -16
	boss_panel.offset_top = -104; boss_panel.offset_bottom = -12
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(boss_panel)
	boss_rows = VBoxContainer.new(); boss_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_child(boss_rows); boss_panel.hide()
	shade = ColorRect.new(); shade.color = Color(0.025, 0.05, 0.06, 0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.offset_left = 24; modal.offset_right = -24; modal.offset_top = 22; modal.offset_bottom = -22
	shade.add_child(modal)
	if FileAccess.file_exists("res://assets/items/icon_manifest.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/icon_manifest.json"))
		if parsed is Dictionary: manifest = parsed
	for extra_path in ["res://assets/items/mechanism_icon_manifest.json", "res://assets/items/build_expansion_icon_manifest.json"]:
		if FileAccess.file_exists(extra_path):
			var extra = JSON.parse_string(FileAccess.get_file_as_string(extra_path))
			if extra is Dictionary:
				if not manifest.has("icons"): manifest.icons = {}
				for id in extra.get("icons", {}):
					if not manifest.icons.has(id):
						var entry: Dictionary = extra.icons[id].duplicate(true)
						entry.atlas = entry.get("atlas", extra.get("atlas", ""))
						manifest.icons[id] = entry
	shade.hide()

func _box(fill: Color, border: Color, padding := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = fill; s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = padding; s.content_margin_right = padding
	s.content_margin_top = padding; s.content_margin_bottom = padding
	return s

func _theme() -> Theme:
	var t := Theme.new(); t.default_font_size = 15
	t.set_color("font_color", "Label", Color("e0eadb"))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, Color("426c5c")))
	t.set_stylebox("panel", "TooltipPanel", _box(INK, AMBER))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var border: Color = AMBER if state in ["hover", "focus"] else MOSS
		var fill: Color = Color("304b40") if state == "pressed" else INK
		if state == "disabled": border = Color("42534c")
		t.set_stylebox(state, "Button", _box(fill, border, 7))
	t.set_color("font_color", "Button", AMBER)
	t.set_color("font_disabled_color", "Button", Color("88928a"))
	t.set_stylebox("normal", "LineEdit", _box(INK, MOSS, 7))
	t.set_stylebox("focus", "LineEdit", _box(INK, AMBER, 7))
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 10)
	return t

func _label(parent: Node, text: String, font_size := 15) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l); return l

func _text(parent: Node, text: String, font_size := 14) -> Label:
	var l := _label(parent, text, font_size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _disclosure(parent:Node,title:String)->VBoxContainer:
	# Read-only local presentation state: expanding information never emits an intent.
	var toggle:=Button.new();toggle.text="SHOW "+title;toggle.toggle_mode=true
	toggle.custom_minimum_size.y=30;parent.add_child(toggle)
	var details:=VBoxContainer.new();details.visible=false;parent.add_child(details)
	toggle.toggled.connect(func(expanded:bool):
		details.visible=expanded
		toggle.text=("HIDE " if expanded else "SHOW ")+title)
	return details

func _button(parent: Node, text: String, action: String, payload: Dictionary = {}, disabled := false) -> Button:
	var b := Button.new(); b.text = text; b.disabled = disabled
	b.custom_minimum_size.y = 34
	b.pressed.connect(func(): intent.emit(action, payload.duplicate(true)))
	parent.add_child(b)
	if first_focus == null and not disabled: first_focus = b
	return b

func _bar(parent: Node, color: Color) -> ProgressBar:
	var b := ProgressBar.new(); b.custom_minimum_size = Vector2(130, 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.show_percentage = false
	b.add_theme_stylebox_override("background", _box(INK, INK, 0))
	b.add_theme_stylebox_override("fill", _box(color, color, 0))
	parent.add_child(b); return b

func _begin(screen: String, title: String, subtitle := "") -> void:
	current_screen = screen
	for child in modal.get_children():
		modal.remove_child(child); child.queue_free()
	first_focus = null
	body = VBoxContainer.new(); modal.add_child(body)
	_label(body, title, 26).add_theme_color_override("font_color", AMBER)
	if not subtitle.is_empty(): _text(body, subtitle, 14)
	shade.show()

func _finish() -> void:
	call_deferred("_focus_current")

func _focus_current() -> void:
	if is_instance_valid(first_focus) and first_focus.is_inside_tree() and first_focus.is_visible_in_tree():
		first_focus.grab_focus()

func _scroll(parent: Node) -> VBoxContainer:
	var s := ScrollContainer.new(); s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.follow_focus = true
	s.focus_mode = Control.FOCUS_ALL
	s.tooltip_text = "Tab to this panel, then use Up/Down or Page Up/Page Down to scroll."
	s.gui_input.connect(func(event: InputEvent):
		if event is InputEventKey and event.pressed:
			var step := 0
			match event.keycode:
				KEY_DOWN: step = 36
				KEY_UP: step = -36
				KEY_PAGEDOWN: step = int(s.size.y) - 36
				KEY_PAGEUP: step = -int(s.size.y) + 36
			if step != 0:
				s.scroll_vertical += step
				s.accept_event())
	parent.add_child(s)
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(v); return v

func icon(id: String) -> Texture2D:
	if icon_cache.has(id): return icon_cache[id]
	var upgrade_icons := {"damage": "power_coil", "speed": "running_boots", "haste": "cooling_fan", "health": "iron_plate", "magnet": "salvage_magnet", "pierce": "capacitor"}
	id = upgrade_icons.get(id, id)
	var entries: Dictionary = manifest.get("icons", {})
	if not entries.has(id): return null
	var entry = entries[id]
	var rect: Array = entry.get("rect", []) if entry is Dictionary else entry
	var path: String = manifest.get("atlas", "")
	if entry is Dictionary: path = entry.get("atlas", path)
	if rect.size() != 4 or not ResourceLoader.exists(path): return null
	var tex := AtlasTexture.new(); tex.atlas = load(path)
	tex.region = Rect2(rect[0], rect[1], rect[2], rect[3]); tex.filter_clip = true
	icon_cache[id] = tex; return tex

func _card(parent: Node, data: Dictionary, suffix := "", statuses: Array = [], compact:=false) -> VBoxContainer:
	var p := PanelContainer.new(); parent.add_child(p)
	var row := HBoxContainer.new(); p.add_child(row)
	var image := TextureRect.new(); image.texture = icon(str(data.get("id", "")))
	image.custom_minimum_size = Vector2(48, 48)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.tooltip_text = str(data.get("description", "")); row.add_child(image)
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(v)
	_text(v, str(data.get("name", data.get("id", ""))) + suffix, 16).add_theme_color_override("font_color", AMBER)
	_text(v, str(data.get("description", "")), 13)
	if data.get("kind", "") == "item":
		var facts:VBoxContainer=_disclosure(v,"ITEM DETAILS") if compact else v
		var details := "TRIGGER: %s\nTRADE-OFF: %s\nICD: %.2fs  /  STACK CAP: %s\nSTACKING: %s" % [data.get("trigger", "Passive while equipped"), data.get("cost", "No additional combat cost"), float(data.get("cooldown", 0)), str(int(data.max_stack)) if data.has("max_stack") else "?", data.get("stack_rule", "Each owned copy adds the listed effect, up to the cap.")]
		_text(facts, details, 12)
		var targets: Array = data.get("synergy_targets", [])
		if not targets.is_empty():
			_text(facts, "PAIR WITH: " + ", ".join(targets.map(func(target): return str(target).replace("_", " ").capitalize())), 12)
		for status in statuses:
			if str(data.get("name", "")) in status.get("requires", []):
				_synergy_line(facts, status)
		image.tooltip_text = str(data.get("description", "")) + "\n" + details
	return v

func update_hud(view: Dictionary) -> void:
	var actor_state: String = str(view.get("actor_state", ""))
	var dash_remaining: float = maxf(0, float(view.get("dash_cooldown", 0)))
	if actor_state.is_empty():
		hud_action.text = ""
	else:
		var dash_status: String = "LOCKED" if actor_state == "death" else ("READY" if dash_remaining <= 0 else "%.1fs" % dash_remaining)
		hud_action.text = "%s  /  DASH %s" % [actor_state.to_upper(), dash_status]
		hud_action.tooltip_text = "Controller action state; dash cooldown in simulation seconds. Paused menus do not advance it."
	hud_title.text = "MOSS CIRCUIT   /   WAVE %s   /   LV %s   /   SCRAP %s" % [view.get("wave", 1), view.get("level", 1), view.get("coins", 0)]
	if view.get("mode_id","")=="rooms":hud_title.text="ROOM %s / %s   ·   LV %s   ·   SCRAP %s"%[view.get("wave",1),view.get("stage_count",3),view.get("level",1),view.get("coins",0)]
	hp.max_value = maxf(1, float(view.get("max_hp", 100))); hp.value = float(view.get("hp", 0))
	xp.max_value = maxf(1, float(view.get("xp_max", 1))); xp.value = float(view.get("xp", 0))
	hud_detail.text = "HP %.0f / %.0f   |   XP %.0f / %.0f   |   %.0fs   |   KILLS %s   |   WASD / arrows: move   SPACE: dash" % [hp.value, hp.max_value, xp.value, xp.max_value, float(view.get("time", 0)), view.get("kills", 0)]
	hud_title.tooltip_text=str(view.get("mode_name",""))+" · "+str(view.get("objective",""))
	hud_detail.tooltip_text = ""
	var mechanics: Dictionary = view.get("mechanics", {})
	if not mechanics.is_empty():
		hud_detail.text = "HP %.0f/%.0f  |  XP %.0f/%.0f  |  %.0fs  |  KILLS %s  |  SHIELD %s  CHAIN %s  FIELDS %s" % [hp.value, hp.max_value, xp.value, xp.max_value, float(view.get("time", 0)), view.get("kills", 0), mechanics.get("shield", 0), mechanics.get("chain_charges", 0), mechanics.get("hazards", 0)]
		hud_detail.tooltip_text = "WASD / arrows: move; Space: dash. Open BUILD for exact per-item cooldowns."

func show_title(seed_value: int = 240102,mode_id:String="arena") -> void:
	_begin("title", "MOSS CIRCUIT", "SURVIVE / SALVAGE / REBUILD")
	var content := _scroll(body)
	_text(content,"A small machine. Six hostile waves. Build your own salvage engine." if mode_id=="arena" else "Three finite room encounters. Clear every enemy, then rebuild. This is not a complete dungeon.",20)
	_text(content, "Move: WASD / arrow keys   |   Dash: Space   |   Auto-fire: nearest target\nPause: Esc   |   Build: I   |   Menus: Tab / Shift+Tab, Enter or Space\nBuy weapons and modules between encounters. Matching tags unlock synergies.")
	_label(content,"MODE: "+("ARENA SURVIVAL" if mode_id=="arena" else "3 ROOM ENCOUNTERS / PROTOTYPE"),14)
	var mode_button:=Button.new();mode_button.text="SWITCH TO "+("ROOM ENCOUNTERS" if mode_id=="arena" else "ARENA SURVIVAL")
	mode_button.custom_minimum_size.y=38;content.add_child(mode_button)
	_label(content, "RUN SEED", 14)
	var seed_edit := LineEdit.new(); seed_edit.text = str(seed_value); seed_edit.max_length = 10
	seed_edit.custom_minimum_size.y = 38; content.add_child(seed_edit)
	seed_edit.text_changed.connect(func(value:String):intent.emit("seed_changed",{"seed":value.to_int()}))
	mode_button.pressed.connect(func():intent.emit("select_mode",{"id":"rooms" if mode_id=="arena" else "arena","seed":seed_edit.text.to_int()}))
	var start := Button.new(); start.text = "START RUN"; start.custom_minimum_size.y = 44
	start.pressed.connect(func(): intent.emit("start", {"seed": seed_edit.text.to_int()}))
	body.add_child(start); first_focus = start
	_button(body, "ENEMY FIELD GUIDE", "codex")
	_button(body, "DISPLAY SETTINGS", "settings")
	_finish()

func show_shop(view: Dictionary) -> void:
	var generation: int = int(view.get("generation", 0))
	_begin("shop", "SALVAGE EXCHANGE  /  %d SCRAP" % int(view.get("coins", 0)), str(view.get("message", "Buy, combine tags, then deploy. Selling returns only the shown scrap.")))
	var columns := HBoxContainer.new(); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_child(columns)
	var offers := _scroll(columns); offers.custom_minimum_size.x = 420
	var bag := _scroll(columns)
	_shop_bias(offers, view.get("shop_bias", {}))
	for offer in view.get("offers", []):
		var c := _card(offers, offer, "", view.get("synergy_status", []),true)
		_text(c, "%s / %s" % [str(offer.get("rarity", "common")).to_upper(), ", ".join(offer.get("tags", []))], 12)
		if offer.has("weight_multiplier"):
			var weight_details:=_disclosure(c,"DRAW-TIME WEIGHT")
			_text(weight_details, "DRAW-TIME RELATIVE WEIGHT: x%.2f (not a chance)" % float(offer.weight_multiplier), 12)
			var reasons: Array = offer.get("bias_reasons", [])
			if not reasons.is_empty(): _text(weight_details, "AT DRAW: " + "; ".join(reasons), 12)
		var sold: bool = bool(offer.get("sold", false))
		var can_buy: bool = bool(offer.get("can_buy", false))
		var payload := {"index": int(offer.get("index", 0)), "generation": generation, "replace_slot": -1}
		var full: bool = offer.get("kind", "") == "weapon" and view.get("weapons", []).size() >= int(view.get("weapon_slots", 4))
		if full and not sold:
			var replacement_notice:=_text(c, "Slots full: replace destroys the old weapon (no refund).", 12)
			var select := OptionButton.new(); select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for w in view.get("weapons", []): select.add_item("Replace %s" % w.get("name", w.get("id", "")), int(w.get("slot", 0)))
			c.add_child(select)
			var buy := Button.new(); buy.text = "REPLACE  /  %d SCRAP" % int(offer.get("price", 0))
			buy.custom_minimum_size.y = 34
			buy.disabled = not can_buy or int(view.get("coins", 0)) < int(offer.get("price", 0))
			buy.pressed.connect(func():
				var p: Dictionary = payload.duplicate(); p.replace_slot = select.get_selected_id(); intent.emit("buy", p))
			c.add_child(buy)
			c.move_child(replacement_notice,1);c.move_child(select,2);c.move_child(buy,3)
			if first_focus == null and not buy.disabled: first_focus = select
		else:
			var purchase:=_button(c, "SOLD" if sold else "BUY  /  %d SCRAP" % int(offer.get("price", 0)), "buy", payload, sold or not can_buy)
			c.move_child(purchase,1)
	_inventory(bag, view, true)
	var footer := HBoxContainer.new(); body.add_child(footer)
	_button(footer, "REFRESH  /  %d SCRAP" % int(view.get("refresh_price", 5)), "refresh", {"generation": generation}, int(view.get("coins", 0)) < int(view.get("refresh_price", 5)))
	_button(footer, "DEPLOY NEXT ROOM" if view.get("mode_id","")=="rooms" else "DEPLOY NEXT WAVE", "continue", {"generation": generation})
	_finish()

func _shop_bias(parent: Node, bias: Dictionary) -> void:
	if bias.is_empty(): return
	var panel := PanelContainer.new(); parent.add_child(panel)
	var content := VBoxContainer.new(); panel.add_child(content)
	_text(content, "NEXT REFRESH / BUILD PREFERENCE", 15).add_theme_color_override("font_color", AMBER)
	var tags: Array = bias.get("preferred_tags", [])
	var partners: Array = bias.get("missing_partners", [])
	_text(content, "PREFERRED TAGS: " + (", ".join(tags) if not tags.is_empty() else "None"), 12)
	var details:=_disclosure(content,"DRAW DETAILS")
	_text(details, "MISSING PARTNERS: " + (", ".join(partners) if not partners.is_empty() else "None"), 12)
	if not str(bias.get("summary", "")).is_empty(): _text(details, str(bias.summary), 12)
	for source in bias.get("sources", []): _text(details, "WEIGHT SOURCE: " + str(source), 12)
	_text(details, "Higher weight improves likelihood, NOT a guarantee. Draws are without replacement; slot chances change. These are relative weights, not percentages.", 12)
	_text(details, "Buying/selling updates the preference above immediately, for the NEXT refresh. Existing offers retain their draw-time weight and do not reroll. Next draws exclude max-stack items. Full weapon slots allow replacement. Unaffordable offers can appear; their purchase is disabled.", 12)

func _inventory(parent: Node, view: Dictionary, selling := false) -> void:
	_label(parent, "WEAPONS  %d / %d" % [view.get("weapons", []).size(), int(view.get("weapon_slots", 4))], 16)
	for w in view.get("weapons", []):
		var c := _card(parent, w, "  [SLOT %s]" % (int(w.get("slot", 0)) + 1))
		if selling: _button(c, "SELL  +%d" % int(w.get("sell_price", 0)), "sell_weapon", {"slot": w.get("slot", 0), "generation": view.get("generation", 0)}, view.get("weapons", []).size() <= 1)
	_label(parent, "MODULES  %d / %d" % [view.get("items", []).size(), int(view.get("item_slots", 8))], 16)
	if view.get("items", []).is_empty(): _text(parent, "No modules yet. Buy one to begin your build.")
	for item in view.get("items", []):
		var c := _card(parent, item, "  x%d / %s" % [int(item.get("count", 1)), str(int(item.max_stack)) if item.has("max_stack") else "?"], view.get("synergy_status", []))
		if selling: _button(c, "SELL ONE  +%d" % int(item.get("sell_price", 0)), "sell_item", {"id": item.get("id", ""), "generation": view.get("generation", 0)})
	var rewards: Array = view.get("rewards", [])
	if not rewards.is_empty():
		_label(parent, "BOSS REWARDS / SECURED", 16).add_theme_color_override("font_color", AMBER)
		for reward in rewards: _text(parent, str(reward), 13)
	var pairs: Array = view.get("synergy_status", [])
	if not pairs.is_empty():
		_label(parent, "MECHANISM PAIRS", 16)
		for pair in pairs: _synergy_line(parent, pair)
	var mechanics: Dictionary = view.get("mechanics", {})
	if not mechanics.is_empty():
		_label(parent, "LIVE MECHANISM SNAPSHOT", 16)
		_text(parent, "Shield: %s  /  Chain charges: %s  /  Friendly fields: %s" % [mechanics.get("shield", 0), mechanics.get("chain_charges", 0), mechanics.get("hazards", 0)], 13)
		for key in ["echo_hits", "phase_charge", "medic_damage"]:
			if mechanics.has(key): _text(parent, "%s: %s" % [str(key).replace("_", " ").capitalize(), mechanics[key]], 13)
		for id in mechanics.get("cooldowns", {}):
			_text(parent, "%s: %.2fs until ready" % [str(id).replace("_", " ").capitalize(), maxf(0, float(mechanics.cooldowns[id]))], 12)
	_label(parent, "ACTIVE TAG SYNERGIES", 16)
	var synergies: Array = view.get("synergies", [])
	_text(parent, "None yet. Match electric / melee / spread tags." if synergies.is_empty() else "\n".join(synergies), 13)
	_label(parent, "DERIVED STATS", 16)
	for key in view.get("stats", {}): _text(parent, "%s: %s" % [str(key).replace("_", " ").capitalize(), str(view.stats[key])], 13)

func _synergy_line(parent: Node, status: Dictionary) -> void:
	var active: bool = bool(status.get("active", false))
	var missing: Array = status.get("missing", [])
	var line := "%s / %s" % ["ACTIVE" if active else "INACTIVE", status.get("name", "PAIR")]
	if active: line += " / Requirements met"
	elif not missing.is_empty(): line += " / Missing: " + ", ".join(missing)
	else: line += " / Requirements not met"
	var label := _text(parent, line, 12)
	label.add_theme_color_override("font_color", MOSS if active else AMBER)
	_text(parent, "REQUIRES: " + ", ".join(status.get("requires", [])), 12)
	if not str(status.get("description", "")).is_empty():
		_text(parent, str(status.description), 12)

func show_inventory(view: Dictionary) -> void:
	_begin("inventory", "YOUR BUILD", "Simulation paused. Stats are calculated by the run controller.")
	_inventory(_scroll(body), view)
	_button(body, "BACK", "close_inventory")
	_finish()

func show_upgrade(options: Array, generation: int) -> void:
	_begin("upgrade", "CIRCUIT UPGRADE", "Choose one permanent improvement for this run.")
	var list := _scroll(body)
	for i in options.size():
		var option: Dictionary = options[i]
		var c := _card(list, option)
		_button(c, "SELECT", "upgrade", {"index": int(option.get("index", i)), "generation": generation})
	_finish()

func show_pause(_view: Dictionary = {}) -> void:
	_begin("pause", "SYSTEM SUSPENDED", "The simulation is paused.")
	_button(body, "RESUME", "resume")
	_button(body, "INSPECT BUILD", "inventory")
	_button(body, "ENEMY FIELD GUIDE", "codex")
	_button(body, "DISPLAY SETTINGS", "settings")
	_button(body, "RETURN TO TITLE", "title")
	_finish()

func show_result(view: Dictionary) -> void:
	var won: bool = bool(view.get("won", view.get("victory", false)))
	_begin("result", "CIRCUIT COMPLETE" if won else "SIGNAL LOST", "%s · %s %s / %s  ·  LV %s  ·  KILLS %s  ·  SEED %s" % [view.get("mode_name","ARENA SURVIVAL"),"Room" if view.get("mode_id","")=="rooms" else "Wave",view.get("wave",1),view.get("stage_count",6),view.get("level",1),view.get("kills",0),view.get("seed",0)])
	_inventory(_scroll(body), view)
	var actions := HBoxContainer.new(); body.add_child(actions)
	_button(actions, "RETRY SAME SEED", "retry")
	_button(actions, "NEW SEED", "new_seed")
	_button(actions, "TITLE", "title")
	_finish()

func hide_modal() -> void:
	shade.hide(); current_screen = ""
	var focused := root.get_viewport().gui_get_focus_owner()
	if focused != null: focused.release_focus()

func modal_visible() -> bool:
	return shade.visible

## The controller supplies only live bosses. Empty input clears prior encounter text.
func update_bosses(bosses: Array) -> void:
	var live: Array = []
	for boss in bosses:
		if float(boss.get("hp", 0)) > 0 and float(boss.get("max_hp", 0)) > 0:
			live.append(boss)
	if live.is_empty():
		for child in boss_rows.get_children():
			boss_rows.remove_child(child); child.queue_free()
		boss_widgets.clear(); boss_panel.hide()
		return
	# Current encounter rules spawn at most one; two rows remain supported.
	while boss_widgets.size() > live.size():
		var old: Dictionary = boss_widgets.pop_back()
		boss_rows.remove_child(old.row); old.row.queue_free()
	while boss_widgets.size() < live.size():
		var row := VBoxContainer.new(); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_rows.add_child(row)
		var title := _label(row, "", 15)
		title.add_theme_color_override("font_color", AMBER)
		var bar := _bar(row, Color("df8958")); bar.custom_minimum_size.y = 10
		var hint := _text(row, "", 12)
		boss_widgets.append({"row": row, "title": title, "bar": bar, "hint": hint})
	for i in live.size():
		var boss: Dictionary = live[i]; var widgets: Dictionary = boss_widgets[i]
		widgets.title.text = "%s  /  PHASE %s  /  %.0f / %.0f HP" % [boss.get("name", "BOSS"), boss.get("phase", 1), float(boss.hp), float(boss.max_hp)]
		widgets.bar.max_value = float(boss.max_hp)
		widgets.bar.value = clampf(float(boss.hp), 0, float(boss.max_hp))
		widgets.hint.text = str(boss.get("hint", ""))
	boss_panel.offset_top = -12 - maxf(92, live.size() * 80)
	boss_panel.show()

func _portrait(entry: Dictionary) -> Texture2D:
	var id: String = str(entry.get("id", ""))
	if enemy_icon_cache.has(id): return enemy_icon_cache[id]
	var path: String = str(entry.get("icon_path", ""))
	var rect: Array = entry.get("rect", [])
	if path.is_empty():
		if enemy_manifest.is_empty() and FileAccess.file_exists("res://assets/enemies/enemy_manifest.json"):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/enemy_manifest.json"))
			if parsed is Dictionary: enemy_manifest = parsed
		var source: Dictionary = enemy_manifest.get("enemies", {}).get(id, {})
		path = str(source.get("path", ""))
		var frames: Array = source.get("frames", [])
		if not frames.is_empty():
			rect = frames[0].get("region", [])
			var visible: Array = frames[0].get("alpha_bbox", [])
			if rect.size() == 4 and visible.size() == 4:
				rect = [float(rect[0]) + float(visible[0]), float(rect[1]) + float(visible[1]), visible[2], visible[3]]
	if path.is_empty() or not ResourceLoader.exists(path): return null
	var texture: Texture2D = load(path)
	if rect.size() == 4:
		var region := AtlasTexture.new(); region.atlas = texture
		region.region = Rect2(rect[0], rect[1], rect[2], rect[3]); region.filter_clip = true
		texture = region
	enemy_icon_cache[id] = texture
	return texture

func show_codex(entries: Array) -> void:
	_begin("codex", "ENEMY FIELD GUIDE", "Read the tell. Move before impact. Tab to the list; arrows / Page Down scroll. Run paused.")
	var content := _scroll(body)
	for entry in entries:
		var panel := PanelContainer.new(); content.add_child(panel)
		var row := HBoxContainer.new(); panel.add_child(row)
		var portrait := TextureRect.new(); portrait.texture = _portrait(entry)
		portrait.custom_minimum_size = Vector2(80, 80)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
		var description := VBoxContainer.new(); description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(description)
		_text(description, str(entry.get("name", entry.get("id", "ENEMY"))), 18).add_theme_color_override("font_color", AMBER)
		_text(description, str(entry.get("description", "")), 14)
		_text(description, "TELL: " + str(entry.get("tell", "")), 13)
		_text(description, "EVADE: " + str(entry.get("dodge", "")), 13)
	_button(body, "BACK", "close_codex")
	_finish()

func show_settings(view: Dictionary) -> void:
	_begin("settings", "DISPLAY SETTINGS", "Presentation only. Changes apply immediately and last for this session.")
	var content := _scroll(body)
	var values: Dictionary = view.get("settings", {})
	var reduced := CheckButton.new()
	reduced.text = "REDUCE DECORATIVE FLASHES"
	reduced.custom_minimum_size.y = 44
	reduced.set_pressed_no_signal(bool(values.get("reduced_flashes", false)))
	reduced.toggled.connect(func(enabled: bool): intent.emit("set_setting", {"key": "reduced_flashes", "value": enabled}))
	content.add_child(reduced)
	first_focus = reduced
	_text(content, "Lowers decorative effect brightness and the hit-white flash. Attack warnings and collision timing remain unchanged, so hazards are still readable.", 15)
	_text(content, "This is a flash-reduction option, not a guarantee that every flashing image is removed. Preferences are not saved to disk in this prototype.", 13)
	_text(content, "ANIMATION COVERAGE", 16).add_theme_color_override("font_color", AMBER)
	_text(content, "Action-state feedback is controller-driven. Some effects and actor states use shared frames or procedural presentation rather than separate hand-drawn animation sheets. Not every action has independent artwork.", 13)
	_button(body, "BACK", "close_settings")
	_finish()
