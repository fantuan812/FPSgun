extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
const FX=preload("res://scripts/effects.gd")
const AI=preload("res://scripts/enemy_ai.gd")
var checks:=0
var failures:Array=[]
var g
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func fresh(mode_id:String="arena",items:Dictionary={})->void:
	g._title();g._select_mode(mode_id);g._start_run(874205)
	g.build.weapons=["cryo_sprayer"];g.build.items=items.duplicate(true);g._recompute()
	quiet()
func quiet()->void:
	g.spawn_clock=999.0
	if g.mode.id=="rooms":g.mode.spawn_clock=999.0
	for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999.0
func enemy(offset:Vector2,kind:String="crawler",hp:float=100)->Dictionary:
	var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset);e.hp=hp;e.max_hp=hp;e.cooldown_left=999.0;return e
func hit(e:Dictionary,weapon:String="rivet_gun",damage:float=1)->void:
	g._hit_segment({"hit":[],"damage":damage,"pierce":0,"life":1.0,"weapon":weapon},e.pos,e.pos)
func _initialize()->void:call_deferred("run")
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	var catalog:Dictionary=g.catalog
	check(Rules.validate_catalog(catalog).is_empty(),"new catalog valid")
	var cryo:Dictionary=Rules.catalog_entry(catalog,"cryo_sprayer")
	var coil:Dictionary=Rules.catalog_entry(catalog,"fracture_coil")
	check(cryo.damage==9 and cryo.interval==.65 and cryo.range==190 and cryo.cone_degrees==60 and cryo.chill_duration==1.2 and cryo.chill_speed==.65,"frozen weapon tuning")
	check(coil.max_stack==1 and coil.fracture_damage==16 and coil.cooldown==0,"unique one-mark payoff tuning")
	for key in ["cone_degrees","chill_duration","chill_speed"]:
		for bad_value in [-1,0,"bad",true,INF,NAN]:
			var bad:Dictionary=catalog.duplicate(true);Rules.catalog_entry(bad,"cryo_sprayer")[key]=bad_value
			check(not Rules.validate_catalog(bad).is_empty(),"invalid cone field "+key+str(bad_value))
	for values in [["cone_degrees",181],["chill_duration",11],["chill_speed",1.1]]:
		var bad:Dictionary=catalog.duplicate(true);Rules.catalog_entry(bad,"cryo_sprayer")[values[0]]=values[1]
		check(not Rules.validate_catalog(bad).is_empty(),"bounded cone field "+values[0])
	for bad_value in [-1,0,"bad",true,INF,NAN,1001]:
		var bad:Dictionary=catalog.duplicate(true);Rules.catalog_entry(bad,"fracture_coil").fracture_damage=bad_value
		check(not Rules.validate_catalog(bad).is_empty(),"invalid fracture damage "+str(bad_value))
	for mode_id in ["arena","rooms"]:
		fresh(mode_id)
		var anchor:Dictionary=enemy(Vector2(100,0))
		var edge_a:Dictionary=enemy(Vector2.from_angle(PI/6)*190)
		var edge_b:Dictionary=enemy(Vector2.from_angle(-PI/6)*190)
		var far:Dictionary=enemy(Vector2(190.01,0))
		var outside:Dictionary=enemy(Vector2.from_angle(deg_to_rad(30.01))*180)
		var behind:Dictionary=enemy(Vector2(-120,0))
		var dead:Dictionary=enemy(Vector2(80,0),"crawler",0)
		var rngs:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
		g._fire_weapon("cryo_sprayer",0)
		for e in [anchor,edge_a,edge_b]:
			check(e.hp==91 and Status.chilled(e,g.elapsed),"inclusive cone primary+mark "+mode_id)
			check(e.chill_until==1.2 and e.chill_weapon=="cryo_sprayer","separate timed mark "+mode_id)
		for e in [far,outside,behind]:check(e.hp==100 and not e.has("chill_until"),"out-of-cone unchanged "+mode_id)
		check(dead.hp==0 and not dead.has("chill_until"),"dead target not hit "+mode_id)
		check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rngs,"no new RNG calls "+mode_id)
		check(g.bullets.is_empty() and g.pending_blasts.is_empty(),"cone is not projectile/mortar "+mode_id)
		check(g.effect_visuals[-1].pos==g.player_pos and g.effect_visuals[-1].radius==190 and is_equal_approx(g.effect_visuals[-1].half_angle,PI/6),"shared visual geometry "+mode_id)
		g.elapsed=.6;g._fire_weapon("cryo_sprayer",0)
		check(is_equal_approx(anchor.chill_until,1.8) and anchor.hp==82,"refresh replaces expiry, no stacks "+mode_id)
		g._on_intent("pause",{});g._process(5)
		check(g.elapsed==.6 and Status.chilled(anchor,g.elapsed),"menu freezes combat expiry "+mode_id)
		g._on_intent("resume",{});g.elapsed=anchor.chill_until
		check(not Status.chilled(anchor,g.elapsed) and Status.movement_factor(anchor,g.elapsed)==1,"exact expiry exclusive "+mode_id)
		fresh(mode_id)
		var left:Dictionary=enemy(Vector2(-100,0));var right:Dictionary=enemy(Vector2(100,0));g.enemies.reverse();g._fire_weapon("cryo_sprayer",0)
		check(left.hp==91 and right.hp==100,"equal-distance ID tie despite reversed container "+mode_id)
		fresh(mode_id);var center:Dictionary=enemy(Vector2.ZERO);var r:Dictionary=enemy(Vector2(100,0));var l:Dictionary=enemy(Vector2(-100,0));g.hero.flip_h=true;g._fire_weapon("cryo_sprayer",0)
		check(center.hp==91 and r.hp==91 and l.hp==100,"coincident target RIGHT fallback "+mode_id)
		fresh(mode_id);enemy(Vector2(300,0));g._fire_weapon("cryo_sprayer",0)
		check(g.effect_visuals.is_empty() and g.weapon_rig.last_shot.is_empty(),"no target means no emission "+mode_id)
		fresh(mode_id);var scaled:Dictionary=enemy(Vector2(210,0));g.stats.damage_bonus=.5;g.stats.range_bonus=.2;g.stats.electric_bonus=5;g.stats.melee_bonus=5;g.stats.extra_pellets=5;g.stats.pierce=5;g._fire_weapon("cryo_sprayer",0)
		check(scaled.hp==86.5 and g.effect_visuals[-1].radius==228,"only global damage and range modifiers "+mode_id)
		fresh(mode_id,{"fracture_coil":1})
		var target:Dictionary=enemy(Vector2(100,0));g._fire_weapon("cryo_sprayer",0);hit(target)
		check(target.hp==74 and not Status.chilled(target,g.elapsed) and target.last_source=="fracture","primary1 then one secondary16 consumes "+mode_id)
		hit(target);check(target.hp==73,"same mark cannot pay twice "+mode_id)
		g._fire_weapon("cryo_sprayer",0);g._fire_weapon("cryo_sprayer",0)
		check(target.hp==55 and Status.chilled(target,g.elapsed),"duplicate Cryo refreshes but never consumes "+mode_id)
		g.build.items.clear();g._recompute();hit(target)
		check(target.hp==54 and Status.chilled(target,g.elapsed),"removing coil disables consumption "+mode_id)
		g.build.items.fracture_coil=1;g._recompute();g.build.weapons=["rivet_gun"];g._recompute();hit(target)
		check(target.hp==37 and not Status.chilled(target,g.elapsed),"already applied mark survives Cryo unequip until consume "+mode_id)
		fresh(mode_id,{"fracture_coil":1});target=enemy(Vector2(100,0));target.slow_until=10;hit(target)
		check(target.hp==99 and not target.has("chill_until"),"legacy slow is not chill "+mode_id)
		fresh(mode_id,{"fracture_coil":1});target=enemy(Vector2(100,0));g._fire_weapon("cryo_sprayer",0);g.elapsed=1.2;hit(target)
		check(target.hp==90 and target.last_source=="primary","expired mark cannot fracture "+mode_id)
		fresh(mode_id,{"fracture_coil":1,"kill_cell":1});target=enemy(Vector2(100,0),"crawler",30);g._fire_weapon("cryo_sprayer",0);hit(target,"rivet_gun",6)
		check(target.hp==-1 and target.last_source=="fracture","secondary kill attribution "+mode_id)
		quiet();g._process(.001)
		check(g.kills==1 and g.pickups.size()==1 and g.pickups[0].get("source","")!="energy","secondary kill does not trigger Kill Cell "+mode_id)
		fresh(mode_id,{"fracture_coil":1});target=enemy(Vector2(100,0),"crawler",20);g._fire_weapon("cryo_sprayer",0);hit(target,"rivet_gun",11)
		check(target.hp==0 and target.last_source=="primary" and target.has("chill_until"),"primary lethal does not consume or shatter "+mode_id)
		fresh(mode_id,{"fracture_coil":1});target=enemy(Vector2(100,0),"crawler",9);g._fire_weapon("cryo_sprayer",0)
		check(target.hp==0 and not target.has("chill_until"),"Cryo lethal never marks "+mode_id)
		fresh(mode_id);target=enemy(Vector2(100,0));g._fire_weapon("cryo_sprayer",0)
		check(Status.movement_factor(target,0)==.65,"chill slow "+mode_id);target.slow_until=10
		check(Status.movement_factor(target,0)==.55,"stronger slow not multiplicative "+mode_id)
		var boss:Dictionary=enemy(Vector2(150,0),"boss_warden",500);g._fire_weapon("cryo_sprayer",0)
		check(Status.chilled(boss,0) and Status.movement_factor(boss,0)==1,"boss mark-only "+mode_id)
		var charge:Dictionary=enemy(Vector2(150,0),"charger");Status.apply_chill(charge,0,cryo);charge.ai_state="charging";charge.aim=Vector2.RIGHT;charge.charge_left=.5
		var control:Dictionary=charge.duplicate(true);var before:Vector2=charge.pos;charge.speed*=Status.movement_factor(charge,0);AI.tick(charge,g.player_pos,.1,0);AI.tick(control,g.player_pos,.1,0)
		check(charge.pos==control.pos and charge.charge_left==control.charge_left and is_equal_approx(charge.pos.x-before.x,31),"committed charge unaffected "+mode_id)
		g._title();g._start_run(874205)
		check(g.enemies.is_empty() and g.effect_visuals.is_empty() and g.build.weapons==["rivet_gun"],"status/presentation/build reset "+mode_id)
	for mode_id in ["arena","rooms"]:
		for orientation in range(8):
			fresh(mode_id)
			var direction:=Vector2.from_angle(orientation*TAU/8)
			var aim_target:Dictionary=enemy(direction*100)
			var boundary:Array=[]
			for side in [-1,0,1]:boundary.append(enemy(direction.rotated(side*PI/6)*190))
			var outer:Dictionary=enemy(direction*190.01)
			g._fire_weapon("cryo_sprayer",0)
			check(aim_target.hp==91,"rotated target "+mode_id+str(orientation))
			for target in boundary:check(target.hp==91,"rotated inclusive edge "+mode_id+str(orientation))
			check(outer.hp==100,"epsilon does not include0.01 beyond range "+mode_id+str(orientation))
	var fx=FX.new();fx.configure(catalog);fx.reset({"fracture_coil":1,"echo_chamber":1,"phase_capacitor":1});fx.echo_hits=4;fx.phase_charge=1
	var marked:Dictionary={"id":1,"hp":100,"pos":Vector2.ZERO,"chill_until":20,"chill_weapon":"cryo_sprayer","chill_speed":.65}
	var context:Dictionary={"time":10.0,"hp":100.0,"max_hp":100.0,"pos":Vector2.ZERO,"enemies":[marked],"damage":1.0}
	var event:Dictionary={"kind":"hit","epoch":fx.epoch,"sequence":1,"target":1,"pos":Vector2.ZERO,"weapon":"rivet_gun"}
	var commands:Array=fx.process(event,context)
	check(commands.map(func(c):return c.kind)==["fracture","echo","phase"],"new consume command precedes unchanged old hit order")
	check(fx.process(event,context).is_empty(),"duplicate event sequence rejected")
	var sequence:=2
	for bad in [{"source":"fracture","depth":1,"weapon":"rivet_gun"},{"source":"chain","depth":1,"weapon":"rivet_gun"},{"source":"primary","depth":1,"weapon":"rivet_gun"},{"source":"primary","depth":0,"weapon":"unknown"},{"source":"primary","depth":0,"weapon":""},{"source":"primary","depth":0,"weapon":"cryo_sprayer"}]:
		event.sequence=sequence;sequence+=1;event.merge(bad,true)
		check(not fx.process(event,context).any(func(c):return c.kind=="fracture"),"only recognized other primary weapon can consume "+str(bad))
	var build:Dictionary=Rules.new_build(catalog);build.coins=100;build.weapons=["cryo_sprayer"]
	var pool:Array=Rules.weighted_pool(build,catalog);var offer:Dictionary=pool.filter(func(e):return e.id=="fracture_coil")[0]
	check(is_equal_approx(offer.weight,3.85),"control tag + missing companion refresh weight")
	check(Rules.transaction(build,catalog,"fracture_coil")=="" and build.coins==72,"module purchase price")
	check(not Rules.transaction(build,catalog,"fracture_coil").is_empty() and build.coins==72,"unique duplicate rejected")
	check(not Rules.weighted_pool(build,catalog).any(func(e):return e.id=="fracture_coil"),"owned unique removed from pool")
	build.items.clear();build.weapons=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw"];build.coins=100
	check(Rules.transaction(build,catalog,"cryo_sprayer",2)=="" and build.coins==56 and build.weapons[2]=="cryo_sprayer","full-slot replacement exactly44")
	fresh("arena",{"fracture_coil":1})
	check(not g._view().synergy_status.filter(func(s):return s.name=="Cold Snap")[0].active,"Cryo+Coil alone honestly inactive")
	g.build.weapons=["cryo_sprayer","cryo_sprayer"];g._recompute()
	check(not g._view().synergy_status.filter(func(s):return s.name=="Cold Snap")[0].active,"duplicate Cryo is not different type prerequisite")
	g.build.weapons.append("rivet_gun");g._recompute()
	check(g._view().synergy_status.filter(func(s):return s.name=="Cold Snap")[0].active,"different type completes declared prerequisite")
	var durable:Dictionary=enemy(Vector2(100,0),"crawler",10000)
	for i in range(20):g._fire_weapon("cryo_sprayer",0);hit(durable)
	check(g.effect_visuals.filter(func(v):return v.kind=="cryo_cone").size()==4,"cone visuals bounded by four slots")
	check(g.effect_visuals.filter(func(v):return v.kind=="fracture").size()==8,"fracture visuals bounded independently")
	check(g.vfx.active.size()<=96,"new effects obey existing VFX cap")
	for id in ["cryo_sprayer","fracture_coil"]:check(g.ui.icon(id)!=null,"new icon present "+id)
	check(g.weapon_rig.assets.has("cryo_sprayer"),"dedicated world sprite present")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g._title();g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("CRYO_BUILD_CHECKS "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
