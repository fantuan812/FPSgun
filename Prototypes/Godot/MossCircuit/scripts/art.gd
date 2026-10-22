extends RefCounted
## Non-destructive atlas regions: source pixels are never rewritten.
static var cached_frames: Dictionary = {}
static func region(texture: Texture2D, frame: int) -> Rect2:
	var w := texture.get_width()
	var h := texture.get_height()
	var col := frame % 3
	var row := frame / 3
	var x0 := int(float(col) * w / 3.0)
	var y0 := int(float(row) * h / 3.0)
	var x1 := int(float(col + 1) * w / 3.0)
	var y1 := int(float(row + 1) * h / 3.0)
	return Rect2(x0, y0, x1 - x0, y1 - y0)

static func frames(path: String, fps: float) -> SpriteFrames:
	var cache_key := path + "@" + str(fps)
	if cached_frames.has(cache_key): return cached_frames[cache_key]
	var texture := load(path) as Texture2D
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art_source/alpha_bounds.json"))
	var bounds: Dictionary = metadata.get(path.get_file().get_basename(), {})
	if bounds.is_empty():
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/enemy_manifest.json"))
		var enemy: Dictionary = manifest.enemies[path.get_file().get_basename()]
		bounds = {"frames":[]}
		for entry in enemy.frames:
			var box: Array = entry.alpha_bbox
			bounds.frames.append({"region":entry.region,"alpha_bbox":[box[0],box[1],box[0]+box[2],box[1]+box[3]]})
	var cell_size := Vector2(ceilf(texture.get_width() / 3.0), ceilf(texture.get_height() / 3.0))
	var result := SpriteFrames.new()
	result.remove_animation("default")
	result.add_animation("walk")
	result.set_animation_speed("walk", fps)
	result.set_animation_loop("walk", true)
	for i in range(9):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		var entry: Dictionary = bounds.frames[i]
		var box: Array = entry.alpha_bbox
		var origin: Array = entry.region
		var visible_size := Vector2(box[2] - box[0], box[3] - box[1])
		atlas.region = Rect2(Vector2(origin[0] + box[0], origin[1] + box[1]), visible_size)
		# Canvas padding aligns horizontal centers and foot baseline without editing PNG.
		atlas.margin = Rect2(Vector2((cell_size.x - visible_size.x) / 2.0, cell_size.y - visible_size.y - 20.0), cell_size - visible_size)
		atlas.filter_clip = true
		result.add_frame("walk", atlas)
	result.add_animation("idle")
	result.add_frame("idle", result.get_frame_texture("walk", 0))
	cached_frames[cache_key] = result
	return result

static func actor(path: String, height: float, fps: float) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames(path, fps)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var first := sprite.sprite_frames.get_frame_texture("walk", 0) as AtlasTexture
	var frame_height := first.get_height()
	if path.begins_with("res://assets/enemies/"):
		frame_height = first.region.size.y
		# Source padding is not character size. Align visible center to collision position.
		sprite.offset.y = -(first.margin.position.y + first.region.size.y * .5 - first.get_height() * .5)
	sprite.scale = Vector2.ONE * height / frame_height
	sprite.play("walk")
	return sprite
