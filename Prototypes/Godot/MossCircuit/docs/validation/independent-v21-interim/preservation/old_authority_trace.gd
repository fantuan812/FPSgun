extends SceneTree
const CombatRuntime=preload("res://scripts/gameplay/combat_runtime.gd")
var traces:Array=[]
func _initialize()->void:call_deferred("run")
func n(value:float)->float:return snappedf(value,.000001)
func vec(value:Vector2)->Array:return [n(value.x),n(value.y)]
func clean(value):
	if value is Vector2:return vec(value)
	if value is float:return n(value)
	if value is Array:
		var a:Array=[]
		for x in value:a.append(clean(x))
		return a
	if value is Dictionary:
		var d:Dictionary={}
		var keys:Array=value.keys();keys.sort()
		for key in keys:d[key]=clean(value[key])
		return d
	return value
func snapshot(g)->Dictionary:
	var actors:Array=[]
	for e in g.enemies:
		var d:Dictionary={}
		for key in ["id","kind","pos","hp","phase","ai_state","aim","target","attack","attack_index","warning_left","charge_left","recover_left","cooldown_left","last_source","parent_id","slow_until"]:d[key]=clean(e.get(key,0.0 if key=="slow_until" else null))
		actors.append(d)
	return {"state":g.state,"time":n(g.elapsed),"hp":n(g.stats.hp),"kills":g.kills,"xp":g.xp,"coins":g.build.coins,"coin_fraction":n(g.build.coin_fraction),"player":vec(g.player_pos),"hurt_clock":n(g.hurt_clock),"enemies":actors,"bullets":clean(g.bullets),"enemy_bullets":clean(g.enemy_bullets),"pickups":clean(g.pickups),"pending_blasts":clean(g.pending_blasts),"hazards":clean(g.hazards),"weapon_clocks":clean(g.weapon_clocks),"effects":{"shield":g.effects.shield,"shield_spent":g.effects.shield_spent,"echo_hits":g.effects.echo_hits,"phase_charge":g.effects.phase_charge,"medic_damage":n(g.effects.medic_damage),"chain_charges":g.effects.chain_charges,"cooldowns":clean(g.effects.cooldowns)},"rng":str(g.rng.state),"loot_rng":str(g.loot_rng.state),"shop_rng":str(g.shop_rng.state),"rewards":clean(g.rewards)}
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	var loadouts:Array=[["rivet_gun","scrap_shotgun","rail_lance","orbit_saw"],["return_disc","shock_mortar","rivet_gun","rail_lance"]]
	var modules:Array=[["arc_relay","kill_cell","echo_chamber","phase_capacitor","pulse_boots","dash_resin","return_spool","blast_fuse"],["mirror_shell","thorn_crown","blood_valve","scrap_mine","gravity_anchor","medic_seed","power_coil","cooling_fan"],["iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear"]]
	for mode_id in ["arena","rooms"]:
		for loadout_index in range(loadouts.size()):
			for module_index in range(modules.size()):
				g._title();g._select_mode(mode_id);g._start_run(874205)
				g.build.weapons=loadouts[loadout_index].duplicate();g.build.items={}
				for id in modules[module_index]:g.build.items[id]=1
				g.build.revision+=1;g._recompute();g.stats.max_hp=100000.0;g.stats.hp=30000.0;g.spawn_clock=999.0
				var origin:Vector2=g.player_pos
				var kinds:Array=["crawler","charger","spitter","flanker","brood_keeper","boss_warden","boss_core"]
				for i in range(14):
					var e:Dictionary=g._spawn_kind(kinds[i%7],origin+Vector2.from_angle(float(i)*TAU/14.0)*(110.0+float(i%3)*35.0))
					if e.is_empty():push_error("fixture spawn missing "+str(kinds[i%7]));quit(1);return
					e.hp=600.0 if e.boss else 90.0;e.max_hp=e.hp;e.anim_hp=e.hp
					if e.boss and i>=7:e.hp*=.4
				var frames:Array=[]
				for step in range(240):
					g.elapsed+=.05;g.hurt_clock=maxf(0,g.hurt_clock-.05);g.stats.dash_time=maxf(0,g.stats.dash_time-.05)
					g.player_pos=origin+Vector2(sin(float(step)*.07),cos(float(step)*.07))*24.0
					if step in [0,80,160]:g._effect_event("dash",{"pos":g.player_pos,"angle":0.0})
					g.combat_frame.area=g.config.arena
					CombatRuntime.step(g.combat_frame,.05)
					g.actor_anim.advance(.05);g.vfx.advance(.05)
					frames.append(snapshot(g))
				var label:String=mode_id+"/weapons"+str(loadout_index)+"/modules"+str(module_index)
				traces.append({"case":label,"frames":frames});print("TRACE_CASE "+label+" "+str(frames.size()))
				await process_frame
	g._title();g.queue_free();await process_frame
	var report:Dictionary={"scope":"controlled shared-combat authority trace; old equipment only; 1e-6 float quantization; excludes intentional expanded shop draws and presentation","cases":traces,"steps_per_case":240,"dt":.05}
	FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(report))
	print("TRACE_COMPLETE "+str(traces.size())+" cases / "+str(traces.size()*240)+" steps")
	quit()
