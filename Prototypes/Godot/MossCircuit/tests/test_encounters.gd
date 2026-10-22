extends SceneTree
const AI = preload("res://scripts/enemy_ai.gd")
var passed := 0
var failures: Array = []
func check(value: bool,label: String) -> void:
	if value: passed += 1
	else: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	check(AI.validate(game.encounters).is_empty(),"encounter schema valid")
	check(not AI.validate({}).is_empty(),"invalid encounter rejected")
	var bad: Dictionary = game.encounters.duplicate(true)
	bad.enemies[0].warning = 0
	check(not AI.validate(bad).is_empty(),"zero telegraph rejected")
	game._start_run(71)
	var p: Vector2 = game.player_pos
	var charger: Dictionary = game._spawn_kind("charger",p + Vector2(200,0))
	charger.cooldown_left = 0
	AI.tick(charger,p,.01,0)
	check(charger.ai_state == "warning", "charge warns")
	var pos: Vector2 = charger.pos
	var locked: Vector2 = charger.aim
	AI.tick(charger,p + Vector2(0,100),.2,0)
	check(charger.pos == pos and charger.aim == locked,"warning stationary and locked aim")
	AI.tick(charger,p,.6,0)
	check(charger.ai_state == "charging","warning transitions charge")
	AI.tick(charger,p,.2,0)
	check(charger.pos != pos,"charge moves")
	AI.tick(charger,p,1,0)
	check(charger.ai_state == "recover","charge recovery safety window")
	charger.ai_state = "charging"
	charger.charge_left = .001
	pos = charger.pos
	AI.tick(charger,p,.05,0)
	check(is_equal_approx(charger.pos.distance_to(pos),charger.charge_speed * .001),"charge respects warned endpoint")
	var spitter: Dictionary = game._spawn_kind("spitter",p+Vector2(100,0))
	var before: float = spitter.pos.distance_to(p)
	AI.tick(spitter,p,.1,0)
	check(spitter.pos.distance_to(p) > before,"ranged retreats when close")
	spitter.cooldown_left = 0
	AI.tick(spitter,p,.01,0)
	var events: Array = AI.tick(spitter,p,1,0)
	check(events.size() == 1 and events[0].kind == "shot","ranged warning emits shot")
	var flank: Dictionary = game._spawn_kind("flanker",p+Vector2(100,0))
	var y: float = flank.pos.y
	AI.tick(flank,p,.1,.5)
	check(not is_equal_approx(flank.pos.y,y),"flanker lateral movement")
	var keeper: Dictionary = game._spawn_kind("brood_keeper",p+Vector2(240,0))
	keeper.cooldown_left = 0
	AI.tick(keeper,p,.01,0)
	events = AI.tick(keeper,p,1,0)
	check(events.size() == 1 and events[0].kind == "summon","summoner delayed event")
	keeper.hp = 0
	check(AI.tick(keeper,p,10,0).is_empty(),"dead enemy emits nothing")
	for kind in ["boss_warden","boss_core"]:
		var boss: Dictionary = game._spawn_kind(kind,p+Vector2(350,0))
		boss.hp = boss.max_hp * .5
		AI.tick(boss,p,.01,0)
		check(boss.phase == 2,"boss second phase " + kind)
	game._start_run(72)
	game.wave = 3
	game.wave_time = 999
	game._complete_wave()
	check(game.wave == 3 and game.boss_spawned and game.state == "playing","timer cannot erase live boss")
	var boss: Dictionary = game.enemies.filter(func(e): return e.boss)[0]
	game._boss_killed(boss)
	check(game.rewards.is_empty(),"alive boss cannot grant reward")
	boss.hp = 0
	game._boss_killed(boss)
	var coins: int = game.build.coins
	var max_hp: float = game.stats.max_hp
	game._boss_killed(boss)
	check(game.rewards.size() == 1 and game.build.coins == coins,"reward once")
	check(max_hp == 125 and game.stats.damage > 15,"midboss reward changes build")
	game._complete_wave()
	check(game.wave == 4 and game.state == "upgrade","boss kill unlocks next wave")
	game._start_run(72)
	check(game.rewards.is_empty() and not game.build.get("boss_protocol",false),"new run clears boss rewards")
	game.wave = 6
	game._ensure_boss()
	boss = game.enemies.filter(func(e): return e.boss)[0]
	game.stats.hp = 1
	game._hurt(999)
	boss.hp = 0
	game._boss_killed(boss)
	game._complete_wave()
	check(game.state == "dead" and game.rewards.is_empty(),"death not overridden by late victory/reward")
	game._start_run(72)
	var owner: Dictionary = game._spawn_kind("spitter",game.player_pos+Vector2(300,0))
	game.enemy_bullets.append({"pos":game.player_pos,"velocity":Vector2.ZERO,"life":0.0,"damage":99,"owner":owner.id})
	game._simulate(.01)
	check(game.stats.hp == 100,"expired enemy projectile does not hit")
	game.enemy_bullets.append({"pos":game.player_pos,"velocity":Vector2.ZERO,"life":3.0,"damage":99,"owner":owner.id})
	owner.hp = 0
	game._simulate(.01)
	check(game.stats.hp == 100,"dead owner projectiles removed before hit")
	game.queue_free()
	await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"enemy telegraph, phase, boss gate/reward headless"}))
	quit(0 if failures.is_empty() else 1)
