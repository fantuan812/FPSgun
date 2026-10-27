extends SceneTree
var passed := 0
var failures: Array = []
func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failures.append(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(123)
	var map: Array = game.map_data.duplicate()
	game.upgrade_pending = 1
	game._show_upgrades()
	var first_choices: Array = game.choices.duplicate(true)
	var stale_generation: int = game.choice_generation
	game._start_run(123)
	check(game.map_data == map, "restart seed map identical")
	game.upgrade_pending = 1
	game._show_upgrades()
	check(game.choices == first_choices, "restart seed loot identical")
	game._take_upgrade(0, stale_generation)
	check(game.upgrade_pending == 1 and game.state == "upgrade", "prior run callback rejected")
	game._take_upgrade(-1, game.choice_generation)
	game._take_upgrade(3, game.choice_generation)
	check(game.upgrade_pending == 1, "invalid choice ignored")
	game._take_upgrade(0, game.choice_generation)
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	game._input(event)
	check(game.state == "paused", "escape pauses")
	var elapsed_before: float = game.elapsed
	var frame_before:int=game.hero.frame
	var age_before:float=game.actor_anim.actors[0].age
	var walk_before:float=game.actor_anim.actors[0].walk_time
	game._process(1.0)
	check(game.elapsed == elapsed_before and game.hero.frame==frame_before and game.actor_anim.actors[0].age==age_before and game.actor_anim.actors[0].walk_time==walk_before and not game.hero.is_playing(), "pause freezes simulation and hero")
	game._input(event)
	check(game.state == "playing", "escape resumes")
	game._start_run(9)
	game._spawn_enemy()
	game.enemies[0].pos = game.player_pos
	game.stats.dash_time = 0.1
	game._simulate(0.016)
	check(game.stats.hp == 100, "dash invulnerable contact")
	game._start_run(5)
	game.config.arena.width = 801
	game.config.arena.height = 560
	game._start_run(5)
	game.state = "paused"
	game._process(0.016)
	check(game.grid_size == Vector2i(11, 7) and game.map_data.size() == 77, "configured partial map dimensions integrated")
	check(is_equal_approx(game.camera.position.x, 400.5), "small map camera centered")
	game._title()
	game._process(1.0)
	check(game.state == "title" and game.elapsed == 0, "title frozen")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free()
	await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_passed":passed,"failures":failures,"scope":"additional headless scenarios, no rendered-window validation"}))
	quit(0 if failures.is_empty() else 1)
