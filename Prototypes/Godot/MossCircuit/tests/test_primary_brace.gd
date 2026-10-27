extends SceneTree
const Guard=preload("res://scripts/gameplay/primary_defense.gd")
const AI=preload("res://scripts/enemy_ai.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var checks:=0
var failures:Array=[]
var g
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func model()->Dictionary:
	return {"kind":"charger","behavior":"charge","boss":false,"hp":1000.0,"pos":Vector2(400,300),"aim":Vector2.RIGHT,"scale":1.2,"ai_state":"warning","attack":"charge","brace_degrees":120.0,"brace_multiplier":.5}
func setup(mode:String,weapon:String="rivet_gun")->Dictionary:
	g._title();g._select_mode(mode);g._start_run(32001)
	g.build.weapons=[weapon];g.build.items={};g._recompute()
	g.player_pos=Vector2(500,300);g.elapsed=10;g.spawn_clock=999;g.weapon_clocks=[999.0]
	g.combat_frame.area=g.config.arena
	var e:Dictionary=g._spawn_kind("charger",Vector2(400,300))
	e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0;e.cooldown_left=999
	e.ai_state="warning";e.attack="charge";e.aim=Vector2.RIGHT;e.warning_left=10.0
	return e
func bullet(id:String="rivet_gun",damage:float=15.0)->Dictionary:
	return {"pos":Vector2(500,300),"velocity":Vector2(-470,0),"life":2.0,"damage":damage,"pierce":4,"hit":[],"weapon":id,"slot":0,"returning":false}
func _initialize()->void:call_deferred("run")
func run()->void:
	var e:Dictionary=model()
	for angle in range(8):
		e.aim=Vector2.from_angle(TAU*angle/8)
		for degrees in [-180.0,-60.1,-60.0,0.0,60.0,60.1,180.0]:
			var toward:Vector2=e.aim.rotated(deg_to_rad(degrees));var origin:Vector2=e.pos+toward*100
			ck(is_equal_approx(Guard.resolve(e,15,origin,toward),7.5 if absf(degrees)<=60 else 15.0),"rotated front edge "+str(angle)+"/"+str(degrees))
		e.aim=Vector2.RIGHT
		ck(Guard.resolve(e,15,e.pos+Vector2(19.2,0),Vector2.RIGHT)==7.5,"body boundary directional")
		ck(Guard.resolve(e,15,e.pos+Vector2(19.19,0),Vector2.RIGHT)==15,"strict interior bypass")
		ck(Guard.resolve(e,15,e.pos,Vector2.ZERO)==15,"coincident origin full")
	for state in ["move","charging","recover"]:
		e=model();e.ai_state=state
		ck(Guard.brace(e).is_empty() and Guard.resolve(e,15,Vector2(500,300),Vector2.RIGHT)==15,"inactive "+state)
	for field in ["kind","behavior","boss","ai_state","attack","hp","scale","aim","pos","brace_degrees","brace_multiplier"]:
		for bad in [null,{},[],"wrong",true]:
			e=model();e[field]=bad
			ck(Guard.brace(e).is_empty(),"malformed runtime "+field+"/"+str(typeof(bad)))
	e=model();var saved:String=var_to_str(e)
	var description:Dictionary=Guard.brace(e);description.direction=Vector2.LEFT
	ck(var_to_str(e)==saved,"descriptor detached")
	ck(Guard.resolve(e,15,Vector2(INF,0),Vector2.RIGHT)==15 and Guard.resolve(e,15,Vector2(500,300),Vector2(NAN,0))==15,"nonfinite approach full")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	ck(AI.validate(data).is_empty(),"valid data")
	var index:int=-1
	for i in range(data.enemies.size()):
		if data.enemies[i].id=="charger":index=i
	ck(index>=0 and data.enemies[index].brace_degrees==120 and data.enemies[index].brace_multiplier==.5,"exact tuning")
	for field in ["brace_degrees","brace_multiplier"]:
		for bad in [null,true,false,".5",{},[],0,-1,NAN,INF]:
			var invalid:Dictionary=data.duplicate(true);invalid.enemies[index][field]=bad
			ck(not AI.validate(invalid).is_empty(),"data guard "+field+"/"+str(typeof(bad)))
		var missing:Dictionary=data.duplicate(true);missing.enemies[index].erase(field)
		ck(not AI.validate(missing).is_empty(),"paired field "+field)
	var legacy:Dictionary=data.duplicate(true);legacy.enemies[index].erase("brace_degrees");legacy.enemies[index].erase("brace_multiplier")
	ck(AI.validate(legacy).is_empty(),"legacy absent opt-in supported")
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode in ["arena","rooms"]:
		for id in ["rivet_gun","scrap_shotgun","rail_lance","return_disc"]:
			e=setup(mode,id);var nominal:float={"rivet_gun":15.0,"scrap_shotgun":9.0,"rail_lance":30.0,"return_disc":18.0}[id]
			var b:Dictionary=bullet(id,nominal);g._hit_segment(b,Vector2(500,300),Vector2(370,300))
			ck(is_equal_approx(e.hp,1000-nominal*.5) and b.damage==nominal and b.hit==[e.id],mode+" actual segment "+id)
		for id in ["orbit_saw","cryo_sprayer"]:
			e=setup(mode,id);g._fire_weapon(id,0)
			ck(is_equal_approx(e.hp,990.0 if id=="orbit_saw" else 995.5),mode+" immediate "+id)
		e=setup(mode,"bankshot_driver");g._fire_weapon("bankshot_driver",0)
		ck(g.bullets.size()==1,mode+" actual Bankshot launch")
		g.weapon_combat.advance_bankshot(g.bullets[0],.3)
		ck(e.hp==991 and g.bullets[0].damage==18,mode+" actual Bankshot guarded contact")
		e=setup(mode,"shock_mortar");g._fire_weapon("shock_mortar",0);g._update_mortars(.6)
		ck(e.hp==964,mode+" centered mortar bypass")
		e=setup(mode,"shock_mortar");g.pending_blasts=[{"pos":Vector2(470,300),"delay":0.0,"damage":36.0,"radius":85.0,"weapon":"shock_mortar"}];g._update_mortars(0)
		ck(e.hp==982,mode+" offcenter frontal mortar reduced")
		e=setup(mode);var other:Dictionary=g._spawn_kind("crawler",Vector2(350,300));other.hp=1000
		var shot:Dictionary=bullet();g._hit_segment(shot,Vector2(500,300),Vector2(300,300))
		ck(e.hp==992.5 and other.hp==985 and shot.damage==15 and shot.hit==[e.id,other.id],mode+" each pierced target independent")
		e=setup(mode);shot=bullet();g._hit_segment(shot,Vector2(410,300),Vector2(370,300))
		ck(e.hp==985,mode+" segment interior full")
		for entering in [false,true]:
			e=setup(mode,"orbit_saw");g.weapon_clocks=[0.0];g.bullets=[bullet()]
			if entering:e.ai_state="move";e.cooldown_left=0
			else:e.warning_left=.01
			Runtime.step(g.combat_frame,.3)
			ck(is_equal_approx(e.hp,972.5 if entering else 975.0),mode+" actual pre/post AI state "+str(entering))
		e=setup(mode);g._sync_telegraphs();var markers:Array=g.telegraphs.markers.filter(func(m):return m.kind=="brace")
		ck(markers.size()==1 and markers[0].direction==Vector2.RIGHT and is_equal_approx(markers[0].radius,38.4),mode+" indicator geometry")
		g.state="paused";g._process(1);ck(e.warning_left==10,mode+" paused warning unchanged")
		g.state="dead";g._sync_telegraphs();ck(not g.telegraphs.markers.any(func(m):return m.kind=="brace"),mode+" terminal no rebuilt brace")
		g._title();ck(g.telegraphs.markers.is_empty(),mode+" title cleanup")
		await process_frame
	print("Primary brace: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures:print("FAIL: "+str(failure))
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	quit(0 if failures.is_empty() else 1)
