extends SceneTree
## Capture accepted source-imported texture pixels, not raw PNG transparent RGB.
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
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2: quit(2); return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	expected.schema_version = 2
	expected.main_scene_structure = scene_structure("res://scenes/main.tscn")
	expected.project_settings = {}
	var project := ConfigFile.new(); project.load("res://project.godot")
	for section in project.get_sections():
		if section == "": continue
		for key in project.get_section_keys(section):
			var full := section + "/" + key
			if full != "application/config/features": expected.project_settings[full] = var_to_str(ProjectSettings.get_setting(full))
	for path in expected.images:
		var texture: Texture2D = load("res://" + path)
		var image: Image = texture.get_image()
		if image.is_compressed(): image.decompress()
		image.clear_mipmaps(); image.convert(Image.FORMAT_RGBA8)
		var h := HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(image.get_data())
		expected.images[path] = {"width": image.get_width(), "height": image.get_height(), "imported_rgba_sha256": h.finish().hex_encode(), "raw_png_sha256": FileAccess.get_sha256("res://" + path), "import_settings_sha256": FileAccess.get_sha256("res://" + path + ".import")}
	var director = load("res://scripts/actor_director.gd").new(); director.load_default()
	expected.actions = {}
	for id in director.assets: expected.actions[id] = director.assets[id].frames.get_frame_count("action")
	expected.texture_comparison_basis = "Source-imported texture RGBA, after Godot import processing including alpha-border handling; not raw source PNG RGBA."
	var f := FileAccess.open(args[1], FileAccess.WRITE); f.store_string(JSON.stringify(expected, "  ") + "\n"); f.close()
	print("PASS: source-imported texture fingerprints: ", expected.images.size(), "; actions: ", expected.actions.size())
	quit(0)
