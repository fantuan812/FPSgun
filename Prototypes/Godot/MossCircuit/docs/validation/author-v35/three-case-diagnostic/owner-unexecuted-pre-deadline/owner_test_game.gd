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
	var owner_refs:Dictionary={}
	var owner_observation:Dictionary={"case":"test_game.gd","before":{},"after_one_frame":{},"chunks":[],"deadline_ms":1000,"scope":"External disposal-only owner observation; original failed resource identities for non-reproduced cases remain unknown."}
	for cue in game.feedback_audio.players:
		var stream:Resource=game.feedback_audio.players[cue].stream
		owner_refs[cue]=weakref(stream)
		owner_observation.before[cue]={"id":stream.get_instance_id(),"class":stream.get_class(),"path":stream.resource_path,"playing":game.feedback_audio.players[cue].playing}
		stream=null # Never pin the resource through the observer.
	var owner_capture:=AudioEffectCapture.new();owner_capture.buffer_length=2.0
	var owner_effect_index:int=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,owner_capture)
	game.queue_free()
	await process_frame
	owner_observation.node_freed=not is_instance_valid(game)
	for cue in owner_refs:owner_observation.after_one_frame[cue]=owner_refs[cue].get_ref()!=null
	var owner_queued:int=owner_capture.get_frames_available()
	if owner_queued>0:owner_capture.get_buffer(owner_queued) # Explicit pre-window drain, not fresh-silence evidence.
	owner_observation.pre_window_drained=owner_queued
	var owner_required:int=int(ceil(AudioServer.get_mix_rate()*.15))
	var owner_start:int=Time.get_ticks_usec()
	var owner_pushed_before:int=owner_capture.get_pushed_frames()
	var owner_silent_frames:int=0
	var owner_complete:=false
	var owner_invalid:int=0
	while Time.get_ticks_usec()-owner_start<1000000:
		await create_timer(.01).timeout
		var owner_count:int=owner_capture.get_frames_available()
		var owner_peak:=0.0
		if owner_count>0:
			var owner_pcm:PackedVector2Array=owner_capture.get_buffer(owner_count)
			for frame in owner_pcm:
				if not is_finite(frame.x) or not is_finite(frame.y):owner_invalid+=1
				owner_peak=maxf(owner_peak,maxf(absf(frame.x),absf(frame.y)))
				if absf(frame.x)<=.000001 and absf(frame.y)<=.000001:owner_silent_frames+=1
				else:owner_silent_frames=0
		var owner_released:=true
		for cue in owner_refs:owner_released=owner_released and owner_refs[cue].get_ref()==null
		owner_observation.chunks.append({"frames":owner_count,"peak":owner_peak,"pushed":owner_capture.get_pushed_frames(),"refs_released":owner_released,"elapsed_us":Time.get_ticks_usec()-owner_start})
		if owner_observation.node_freed and owner_invalid==0 and owner_released and owner_silent_frames>=owner_required and owner_capture.get_pushed_frames()-owner_pushed_before>=owner_required and Time.get_ticks_usec()-owner_start>=150000 and owner_capture.get_discarded_frames()==0:
			owner_complete=true;break
	owner_observation.complete=owner_complete
	owner_observation.invalid_samples=owner_invalid
	owner_observation.silent_frames=owner_silent_frames
	owner_observation.discarded=owner_capture.get_discarded_frames()
	owner_observation.new_pushed=owner_capture.get_pushed_frames()-owner_pushed_before
	owner_observation.required_frames=owner_required
	owner_observation.elapsed_us=Time.get_ticks_usec()-owner_start
	AudioServer.remove_bus_effect(0,owner_effect_index)
	owner_observation.capture_removed=AudioServer.get_bus_effect_count(0)==owner_effect_index
	var owner_args:=OS.get_cmdline_user_args()
	if not owner_args.is_empty():FileAccess.open(owner_args[0],FileAccess.WRITE).store_string(JSON.stringify(owner_observation,"  ")+"\n")
	print("OWNER_OBSERVATION ",JSON.stringify(owner_observation))
	if not owner_complete or not owner_observation.capture_removed:push_error("External owner observation reached bounded deadline without complete reference release/fresh silence")
	print(JSON.stringify({"passed":passed, "failures":failures, "scope":"Godot headless finite rules and scene transitions; not human playtest"}))
	quit(0 if failures.is_empty() else 1)
