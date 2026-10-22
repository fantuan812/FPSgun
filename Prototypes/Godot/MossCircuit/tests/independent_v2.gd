extends SceneTree
const Rules = preload("res://scripts/rules.gd")
var passed := 0
var failures: Array = []
func check(v: bool, s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void: call_deferred("run")
func offer(game, id: String) -> void:
	game.shop_offers = [{"id":id,"sold":false}]
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(61)
	game._open_shop()
	var initial: Array = game.shop_offers.duplicate(true)
	var old_run_gen: int = game.shop_generation
	game._start_run(61)
	game._open_shop()
	check(game.shop_offers == initial, "same seed shop sequence")
	check(not game._buy(0,old_run_gen), "prior run purchase rejected")
	game.build.coins = 1000
	offer(game,"power_coil")
	var gen: int = game.shop_generation
	check(game._buy(0,gen), "purchase succeeds")
	var coins: int = game.build.coins
	check(not game._buy(0,gen) and game.build.coins == coins, "repeated purchase no double charge")
	check(is_equal_approx(game.stats.damage_bonus,.15), "item attribute applied")
	gen = game.shop_generation
	check(game._sell_item("power_coil",gen), "sell item")
	check(is_equal_approx(game.stats.damage_bonus,0) and not game.build.items.has("power_coil"), "sold attribute removed")
	coins = game.build.coins
	check(not game._sell_item("power_coil",gen) and game.build.coins == coins, "stale sell rejected")
	game.build.coins = 0
	offer(game,"power_coil")
	var before: Dictionary = game.build.duplicate(true)
	check(not game._buy(0,game.shop_generation) and game.build == before, "unaffordable purchase atomic")
	check(not game._refresh_shop(game.shop_generation) and game.build.coins == 0, "unaffordable refresh atomic")
	game.build.coins = 1000
	game.build.weapons = ["rivet_gun","rivet_gun","rivet_gun","rivet_gun"]
	game._recompute()
	offer(game,"rail_lance")
	before = game.build.duplicate(true)
	check(not game._buy(0,game.shop_generation) and game.build == before, "full weapon no implicit replacement")
	check(not game._buy(0,game.shop_generation,99) and game.build == before, "invalid replacement atomic")
	check(game._buy(0,game.shop_generation,2) and game.build.weapons[2] == "rail_lance" and game.build.weapons.size() == 4, "explicit replacement")
	game.build.weapons = ["rivet_gun"]
	game.build.items = {"capacitor":3}
	game._recompute()
	check("ARC GRID" in game.stats.synergies, "synergy activated")
	game._sell_item("capacitor",game.shop_generation)
	check(not "ARC GRID" in game.stats.synergies, "selling disables synergy")
	game.build.items = {"power_coil":5}
	game._recompute()
	offer(game,"power_coil")
	before = game.build.duplicate(true)
	check(not game._buy(0,game.shop_generation) and game.build == before, "item cap atomic")
	game.build.items.clear()
	for e in game.catalog.items.slice(0,8): game.build.items[e.id] = 1
	offer(game,"capacitor")
	before = game.build.duplicate(true)
	check(not game._buy(0,game.shop_generation) and game.build == before, "item slots cap atomic")
	gen = game.shop_generation
	check(game._refresh_shop(gen), "refresh succeeds")
	coins = game.build.coins
	check(not game._refresh_shop(gen) and game.build.coins == coins, "old refresh rejected")
	var elapsed_before: float = game.elapsed
	var frame_before:int=game.hero.frame
	var age_before:float=game.actor_anim.actors[0].age
	var walk_before:float=game.actor_anim.actors[0].walk_time
	game._process(1)
	check(game.elapsed == elapsed_before and game.hero.frame==frame_before and game.actor_anim.actors[0].age==age_before and game.actor_anim.actors[0].walk_time==walk_before and not game.hero.is_playing(), "shop pauses simulation")
	gen = game.shop_generation
	game._leave_shop(gen)
	check(game.state == "playing" and not game._buy(0,gen), "leave rejects purchases")
	game._start_run(8)
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos + Vector2(30,0)
	game._fire_weapon("rivet_gun",0)
	check(game.bullets.size() == 1 and game.bullets[0].pierce == 0, "single projectile")
	game.bullets.clear()
	game._fire_weapon("scrap_shotgun",0)
	check(game.bullets.size() == 5 and not game.bullets[0].velocity.is_equal_approx(game.bullets[4].velocity), "spread five distinct trajectories")
	game.bullets.clear()
	game._fire_weapon("rail_lance",0)
	check(game.bullets.size() == 1 and game.bullets[0].pierce == 3, "rail piercing projectile")
	game.bullets.clear()
	var hp: float = game.enemies[0].hp
	for weapon in game.catalog.weapons:
		if weapon.behavior == "orbit": game._fire_weapon(weapon.id,0)
	check(game.bullets.is_empty() and game.enemies[0].hp < hp, "radial melee real damage")
	game._start_run(7)
	for weapon in game.catalog.weapons:
		if weapon.behavior == "orbit": game.build.weapons = [weapon.id]
	game._recompute()
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos
	game.enemies[0].hp = 1
	game.stats.hp = 1
	game.spawn_clock = 999
	game._simulate(.016)
	check(game.state == "playing" and game.stats.hp == 1 and game.kills == 1, "radial kill prevents ghost contact damage")
	game._start_run(2)
	game._open_shop()
	check(not game._sell_weapon(0,game.shop_generation), "cannot sell final weapon")
	game.upgrade_pending = 1
	game._show_upgrades()
	elapsed_before = game.elapsed
	game._process(1)
	check(game.elapsed == elapsed_before, "upgrade paused")
	game.queue_free()
	await process_frame
	print(JSON.stringify({"independent_v2_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
