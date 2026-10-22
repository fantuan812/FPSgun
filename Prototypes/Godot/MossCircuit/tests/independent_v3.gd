extends SceneTree
const AI = preload("res://scripts/enemy_ai.gd")
var passed := 0
var failures: Array = []
func check(v: bool,s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void: call_deferred("run")
func reset(g) -> void:
	g._start_run(50)
	g.spawn_clock = 999
	g.weapon_clocks = [999.0]
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	root.add_child(g)
	g.set_process(false)
	reset(g)
	var e: Dictionary = g._spawn_kind("crawler",g.player_pos + Vector2(100,0))
	var p: Vector2 = e.pos
	AI.tick(e,g.player_pos,.1,1)
	check(e.pos.distance_to(g.player_pos) < p.distance_to(g.player_pos),"crawler pursues")
	e = g._spawn_kind("flanker",g.player_pos + Vector2(200,0))
	p = e.pos
	AI.tick(e,g.player_pos,.1,1)
	check(absf(e.pos.y-p.y) > .1,"flanker lateral motion")
	e = g._spawn_kind("spitter",g.player_pos + Vector2(100,0))
	p = e.pos
	AI.tick(e,g.player_pos,.1,1)
	check(e.pos.distance_to(g.player_pos) > p.distance_to(g.player_pos),"spitter keeps distance")
	reset(g)
	e = g._spawn_kind("charger",g.player_pos)
	e.ai_state = "warning"
	e.attack = "charge"
	e.warning_left = .2
	e.aim = Vector2.RIGHT
	g._simulate(.1)
	check(g.stats.hp == 100 and e.ai_state == "warning","warning contact safe")
	e.ai_state = "recover"
	e.recover_left = .5
	g._simulate(.1)
	check(g.stats.hp == 100 and e.ai_state == "recover","recovery safe")
	e.ai_state = "charging"
	e.charge_left = .001
	e.aim = Vector2.RIGHT
	p = e.pos
	AI.tick(e,g.player_pos,.05,1)
	check(is_equal_approx(e.pos.distance_to(p),e.charge_speed*.001),"charge endpoint limited by remaining duration")
	reset(g)
	e = g._spawn_kind("spitter",g.player_pos + Vector2(100,0))
	e.ai_state = "warning"
	e.attack = "shot"
	e.aim = Vector2.LEFT
	e.warning_left = .01
	g._simulate(.02)
	check(g.enemy_bullets.size() == 1,"telegraphed shot releases")
	g.enemy_bullets[0].pos = g.player_pos + Vector2(1,0)
	g._simulate(.02)
	check(g.stats.hp < 100,"enemy projectile damages player")
	reset(g)
	e = g._spawn_kind("spitter",g.player_pos + Vector2(200,0))
	g.enemy_bullets = [{"pos":g.player_pos,"velocity":Vector2.ZERO,"life":0.0,"damage":90.0,"owner":e.id}]
	g._simulate(.02)
	check(g.stats.hp == 100 and g.enemy_bullets.is_empty(),"expired projectile harmless")
	reset(g)
	e = g._spawn_kind("brood_keeper",g.player_pos + Vector2(250,0))
	for i in range(10):
		e.ai_state = "warning"
		e.attack = "summon"
		e.warning_left = .001
		g._simulate(.01)
	var children: Array = g.enemies.filter(func(c):return c.parent_id == e.id)
	check(children.size() == int(e.summon_limit),"summon limit exact")
	reset(g)
	g.wave = 3
	g._ensure_boss()
	e = g.enemies.filter(func(c):return c.boss)[0]
	g.wave_time = 999
	g._complete_wave()
	check(g.wave == 3 and g.state == "playing" and g.enemies.has(e),"timer cannot clear living boss")
	e.hp = e.max_hp * .5
	AI.tick(e,g.player_pos,.01,1)
	check(e.phase == 2,"half hp enters phase2")
	var warning_before: float = e.warning_left
	var cooldown_before: float = e.cooldown_left
	var elapsed_before: float = g.elapsed
	g.state = "paused"
	g._process(1)
	check(e.warning_left == warning_before and e.cooldown_left == cooldown_before and g.elapsed == elapsed_before,"pause freezes enemy timers")
	g.state = "playing"
	g.upgrade_pending = 1
	g._show_upgrades()
	g._process(1)
	check(e.cooldown_left == cooldown_before,"upgrade freezes boss")
	g._take_upgrade(0,g.choice_generation)
	e.hp = 0
	var coins: int = g.build.coins
	g._boss_killed(e)
	var hp: float = g.stats.max_hp
	g._boss_killed(e)
	check(g.build.coins == coins+50 and g.rewards.size() == 1 and g.stats.max_hp == hp,"boss reward exactly once")
	g._open_shop()
	check(not g._sell_item("boss_protocol",g.shop_generation) and g.build.boss_protocol,"protocol cannot sell")
	reset(g)
	check(g.rewards.is_empty() and g.boss_rewards.is_empty() and not g.boss_spawned and not g.boss_defeated and g.enemy_bullets.is_empty(),"restart clears encounter state")
	g.wave = 6
	g._ensure_boss()
	e = g.enemies.filter(func(c):return c.boss)[0]
	e.hp = 0
	g._boss_killed(e)
	g.enemy_bullets = [{"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":10,"owner":999}]
	g._complete_wave()
	check(g.enemy_bullets.is_empty(),"victory clears all enemy projectiles")
	check(g.state == "won" and g.rewards.size() == 1,"final boss trophy and victory")
	g._hurt(1000)
	check(g.state == "won","victory cannot become death")
	g.queue_free()
	await process_frame
	print(JSON.stringify({"independent_v3_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
