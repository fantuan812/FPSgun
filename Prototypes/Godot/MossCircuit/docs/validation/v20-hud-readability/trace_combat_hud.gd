extends SceneTree
var traces:Array=[]
var states:Dictionary={}
func _initialize()->void:call_deferred("run")
func clean(v):
	if v is Dictionary:
		var d:Dictionary={}
		for k in v:
			if not v[k] is Object:d[str(k)]=clean(v[k])
		return d
	if v is Array:
		var a:Array=[]
		for x in v:
			if not x is Object:a.append(clean(x))
		return a
	return v
func sample(g,mode_id:String,kind:String,step:int)->void:
	var d:Dictionary={"mode":mode_id,"kind":kind,"step":step,"rng":g.rng.state,"loot_rng":g.loot_rng.state,"shop_rng":g.shop_rng.state}
	for key in ["state","player_pos","stats","enemies","bullets","enemy_bullets","pending_blasts","hazards","pickups","elapsed","wave_time","wave","xp","level","kills","build","upgrade_pending","boss_rewards","rewards"]:d[key]=clean(g.get(key))
	traces.append(d)
	for e in g.enemies:
		if e.boss:states[e.kind+"/"+e.ai_state+"/"+e.attack]=true
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode_id in ["arena","rooms"]:
		for kind in ["boss_warden","boss_core"]:
			g._title();g._select_mode(mode_id);g._start_run(874205);g.spawn_clock=999;g.weapon_clocks=[999.0]
			g.stats.hp=1000;g.stats.max_hp=1000
			g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height-24)
			var e:Dictionary=g._spawn_kind(kind,g.player_pos+Vector2(-150,-100))
			e.hp=e.max_hp*.4;e.cooldown_left=.01
			for step in range(400):
				if step in [60,120,240]:
					var b:Dictionary={"hit":[],"damage":1.0,"pierce":0,"life":1.0,"weapon":"rivet_gun"}
					g._hit_segment(b,e.pos-Vector2(1,0),e.pos+Vector2(1,0))
				if step==180:g.player_pos=Vector2(24,24)
				if step==300:g.player_pos=Vector2(g.config.arena.width-24,24)
				g._process(.025 if step%2==0 else .05)
				sample(g,mode_id,kind,step)
	var output:String=OS.get_cmdline_user_args()[0]
	var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify({"trace":traces,"observed_boss_states":states,"scope":"controlled fixed-step actual combat, primary hits, lower/upper boundary positions; no GUI claim"}));file.close()
	g.queue_free();await process_frame
	print("PASS: captured ",traces.size()," authority steps")
	quit()
