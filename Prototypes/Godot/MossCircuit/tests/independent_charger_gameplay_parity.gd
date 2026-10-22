extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func setup(mode_id:String,legacy:bool):
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	g._select_mode(mode_id);g._start_run(66519)
	g.spawn_clock=999.0;g.weapon_clocks=[999.0]
	if legacy:
		g.actor_anim.config.profiles.erase("charger")
		for key in ["charger_charge","charger_hurt","charger_death"]:g.actor_anim.assets.erase(key)
	var e:Dictionary=g._spawn_kind("charger",g.player_pos+Vector2(-160,0))
	e.cooldown_left=.01
	return g
func snapshot(g)->Dictionary:
	var result:Dictionary={"hp":g.stats.hp,"pos":g.player_pos,"elapsed":g.elapsed,"wave_time":g.wave_time,"xp":g.xp,"level":g.level,"kills":g.kills,"coins":g.build.coins,"state":g.state,"rng":g.rng.state,"loot_rng":g.loot_rng.state,"shop_rng":g.shop_rng.state,"wave":g.wave,"pickups":g.pickups.duplicate(true),"enemies":[]}
	for e in g.enemies:
		var row:Dictionary={}
		for key in ["id","hp","pos","ai_state","aim","attack","attack_index","cooldown_left","warning_left","charge_left","recover_left"]:row[key]=e.get(key)
		result.enemies.append(row)
	return result
func run()->void:
	for mode_id in ["arena","rooms"]:
		var a=setup(mode_id,false)
		var b=setup(mode_id,true)
		check(a.actor_anim.config.profiles.has("charger") and not b.actor_anim.config.profiles.has("charger"),"comparison really has distinct visual profile "+mode_id)
		for step in range(180):
			if step in [5,22,35] and not a.enemies.is_empty():
				a.enemies[0].hp-=1;b.enemies[0].hp-=1
			if step==120:
				for e in a.enemies:e.hp=0
				for e in b.enemies:e.hp=0
			var dt:float=[.016,.049,.2,.8][step%4]
			a._process(dt);b._process(dt)
			check(snapshot(a)==snapshot(b),"art/fallback identical gameplay "+mode_id+" step "+str(step))
		check(a.kills==1 and b.kills==1,"one real charger death reward per mode "+mode_id)
		a._title();b._title()
		check(a.actor_anim.corpses.is_empty() and b.actor_anim.corpses.is_empty(),"title clears both authored/procedural corpse pools "+mode_id)
		a.queue_free();b.queue_free();await process_frame
	print("INDEPENDENT CHARGER PARITY: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
