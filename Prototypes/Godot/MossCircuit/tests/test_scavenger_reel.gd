extends SceneTree
const Reel=preload("res://scripts/gameplay/scavenger_reel.gd")
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const AudioTeardown=preload("res://tests/support/audio_teardown.gd")
var game
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func reset(mode_id:String)->void:
	game._title();game._select_mode(mode_id);game._start_run(36036);game.set_process(false)
	game.build.weapons=["return_disc"];game.build.items={"scavenger_reel":1};game._recompute();game.weapon_clocks=[999.0]
	game.player_pos=Vector2(300,300);game.hero.position=game.player_pos;game.stats.bullet_speed=100.0;game.stats.pickup_radius=0.0
	game.build.coins=0;game.build.coin_fraction=0.0;game.stats.coin_bonus=0.0;game.xp=0
	game.combat_frame.area=game.config.arena
func disc(remaining:int=3)->Dictionary:
	var result:Dictionary={"pos":Vector2(400,300),"velocity":Vector2.LEFT*100,"life":2.0,"damage":1.0,"pierce":99,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.0,"scavenger":Reel.snapshot(game.build,game.catalog)}
	result.scavenger.remaining=remaining
	return result
func pickup(pos:Vector2,source:String="normal")->Dictionary:return {"pos":pos,"source":source,"xp":2,"coins":3}
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
	check(Rules.validate_catalog(game.catalog).is_empty(),"expanded catalog valid")
	var row:Dictionary=Rules.catalog_entry(game.catalog,"scavenger_reel")
	check(row.price==28 and row.rarity=="rare" and row.effects.is_empty(),"unique bounded content")
	check(Reel.describe(row).contains("3 normal/energy") and Reel.describe(row).contains("18.0 px"),"data-derived description")
	var changed:Dictionary=row.duplicate(true);changed.return_pickup_limit=5.0;changed.return_pickup_radius=22.0
	check(Reel.describe(changed).contains("5 normal/energy") and Reel.describe(changed).contains("22.0 px"),"custom valid numbers reflected")
	for bad in [null,true,"3",2.5,0,9,NAN,INF]:
		changed=row.duplicate(true);changed.return_pickup_limit=bad;check(Reel.definition(changed).is_empty(),"invalid quota rejected "+str(bad))
	for value in [1,1.0,8,8.0]:
		changed=row.duplicate(true);changed.return_pickup_limit=value;var p:=Reel.definition(changed);check(p.maximum is int and p.maximum==int(value),"integral catalog normalized "+str(value))
	for mode_id in ["arena","rooms"]:
		reset(mode_id)
		var one:=Reel.snapshot(game.build,game.catalog);var two:=Reel.snapshot(game.build,game.catalog);one.remaining=0;one.sources.clear()
		check(two.remaining==3 and two.sources.size()==2,"independent launch quota/sources "+mode_id)
		var shot:=disc();var sw:Dictionary={"disc":shot,"start":Vector2(400,300),"end":Vector2(300,300)}
		check(Reel.eligible(sw,pickup(Vector2(350,317))),"inside strict radius")
		check(not Reel.eligible(sw,pickup(Vector2(350,318))),"exact tangent excluded")
		check(not Reel.eligible(sw,pickup(Vector2(350,300),"medical")),"medical remote excluded")
		check(not Reel.eligible({"disc":shot,"start":Vector2(350,300),"end":Vector2(350,300)},pickup(Vector2(350,300))),"zero segment excluded")
		game.bullets=[shot];game.pickups=[pickup(Vector2(325,300)),pickup(Vector2(340,300)),pickup(Vector2(355,300)),pickup(Vector2(370,300))]
		Runtime.step(game.combat_frame,.8)
		check(game.pickups.size()==1 and game.pickups[0].pos==Vector2(325,300),"reverse pickup index consumes last three")
		check(shot.scavenger.remaining==0 and game.xp==6 and game.build.coins==9,"three rewards once")
		check(game.effect_visuals.filter(func(v):return v.kind=="scavenger_pickup").size()==3,"one visual per real intercept")
		reset(mode_id);shot=disc();shot.pos=Vector2(314,300);game.bullets=[shot];game.pickups=[pickup(Vector2(313,300))]
		Runtime.step(game.combat_frame,.01)
		check(game.pickups.is_empty() and shot.scavenger.remaining==3,"physical contact precedence spends no quota")
		reset(mode_id);game.stats.pickup_radius=30.0;shot=disc();shot.pos=Vector2(320,300);shot.scavenger.radius=1.0;game.stats.bullet_speed=260.0;game.bullets=[shot];game.pickups=[pickup(Vector2(320,300))]
		Runtime.step(game.combat_frame,.05)
		check(game.pickups.is_empty() and shot.scavenger.remaining==2,"postmagnet endpoint collection uses pre-move physical condition")
		reset(mode_id);shot=disc();shot.life=.2;game.bullets=[shot];game.pickups=[pickup(Vector2(385,300))]
		Runtime.step(game.combat_frame,.7)
		check(game.bullets.is_empty() and game.pickups.is_empty() and shot.scavenger.remaining==2,"life clipped final segment still settles")
		reset(mode_id);shot=disc();shot.returning=false;shot.outbound_left=.2;shot.velocity=Vector2.RIGHT*100;game.bullets=[shot];game.pickups=[pickup(Vector2(380,300))]
		Runtime.step(game.combat_frame,.2)
		check(game.pickups.size()==1 and shot.scavenger.remaining==3,"outbound-only no remote sweep")
		reset(mode_id);shot=disc();game.bullets=[shot];game.pickups=[pickup(Vector2(350,300),"medical")]
		Runtime.step(game.combat_frame,.8)
		check(game.pickups.size()==1 and shot.scavenger.remaining==3,"medical remains on ground")
		reset(mode_id);shot=disc();var second:=disc();game.bullets=[shot,second];game.pickups=[pickup(Vector2(350,300))]
		Runtime.step(game.combat_frame,.8)
		check(second.scavenger.remaining==2 and shot.scavenger.remaining==3,"descending bullet index wins")
		reset(mode_id);shot=disc();game.bullets=[shot];game.pickups=[pickup(Vector2(350,300))];game.state="won"
		Runtime.step(game.combat_frame,.8)
		check(game.pickups.size()==1 and shot.scavenger.remaining==3,"terminal directstep no remote reward")
		game._title();check(game.bullets.is_empty() and game.pickups.is_empty(),"title clears prior run state")
	var audio_teardown=AudioTeardown.new();audio_teardown.prepare([game]);game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"Scavenger Reel author focused validation"}))
	quit(0 if failures.is_empty() else 1)
