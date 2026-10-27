extends SceneTree
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void: call_deferred("run")
func reset(g,items: Dictionary = {}) -> void:
	g._start_run(50)
	g.spawn_clock = 999
	g.weapon_clocks = [999.0]
	g.build.items = items.duplicate(true)
	g._recompute()
func enemy(g,offset: Vector2) -> Dictionary:
	var e: Dictionary = g._spawn_kind("crawler",g.player_pos+offset)
	e.hp = 100
	e.max_hp = 100
	return e
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	reset(g,{"arc_relay":1})
	var a: Dictionary = enemy(g,Vector2(100,0))
	var b: Dictionary = enemy(g,Vector2(120,0))
	var c: Dictionary = enemy(g,Vector2(140,0))
	var d: Dictionary = enemy(g,Vector2(160,0))
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20.0})
	check(a.hp == 100 and b.hp == 92 and c.hp == 92 and d.hp == 100,"chain excludes primary exactly2 nearest")
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20.0})
	check(b.hp == 92,"chain ICD")
	g.elapsed += .7
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20.0,"source":"chain","depth":1})
	check(b.hp == 92,"secondary hit cannot chain recursively")
	g.build.items.kill_cell = 1
	g._recompute()
	for i in range(10): g._effect_event("pickup",{"source":"energy","pos":g.player_pos})
	check(g.effects.chain_charges == 3,"energy pair capped3")
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20.0})
	check(d.hp == 92 and g.effects.chain_charges == 2,"charged chain expands targets and spends charge")
	g.build.items.erase("kill_cell")
	g._recompute()
	check(g.effects.chain_charges == 0,"removing pair removes charges")
	reset(g,{"kill_cell":1})
	a = enemy(g,Vector2(200,0))
	a.hp = 0
	a.last_source = "primary"
	g._simulate(.01)
	var energy: Array = g.pickups.filter(func(p):return p.get("source","") == "energy")
	check(g.kills == 1 and energy.size() == 1,"primary death emits exactlyone orb")
	g._simulate(.01)
	check(g.kills == 1 and g.pickups.filter(func(p):return p.get("source","") == "energy").size() == 1,"removed dead cannot repeat kill")
	reset(g,{"kill_cell":1})
	a = enemy(g,Vector2(200,0)); a.hp = 0; a.last_source = "chain"
	g._simulate(.01)
	check(g.pickups.filter(func(p):return p.get("source","") == "energy").is_empty(),"secondary kills no orb recursion")
	reset(g,{"mirror_shell":1,"thorn_crown":1})
	a = enemy(g,Vector2(60,0))
	g._hurt(9)
	check(g.stats.hp == 100 and g.effects.shield == 0 and a.hp == 82,"shield block retaliates only with pair")
	g.build.items.erase("mirror_shell");g._recompute()
	g.build.items.mirror_shell = 1;g._recompute()
	check(g.effects.shield == 0,"remove rebuy cannot recharge spent shield")
	g.hurt_clock = 0;g.elapsed += 1.1;g._hurt(9)
	check(g.stats.hp == 91 and a.hp == 64,"unblocked hurt thorns")
	reset(g,{"mirror_shell":1})
	a = enemy(g,Vector2(60,0));g._hurt(9)
	check(a.hp == 100,"shield without thorns no retaliation")
	reset(g,{"blood_valve":1})
	g.stats.hp = 39
	g._effect_event("hit",{"target":1,"pos":g.player_pos})
	check(g.stats.hp == 42,"lowhp primary hit heals3")
	g.stats.hp = 30;g._effect_event("hit",{"target":1,"pos":g.player_pos})
	check(g.stats.hp == 30,"lifesteal ICD")
	g.elapsed += 2;g._effect_event("hit",{"target":1,"pos":g.player_pos,"source":"mine","depth":1})
	check(g.stats.hp == 30,"secondary no generic lifesteal")
	reset(g,{"scrap_mine":1,"blood_valve":1})
	g.stats.hp = 50
	a = enemy(g,Vector2(100,0));a.hp = 20
	g._effect_event("pickup",{"pos":a.pos})
	g._update_hazards(.29)
	check(a.hp == 20,"mine arming delay")
	g._update_hazards(.02)
	check(a.hp <= 0 and g.hazards.is_empty(),"mine detonates once")
	g._simulate(.01)
	check(g.stats.hp == 55,"minekill pair heals5")
	reset(g,{"dash_resin":1,"pulse_boots":1})
	a = enemy(g,Vector2(60,0))
	g._effect_event("dash",{"pos":g.player_pos})
	check(is_equal_approx(a.pos.distance_to(g.player_pos),150),"pulse pushes90")
	a.pos = g.player_pos
	g._update_hazards(.01)
	check(a.hp == 92 and a.slow_until > g.elapsed,"resin pair damage and slow")
	g._update_hazards(.01)
	check(a.hp == 92,"zone tick interval")
	g.build.items.erase("pulse_boots");g._recompute()
	check(a.slow_until == 0 and not g.hazards[0].slow,"pair removal clears slow")
	var life: float = g.hazards[0].life
	g._on_intent("pause",{})
	g._process(1)
	check(g.hazards.size() == 1 and is_equal_approx(g.hazards[0].life,life),"pause preserves and freezes hazard")
	g._resume()
	g.build.items.erase("dash_resin");g._recompute()
	check(g.hazards.is_empty(),"selling resin removes zones")
	reset(g,{"scrap_mine":1})
	for i in range(10):
		g.elapsed += 1.1
		g._effect_event("pickup",{"pos":g.player_pos})
	check(g.hazards.size() == 4,"mine cap4")
	reset(g,{"dash_resin":1})
	for i in range(10):g._effect_event("dash",{"pos":g.player_pos})
	check(g.hazards.size() == 3,"trail cap3")
	reset(g)
	check(g.hazards.is_empty() and g.effects.chain_charges == 0 and g.effects.cooldowns.is_empty() and g.effects.shield == 0,"new run clears mechanics")
	reset(g,{"arc_relay":1})
	a = enemy(g,Vector2(100,0))
	var boss: Dictionary = g._spawn_kind("boss_warden",g.player_pos+Vector2(130,0))
	var boss_hp: float = boss.hp
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"damage":20.0})
	check(boss.hp == boss_hp-8,"chain damages correct boss identity")
	var old_epoch: int = g.effects.epoch
	g._on_intent("pause",{})
	var rejected: Array = g.effects.process({"kind":"pickup","epoch":old_epoch,"sequence":999,"source":"energy"},{"time":g.elapsed,"enemies":[],"damage":15,"hp":100,"max_hp":100,"pos":g.player_pos})
	check(rejected.is_empty() and g.effects.chain_charges == 0,"prepause stale event rejected")
	reset(g,{"scrap_mine":1})
	g._effect_event("pickup",{"pos":g.player_pos})
	g._open_shop()
	check(g._sell_item("scrap_mine",g.shop_generation) and g.hazards.is_empty() and not g.effects.active.has("scrap_mine"),"real sale removes hazard and active mechanic")
	reset(g,{"blood_valve":1})
	g.stats.hp = 40
	g._effect_event("hit",{"target":1,"pos":g.player_pos})
	check(g.stats.hp == 40,"exact40percent not lowhp")
	g.stats.hp = 30
	g._effect_event("kill",{"source":"mine","depth":1,"pos":g.player_pos})
	check(g.stats.hp == 30,"mine lifesteal requires both items")
	reset(g,{"arc_relay":1,"kill_cell":1})
	a = enemy(g,Vector2(30,0));a.hp = 1
	b = enemy(g,Vector2(40,0));b.hp = 1
	for weapon in g.catalog.weapons:
		if weapon.behavior == "orbit": g._fire_weapon(weapon.id,0)
	check(b.last_source == "chain","chain killed target not reattributed by orbit")
	g._simulate(.01)
	check(g.pickups.filter(func(p):return p.get("source","") == "energy").size() == 1,"orbit chain kills only one primary orb")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free()
	await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_v4_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
