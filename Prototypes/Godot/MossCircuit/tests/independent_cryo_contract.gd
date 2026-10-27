extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.001
func _initialize()->void:call_deferred("run")
func reset(mode_id:String,weapons:Array=["cryo_sprayer"],items:Dictionary={})->void:
	g._title();g._select_mode(mode_id);g._start_run(874205)
	g.build.weapons=weapons.duplicate();g.build.items=items.duplicate();g.build.revision+=1;g._recompute()
	g.elapsed=10.0;g.spawn_clock=999.0;g.stats.hp=10000.0;g.stats.max_hp=10000.0
	g.combat_frame.area=g.config.arena
	for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999.0
func spawn(offset:Vector2,hp:float=500.0,kind:String="crawler")->Dictionary:
	var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset);e.hp=hp;e.max_hp=hp;e.anim_hp=hp;return e
func marked(e:Dictionary)->bool:return float(e.get("chill_until",0.0))>g.elapsed and e.get("chill_weapon","")=="cryo_sprayer"
func hit(e:Dictionary,weapon:String="rivet_gun",damage:float=1.0,extra:Dictionary={})->void:
	var b:Dictionary={"hit":[],"damage":damage,"pierce":0,"life":1.0,"weapon":weapon};b.merge(extra,true);g._hit_segment(b,e.pos,e.pos)
