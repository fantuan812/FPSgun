extends SceneTree
# Independent black-box tests: deliberately use public intent/stable adapters,
# not the mode author's test fixtures. Run against --path v9 with this absolute script.
var passed := 0
var failures: Array = []
func check(value: bool, message: String) -> void:
	if value: passed += 1
	else: failures.append(message)
func _initialize() -> void: call_deferred("run")
func begin(g, id: String, seed_value: int = 9347) -> void:
	g._title()
	g._select_mode(id)
	g._start_run(seed_value)
	g.spawn_clock = 999.0
	g.weapon_clocks = [999.0]
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	begin(g,"arena")
	check(g._view().mode_id == "arena", "title selects arena")
	# Capture real old UI tokens, then recreate matching state in another run.
	g._open_shop()
	var old_shop: int = g.shop_generation
	begin(g,"rooms")
	g._open_shop()
	var coins: int = g.build.coins
	var offers: Array = g.shop_offers.duplicate(true)
	var stage: int = g.wave
	check(not g._buy(0,old_shop),"cross-mode old buy rejected")
	check(not g._refresh_shop(old_shop),"cross-mode old refresh rejected")
	check(not g._sell_weapon(0,old_shop),"cross-mode old sale rejected")
	g._leave_shop(old_shop)
	check(g.state == "shop" and g.build.coins == coins and g.shop_offers == offers and g.wave == stage,"old shop tokens preserve complete state")
	g.upgrade_pending = 1
	g._show_upgrades()
	var old_choice: int = g.choice_generation
	begin(g,"arena")
	g.upgrade_pending = 1
	g._show_upgrades()
	var levels: Dictionary = g.build.levels.duplicate(true)
	g._take_upgrade(0,old_choice)
	check(g.state == "upgrade" and g.build.levels == levels and g.upgrade_pending == 1,"old cross-mode upgrade rejected")
	# Every non-title state is forbidden for selection, including result tails.
	for id in ["rooms","arena"]:
		begin(g,id)
		for blocked_state in ["playing","paused","inventory","shop","upgrade","dead","won","settings","codex","room_clear"]:
			g.state = blocked_state
			var snapshot: Dictionary = g.build.duplicate(true)
			g._select_mode("arena" if id == "rooms" else "rooms")
			check(g._view().mode_id == id and g.state == blocked_state and g.build == snapshot,"mode locked in " + blocked_state + " from " + id)
	# Title invalid input cannot partially change selected mode.
	g._title()
	g._select_mode("rooms")
	g._select_mode("not-a-mode")
	check(g._view().mode_id == "rooms" and g.state == "title","invalid mode preserves title selection")
	for id in ["rooms","arena","rooms"]:
		begin(g,id)
		g.build.items = {"echo_chamber":1,"phase_capacitor":1,"medic_seed":1}
		g.build.levels = {"damage":3}
		g.build.coin_fraction = .75
		g.build.coins = 777
		g._recompute()
		g.effects.echo_hits = 4
		g.effects.phase_charge = 1
		g.effects.medic_damage = 29
		g.shop_pending = true
		g.upgrade_pending = 3
		g._finish(false)
		g._title()
		g._start_run(9347)
		g.weapon_clocks = [999.0]
		for frame in range(25):g._process(.05)
		check(g._view().mode_id == id and g.state == "playing" and not g.result_pending,"old death tail cannot cover new " + id)
		check(g.build.items.is_empty() and g.build.levels.is_empty() and g.build.coin_fraction == 0.0 and g.build.coins == int(g.catalog.starting_coins),"new run resets build and money " + id)
		check(g.effects.echo_hits == 0 and g.effects.phase_charge == 0 and g.effects.medic_damage == 0 and not g.shop_pending and g.upgrade_pending == 0,"new run resets growth and procs " + id)
		g._finish(false)
		g._on_intent("retry",{})
		check(g._view().mode_id == id and g.run_seed == 9347 and g.state == "playing","retry retains mode and seed " + id)
		g._finish(true)
		g._on_intent("new_seed",{})
		check(g._view().mode_id == id and g.run_seed == 9348 and g.state == "playing","new seed retains mode " + id)
	g.queue_free()
	await process_frame
	print("INDEPENDENT MODES: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
