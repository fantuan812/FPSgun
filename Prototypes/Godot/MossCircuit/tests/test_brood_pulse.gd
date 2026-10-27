extends SceneTree
const Band=preload("res://scripts/gameplay/annulus_geometry.gd")
const AI=preload("res://scripts/enemy_ai.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
var passed:=0
var failures:Array=[]
var g
func ck(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={})->void:
	g._title();g._select_mode(mode);g._start_run(27001)
	g.build.items=items.duplicate(true);g._recompute()
	g.player_pos=Vector2(400,300);g.elapsed=10;g.stats.hp=100;g.stats.max_hp=100
	g.hurt_clock=0;g.spawn_clock=999;g.weapon_clocks=[999.0];g.combat_frame.area=g.config.arena
func keeper(pos:Vector2=Vector2(300,300))->Dictionary:
	var e:Dictionary=g._spawn_kind("brood_keeper",pos)
	e.cooldown_left=0
	return e
func tick(dt:float)->void:
	Motor.step(g.combat,g.config.arena,Vector2.ZERO,false,dt)
	g.elapsed+=dt;Runtime.step(g.combat_frame,dt)
func echoes()->Array:return g.effect_visuals.filter(func(v):return v.kind=="annulus_impact")
func run()->void:
	for angle in range(8):
		var center:=Vector2(451,327)
		for radius in [0.0,69.99,70.0,70.01,179.99,180.0,180.01]:
			var point:Vector2=center+Vector2.from_angle(angle*TAU/8)*radius
			ck(Band.contains(point,center,70,180)==(radius>=70 and radius<=180),"rotated band "+str(angle)+"/"+str(radius))
	for radii in [[0,180],[-1,180],[70,70],[180,70],[NAN,180],[70,INF]]:
		ck(not Band.contains(Vector2(100,0),Vector2.ZERO,radii[0],radii[1]),"invalid geometry")
	ck(not Band.contains(Vector2(INF,0),Vector2.ZERO,70,180),"nonfinite point")
	var quads:Array=Band.band_quads(Vector2.ZERO,70,180)
	ck(quads.size()==96,"bounded band tessellation")
	for quad in quads:
		ck(not Geometry2D.is_point_in_polygon(Vector2.ZERO,quad),"safe hole not filled")
		ck(is_equal_approx(quad[0].length(),70) and is_equal_approx(quad[1].length(),180),"shared rendering radii")
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode in ["arena","rooms"]:
		for radius in [0.0,69.99,70.0,70.01,179.99,180.0,180.01]:
			setup(mode);var e:Dictionary=keeper();tick(0)
			ck(e.attack=="annulus" and e.attack_index==1 and e.warning_left==1.0,mode+" natural pulse first")
			g.player_pos=e.pulse_center+Vector2(radius,0);tick(.5)
			ck(g.stats.hp==100 and echoes().is_empty(),mode+" no early damage")
			ck(is_equal_approx(g.actor_anim.actors[e.id].phase_progress,.5),mode+" one-second pose warning")
			tick(.5)
			ck(g.stats.hp==(89 if radius>=70 and radius<=180 else 100),mode+" actual band "+str(radius))
			ck(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7) and echoes().size()==1,mode+" one release recovery")
			ck(g.flashes.is_empty() and g.enemy_bullets.is_empty(),mode+" no filled blast or projectile")
			g._sync_telegraphs()
			var markers:Array=g.telegraphs.markers.filter(func(m):return m.kind=="annulus")
			ck(markers.size()==1 and markers[0].inner_radius==70 and markers[0].outer_radius==180,mode+" impact geometry preserved")
			tick(.21);ck(echoes().is_empty(),mode+" visual expires without repeat")
		setup(mode);var e:Dictionary=keeper(Vector2(20,20));g.player_pos=Vector2(30,30);tick(.05)
		ck(e.pulse_center==Vector2(20,20) and e.pos==Vector2(20,20),mode+" center locked after shared clamp")
		e.pos+=Vector2(90,90);g.player_pos=Vector2(120,20);tick(1.3)
		ck(e.pulse_center==Vector2(20,20) and g.stats.hp==89,mode+" displaced owner cannot drag band")
		ck(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7),mode+" overshoot no catch-up recovery")
		tick(.8);ck(e.ai_state=="move",mode+" later tick recovery completes")
		e.cooldown_left=0;tick(0)
		ck(e.attack=="summon" and e.attack_index==2 and is_equal_approx(e.warning_left,.65) and not e.has("warning_span"),mode+" next existing summon timing")
		tick(.65);ck(g.enemies.filter(func(c):return c.get("parent_id",-1)==e.id).size()==1,mode+" actual unchanged summon child")
		tick(.7);e.cooldown_left=0;tick(0);ck(e.attack=="annulus" and e.attack_index==3,mode+" alternating pulse again")
		for defense in ["dash_positive","dash_zero","hurt","mirror","feedback"]:
			setup(mode,{"mirror_shell":1} if defense=="mirror" else {"feedback_diode":1})
			e=keeper();tick(0);e.warning_left=.01
			if defense=="dash_positive":g.stats.dash_time=.011
			if defense=="dash_zero":g.stats.dash_time=.01
			if defense=="hurt":g.hurt_clock=.1
			if defense=="feedback":g.effects.feedback_armed=true;g.stats.dash_time=.1
			tick(.01)
			ck(g.stats.hp==(89 if defense=="dash_zero" else 100),mode+" inherited defense "+defense)
			if defense=="feedback":ck(g.effects.feedback_armed and e.hp==75,mode+" annulus cannot counter")
		setup(mode);e=keeper();tick(0);g._on_intent("pause",{});g._process(2)
		ck(e.warning_left==1 and e.attack_index==1 and echoes().is_empty(),mode+" paused warning/index")
		g._on_intent("resume",{});tick(0);ck(e.warning_left==1,mode+" zero delta preserves clock")
		e.hp=0;tick(2);ck(echoes().is_empty() and g.stats.hp==100,mode+" dead owner cancels unreleased pulse")
		setup(mode);e=keeper();tick(0);tick(1);g._title()
		ck(echoes().is_empty() and g.telegraphs.markers.is_empty(),mode+" title clears impact")
		g._start_run(27001);e=keeper();ck(e.attack_index==0,mode+" fresh actor resets phase")
		for won in [false,true]:
			setup(mode);e=keeper();tick(0);g._sync_telegraphs()
			ck(g.telegraphs.markers.any(func(m):return m.kind=="annulus"),mode+" live warning exists before result")
			g._finish(won);g._sync_telegraphs()
			ck(not g.telegraphs.markers.any(func(m):return m.kind=="annulus"),mode+" terminal cannot rebuild warning")
		await process_frame
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	ck(AI.validate(data).is_empty(),"valid encounter data")
	var keeper_index:int=-1
	for index in range(data.enemies.size()):
		if data.enemies[index].id=="brood_keeper":keeper_index=index
	for key in ["pulse_inner_radius","pulse_outer_radius","pulse_warning"]:
		for bad in [null,"70",true,{},[],0,-1,INF,NAN]:
			var modified:Dictionary=data.duplicate(true);modified.enemies[keeper_index][key]=bad
			ck(not AI.validate(modified).is_empty(),"invalid pulse field "+key+"/"+str(bad))
	var reversed:Dictionary=data.duplicate(true);reversed.enemies[keeper_index].pulse_inner_radius=180
	ck(not AI.validate(reversed).is_empty(),"closed or reversed annulus invalid")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("BROOD PULSE: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
