extends SceneTree

# Run after headless editor import. Kept under art ownership.
func _init() -> void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/icon_manifest.json"))
	var texture = load(manifest.atlas) as Texture2D
	assert(texture != null)
	assert(texture.get_width() == int(manifest.size[0]))
	assert(texture.get_height() == int(manifest.size[1]))
	var seen := {}
	assert(manifest.icons.size() == 16)
	for id in manifest.icons:
		var entry = manifest.icons[id]
		var r = entry.rect
		var sliced := AtlasTexture.new()
		sliced.atlas = texture
		sliced.region = Rect2(r[0], r[1], r[2], r[3])
		var pixels := sliced.get_image()
		assert(not pixels.is_empty(), id)
		var opaque := 0
		for y in pixels.get_height():
			for x in pixels.get_width():
				if pixels.get_pixel(x, y).a > 0.125:
					opaque += 1
		assert(opaque > 100, id)
		var signature := pixels.get_data().hex_encode().sha256_text()
		assert(not seen.has(signature), id)
		seen[signature] = true
	print("PASS: imported atlas + 16 nonempty, unique Godot AtlasTexture slices")
	quit()
