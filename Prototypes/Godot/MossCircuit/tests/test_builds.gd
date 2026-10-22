extends SceneTree
const Rules = preload("res://scripts/rules.gd")
var passed := 0
var failures := []
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	check(Rules.validate_catalog(c).is_empty(), "catalog valid")
	check(not Rules.validate_catalog({}).is_empty(), "empty catalog rejected")
	var bad := c.duplicate(true)
	bad.weapons[0].interval = 0
	check(not Rules.validate_catalog(bad).is_empty(), "zero interval rejected")
	bad = c.duplicate(true)
	bad.items[0].id = bad.weapons[0].id
	check(not Rules.validate_catalog(bad).is_empty(), "duplicate ID rejected")
	bad = c.duplicate(true)
	bad.items[0].price = "free"
	check(not Rules.validate_catalog(bad).is_empty(), "text price rejected without crash")
	bad = c.duplicate(true)
	bad.items[0].effects = {"unknown":1}
	check(not Rules.validate_catalog(bad).is_empty(), "unknown effect rejected")
	var b := Rules.new_build(c)
	b.coins = 10000
	for item in c.items:
		b.items.clear()
		for i in range(item.max_stack): check(Rules.transaction(b,c,item.id) == "", "buy " + item.id)
		var snapshot := b.duplicate(true)
		check(Rules.transaction(b,c,item.id) != "" and b == snapshot, "cap atomic " + item.id)
	b = Rules.new_build(c)
	b.coins = 0
	var snapshot := b.duplicate(true)
	check(Rules.transaction(b,c,"rail_lance") != "" and snapshot == b, "insufficient funds atomic")
	b.coins = 10000
	for id in ["scrap_shotgun","rail_lance","orbit_saw"]: Rules.transaction(b,c,id)
	snapshot = b.duplicate(true)
	check(Rules.transaction(b,c,"rivet_gun") != "" and snapshot == b, "full weapon slots")
	check(Rules.transaction(b,c,"rail_lance",1) == "" and b.weapons[1] == "rail_lance", "replace slot")
	for spec in [["rail_lance","capacitor","electric_bonus"],["orbit_saw","gear","melee_bonus"],["scrap_shotgun","pellet_pouch","extra_pellets"]]:
		b = Rules.new_build(c)
		b.weapons = [spec[0]]
		b.items[spec[1]] = 2
		var derived := Rules.derive(balance.player,b,c)
		check(derived.synergies.size() == 1 and derived[spec[2]] > 0, "synergy " + spec[0])
	b = Rules.new_build(c)
	for i in range(100): Rules.credit(b,1.25)
	check(b.coins == 160 and is_zero_approx(b.coin_fraction), "fractional income")
	b.items = {"power_coil":3,"cooling_fan":2,"iron_plate":1}
	var first := Rules.derive(balance.player,b,c)
	for i in range(100): check(Rules.derive(balance.player,b,c) == first, "derive idempotent")
	b.items.erase("power_coil")
	check(Rules.derive(balance.player,b,c).damage == balance.player.damage, "sell removes bonus exactly")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(44)
	game._open_shop()
	var offers = game.shop_offers.duplicate(true)
	game._start_run(44)
	game._open_shop()
	check(offers == game.shop_offers, "shop seed reproducible")
	game.build.coins = 999
	var generation: int = game.shop_generation
	check(game._buy(0,generation), "buy success")
	var coins: int = game.build.coins
	check(not game._buy(0,generation) and game.build.coins == coins, "duplicate callback rejected")
	game._start_run(44)
	game._open_shop()
	check(not game._buy(1,generation), "cross-run stale callback rejected")
	game._start_run(44)
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos + Vector2(50,0)
	game._fire_weapon("scrap_shotgun",0)
	check(game.bullets.size() == 5, "shotgun projectiles")
	game.bullets.clear()
	game._fire_weapon("rail_lance",0)
	check(game.bullets.size() == 1 and game.bullets[0].pierce == 3, "rail pierce")
	var hp: float = game.enemies[0].hp
	game._fire_weapon("orbit_saw",0)
	check(game.enemies[0].hp < hp and game.bullets.size() == 1, "radial melee damages without projectile")
	game._start_run(44)
	game.build.weapons = ["orbit_saw"]
	game._recompute()
	game.stats.hp = 1
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos
	game.enemies[0].hp = 1
	game._simulate(.016)
	check(game.stats.hp == 1 and game.state == "playing", "dead melee enemy cannot deal ghost damage")
	game._start_run(44)
	for i in range(6):
		game._ensure_boss()
		for enemy in game.enemies:
			if enemy.boss:
				enemy.hp = 0
				game._boss_killed(enemy)
		game._complete_wave()
		if game.state == "upgrade": game._take_upgrade(0,game.choice_generation)
		if i < 5:
			check(game.state == "shop", "wave enters shop")
			game._leave_shop(game.shop_generation)
	check(game.state == "won", "six wave economic loop")
	game.queue_free()
	await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v2 build/economy headless"}))
	quit(0 if failures.is_empty() else 1)
