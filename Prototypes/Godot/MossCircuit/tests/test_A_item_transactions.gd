extends SceneTree
# External author supplemental fixture; never installed into frozen common candidate here.
const Rules=preload("res://scripts/rules.gd")
const AudioTeardown=preload("res://tests/support/audio_teardown.gd")
var game
var checks:=0
var failures:Array=[]
const PRICES={"lock_memory":26,"return_collar":28,"recoil_plate":24}
const SOLD_BALANCES={"lock_memory":87,"return_collar":86,"recoil_plate":88}
const REBOUGHT_BALANCES={"lock_memory":61,"return_collar":58,"recoil_plate":64}
func ck(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func _initialize()->void:call_deferred("run")
func state()->Dictionary:
	return {"build":game.build.duplicate(true),"generation":game.shop_generation,"rng":[game.rng.state,game.loot_rng.state,game.shop_rng.state],"old_effects":[game.effects.epoch,game.effects.last_sequence,game.effects.echo_hits,game.effects.phase_charge,game.effects.chain_charges,game.effects.medic_damage,game.effects.cooldowns.duplicate(true)],"recoil":game.effects.recoil_cooldown.duplicate(true)}
func setup(mode:String,id:String)->void:
	game._title();game._select_mode(mode);game._start_run(39039);game.set_process(false)
	game.build.items={"echo_chamber":1,"arc_relay":1};game.build.coins=100;game._recompute()
	game.state="shop";game.shop_offers=[{"id":id,"sold":false}];game.reserved_offer={}
	game.effects.echo_hits=3;game.effects.cooldowns={"arc_relay":14.6}
	game.elapsed=11.0;game.effects.recoil_cooldown={"ready_at":12.0}
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	var catalog:Dictionary=game.catalog
	ck(Rules.validate_catalog(catalog).is_empty(),"real catalog valid")
	for id in PRICES:
		var row:Dictionary=Rules.catalog_entry(catalog,id)
		ck(row.price==PRICES[id] and row.max_stack==1 and row.effects.is_empty(),id+" literal price unique no passive bonus")
		for bad in [null,true,"1",0,-1,2,NAN,INF,{},[]]:
			var mutated:Dictionary=catalog.duplicate(true);Rules.catalog_entry(mutated,id).max_stack=bad
			ck(not Rules.validate_catalog(mutated).is_empty(),id+" invalid unique "+str(bad))
		for bad in [null,true,"24",-1,1.5,NAN,INF,{},[]]:
			var mutated:Dictionary=catalog.duplicate(true);Rules.catalog_entry(mutated,id).price=bad
			ck(not Rules.validate_catalog(mutated).is_empty(),id+" invalid price "+str(bad))
	var fields:Dictionary={"lock_memory":["grace_seconds"],"return_collar":["inward_seconds","inward_damage_scale"],"recoil_plate":["radius","distance","cooldown"]}
	for id in fields:
		for field in fields[id]:
			for bad in [null,true,"2",0,-1,NAN,INF,{},[]]:
				var mutated:Dictionary=catalog.duplicate(true);Rules.catalog_entry(mutated,id)[field]=bad
				ck(not Rules.validate_catalog(mutated).is_empty(),id+" invalid "+field+" "+str(bad))
	var beyond:Dictionary=catalog.duplicate(true);Rules.catalog_entry(beyond,"lock_memory").grace_seconds=.201
	ck(not Rules.validate_catalog(beyond).is_empty(),"memory cannot extend beyond C2 grace cap")
	beyond=catalog.duplicate(true);Rules.catalog_entry(beyond,"return_collar").inward_damage_scale=1.001
	ck(not Rules.validate_catalog(beyond).is_empty(),"return scale exceeds one")
	for mode in ["arena","rooms"]:
		for id in PRICES:
			setup(mode,id)
			var generation:int=game.shop_generation;var before:=state()
			ck(not game._buy(0,generation-1) and state()==before,mode+id+" stale buy atomic")
			ck(game._buy(0,generation),mode+id+" actual main buy")
			ck(game.build.coins==100-int(PRICES[id]) and game.build.items[id]==1,mode+id+" exact price and count")
			ck(game.effects.echo_hits==3 and game.effects.cooldowns=={"arc_relay":14.6},mode+id+" old effects preserved on buy")
			ck(game.effects.recoil_cooldown=={"ready_at":12.0},mode+id+" no Recoil cooldown recharge on buy")
			game.shop_offers=[{"id":id,"sold":false}];before=state()
			ck(not game._buy(0,game.shop_generation) and state()==before,mode+id+" actual duplicate unique reject atomic")
			generation=game.shop_generation;before=state()
			ck(not game._sell_item(id,generation-1) and state()==before,mode+id+" stale sell atomic")
			ck(game._sell_item(id,generation),mode+id+" actual sell")
			ck(game.build.coins==SOLD_BALANCES[id] and not game.build.items.has(id),mode+id+" exact half-price sale")
			ck(game.effects.echo_hits==3 and game.effects.cooldowns=={"arc_relay":14.6} and game.effects.recoil_cooldown=={"ready_at":12.0},mode+id+" old effects and new tombstone survive sale")
			game.shop_offers=[{"id":id,"sold":false}]
			ck(game._buy(0,game.shop_generation) and game.build.coins==REBOUGHT_BALANCES[id] and game.build.items[id]==1,mode+id+" actual rebuy exact")
			ck(game.effects.recoil_cooldown=={"ready_at":12.0},mode+id+" rebuy does not rearm cooldown")
			setup(mode,id);game.build.coins=0;before=state()
			ck(not game._buy(0,game.shop_generation) and state()==before,mode+id+" no funds atomic")
			setup(mode,id)
			game.build.items={"power_coil":1,"cooling_fan":1,"iron_plate":1,"moss_patch":1,"running_boots":1,"salvage_magnet":1,"lucky_chip":1,"lens":1};game._recompute();before=state()
			ck(not game._buy(0,game.shop_generation) and state()==before,mode+id+" full eight slots atomic")
			ck(not game.build.items.has(id),mode+id+" full slots no ghost item")
	var teardown=AudioTeardown.new();teardown.prepare([game]);game.queue_free();game=null;await process_frame
	var report:Dictionary=await teardown.finish(self)
	ck(bool(report.complete),"bounded actual owner/audio release")
	print(JSON.stringify({"A_item_transaction_checks":checks,"failures":failures,"scope":"author supplemental real main buy/sell/rebuy and pure Rules malformed A3 profiles; not ordinary shop acquisition"}))
	quit(0 if failures.is_empty() else 1)
