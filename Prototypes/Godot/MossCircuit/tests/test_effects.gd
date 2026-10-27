extends SceneTree
const EngineEffects = preload("res://scripts/effects.gd")
var passed := 0
var failures: Array = []
var sequence := 0
func check(value: bool,label: String) -> void:
	if value: passed += 1
	else: failures.append(label)
func send(engine,kind: String,context: Dictionary,data: Dictionary = {}) -> Array:
	sequence += 1
	var event := data.duplicate(true)
	event.kind = kind
	event.epoch = engine.epoch
	event.sequence = sequence
	return engine.process(event,context)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var fx = EngineEffects.new()
	var ctx := {"time":0.0,"enemies":[],"damage":20.0,"hp":20.0,"max_hp":100.0,"pos":Vector2.ZERO}
	for id in range(1,7): ctx.enemies.append({"id":id,"hp":100.0,"pos":Vector2(id*20,0)})
	fx.reset({"arc_relay":1})
	var commands := send(fx,"hit",ctx,{"target":1,"pos":Vector2(20,0)})
	check(commands.size() == 1 and commands[0].targets == [2,3] and commands[0].damage == 8,"chain distinct other nearest targets")
	check(send(fx,"hit",ctx,{"target":1,"pos":Vector2(20,0)}).is_empty(),"chain ICD")
	ctx.time = 1.0
	check(send(fx,"hit",ctx,{"target":1,"pos":Vector2(20,0),"source":"chain","depth":1}).is_empty(),"proc hit cannot recurse")
	fx.reset({"arc_relay":1,"kill_cell":1})
	commands = send(fx,"kill",ctx,{"pos":Vector2.ZERO})
	check(commands.size()==1 and commands[0].kind=="orb","primary kill energy orb")
	check(send(fx,"kill",ctx,{"pos":Vector2.ZERO,"source":"chain","depth":1}).is_empty(),"proc kill no bonus orb")
	for i in range(8): send(fx,"pickup",ctx,{"source":"energy","pos":Vector2.ZERO})
	check(fx.chain_charges==3,"charge cap")
	commands=send(fx,"hit",ctx,{"target":1,"pos":Vector2(20,0)})
	check(commands[0].targets==[2,3,4,5] and fx.chain_charges==2,"charged network increases actual chain targets")
	fx.sync({"arc_relay":1})
	check(fx.chain_charges==0,"removal clears charges")
	fx.reset({"dash_resin":1,"pulse_boots":1})
	commands=send(fx,"dash",ctx,{"pos":Vector2.ZERO})
	check(commands.size()==2 and commands[0].slow and commands[1].kind=="push","sticky jet changes zone and push")
	fx.reset({"mirror_shell":1,"thorn_crown":1})
	commands=send(fx,"before_hurt",ctx)
	check(commands.size()==2 and commands[0].kind=="block" and commands[1].kind=="thorns","mirror thorns triggers on block")
	check(send(fx,"before_hurt",ctx).is_empty() and fx.shield==0,"shield consumed once")
	fx.sync({})
	fx.sync({"mirror_shell":1})
	check(fx.shield==0,"sell re-buy no shield exploit")
	fx.reset({"mirror_shell":1})
	check(fx.shield==1,"wave recharge")
	fx.invalidate()
	check(fx.shield==1,"pause does not change shield")
	fx.reset({"thorn_crown":1})
	check(send(fx,"hurt",ctx).size()==1,"hurt thorns alone")
	check(send(fx,"hurt",ctx).is_empty(),"thorns ICD")
	fx.reset({"blood_valve":1,"scrap_mine":1})
	commands=send(fx,"hit",ctx,{"target":1,"pos":Vector2.ZERO})
	check(commands.size()==1 and commands[0].amount==3,"low hp lifesteal")
	ctx.time += 2
	ctx.hp=50.0
	check(send(fx,"hit",ctx,{"target":1,"pos":Vector2.ZERO}).is_empty(),"no lifesteal above threshold")
	commands=send(fx,"pickup",ctx,{"source":"normal","pos":Vector2.ZERO})
	check(commands.size()==1 and commands[0].kind=="mine","normal pickup mine")
	check(send(fx,"pickup",ctx,{"source":"energy","pos":Vector2.ZERO}).is_empty(),"energy pickup never lays mine")
	commands=send(fx,"kill",ctx,{"source":"mine","depth":1,"pos":Vector2.ZERO})
	check(commands.size()==1 and commands[0].amount==5,"blood mine kill heals")
	var event := {"kind":"kill","epoch":fx.epoch,"sequence":sequence+1,"source":"mine","depth":1,"pos":Vector2.ZERO}
	check(fx.process(event,ctx).size()==1,"event first commit")
	for i in range(100): check(fx.process(event,ctx).is_empty(),"duplicate event rejected")
	fx.reset({"blood_valve":1,"scrap_mine":1})
	check(fx.process(event,ctx).is_empty(),"stale epoch rejected")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game); game.set_process(false); game._start_run(88)
	game.build.items={"dash_resin":1,"pulse_boots":1,"scrap_mine":1,"blood_valve":1}
	game._recompute()
	var enemy: Dictionary = game._spawn_kind("crawler",game.player_pos+Vector2(40,0))
	var before: Vector2 = enemy.pos
	game._effect_event("dash",{"pos":game.player_pos})
	check(enemy.pos.distance_to(game.player_pos)>before.distance_to(game.player_pos),"actual dash push")
	enemy.pos=game.player_pos+Vector2(20,0)
	var hp: float = enemy.hp
	game._update_hazards(.01)
	check(enemy.hp<hp and enemy.slow_until>game.elapsed,"actual zone damage and slow")
	game.build.items.erase("dash_resin");game._recompute()
	check(game.hazards.is_empty() and enemy.slow_until==0,"sell zone clears hazard and debuff")
	game._effect_event("pickup",{"source":"normal","pos":enemy.pos})
	hp=enemy.hp
	game._update_hazards(.1)
	check(enemy.hp==hp,"mine arming delay")
	game._update_hazards(.21)
	check(enemy.hp<hp and game.hazards.is_empty(),"mine detonates once")
	game.build.items={"mirror_shell":1,"thorn_crown":1};game.effects.reset(game.build.items);game._recompute()
	game.stats.hp=100;game.hurt_clock=0
	game._hurt(20)
	check(game.stats.hp==100 and game.effects.shield==0,"shield blocks real hurt")
	game.hurt_clock=0;game._hurt(20)
	check(game.stats.hp==80,"next hit causes damage")
	game.build.items={"dash_resin":1,"arc_relay":1,"kill_cell":1}
	game._recompute()
	game._effect_event("dash",{"pos":game.player_pos})
	game.effects.chain_charges=2
	var snapshot: Array = game.hazards.duplicate(true)
	var epoch: int = game.effects.epoch
	game._on_intent("pause",{})
	game._process(5.0)
	check(game.hazards==snapshot and game.effects.chain_charges==2 and game.effects.epoch>epoch,"pause freezes persistent effects without losing charge")
	game._on_intent("inventory",{})
	game._process(5.0)
	check(game.hazards==snapshot and game.effects.chain_charges==2,"inventory freezes persistent effects")
	game._start_run(89)
	check(game.hazards.is_empty() and game.effect_visuals.is_empty() and game.effects.shield==0,"run resets all effect state")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v4 real effects, anti-recursion and removal"}))
	quit(0 if failures.is_empty() else 1)
