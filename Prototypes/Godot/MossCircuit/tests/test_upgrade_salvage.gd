extends SceneTree
const Rules = preload("res://scripts/rules.gd")
var passed := 0
var failures: Array = []
var game

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failures.append(label)

func _initialize() -> void: call_deferred("run")

func setup(mode_id: String, pending: int = 1, shop: bool = false) -> void:
	game._title(); game._select_mode(mode_id); game._start_run(29128)
	game.upgrade_pending = pending; game.shop_pending = shop
	game.level = 4; game.xp = 7
	game.build.coins = 35; game.build.coin_fraction = 0.1
	game.stats.hp = 43.0; game.stats.coin_bonus = 7.0
	game._show_upgrades()

func stable_state() -> Dictionary:
	return {"build":game.build.duplicate(true), "stats":game.stats.duplicate(true),
		"level":game.level, "xp":game.xp, "rng":[game.rng.state,game.loot_rng.state,game.shop_rng.state],
		"hold":game.reserved_offer.duplicate(true), "offers":game.shop_offers.duplicate(true),
		"shop_generation":game.shop_generation, "clocks":game.weapon_clocks.duplicate(true),
		"hurt":game.hurt_clock, "bullets":game.bullets.duplicate(true),
		"hostile":game.enemy_bullets.duplicate(true), "hazards":game.hazards.duplicate(true),
		"blasts":game.pending_blasts.duplicate(true), "visuals":game.effect_visuals.duplicate(true),
		"effects":[game.effects.epoch, game.effects.last_sequence, game.effect_runtime.sequence,
		game.effects.shield,game.effects.shield_spent,game.effects.echo_hits,game.effects.phase_charge,
		game.effects.chain_charges,game.effects.medic_damage,game.effects.feedback_armed,
		game.effects.active.duplicate(true),game.effects.cooldowns.duplicate(true)]}

func whole_state() -> Dictionary:
	return {"stable":stable_state(),"state":game.state,"generation":game.choice_generation,
		"pending":game.upgrade_pending,"shop_pending":game.shop_pending,"choices":game.choices.duplicate(true)}

