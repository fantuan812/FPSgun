extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func drain(g)->void:
	for n in range(20):
		if g.state!="upgrade":break
		g._take_upgrade(0,g.choice_generation)
func populate(g)->void:
	for n in range(g.mode.planned_count):g._spawn_enemy()
	g.weapon_clocks=[999.0]
	g.spawn_clock=999.0
func remove_via_combat(g)->void:
	for e in g.enemies:e.hp=0
	g._simulate(.001)
	drain(g)
	if g.state=="playing":g._simulate(.001)
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	g._select_mode("rooms");g._start_run(90210)
	g.build.items={"power_coil":2}
	g.build.levels={"speed":1}
	g._recompute()
	check(g.mode.planned_count==3 and g.mode.planned_index==0,"first HUD has three pending foes")
	var coins:int=g.build.coins
	g._complete_wave()
	check(g.wave==1 and g.state=="playing" and g.build.coins==coins,"empty initial array not room clear")
	populate(g)
	g.wave_time=300.0
	g._simulate(.001)
	check(g.wave==1 and g.state=="playing","long timer cannot bypass live room foes")
	var child:Dictionary=g._spawn_kind("crawler",Vector2(60,60),g.enemies[0].id)
	for e in g.enemies:
		if e.id!=child.id:e.hp=0
	g._simulate(.001);drain(g)
	check(g.state=="playing" and g.enemies.size()==1 and not g.mode.can_end(g.run,g.combat,g.encounters),"living summoned child blocks clear")
	# Create a genuine pending mortar before death cleanup.
	g._fire_weapon("shock_mortar",0)
	check(g.pending_blasts.size()==1,"real delayed mortar armed")
	remove_via_combat(g)
	check(g.state=="room_clear","death cleanup enters authority clear state")
	check(g.bullets.is_empty() and g.enemy_bullets.is_empty() and g.pending_blasts.is_empty() and g.hazards.is_empty(),"clear entry destroys delayed combat effects")
	coins=g.build.coins
	var elapsed:float=g.elapsed
	var progress:float=g.mode.clear_elapsed
	g._complete_wave();g._complete_wave()
	check(g.wave==1 and g.state=="room_clear" and g.build.coins==coins and g.mode.clear_elapsed==progress,"early duplicate completion neither pays nor resets timer")
	g._process(.05)
	progress=g.mode.clear_elapsed
	g._on_intent("pause",{})
	for n in range(20):g._process(.05)
	check(g.state=="paused" and g.mode.clear_elapsed==progress and g.elapsed==elapsed,"pause freezes clear timer and gameplay")
	g._on_intent("inventory",{});g._on_intent("close_inventory",{})
	g._on_intent("resume",{})
	check(g.state=="room_clear","pause inventory resume returns clear state")
	g._on_intent("inventory",{})
	for n in range(20):g._process(.05)
	g._on_intent("close_inventory",{})
	check(g.state=="room_clear" and g.mode.clear_elapsed==progress,"direct inventory freezes and restores clear")
	var build_items:Dictionary=g.build.items.duplicate(true)
	for n in range(15):g._process(.05)
	check(g.wave==2 and g.state=="upgrade" and g.elapsed==elapsed,"clear settles once without battle progression")
	var credited:int=g.build.coins
	g._complete_wave();g._complete_wave()
	check(g.wave==2 and g.build.coins==credited and g.build.items==build_items and g.build.items.get("power_coil",0)==2 and g.build.levels.get("speed",0)==1,"post-settlement callbacks cannot duplicate payout or reset build")
	drain(g)
	check(g.state=="shop","room reward flows to shared shop")
	var generation:int=g.shop_generation
	g._leave_shop(generation);g._leave_shop(generation)
	check(g.wave==2 and g.state=="playing" and g.mode.planned_index==0,"double shop continue does not double spawn/skip room")
	# Finish remaining rooms using real death cleanup; no private room counter manipulation.
	for expected in [2,3]:
		populate(g);remove_via_combat(g)
		check(g.state=="room_clear" and g.wave==expected,"room "+str(expected)+" clears finite roster")
		for n in range(15):g._process(.05)
		if expected==2:
			drain(g);g._leave_shop(g.shop_generation)
		else:check(g.state=="won" and g.wave==3,"third room is terminal victory without fourth shop")
	credited=g.build.coins
	for n in range(5):g._complete_wave();g._process(.05)
	check(g.state=="won" and g.build.coins==credited and g.enemies.is_empty() and g.enemy_bullets.is_empty(),"terminal residue cannot spawn or recredit")
	# Interrupt an active signal with title/start; stale transition cannot settle new room.
	g._title();g._start_run(90210);populate(g);remove_via_combat(g)
	g._process(.05);g._title();g._start_run(90210)
	g.weapon_clocks=[999.0]
	for n in range(20):g._process(.05)
	check(g.state=="playing" and g.wave==1 and g.mode.clear_elapsed==0 and g.build.coins==int(g.catalog.starting_coins),"title restart cancels stale clear timer and reward")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("INDEPENDENT ROOM BOUNDARIES: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
