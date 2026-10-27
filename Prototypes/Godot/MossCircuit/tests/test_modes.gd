extends SceneTree
const Rooms=preload("res://scripts/modes/room_mode.gd")
const Flow=preload("res://scripts/gameplay/run_flow.gd")
var passed:=0
var failures:Array=[]
func check(value:bool,message:String)->void:
	if value:passed+=1
	else:failures.append(message)
func _initialize()->void:call_deferred("run_tests")
func run_tests()->void:
	var profile=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_encounters.json"))
	var encounter_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	for invalid in [NAN,INF,-INF,"x",{},[],true,null]:
		var bad:Dictionary=profile.duplicate(true);bad.field.tile_size=invalid
		check(not Rooms.validate(bad,encounter_data).is_empty(),"invalid tile type/finite rejected")
	var grid:Dictionary=profile.duplicate(true);grid.field={"width":64,"height":64,"tile_size":1}
	check(Rooms.validate(grid,encounter_data).is_empty(),"4096 cells accepted without allocation")
	grid.field.width=65
	check(not Rooms.validate(grid,encounter_data).is_empty(),"over cell budget rejected before allocation")
	grid.field.width=1e300
	check(not Rooms.validate(grid,encounter_data).is_empty(),"unrepresentable field quotient rejected")
	for invalid in [NAN,INF,-INF,"x",{},[],true,null]:
		var decision={"terminal":true,"next_stage":1,"shop":false,"upgrades":invalid,"coins":0,"heal":0}
		check(not Flow.validate_resolution(decision).is_empty(),"invalid settlement rejected without coercion crash")
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);await process_frame;g.set_process(false)
	check(g.mode.id=="arena","default survivor mode")
	check(not g._select_mode("unknown"),"unknown mode rejected")
	check(g._select_mode("rooms"),"title selects rooms")
	g._start_run(90210)
	check(g.mode.planned_count==3 and g.mode.planned_index==0,"finite plan initialized before first tick")
	check(g.config.arena.width==960 and g.config.arena.height==640,"mode field activated")
	check(not g._select_mode("arena"),"cannot switch an active run")
	g._complete_wave();check(g.state=="playing" and g.wave==1,"initial empty field cannot clear pending plan")
	g.spawn_clock=0;g._simulate(.01)
	check(g.enemies.size()==1 and g.mode.planned_index==1,"room spawns deterministic finite plan")
	g.wave_time=1000;g.spawn_clock=999;g._simulate(.01)
	check(g.state=="playing" and g.wave==1,"time does not clear room")
	var build_reference:Dictionary=g.build
	g.build.weapons=["return_disc","shock_mortar","rail_lance","orbit_saw"]
	g.build.items={"arc_relay":1,"return_spool":1};g._recompute()
	for stage in range(1,4):
		while g.mode.planned_index<g.mode.planned_count:g._spawn_enemy()
		var count:int=g.enemies.size();g._spawn_enemy()
		check(g.enemies.size()==count,"finite plan does not over-spawn stage "+str(stage))
		g.weapon_clocks=[999.0,999.0,999.0,999.0]
		for e in g.enemies:e.hp=0
		g._simulate(.01)
		while g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
		if g.state=="playing":g._simulate(.001)
		check(g.state=="room_clear","clear enters safe phase "+str(stage))
		check(g.bullets.is_empty() and g.enemy_bullets.is_empty() and g.hazards.is_empty() and g.pending_blasts.is_empty(),"clear phase clears all attacks")
		var before:float=g.mode.clear_elapsed
		g._on_intent("pause",{});g._process(.05)
		check(g.state=="paused" and g.mode.clear_elapsed==before,"pause freezes clear clock")
		g._resume();check(g.state=="room_clear","resume returns to clear phase")
		for i in range(13):g._process(.05)
		if stage<3:
			check(g.state=="upgrade" and g.wave==stage+1,"shared settlement advances room")
			var coins:int=g.build.coins
			g._complete_wave();check(g.build.coins==coins,"repeated settle cannot credit twice")
			while g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
			check(g.state=="shop","same shop between room stages")
			g._leave_shop(g.shop_generation)
			check(g.build.weapons==build_reference.weapons and g.build.items==build_reference.items,"build preserved between stages")
			check(g.mode.planned_index==0,"new room receives fresh plan")
		else:check(g.state=="won","third room wins")
	var old_generation:int=g.shop_generation
	g._title();check(g._select_mode("arena"),"return to survivor through title")
	g._start_run(90210)
	check(g.build.weapons==["rivet_gun"] and g.build.items.is_empty(),"new mode starts new run not cross-mode inventory leakage")
	check(not g._buy(0,old_generation),"old shop intent rejected after mode restart")
	check(g.combat.stats==g.stats and g.run.build==g.build,"scene accessors expose the sole state owners")
	for mode_id in ["arena","rooms"]:
		for weapon in ["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar"]:
			g._title();g._select_mode(mode_id);g._start_run(22)
			g.build.weapons=[weapon];g._recompute()
			var target:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(40,0))
			var hp:float=target.hp
			g._fire_weapon(weapon,0)
			var fired:bool=not g.bullets.is_empty()
			if weapon=="orbit_saw":fired=target.hp<hp
			if weapon=="shock_mortar":fired=g.pending_blasts.size()==1
			check(fired,"same combat fires "+weapon+" in "+mode_id)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v9 shared combat, finite mode and lifecycle"}))
	quit(0 if failures.is_empty() else 1)
