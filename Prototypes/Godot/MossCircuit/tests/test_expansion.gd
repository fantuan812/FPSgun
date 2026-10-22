extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const FX = preload("res://scripts/effects.gd")
var passed := 0
var failures: Array = []
var serial := 0
func check(ok: bool,label: String) -> void:
	if ok: passed += 1
	else: failures.append(label)
func event(fx,kind: String,data: Dictionary={}) -> Array:
	serial += 1
	data = data.duplicate(true)
	data.merge({"kind":kind,"epoch":fx.epoch,"sequence":serial},true)
	return fx.process(data,{"time":10.0,"hp":70.0,"max_hp":100.0,"pos":Vector2.ZERO,"enemies":[],"damage":18.0})
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var build := Rules.new_build(catalog)
	build.weapons=["return_disc"]
	var pool := Rules.weighted_pool(build,catalog)
	var spool: Dictionary = pool.filter(func(e): return e.id=="return_spool")[0]
	check(is_equal_approx(spool.weight,3.85),"exact tag + missing partner weight")
	for entry in pool: check(entry.weight>=1 and entry.weight<=6,"positive capped weight " + entry.id)
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed=717; r2.seed=717
	for i in range(100):
		var a:=Rules.draw_shop(build,catalog,r1)
		check(a==Rules.draw_shop(build,catalog,r2),"seed operation replay")
		var ids: Array=[]
		for offer in a:
			check(not offer.id in ids,"without replacement")
			ids.append(offer.id)
	build.coins=0
	check(Rules.weighted_pool(build,catalog)==pool,"zero money does not filter")
	build.items.return_spool=1
	check(not Rules.weighted_pool(build,catalog).any(func(e): return e.id=="return_spool"),"max-stack filtered")
	build.weapons=["return_disc","rivet_gun","rail_lance","scrap_shotgun"]
	check(Rules.weighted_pool(build,catalog).any(func(e): return e.id=="shock_mortar"),"full slots allow replacing")
	for bad_key in catalog.shop_weighting:
		var bad:=catalog.duplicate(true)
		bad.shop_weighting[bad_key]=-1
		check(not Rules.validate_catalog(bad).is_empty(),"bad weighting rejected " + bad_key)
	var fx=FX.new()
	fx.reset({"return_spool":1})
	check(event(fx,"hit",{"weapon":"return_disc","returning":false,"target":1,"pos":Vector2.ZERO}).is_empty(),"outbound no heal")
	check(event(fx,"hit",{"weapon":"return_disc","returning":true,"target":1,"pos":Vector2.ZERO})[0].amount==1,"return heal")
	check(event(fx,"hit",{"weapon":"return_disc","returning":true,"target":1,"pos":Vector2.ZERO}).is_empty(),"spool ICD")
	fx.reset({"echo_chamber":1})
	for i in range(4): check(event(fx,"hit",{"target":1,"pos":Vector2.ZERO}).is_empty(),"echo counts before fifth")
	check(event(fx,"hit",{"target":1,"pos":Vector2.ZERO})[0].kind=="echo" and fx.echo_hits==0,"fifth echoes once")
	check(event(fx,"hit",{"source":"echo","depth":1,"target":1,"pos":Vector2.ZERO}).is_empty() and fx.echo_hits==0,"secondary cannot recurse")
	fx.reset({"phase_capacitor":1})
	event(fx,"dash");event(fx,"dash")
	check(fx.phase_charge==1,"phase cap1")
	check(event(fx,"hit",{"target":1,"pos":Vector2.ZERO})[0].kind=="phase" and fx.phase_charge==0,"phase consumed")
	fx.reset({"medic_seed":1})
	check(event(fx,"hurt",{"amount":29.0}).is_empty(),"medical threshold")
	check(event(fx,"hurt",{"amount":32.0}).size()==2 and fx.medic_damage==1,"medical retained remainder")
	fx.invalidate()
	check(fx.medic_damage==1,"pause freeze retains meter")
	fx.sync({})
	check(fx.medic_damage==0,"removal clears meter")
	fx.reset({"blast_fuse":1,"gravity_anchor":1})
	check(event(fx,"mortar",{"pos":Vector2.ZERO})[0].kind=="scorch","fuse after mortar")
	check(event(fx,"mine_detonate",{"pos":Vector2.ZERO,"source":"mine","depth":1})[0].kind=="pull","mine pull")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_run(91)
	game.build.weapons=["shock_mortar"]
	game.build.items={"blast_fuse":1}
	game._recompute()
	game._spawn_kind("crawler",game.player_pos+Vector2(120,0))
	game.enemies[0].hp=200.0
	game._fire_weapon("shock_mortar",0)
	var target_hp: float=game.enemies[0].hp
	check(game.pending_blasts.size()==1,"mortar creates delayed locked marker")
	game._update_mortars(.59)
	check(game.enemies[0].hp==target_hp,"warning has no damage")
	game._update_mortars(.02)
	check(game.enemies[0].hp<target_hp and game.hazards.size()==1,"detonation damage and fuse")
	game.build.items={}
	game._recompute()
	check(game.hazards.is_empty(),"fuse removal clears zones")
	game.build.weapons=["return_disc"]
	game._recompute()
	game._fire_weapon("return_disc",0)
	var disc: Dictionary=game.bullets[-1]
	game._advance_disc(disc,disc.outbound_left)
	check(disc.returning,"disc returns after outbound phase")
	var out_pos:Vector2=disc.pos
	game._advance_disc(disc,.1)
	check(disc.pos.distance_to(game.player_pos)<out_pos.distance_to(game.player_pos),"disc homes back")
	game.queue_free()
	await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v5 expansion + weighted shop"}))
	quit(0 if failures.is_empty() else 1)
