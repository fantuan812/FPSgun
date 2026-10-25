extends SceneTree
var traces:Array=[]
var g
func _initialize()->void:call_deferred("run")
func mark(label:String)->void:
	traces.append({"label":label,"state":g.state,"xp":g.xp,"level":g.level,"pending":g.upgrade_pending,"wave":g.wave,"build_levels":g.build.levels.duplicate(true),"focus":str(root.gui_get_focus_owner())})
func key(down:bool,echoed:bool=false)->void:
	var e:=InputEventKey.new();e.keycode=KEY_SPACE;e.physical_keycode=KEY_SPACE;e.pressed=down;e.echo=echoed
	root.push_input(e)
func run()->void:
	root.size=Vector2i(960,540)
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	g._select_mode("rooms");g._start_run(874205)
	for i in range(g.mode.planned_count):g._spawn_enemy()
	for e in g.enemies:e.hp=0
	g.weapon_clocks=[999.0];g.spawn_clock=999.0
	g._simulate(.001)
	while g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
	if g.state=="playing":g._simulate(.001)
	g.level=1;g.xp=g.Rules.xp_threshold(g.level)-1;g.pickups.clear();g.pickups.append({"pos":Vector2(100,100),"xp":2,"coins":0})
	mark("before settlement: threshold minus 1 XP plus 2 floor XP")
	for i in range(20):g._process(.05)
	mark("after settlement")
	while g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
	mark("after stage reward accepted, before Deploy")
	g._leave_shop(g.shop_generation);mark("immediate Deploy")
	g._process(.001);mark("first simulation frame after Deploy")
	# Controlled input propagation only, not an OS timing claim.
	g._title();g._start_run(874205);g.upgrade_pending=2
	await process_frame
	key(true);mark("Space down before modal")
	g._show_upgrades();await process_frame;await process_frame
	mark("modal focused with Space already held")
	key(true,true);await process_frame;mark("echo while held")
	key(false);await process_frame;mark("release of pre-modal Space")
	key(true);await process_frame;mark("fresh Space press")
	key(false);await process_frame;await process_frame;mark("fresh Space release")
	key(true,true);await process_frame;mark("echo on new modal without fresh press")
	key(false);await process_frame;mark("second release")
	print(JSON.stringify({"scope":"controlled headless input propagation and settlement ordering; not GUI or real OS key repeat", "trace":traces}))
	g.queue_free();await process_frame;quit()
