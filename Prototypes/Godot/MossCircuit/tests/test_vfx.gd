extends SceneTree
const Layer = preload("res://scripts/vfx_layer.gd")
var passed := 0
var failures: Array = []
func check(ok: bool,label: String) -> void:
	if ok: passed += 1
	else: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vfx.json"))
	var layer=Layer.new()
	root.add_child(layer)
	layer.configure(data,{})
	for id in data.effects:
		layer.clear()
		check(layer.play(id,Vector2(10.2,20.8)),"known effect " + id)
		check(layer.active[0].frame==0 and layer.active[0].pos==Vector2(10,21),"first frame and pixel snap")
		var fps:float=data.effects[id].fps
		for frame in range(1,9):
			layer.advance(1.0/fps)
			check(layer.active[0].frame==frame,"nine distinct timeline indices")
		layer.advance(1.0/fps)
		check(layer.active.is_empty(),"one shot returns to pool")
	check(layer.fallback_count==6,"missing resources explicitly fallback")
	for i in range(300): layer.play("hit_spark",Vector2(i,0))
	check(layer.active.size()==96 and layer.created==96,"bounded active and node pool")
	layer.clear()
	check(layer.active.is_empty() and layer.idle.size()==96,"clear recycles all")
	var old_generation:int=layer.generation
	layer.play("hit_spark",Vector2.ZERO)
	check(layer.active[0].generation==old_generation,"new generation only")
	var small:=data.duplicate(true)
	small.max_active=3
	layer.configure(small,{})
	check(layer.created<=3,"reconfigure lower cap trims free pool")
	check(not layer.play("not_known",Vector2.ZERO),"unknown ID rejected")
	for value in [0,-1,"bad",INF]:
		var spec:Dictionary=data.effects.hit_spark.duplicate(true)
		spec.fps=value
		check(not Layer.valid_spec(spec),"invalid fps rejected")
	var delayed:=data.duplicate(true)
	delayed.effects.hit_spark.start_delay=.2
	layer.configure(delayed,{})
	layer.play("hit_spark",Vector2.ZERO)
	layer.advance(.1)
	check(layer.active[0].frame==0,"start delay no progression")
	layer.advance(.1)
	check(layer.active[0].frame==0,"first frame after start delay")
	layer.load_default()
	var pending := "--allow-pending" in OS.get_cmdline_user_args()
	if not pending: check(layer.resources.size()==6,"six real sheets available")
	for id in layer.resources:
		layer.clear()
		layer.play(id,Vector2.ZERO)
		check(not layer.active[0].fallback and layer.active[0].sprite.texture!=null,"real texture " + id)
		check(layer.resources[id].frames.size()==9,"nine atlas regions " + id)
		check(layer.active[0].sprite.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest filter")
		for frame in layer.resources[id].frames:
			check(frame.filter_clip,"atlas clip excludes neighbor")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(70)
	game._spawn_kind("crawler",game.player_pos+Vector2(100,0))
	game.enemies[0].hp=1000
	var r1:int=game.rng.state
	var r2:int=game.loot_rng.state
	var r3:int=game.shop_rng.state
	game._fire_weapon("rivet_gun",0)
	check(game.vfx.active.any(func(e): return e.id=="muzzle_flash"),"actual muzzle hook")
	game._advance_bullet(game.bullets[0],.3)
	check(game.vfx.active.any(func(e): return e.id=="hit_spark"),"actual primary hit hook")
	game.build.items={"mirror_shell":1}
	game._recompute()
	var hp:float=game.stats.hp
	game._hurt(8)
	check(game.stats.hp==hp and game.vfx.active.any(func(e): return e.id=="shield_impact"),"shield consequence hook")
	game._effect_event("dash",{"pos":game.player_pos,"angle":PI})
	check(game.vfx.active[-1].id=="dash_trail","dash consequence hook")
	check(game.rng.state==r1 and game.loot_rng.state==r2 and game.shop_rng.state==r3,"decorations do not consume logic RNG")
	game._fire_weapon("shock_mortar",0)
	game._update_mortars(.6)
	check(game.vfx.active.any(func(e): return e.id=="explosion"),"actual mortar release hook")
	game._sync_telegraphs()
	check(game.telegraphs.z_index>game.vfx.z_index,"precise warning geometry above decoration")
	var age:float=game.vfx.active[0].age
	game.state="paused"
	game._process(.2)
	check(game.vfx.active[0].age==age,"pause freezes all visual ages")
	game._start_run(70)
	check(game.vfx.active.is_empty() and game.telegraphs.markers.is_empty(),"restart clears effects and warnings")
	game._vfx("hit_spark",Vector2.ZERO)
	game._title()
	check(game.vfx.active.is_empty(),"title clears visual leftovers")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game, layer])
	game.queue_free();layer.queue_free()
	await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"pending_assets":pending,"scope":"v6 pure presentation pipeline"}))
	quit(0 if failures.is_empty() else 1)
