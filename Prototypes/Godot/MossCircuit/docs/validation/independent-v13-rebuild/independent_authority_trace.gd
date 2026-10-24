extends SceneTree
# Intentionally external to the project: run identical source against restored v12 and candidate.
var traces:Dictionary={}
func _initialize()->void:call_deferred("run")
func clean(v:Variant)->Variant:
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
func props(o:Object)->Dictionary:
	var d:Dictionary={}
	for p in o.get_property_list():
		if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and not o.get(p.name) is Object:d[p.name]=clean(o.get(p.name))
	return d
func snapshot(g)->String:
	return JSON.stringify({"combat":props(g.combat),"run":props(g.run),"mode":props(g.mode),"rng":str(g.rng.state),"loot_rng":str(g.loot_rng.state),"shop_rng":str(g.shop_rng.state),"effect_sequence":g.effect_sequence}).sha256_text()
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var saved:Dictionary=g.actor_anim.assets.duplicate(true)
	for mode_id in ["arena","rooms"]:
		for seed_value in [71,240102,918273]:
			for fallback in [false,true]:
				g.free()
				g=load("res://scenes/main.tscn").instantiate()
				root.add_child(g);g.set_process(false)
				g._title();g._select_mode(mode_id);g._start_run(seed_value)
				g.actor_anim.assets=saved.duplicate(true)
				if fallback:
					for id in ["crawler_hurt","crawler_death","flanker_hurt","flanker_death"]:g.actor_anim.assets.erase(id)
				g.stats.hp=100000;g.stats.max_hp=100000
				var track:Array=[]
				# All archetypes run together: contact, shots, charges, summon, both boss phases.
				for entry in g.encounters.enemies:
					var e:Dictionary=g._spawn_kind(entry.id,g.player_pos+Vector2(60+30*track.size(),0))
					e.cooldown_left=0
					if e.boss:e.hp=e.max_hp*.4
					track.append(entry.id)
				var frames:Array=[]
				for i in range(900):
					if i==120:
						for e in g.enemies:
							if e.kind in ["crawler","flanker"]:e.hp-=1
					if i==180:
						for e in g.enemies:
							if e.kind in ["crawler","flanker"]:e.hp=0
					if g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
					g._process(.016)
					frames.append(snapshot(g))
				traces["%s/%s/fallback=%s"%[mode_id,seed_value,fallback]]={"frames":frames,"final":clean({"hp":g.stats.hp,"kills":g.kills,"state":g.state,"enemy_count":g.enemies.size(),"rng":str(g.rng.state),"loot_rng":str(g.loot_rng.state),"shop_rng":str(g.shop_rng.state)})}
	# Direct EnemyAI matrix captures every field and emitted event, independent of renderer.
	var AI=load("res://scripts/enemy_ai.gd")
	for entry in g.encounters.enemies:
		for phase2 in [false,true]:
			g._start_run(71)
			var e:Dictionary=g._spawn_kind(entry.id,Vector2(200,200))
			e.cooldown_left=0
			if phase2:e.hp=e.max_hp*.3
			var frames:Array=[]
			var t:=0.0
			for i in range(1200):
				var dt:float=[.001,.016,.033,.05][i%4]
				t+=dt
				var events:Array=AI.tick(e,Vector2(200+cos(t)*130,200+sin(t)*130),dt,t)
				frames.append(JSON.stringify({"enemy":clean(e),"events":clean(events)}).sha256_text())
			traces["AI/%s/phase2=%s"%[entry.id,phase2]]={"frames":frames}
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1:push_error("Pass output JSON after --");quit(2);return
	var f:=FileAccess.open(args[0],FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"Headless authoritative state traces; not GUI or Windows playtest","cases":traces},"\t"));f.close()
	g.queue_free();await process_frame
	print("INDEPENDENT_AUTHORITY_TRACE_WRITTEN cases=",traces.size())
	quit()