func old_fire(id:String)->void:
	g._fire_weapon(id,1)
	if id=="shock_mortar":g._update_mortars(.6)
	elif id=="return_disc":
		for b in g.bullets:g._advance_disc(b,.4)
	elif id!="orbit_saw":
		for b in g.bullets:g._advance_bullet(b,.4)
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode_id in ["arena","rooms"]:
		for facing in [0.0,PI*.25,PI*.5,PI*.75,PI,PI*1.25,PI*1.5,PI*1.75]:
			reset(mode_id);var label:String=mode_id+"/angle"+str(facing)
			spawn(Vector2.from_angle(facing)*40.0)
			var rows:Array=[]
			for spec in [[150.0,0.0,true],[150.0,29.99,true],[150.0,-29.99,true],[150.0,30.0,true],[150.0,-30.0,true],[150.0,30.02,false],[150.0,-30.02,false],[150.0,180.0,false],[190.0,0.0,true],[190.02,0.0,false]]:
				rows.append({"enemy":spawn(Vector2.from_angle(facing+deg_to_rad(spec[1]))*spec[0]),"expected":spec[2],"spec":str(spec)})
			var rng:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state];g._fire_weapon("cryo_sprayer",0)
			for row in rows:
				check(near(row.enemy.hp,491.0 if row.expected else 500.0),label+" damage "+row.spec)
				check(marked(row.enemy)==row.expected,label+" mark "+row.spec)
			check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rng,label+" no RNG draws")
			var cone:Array=g.effect_visuals.filter(func(v):return v.kind=="cryo_cone")
			check(cone.size()==1 and cone[0].pos==g.player_pos and near(cone[0].radius,190.0),label+" authority visual geometry")
		reset(mode_id);var e:Dictionary=spawn(Vector2.ZERO);var behind:Dictionary=spawn(Vector2(-80,0));g._fire_weapon("cryo_sprayer",0)
		check(marked(e) and not marked(behind),mode_id+" coincident RIGHT fallback")
		reset(mode_id);var a:Dictionary=spawn(Vector2(70,0));var b:Dictionary=spawn(Vector2(-70,0));g.enemies.reverse();g._fire_weapon("cryo_sprayer",0)
		check(marked(a) and not marked(b),mode_id+" equal-distance ID tie independent of array order")
		reset(mode_id);e=spawn(Vector2(250,0));g._fire_weapon("cryo_sprayer",0)
		check(e.hp==500 and g.effect_visuals.is_empty(),mode_id+" out-of-range no fire")
		g.stats.range_bonus=1.0;g.stats.damage_bonus=.5;g._fire_weapon("cryo_sprayer",0)
		check(near(e.hp,486.5) and marked(e),mode_id+" global range/damage bonuses")
		reset(mode_id,["cryo_sprayer","cryo_sprayer"],{"fracture_coil":1});e=spawn(Vector2(90,0));g._fire_weapon("cryo_sprayer",0);g.elapsed=10.4;g._fire_weapon("cryo_sprayer",1)
		check(near(e.hp,482.0) and near(e.chill_until,11.6),mode_id+" duplicate Cryo refreshes never consumes")
		g._on_intent("pause",{});g._process(5.0);check(near(g.elapsed,10.4) and near(e.chill_until,11.6),mode_id+" menu freezes combat expiry");g._on_intent("resume",{})
		g.elapsed=11.6;hit(e);check(near(e.hp,481.0),mode_id+" exact expiry no fracture")
		for weapon in ["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar"]:
			reset(mode_id,["cryo_sprayer",weapon]);e=spawn(Vector2(90,0));g._fire_weapon("cryo_sprayer",0);old_fire(weapon);var plain:float=e.hp
			reset(mode_id,["cryo_sprayer",weapon],{"fracture_coil":1});e=spawn(Vector2(90,0));g._fire_weapon("cryo_sprayer",0);old_fire(weapon)
			check(near(e.hp,plain-16.0) and not marked(e),mode_id+" actual "+weapon+" path fractures once")
			var hp:float=e.hp;hit(e,weapon);check(near(e.hp,hp-1.0),mode_id+" consumed mark cannot repeat "+weapon)
		reset(mode_id,["cryo_sprayer","rivet_gun"],{"fracture_coil":1});e=spawn(Vector2(90,0));g._fire_weapon("cryo_sprayer",0);hit(e);g._fire_weapon("cryo_sprayer",0);hit(e)
		check(near(e.hp,448.0),mode_id+" no hidden ICD, fresh mark can immediately consume")
		for invalid_weapon in ["","unknown","cryo_sprayer"]:
			reset(mode_id,["cryo_sprayer"],{"fracture_coil":1});e=spawn(Vector2(90,0));g._fire_weapon("cryo_sprayer",0);hit(e,invalid_weapon)
			check(near(e.hp,490.0) and marked(e),mode_id+" non-consumer "+invalid_weapon)
		reset(mode_id,["cryo_sprayer"],{"fracture_coil":1});e=spawn(Vector2(90,0));e.slow_until=11.0;hit(e)
		check(near(e.hp,499.0) and not marked(e),mode_id+" resin is not a chill mark")
		g._fire_weapon("cryo_sprayer",0);var before:float=e.hp
		for source in ["chain","echo","phase","fracture","mine","trail","scorch"]:
			g._effect_event("hit",{"source":source,"depth":1,"weapon":"rivet_gun","target":e.id,"pos":e.pos,"damage":50.0})
		check(near(e.hp,before) and marked(e),mode_id+" secondary events never consume or recurse")
		g.build.items={};g._recompute();hit(e);check(near(e.hp,before-1.0) and marked(e),mode_id+" module removal disables consume but keeps mark")
		g.build.weapons=["rivet_gun"];g._recompute();check(marked(e),mode_id+" weapon removal keeps existing timed mark")
		for kind in ["crawler","boss_warden","boss_core"]:
			reset(mode_id);e=spawn(Vector2(100,0),500,kind);g._fire_weapon("cryo_sprayer",0)
			check(marked(e),mode_id+" boss/nonboss mark "+kind)
			if kind!="boss_core":
				var pos:Vector2=e.pos;var speed:float=e.speed;Runtime.step(g.combat_frame,.1)
				check(near(pos.distance_to(e.pos),speed*.1*(1.0 if e.boss else .65)),mode_id+" movement policy "+kind)
				check(e.speed==speed,mode_id+" base speed restored "+kind)
		reset(mode_id);e=spawn(Vector2(100,0));g._fire_weapon("cryo_sprayer",0);e.slow_until=11.0;var pos:Vector2=e.pos;var speed:float=e.speed;Runtime.step(g.combat_frame,.1)
		check(near(pos.distance_to(e.pos),speed*.1*.55),mode_id+" stronger slow wins without multiplication")
		for phase in ["warning","recover","charging"]:
			reset(mode_id);e=spawn(Vector2(100,0),500,"charger");g._fire_weapon("cryo_sprayer",0);e.ai_state=phase;e.warning_left=.5;e.recover_left=.5;e.charge_left=.5;e.aim=Vector2.RIGHT;pos=e.pos;Runtime.step(g.combat_frame,.1)
			check(near(pos.distance_to(e.pos),e.charge_speed*.1 if phase=="charging" else 0.0),mode_id+" committed geometry "+phase)
			check(near(e["charge_left" if phase=="charging" else ("warning_left" if phase=="warning" else "recover_left")],.4),mode_id+" clock unchanged "+phase)
		reset(mode_id,["cryo_sprayer","rivet_gun"],{"fracture_coil":1,"kill_cell":1,"echo_chamber":1});e=spawn(Vector2(100,0),29.0);g._fire_weapon("cryo_sprayer",0);g.effects.echo_hits=4;hit(e,"rivet_gun",5.0)
		check(e.hp<=0 and e.last_source=="fracture" and g.effects.echo_hits==0,mode_id+" primary then fracture then old echo order")
		Runtime.step(g.combat_frame,0.0);check(g.kills==1 and not g.pickups.any(func(p):return p.get("source","")=="energy"),mode_id+" fracture kill never Kill Cell proc")
		reset(mode_id,["cryo_sprayer","rivet_gun"],{"fracture_coil":1,"kill_cell":1});e=spawn(Vector2(100,0),14.0);g._fire_weapon("cryo_sprayer",0);hit(e,"rivet_gun",5.0)
		check(e.hp==0 and e.last_source=="primary",mode_id+" primary lethal not reclassified")
		Runtime.step(g.combat_frame,0.0);check(g.pickups.any(func(p):return p.get("source","")=="energy"),mode_id+" primary lethal preserves old Kill Cell")
		reset(mode_id);e=spawn(Vector2(100,0),9.0);g._fire_weapon("cryo_sprayer",0);check(e.hp==0 and not e.has("chill_until"),mode_id+" lethal Cryo applies no mark")
		g._title();g._start_run(874205);check(g.enemies.is_empty() and g.effect_visuals.is_empty(),mode_id+" run reset clears targets and feedback")
		await process_frame
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"independent controlled source integration contract; both modes, geometry, six old primary routes, status and proc ordering; not GUI"}
	var outputs:PackedStringArray=OS.get_cmdline_user_args()
	if not outputs.is_empty():FileAccess.open(outputs[0],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
