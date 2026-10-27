extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Art = preload("res://scripts/art.gd")
var passed := 0
var failures: Array = []
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failures.append(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	check(Rules.map_cells(7, 18, 12) == Rules.map_cells(7, 18, 12), "same seed repeat")
	check(Rules.map_cells(7, 18, 12) != Rules.map_cells(8, 18, 12), "different seeds differ")
	for seed_value in range(20):
		var tiles: Array = Rules.map_cells(seed_value, 18, 12)
		check(tiles.size() == 216 and tiles.all(func(t): return t >= 0 and t < 9), "tile range %d" % seed_value)
	check(Rules.grid_dimensions({"width":801,"height":560,"tile_size":80}) == Vector2i(11,7), "partial tile dimensions")
	check(Rules.map_cells(5, 11, 7).size() == 77, "configured tile count")
	var random := RandomNumberGenerator.new()
	random.seed = 8
	for iteration in range(100):
		var options: Array = Rules.choose_upgrades(config.upgrades, random)
		var unique: Dictionary = {}
		for o in options: unique[o.id] = true
		check(options.size() == 3 and unique.size() == 3, "unique choice %d" % iteration)
	var stats: Dictionary = config.player.duplicate(true)
	stats.max_hp = stats.hp
	stats.pierce = 0
	for i in range(100):
		for upgrade in config.upgrades: Rules.apply_upgrade(stats, upgrade)
	check(stats.fire_interval >= 0.09 and stats.speed <= 300 and stats.pierce <= 5, "upgrade caps")
	check(stats.hp <= stats.max_hp, "heal cap")
	for path in ["res://assets/hero_walk.png", "res://assets/beetle_walk.png"]:
		var frames: SpriteFrames = Art.frames(path, 10)
		check(frames.get_frame_count("walk") == 9, "nine frames " + path)
		for i in range(9):
			var texture: AtlasTexture = frames.get_frame_texture("walk", i)
			check(texture.get_size() == frames.get_frame_texture("walk", 0).get_size(), "uniform canvas")
			check(is_equal_approx(texture.margin.position.y + texture.region.size.y, texture.get_height() - 20.0), "stable feet pivot")
			check(texture.region.size.x > 0 and texture.region.end.x <= texture.atlas.get_width() and texture.region.end.y <= texture.atlas.get_height(), "valid atlas region")
	check(Art.frames("res://assets/beetle_walk.png", 9).get_animation_speed("walk") == 9 and Art.frames("res://assets/beetle_walk.png", 11).get_animation_speed("walk") == 11, "per fps frame cache")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(7)
	check(game.state == "playing" and game.enemies.is_empty() and game.level == 1, "start reset")
	game._spawn_enemy()
	check(game.enemies.size() == 1, "spawn enemy")
	game.enemies[0].pos = game.player_pos + Vector2(30, 0)
	game._shoot()
	check(game.bullets.size() == 1, "auto attack bullet")
	game.hurt_clock = 99
	for i in range(30): game._simulate(1.0 / 60)
	check(game.kills >= 1, "projectile damages and kills")
	game._start_run(7)
	game.upgrade_pending = 2
	game._show_upgrades()
	var old_generation: int = game.choice_generation
	game._take_upgrade(0, old_generation)
	check(game.upgrade_pending == 1, "first choice commits once")
	game._take_upgrade(0, old_generation)
	check(game.upgrade_pending == 1, "stale choice rejected")
	game._take_upgrade(0, game.choice_generation)
	check(game.state == "playing" and game.upgrade_pending == 0, "choices resume")
	game._start_run(7)
	for i in range(int(config.waves.count)):
		game._ensure_boss()
		for enemy in game.enemies:
			if enemy.boss:
				enemy.hp = 0
				game._boss_killed(enemy)
		game._complete_wave()
		if game.state == "upgrade": game._take_upgrade(0, game.choice_generation)
		if game.state == "shop": game._leave_shop(game.shop_generation)
	check(game.state == "won", "six waves win")
	game._start_run(7)
	game.stats.hp = 1
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos
	game._simulate(0.016)
	check(game.state == "dead", "contact death")
	game._start_run(8)
	check(game.state == "playing" and game.kills == 0 and game.bullets.is_empty() and game.wave == 1 and game.stats.hp == 100, "retry complete reset")
	game.queue_free()
	await process_frame
	print(JSON.stringify({"passed":passed, "failures":failures, "scope":"Godot headless finite rules and scene transitions; not human playtest"}))
	quit(0 if failures.is_empty() else 1)
