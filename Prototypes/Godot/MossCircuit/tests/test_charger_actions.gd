extends SceneTree
const Director=preload("res://scripts/actor_director.gd")
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func run_checks()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(1010)
	g.spawn_clock=999;g.weapon_clocks=[999.0]
	var a=g.actor_anim
	for id in ["charger_charge","charger_hurt","charger_death"]:
		check(a.assets.has(id),"approved resource loaded: "+id)
		if not a.assets.has(id):continue
		var asset:Dictionary=a.assets[id]
		check(asset.frames.get_frame_count("action")==9,"nine actual frames "+id)
		check(not asset.frames.get_animation_loop("action"),"one-shot "+id)
		var canvas:Vector2=asset.frames.get_frame_texture("action",0).get_size()
		for i in range(9):check(asset.frames.get_frame_texture("action",i).get_size()==canvas,"fixed canvas "+id+str(i))
		if id=="charger_death":
			for i in range(2):
				var box:Array=asset.records[i].alpha_bbox
				check(is_equal_approx(float(box[1]+box[3]),float(asset.anchor[1])*canvas.y),"authored death contact keyframe aligns foot "+str(i))
	for bad in [null,{},[0],[0,9],[-1,3],[4,1],[0,NAN],[0,INF],[0,2.5],[true,3]]:
		check(not Director.valid_segment(bad),"reject bad frame segment")
	check(Director.valid_segment([0.0,3.0]),"JSON integral float range allowed")
	var e:Dictionary=g._spawn_kind("charger",g.player_pos+Vector2(220,0))
	var entry:Dictionary=a.actors[e.id]
	for state in ["warning","attack","recover"]:
		var segment:Array=a.config.profiles.charger.phase_frames[state]
		for step in range(11):
			a.set_phase(e.id,state,float(step)/10)
			if a.assets.has("charger_charge"):
				var expected:int=int(segment[0])+mini(int(segment[1]-segment[0]),floori(float(step)/10*(segment[1]-segment[0]+1)+.0000001))
				check(e.sprite.frame==expected,"phase mapped "+state+str(step))
			check(not a.trigger(e.id,"attack"),"contact feedback cannot restart phase")
	e.ai_state="warning";e.warning_left=e.warning*.5;e.aim=Vector2.RIGHT
	a.observe_enemy(e,"move",e.pos-Vector2(100,0))
	check(e.sprite.flip_h,"warning faces locked aim not player")
	e.aim=Vector2(0,1);a.observe_enemy(e,"warning",e.pos-Vector2(100,0))
	check(e.sprite.flip_h,"vertical aim preserves previous flip")
	a.trigger(e.id,"hurt")
	e.ai_state="charging";e.charge_left=e.charge_duration*.25;e.aim=Vector2.LEFT
	a.observe_enemy(e,"warning",e.pos+Vector2(100,0))
	check(a.state_of(e.id)=="hurt","hurt presentation overrides current phase")
	a.advance(.27)
	check(a.state_of(e.id)=="attack" and is_equal_approx(entry.phase_progress,.75),"hurt ends at current authoritative charge progress")
	if a.assets.has("charger_charge"):check(e.sprite.frame==6,"hurt does not replay expired windup")
	e.ai_state="recover";e.recover_left=.8;a.observe_enemy(e,"charging",g.player_pos)
	check(is_equal_approx(entry.recover_span,.8),"capture actual AI recovery duration")
	e.recover_left=.2;a.observe_enemy(e,"recover",g.player_pos)
	check(is_equal_approx(entry.phase_progress,.75),"recovery progress follows authoritative remaining time")
	if a.assets.has("charger_charge"):check(e.sprite.frame==8,"recovery uses last authored segment")
	var before:float=entry.walk_time
	g._on_intent("pause",{});g._process(.05)
	check(entry.walk_time==before,"paused action timers frozen")
	g._resume()
	e.hp=0;var kills:int=g.kills;g._simulate(.001)
	check(g.kills==kills+1 and a.state_of(e.id)=="death","death rewards immediate while body tail plays")
	g._simulate(.001);check(g.kills==kills+1,"corpse cannot duplicate kill reward")
	a.advance(.64)
	if a.assets.has("charger_death"):check(e.sprite.frame==8,"final death frame reached before reclamation")
	check(a.actors.has(e.id),"death last frame has time to display")
	a.advance(.081);check(not a.actors.has(e.id),"death one-shot reclaimed")
	g._title();g._select_mode("rooms");g._start_run(1010)
	check(a.actors.keys()==[0] and a.corpses.is_empty(),"new mode has no old body callbacks or corpses")
	g.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v10 authored charger phase presentation only"}))
	quit(0 if failures.is_empty() else 1)