func buttons(node: Node) -> Array:
	var result: Array = []
	if node is Button: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child))
	return result

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); game.set_process(false)
	check(game.config.upgrades.size() == 6, "still six permanent upgrades")
	check(game.catalog.weapons.size() + game.catalog.items.size() == 37, "still 37 catalog entries")
	var definition := Rules.upgrade_salvage_definition()
	check(definition.id == "salvage_upgrade" and definition.scrap is int and definition.scrap == 10, "fixed shared definition")
	definition.scrap = 999; definition.id = "health"
	check(Rules.upgrade_salvage_definition().scrap == 10 and Rules.UPGRADE_SALVAGE.id == "salvage_upgrade", "detached definition")
	for fraction in [0.0, 0.1, 0.2, 0.3, 0.9999999999]:
		var build := Rules.new_build(game.catalog); build.coin_fraction = fraction
		var old := build.duplicate(true); Rules.credit_upgrade_salvage(build); old.coins += 10
		check(build == old, "whole credit leaves exact remainder/other fields " + str(fraction))
	for mode_id in ["arena", "rooms"]:
		setup(mode_id)
		var generation: int = game.choice_generation
		var old := whole_state()
		for bad in [null, true, false, {}, [], "0", 1.5, float(generation)]:
			check(not game._salvage_upgrade(bad, "salvage_upgrade"), "direct generation type " + mode_id + str(bad))
			game._on_intent("salvage_upgrade", {"id":"salvage_upgrade", "generation":bad})
			check(whole_state() == old, "generation reject atomic " + mode_id + str(bad))
		for bad in [null, true, 0, {}, [], 1.5, "health", "", "SALVAGE_UPGRADE"]:
			check(not game._salvage_upgrade(generation, bad), "direct ID type/value " + mode_id + str(bad))
			game._on_intent("salvage_upgrade", {"id":bad, "generation":generation})
			check(whole_state() == old, "ID reject atomic " + mode_id + str(bad))
		check(not game._salvage_upgrade(generation - 1, "salvage_upgrade") and whole_state() == old, "stale generation " + mode_id)
		var view: Dictionary = game._upgrade_salvage_view(); view.scrap = 1000000; view.coins = -2
		check(whole_state() == old, "read-only presentation " + mode_id)
		game.effects.cooldowns = {"echo_chamber":23.0}; game.effects.echo_hits = 3
		game.effects.phase_charge = 2; game.effects.feedback_armed = true
		game.weapon_clocks = [0.21]; game.bullets = [{"id":"frozen-test", "life":0.7, "pos":Vector2(400,300)}]
		var expected := stable_state(); expected.build.coins += 10
		game._on_intent("salvage_upgrade", {"id":"salvage_upgrade", "generation":generation, "amount":999999, "scrap":-200})
		check(stable_state() == expected, "fixed credit only; no effects/stats/RNG/in-flight mutation " + mode_id)
		check(game.state == "playing" and game.upgrade_pending == 0 and game.choices.is_empty(), "single resolution resumes " + mode_id)
		old = whole_state()
		check(not game._salvage_upgrade(generation, "salvage_upgrade") and whole_state() == old, "double payout refused " + mode_id)
		for state_name in ["title", "playing", "paused", "shop", "inventory", "dead", "won"]:
			setup(mode_id); game.state = state_name; old = whole_state()
			check(not game._salvage_upgrade(game.choice_generation, "salvage_upgrade") and whole_state() == old, "wrong state atomic " + mode_id + state_name)
		setup(mode_id); game.upgrade_pending = 0; old = whole_state()
		check(not game._salvage_upgrade(game.choice_generation, "salvage_upgrade") and whole_state() == old, "no pending atomic " + mode_id)
		setup(mode_id); game.choices.clear(); old = whole_state()
		check(not game._salvage_upgrade(game.choice_generation, "salvage_upgrade") and whole_state() == old, "empty page atomic " + mode_id)
		setup(mode_id, 3)
		var control := RandomNumberGenerator.new(); control.state = game.loot_rng.state
		var next_choices := Rules.choose_upgrades(game.config.upgrades, control)
		generation = game.choice_generation
		check(game._salvage_upgrade(generation, "salvage_upgrade"), "queued salvage accepted " + mode_id)
		check(game.upgrade_pending == 2 and game.state == "upgrade" and game.choice_generation == generation + 1, "exactly one queued choice " + mode_id)
		check(game.choices == next_choices and game.loot_rng.state == control.state, "only ordinary next-page RNG " + mode_id)
		old = whole_state()
		check(not game._salvage_upgrade(generation, "salvage_upgrade") and whole_state() == old, "old callback cannot salvage next page " + mode_id)
		game._take_upgrade(0, game.choice_generation)
		check(game.build.levels.size() == 1 and game.upgrade_pending == 1 and game.build.coins == 45, "normal stat pick remains available " + mode_id)
		check(game._salvage_upgrade(game.choice_generation, "salvage_upgrade") and game.upgrade_pending == 0 and game.build.coins == 55, "mixed three-page queue " + mode_id)
		check(game.level == 4 and game.xp == 7, "earned level and XP stay " + mode_id)
		setup(mode_id); game.state = "shop"
		game.shop_offers = [{"id":"rail_lance","sold":false,"weight_multiplier":1.0,"bias_reasons":[]}]
		check(game._reserve_offer(0, game.shop_generation), "reserve unaffordable offer before later choice " + mode_id)
		var hold: Dictionary = game.reserved_offer.duplicate(true)
		game.upgrade_pending = 1; game.shop_pending = true; game._show_upgrades()
		check(game._salvage_upgrade(game.choice_generation, "salvage_upgrade"), "salvage returns to already-pending shop " + mode_id)
		check(game.state == "shop" and game.reserved_offer == hold and game.build.coins == 45, "hold retained and now affordable " + mode_id)
		check(game._buy(0, game.shop_generation) and game.build.coins == 3 and game.reserved_offer.is_empty(), "ordinary exact-price held purchase " + mode_id)
		for size in [Vector2i(960,540), Vector2i(1280,720)]:
			root.size = size; setup(mode_id)
			await process_frame; await process_frame
			var selects: Array = []; var salvage_button: Button
			for b in buttons(game.ui.modal):
				if b.text == "SELECT": selects.append(b)
				if b.text.begins_with("SALVAGE THIS UPGRADE"): salvage_button = b
			check(selects.size() == 3 and salvage_button != null, "three stat cards plus separate resolution " + mode_id + str(size))
			check(game.ui.first_focus == selects[0] and root.gui_get_focus_owner() == selects[0], "ordinary SELECT initial focus " + mode_id + str(size))
			check(salvage_button.text.contains("+10 SCRAP") and not salvage_button.disabled, "exact payout visible " + mode_id + str(size))
			check(game.ui.modal.get_global_rect().encloses(salvage_button.get_global_rect()), "salvage visible inside modal " + mode_id + str(size))
			old = whole_state(); game.ui.show_upgrade(game.choices, game.choice_generation, game._upgrade_salvage_view())
			check(whole_state() == old, "render is read-only " + mode_id + str(size))
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free(); await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failed":failures.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
