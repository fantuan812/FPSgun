extends SceneTree
## Run with the editor reader and --main-pack, from a directory without source.
## This is packed-resource integration, not native exported GUI certification.
var checks := 0
var failures: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func scene_structure(path: String) -> Array:
	var state: SceneState = (load(path) as PackedScene).get_state()
	var records: Array = []
	for i in state.get_node_count():
		var properties: Dictionary = {}
		for j in state.get_node_property_count(i):
			var value = state.get_node_property_value(i, j)
			properties[str(state.get_node_property_name(i, j))] = {"resource": value.resource_path, "class": value.get_class()} if value is Resource else var_to_str(value)
		records.append({"name": str(state.get_node_name(i)), "type": str(state.get_node_type(i)), "path": str(state.get_node_path(i)), "properties": properties})
	return records
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Expected source-fingerprint JSON and report destination")
		quit(2); return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	check(int(expected.get("schema_version", 0)) == 2, "complete source-imported fingerprint schema")
	check(scene_structure("res://scenes/main.tscn") == expected.main_scene_structure, "packed main scene structure and properties match source")
	for key in expected.project_settings:
		check(var_to_str(ProjectSettings.get_setting(key)) == expected.project_settings[key], "packed project setting " + key)
	for path in expected.exact_files:
		check(FileAccess.file_exists("res://" + path), "packed file exists " + path)
		check(FileAccess.get_sha256("res://" + path) == expected.exact_files[path], "packed bytes match " + path)
	for path in expected.images:
		check(ResourceLoader.exists("res://" + path), "import remap resolves " + path)
		var texture = load("res://" + path)
		check(texture is Texture2D, "packed texture loads " + path)
		if not texture is Texture2D: continue
		var image: Image = texture.get_image()
		check(image != null and not image.is_empty(), "packed pixels readable " + path)
		if image == null or image.is_empty(): continue
		if image.is_compressed(): image.decompress()
		image.clear_mipmaps(); image.convert(Image.FORMAT_RGBA8)
		var h := HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(image.get_data())
		check(image.get_width() == int(expected.images[path].width) and image.get_height() == int(expected.images[path].height), "texture dimensions " + path)
		check(h.finish().hex_encode() == expected.images[path].imported_rgba_sha256, "decoded alpha/RGBA parity " + path)
	for path in ["docs", "tests", "tools", "art_source/v9-room-candidates"]:
		check(not DirAccess.dir_exists_absolute("res://" + path), "excluded directory " + path)
	for path in ["MANIFEST.json", "README.md", "ui/test_ui.gd", "art_source/provenance.json"]:
		check(not FileAccess.file_exists("res://" + path), "excluded file " + path)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false)
	check(game.actor_anim.assets.size() == expected.actions.size(), "all 25 dynamically referenced actions present")
	var frames := 0
	for id in game.actor_anim.assets:
		var asset: Dictionary = game.actor_anim.assets[id]
		frames += asset.frames.get_frame_count("action")
		for index in asset.frames.get_frame_count("action"):
			var atlas: AtlasTexture = asset.frames.get_frame_texture("action", index)
			check(atlas != null and atlas.atlas != null and atlas.filter_clip, "packed action atlas " + id + "/" + str(index))
	var expected_frames := 0
	for id in expected.actions:
		expected_frames += int(expected.actions[id])
		check(game.actor_anim.assets.has(id) and game.actor_anim.assets[id].frames.get_frame_count("action") == int(expected.actions[id]), "packed action frame count " + id)
	check(frames == expected_frames, "all source-approved action frames present")
	for mode in ["arena", "rooms"]:
		game._title(); game._select_mode(mode); game._start_run(1919)
		check(game.state == "playing", "packed mode starts " + mode)
		var index := 0
		for kind in ["crawler", "flanker", "charger", "spitter", "brood_keeper", "boss_warden", "boss_core"]:
			var enemy: Dictionary = game._spawn_kind(kind, game.player_pos + Vector2(150 + index * 20, 0))
			check(enemy.sprite.sprite_frames != null, "packed enemy walk " + kind + "/" + mode)
			check(game.actor_anim.trigger(enemy.id, "hurt"), "packed hurt event " + kind + "/" + mode)
			check(game.actor_anim.trigger(enemy.id, "death"), "packed death interruption " + kind + "/" + mode)
			index += 1
		game.build.coins = 100; game._open_shop()
		check(game.ui.current_screen == "shop", "packed shop builds " + mode)
		game.ui.show_inventory(game._view())
		check(game.ui.current_screen == "inventory", "packed inventory builds " + mode)
	for item in game.catalog.weapons + game.catalog.items:
		check(game.ui.icon(item.id) != null, "packed catalog icon " + item.id)
	game.queue_free(); await process_frame
	var report := {"checks": checks, "failures": failures, "exact_files": expected.exact_files.size(), "images": expected.images.size(), "actions": expected.actions.size(), "action_frames": frames, "scope": "editor reader of exported PCK, no source fallback; dynamic resources and controlled integration, not native GUI or Windows runtime acceptance"}
	var out := FileAccess.open(args[1], FileAccess.WRITE); out.store_string(JSON.stringify(report, "  ") + "\n"); out.close()
	print(JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
