extends SceneTree
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v:passed += 1
	else:failures.append(s)
func _initialize() -> void:call_deferred("run")
func reset(g,items: Dictionary = {}) -> void:
	g._start_run(60);g.spawn_clock = 999;g.weapon_clocks = [999.0]
	g.build.items = items.duplicate(true);g._recompute()
func enemy(g,offset: Vector2) -> Dictionary:
	var e: Dictionary = g._spawn_kind("crawler",g.player_pos+offset)
	e.hp = 1000;e.max_hp = 1000;e.speed = 0
	return e
func count_fx(g,id: String) -> int:
	return g.vfx.active.filter(func(e):return e.id == id).size()
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	reset(g)
	for id in g.vfx.specs:
		check(g.vfx.resources.has(id),"real resource " + id)
		if not g.vfx.resources.has(id):continue
		g.vfx.clear();g.vfx.play(id,Vector2(100,100))
		var fixed_offset: Vector2 = g.vfx.active[0].sprite.offset
		var fixed_scale: Vector2 = g.vfx.active[0].sprite.scale
		var fps: float = g.vfx.specs[id].fps
		check(g.vfx.active[0].frame == 0,"initial frame0 " + id)
		for i in range(1,9):
			g.vfx.advance(1.0/fps)
			check(g.vfx.active.size() == 1 and g.vfx.active[0].frame == i,"frame step " + id+str(i))
			check(g.vfx.active[0].sprite.offset == fixed_offset and g.vfx.active[0].sprite.scale == fixed_scale,"fixed canvas anchor " + id+str(i))
		g.vfx.advance(1.0/fps+.00001)
		check(g.vfx.active.is_empty(),"one shot recycle " + id)
	g.vfx.clear()
	for i in range(200):g.vfx.play("hit_spark",Vector2(i,0))
	check(g.vfx.active.size() == g.vfx.max_active and g.vfx.created <= g.vfx.max_active,"bounded active and node pool")
	reset(g)
	var a: Dictionary = enemy(g,Vector2(100,0))
	g._fire_weapon("rivet_gun",0)
	check(count_fx(g,"muzzle_flash") == 1 and g.bullets.size() == 1,"real fire muzzle hook")
	for i in range(20):g._simulate(.016)
	check(count_fx(g,"hit_spark") > 0 and a.hp < 1000,"actual hit spark hook")
	reset(g,{"mirror_shell":1})
	g._hurt(5)
	check(count_fx(g,"shield_impact") == 1 and g.stats.hp == 100,"actual shield block hook")
	reset(g,{"arc_relay":1})
	a = enemy(g,Vector2(100,0))
	var b: Dictionary = enemy(g,Vector2(120,0))
	var c: Dictionary = enemy(g,Vector2(140,0))
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20})
	var arcs: Array = g.vfx.active.filter(func(e):return e.id == "chain_arc")
	check(arcs.size() == 2 and b.hp == 992 and c.hp == 992,"chain VFX matches2 damaged targets")
	var ends: Array = arcs.map(func(e):return e.options.end)
	check(b.pos in ends and c.pos in ends,"chain endpoints are actual enemy positions")
	for arc in arcs:
		if arc.fallback:continue
		var sprite: Sprite2D = arc.sprite
		var asset: Dictionary = g.vfx.resources.chain_arc
		var start := Vector2(asset.endpoints[0][0],asset.endpoints[0][1])
		var finish := Vector2(asset.endpoints[1][0],asset.endpoints[1][1])
		check(sprite.to_global(sprite.texture.get_size()*start+sprite.offset).distance_to(arc.pos) < .01,"chain rendered start anchor")
		check(sprite.to_global(sprite.texture.get_size()*finish+sprite.offset).distance_to(arc.options.end.round()) < .01,"chain rendered end anchor")
	check(g.telegraphs.z_index > g.vfx.z_index,"critical telegraphs above VFX")
	reset(g)
	a = enemy(g,Vector2(150,0));g._fire_weapon("shock_mortar",0);g._update_mortars(.61)
	check(count_fx(g,"explosion") == 1 and a.hp == 964,"mortar release explosion hook")
	g._effect_event("dash",{"pos":g.player_pos,"angle":1.2})
	check(count_fx(g,"dash_trail") == 1,"dash event trail hook")
	var item: Dictionary = g.vfx.active.back()
	var age: float = item.age
	g._on_intent("pause",{});g._process(1)
	check(item.age == age and g.vfx.active.has(item),"pause freezes active VFX")
	var generation: int = g.vfx.generation
	reset(g)
	check(g.vfx.active.is_empty() and g.vfx.generation > generation,"new run removes prior instances")
	var full_specs: Dictionary = g.vfx.specs.duplicate(true)
	var outcomes: Array = []
	for disabled in [false,true]:
		reset(g)
		g.vfx.specs = {} if disabled else full_specs.duplicate(true)
		g.vfx.max_active = 1
		a = enemy(g,Vector2(100,0))
		for i in range(20):g.vfx.play("hit_spark",Vector2.ZERO)
		g._fire_weapon("rivet_gun",0)
		for i in range(20):g._simulate(.016)
		outcomes.append([a.hp,g.stats.hp,g.rng.state,g.loot_rng.state,g.shop_rng.state,g.kills,g.bullets.size()])
	check(outcomes[0] == outcomes[1],"VFX pool-full vs disabled damage and RNG identical")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_vfx_passed":passed,"failures":failures,"scope":"headless timing hooks isolation; no rendered-window review"}))
	quit(0 if failures.is_empty() else 1)
