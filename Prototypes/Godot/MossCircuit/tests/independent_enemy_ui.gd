extends SceneTree
const Art = preload("res://scripts/art.gd")
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	g._on_intent("codex",{})
	await process_frame
	await process_frame
	check(g.state == "codex" and root.gui_get_focus_owner() != null,"title codex focused")
	g._on_intent("close_codex",{})
	check(g.state == "title","codex returns title")
	g._start_run(1)
	g._on_intent("pause",{})
	g._on_intent("codex",{})
	g._on_intent("close_codex",{})
	await process_frame
	await process_frame
	check(g.state == "paused" and root.gui_get_focus_owner() != null,"codex returns pause focus")
	g._resume()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/enemy_manifest.json"))
	for entry in g.encounters.enemies:
		var path: String = manifest.enemies[entry.id].path
		check(ResourceLoader.exists(path),"mapped sheet " + entry.id)
		if not ResourceLoader.exists(path): continue
		var frames: SpriteFrames = Art.frames(path,9)
		check(frames.get_frame_count("walk") == 9,"nine frames " + entry.id)
		for i in range(9):
			var tex: AtlasTexture = frames.get_frame_texture("walk",i)
			check(tex.region.size.x > 0 and tex.region.size.y > 0 and tex.region.end.x <= tex.atlas.get_width() and tex.region.end.y <= tex.atlas.get_height(),"valid frame " + entry.id + str(i))
		if path.begins_with("res://assets/enemies/"):
			var actor = Art.actor(path,57.0 * entry.scale,9)
			var first: AtlasTexture = actor.sprite_frames.get_frame_texture("walk",0)
			check(is_equal_approx(first.region.size.y * actor.scale.y,57.0 * entry.scale),"visible actor height " + entry.id)
			check(is_zero_approx((first.margin.position.y + first.region.size.y*.5 - first.get_height()*.5 + actor.offset.y) * actor.scale.y),"visible actor centered " + entry.id)
			actor.free()
		var portrait = g.ui._portrait(entry)
		check(portrait != null,"portrait " + entry.id)
		if portrait is AtlasTexture:
			check(portrait.region.position.x >= 0 and portrait.region.position.y >= 0 and portrait.region.end.x <= portrait.atlas.get_width() and portrait.region.end.y <= portrait.atlas.get_height(),"portrait bounds " + entry.id)
	g.wave = 3
	g._ensure_boss()
	var boss: Dictionary = g.enemies.filter(func(e):return e.boss)[0]
	boss.phase = 2
	g._update_hud()
	check(g.ui.boss_panel.visible and "PHASE 2" in g.ui.boss_widgets[0].title.text,"boss phase HUD")
	boss.hp = 0
	g._update_hud()
	check(not g.ui.boss_panel.visible and g.ui.boss_widgets.is_empty(),"dead boss HUD clears")
	g._start_run(2)
	g._update_hud()
	check(not g.ui.boss_panel.visible,"restart clears boss HUD")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free()
	await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_enemy_ui_passed":passed,"failures":failures,"scope":"headless assets and UI structure, not rendered-window verification"}))
	quit(0 if failures.is_empty() else 1)
