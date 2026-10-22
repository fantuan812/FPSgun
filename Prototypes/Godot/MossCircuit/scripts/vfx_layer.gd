extends Node2D
## Presentation only: no game state references, signals, RNG or damage callbacks.
## A bounded reusable Sprite2D pool advances only when main explicitly ticks it.
var reduced_flashes := false
var specs: Dictionary = {}
var resources: Dictionary = {}
var active: Array = []
var idle: Array = []
var max_active := 96
var created := 0
var emitted := 0
var recycled := 0
var fallback_count := 0
var last_emission: Dictionary = {}
var generation := 0

func configure(data: Dictionary,manifest: Dictionary = {}) -> void:
	clear()
	specs = data.get("effects",{}).duplicate(true)
	max_active = clampi(int(data.get("max_active",96)),1,256)
	while idle.size() > max_active:
		idle.pop_back().queue_free()
		created -= 1
	resources.clear()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 12
	for id in specs.keys():
		var spec: Dictionary = specs[id]
		if not valid_spec(spec):
			specs.erase(id)
			continue
		var asset: Dictionary = manifest.get("effects",{}).get(id,{})
		if asset.is_empty() or not ResourceLoader.exists(asset.get("path","")): continue
		var source := load(asset.path) as Texture2D
		if source == null or asset.get("frames",[]).size() != 9: continue
		var frames: Array = []
		for record in asset.frames:
			var region: Array = record.region
			var rect := Rect2(region[0],region[1],region[2],region[3])
			if rect.size.x <= 0 or rect.size.y <= 0 or not Rect2(Vector2.ZERO,source.get_size()).encloses(rect):
				frames.clear()
				break
			var texture := AtlasTexture.new()
			texture.atlas = source
			texture.region = rect
			texture.filter_clip = true
			frames.append(texture)
		if frames.size()==9: resources[id]={"frames":frames,"anchor":asset.get("anchor",[.5,.5]),"endpoints":asset.get("endpoints",[[.15,.5],[.85,.5]])}

func load_default() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vfx.json"))
	var manifest := {}
	if FileAccess.file_exists(data.manifest):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(data.manifest))
		if parsed is Dictionary: manifest = parsed
	configure(data,manifest)

func play(id: String,pos: Vector2,options: Dictionary = {}) -> bool:
	if not specs.has(id): return false
	if active.size() >= max_active: _release(0)
	var sprite: Sprite2D
	if idle.is_empty():
		sprite = Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		add_child(sprite)
		created += 1
	else: sprite = idle.pop_back()
	var spec: Dictionary = specs[id]
	var item := {"id":id,"pos":pos.round(),"age":0.0,"frame":0,"sprite":sprite,"options":options.duplicate(true),"generation":generation,"fallback":not resources.has(id)}
	active.append(item)
	emitted += 1
	last_emission = {"id":id,"pos":pos.round(),"frame":0,"generation":generation}
	if item.fallback: fallback_count += 1
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if spec.get("blend","mix") == "add" else CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = material
	_present(item)
	queue_redraw()
	return true

func _present(item: Dictionary) -> void:
	var sprite: Sprite2D = item.sprite
	var spec: Dictionary = specs[item.id]
	sprite.modulate = item.options.get("tint",Color.WHITE)
	if reduced_flashes: sprite.modulate.a *= .4
	sprite.position = item.pos
	sprite.rotation = float(item.options.get("angle",0))
	sprite.visible = not item.fallback and item.age >= float(spec.get("start_delay",0))
	if item.fallback: return
	var asset: Dictionary = resources[item.id]
	var texture: Texture2D = asset.frames[item.frame]
	sprite.texture = texture
	var size := Vector2(spec.size[0],spec.size[1])
	if item.options.has("size"): size = item.options.size
	var anchor := Vector2(asset.anchor[0],asset.anchor[1])
	if item.options.has("radius"):
		# The whole square texture remains INSIDE the exact gameplay-radius ring.
		size = Vector2.ONE * float(item.options.radius) * sqrt(2.0)
	sprite.offset = -texture.get_size() * anchor
	sprite.scale = size / texture.get_size()
	if item.options.has("end"):
		var endpoint: Vector2 = item.options.end
		var displacement: Vector2 = endpoint.round()-item.pos
		var start := Vector2(asset.endpoints[0][0],asset.endpoints[0][1])
		var finish := Vector2(asset.endpoints[1][0],asset.endpoints[1][1])
		var span := maxf(.01,finish.x-start.x)
		sprite.offset = -texture.get_size()*start
		sprite.rotation = displacement.angle()
		sprite.scale.x = displacement.length() / (texture.get_width()*span)

func advance(dt: float) -> void:
	if dt <= 0: return
	for i in range(active.size()-1,-1,-1):
		var item: Dictionary = active[i]
		var spec: Dictionary = specs[item.id]
		item.age += dt
		var time: float = item.age-float(spec.get("start_delay",0))
		if time >= float(spec.duration)-.0000001:
			_release(i)
			continue
		item.frame = clampi(floori(maxf(0,time)*spec.fps+0.0000001),0,8)
		_present(item)
	queue_redraw()

func _release(index: int) -> void:
	var sprite: Sprite2D = active[index].sprite
	sprite.visible = false
	sprite.texture = null
	idle.append(sprite)
	active.remove_at(index)
	recycled += 1

func clear() -> void:
	for i in range(active.size()-1,-1,-1): _release(i)
	generation += 1
	last_emission.clear()
	queue_redraw()

func _draw() -> void:
	# Explicit missing-asset fallback, not represented as a nine-frame animation.
	for item in active:
		if not item.fallback or item.age < float(specs[item.id].get("start_delay",0)): continue
		if item.options.has("end"):
			draw_line(item.pos,item.options.end,Color(.73,.95,.98,.4 if reduced_flashes else 1.0),2)
		else:
			draw_circle(item.pos,minf(12,item.options.get("radius",12)),Color(.97,.83,.55,.4 if reduced_flashes else 1.0),false,2)

static func valid_spec(spec: Dictionary) -> bool:
	for key in ["fps","duration","start_delay"]:
		var number: Variant = spec.get(key)
		if not (number is int or number is float) or not is_finite(float(number)): return false
	if spec.fps <= 0 or spec.duration <= 0 or spec.start_delay < 0 or spec.get("frames",0) != 9: return false
	if not is_equal_approx(float(spec.duration),9.0/float(spec.fps)): return false
	if not spec.get("blend","mix") in ["mix","add"]: return false
	var size: Variant = spec.get("size")
	if not size is Array or size.size()!=2: return false
	for number in size:
		if not (number is int or number is float) or not is_finite(float(number)) or number <= 0: return false
	return true

func refresh_style() -> void:
	for item in active:_present(item)
	queue_redraw()
