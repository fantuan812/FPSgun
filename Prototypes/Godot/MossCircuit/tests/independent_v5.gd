extends SceneTree
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void:call_deferred("run")
func reset(g,items: Dictionary = {}) -> void:
	g._start_run(50);g.spawn_clock = 999;g.weapon_clocks = [999.0]
	g.build.items = items.duplicate(true);g._recompute()
func enemy(g,offset: Vector2) -> Dictionary:
	var e: Dictionary = g._spawn_kind("crawler",g.player_pos+offset)
	e.hp = 1000;e.max_hp = 1000;e.speed = 0
	return e
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	reset(g,{"return_spool":1})
	var a: Dictionary = enemy(g,Vector2(150,0))
	g.stats.hp = 50
	g._fire_weapon("return_disc",0)
	check(g.bullets.size() == 1 and g.bullets[0].weapon == "return_disc","return disc real projectile")
	for i in range(110):g._simulate(.016)
	check(a.hp == 964,"disc hits once per leg exactly twice")
	check(g.stats.hp == 51,"only return leg heals once")
	reset(g,{"return_spool":1})
	g.stats.hp = 50
	g._effect_event("hit",{"target":1,"pos":g.player_pos,"weapon":"return_disc","returning":true})
	g._effect_event("hit",{"target":1,"pos":g.player_pos,"weapon":"return_disc","returning":true})
	check(g.stats.hp == 51,"spool .6 ICD")
	g.elapsed += .7
	g._effect_event("hit",{"target":1,"pos":g.player_pos,"weapon":"return_disc","returning":true,"source":"chain","depth":1})
	check(g.stats.hp == 51,"spool no secondary heal")
	reset(g,{"blast_fuse":1})
	a = enemy(g,Vector2(150,0))
	g._fire_weapon("shock_mortar",0)
	check(g.bullets.is_empty() and g.pending_blasts.size() == 1,"mortar pending rather than straight bullet")
	var target: Vector2 = g.pending_blasts[0].pos
	a.pos += Vector2(200,0)
	g._update_mortars(.59)
	check(g.pending_blasts.size() == 1 and a.hp == 1000,"mortar respects delay")
	g._update_mortars(.02)
	check(a.hp == 1000 and g.pending_blasts.is_empty() and g.hazards.size() == 1 and g.hazards[0].pos == target,"fixed mortar does not track moved target and creates scorch")
	a.pos = target
	g._update_hazards(.01)
	check(a.hp == 994,"scorch6 damage")
	g._update_hazards(.01)
	check(a.hp == 994,"scorch tick ICD")
	reset(g,{"echo_chamber":1})
	a = enemy(g,Vector2(100,0))
	for i in range(4):g._effect_event("hit",{"target":a.id,"pos":a.pos})
	check(a.hp == 1000 and g.effects.echo_hits == 4,"echo no early proc")
	g._effect_event("hit",{"target":a.id,"pos":a.pos})
	check(a.hp == 988 and g.effects.echo_hits == 0,"fifth primary targeted12")
	g._effect_event("hit",{"target":a.id,"pos":a.pos,"source":"echo","depth":1})
	check(g.effects.echo_hits == 0,"echo cannot count itself")
	reset(g,{"phase_capacitor":1})
	a = enemy(g,Vector2(100,0))
	var b: Dictionary = enemy(g,Vector2(130,0))
	for i in range(3):g._effect_event("dash",{"pos":g.player_pos})
	check(g.effects.phase_charge == 1,"phase charge cap1")
	g._effect_event("hit",{"target":a.id,"pos":a.pos})
	check(a.hp == 988 and b.hp == 988 and g.effects.phase_charge == 0,"phase splash real targets and spend")
	reset(g,{"medic_seed":1,"scrap_mine":1})
	g._hurt(29)
	check(g.pickups.is_empty() and g.effects.medic_damage == 29,"medic threshold not early")
	g.hurt_clock = 0;g._hurt(1)
	check(g.pickups.size() == 1 and g.pickups[0].source == "medical" and g.effects.medic_damage == 0,"actual30 drops medical")
	g.pickups[0].pos = g.player_pos
	g._simulate(.01)
	check(g.stats.hp == 78 and g.hazards.is_empty(),"medical heals8 no scrap-mine trigger")
	reset(g,{"mirror_shell":1,"medic_seed":1})
	g._hurt(100)
	check(g.effects.medic_damage == 0 and g.pickups.is_empty(),"blocked damage not actual damage")
	reset(g,{"gravity_anchor":1,"scrap_mine":1})
	a = enemy(g,Vector2(50,0));b = enemy(g,Vector2(120,0))
	g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
	g._update_hazards(.31)
	check(is_equal_approx(b.pos.distance_to(g.player_pos),60),"mine trigger pulls nearby living enemy60")
	check(a.hp == 976 and b.hp == 1000,"pull does not itself damage")
	g._start_run(1)
	check(g.pending_blasts.is_empty() and g.effects.echo_hits == 0 and g.effects.phase_charge == 0 and g.effects.medic_damage == 0,"restart clears new counters")
	reset(g)
	var disc := {"pos":g.player_pos+Vector2(100,0),"velocity":Vector2(g.stats.bullet_speed,0),"life":1.0,"outbound_left":.001,"returning":false,"hit":[],"damage":18.0,"pierce":99,"weapon":"return_disc"}
	g._advance_disc(disc,.05)
	check(is_equal_approx(disc.pos.x,g.player_pos.x+100+g.stats.bullet_speed*.001-g.stats.bullet_speed*.049),"disc boundary splits outbound and return distance")
	check(disc.returning and is_equal_approx(disc.life,.95),"disc split consumes exact total time")
	reset(g,{"echo_chamber":1,"phase_capacitor":1,"medic_seed":1})
	g.effects.echo_hits = 4;g.effects.phase_charge = 1;g.effects.medic_damage = 29
	g.build.items.clear();g._recompute()
	check(g.effects.echo_hits == 0 and g.effects.phase_charge == 0 and g.effects.medic_damage == 0,"item removal clears new accumulators")
	reset(g)
	a = enemy(g,Vector2(150,0));g._fire_weapon("shock_mortar",0)
	var delay: float = g.pending_blasts[0].delay
	g._on_intent("pause",{});g._process(1)
	check(g.pending_blasts.size() == 1 and g.pending_blasts[0].delay == delay,"pause freezes pending mortar")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_v5_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
