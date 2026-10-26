extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Hold=preload("res://scripts/gameplay/shop_reservation.gd")
var passed:=0
var failures:Array=[]
var game
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func offer(id:String)->Dictionary:return {"id":id,"sold":false,"weight_multiplier":2.5,"bias_reasons":["Original reason"]}
func setup(mode:String="arena")->void:
	game._title();game._select_mode(mode);game._start_run(2801)
	game.build.coins=100;game._open_shop()
	game.shop_offers=[offer("rail_lance"),offer("power_coil"),offer("feedback_diode"),offer("cryo_sprayer")]
func snapshot()->Dictionary:
	return {"build":game.build.duplicate(true),"stats":game.stats.duplicate(true),"offers":game.shop_offers.duplicate(true),"held":game.reserved_offer.duplicate(true),"generation":game.shop_generation,"rng":[game.rng.state,game.shop_rng.state,game.loot_rng.state],"clocks":game.weapon_clocks.duplicate(),"epoch":game.effects.epoch,"sequence":game.effect_runtime.sequence}
func buttons(node:Node)->Array:
	var found:Array=[]
	if node is Button:found.append(node)
	for child in node.get_children():found.append_array(buttons(child))
	return found
func visible_in_scroll(button:Button)->bool:
	var node:Node=button.get_parent()
	while node!=null and not node is ScrollContainer:node=node.get_parent()
	if node==null:return false
	var rect:Rect2=button.get_global_rect();var viewport:Rect2=node.get_global_rect()
	return rect.position.y>=viewport.position.y and rect.end.y<=viewport.end.y
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	var catalog:Dictionary=game.catalog
	var build:Dictionary=Rules.new_build(catalog)
	var rng:=RandomNumberGenerator.new();var control:=RandomNumberGenerator.new()
	for seed_value in range(100):
		rng.seed=seed_value;control.seed=seed_value
		check(Hold.draw(build,catalog,rng,{}).offers==Rules.draw_shop(build,catalog,control,4) and rng.state==control.state,"unheld exact draw/RNG "+str(seed_value))
	for slot in range(4):
		var original:=offer("rail_lance")
		var record:=Hold.create(build,catalog,original,slot,10)
		check(record.slot==slot and record.token==10 and record.price==42,"record identity "+str(slot))
		original.bias_reasons.append("external mutation")
		check(record.offer.bias_reasons==["Original reason"],"deep original metadata "+str(slot))
		for seed_value in range(20):
			rng.seed=seed_value;control.seed=seed_value
			var expected:=Rules.draw_shop(build,catalog,control,3,["rail_lance"])
			expected.insert(slot,record.offer.duplicate(true))
			var drawn:=Hold.draw(build,catalog,rng,record)
			check(drawn.offers==expected and rng.state==control.state,"exact three new draw "+str(slot)+":"+str(seed_value))
			check(drawn.offers.filter(func(o):return o.id=="rail_lance").size()==1,"no held duplicate "+str(slot)+":"+str(seed_value))
			drawn.offers[slot].bias_reasons.append("detached output")
			check(record.offer.bias_reasons.size()==1,"detached drawn metadata "+str(slot)+":"+str(seed_value))
		var short_catalog:=catalog.duplicate(true)
		short_catalog.weapons=short_catalog.weapons.filter(func(w):return w.id=="rail_lance")
		short_catalog.items=[]
		var short_build:=build.duplicate(true);short_build.weapons=[]
		var short_draw:=Hold.draw(short_build,short_catalog,rng,record)
		check(short_draw.offers.size()==1 and short_draw.offers[0].id=="rail_lance" and record.slot==slot,"short pool no holes/preferred slot retained "+str(slot))
	var record:=Hold.create(build,catalog,offer("rail_lance"),0,12)
	for field in ["id","price","slot","token","offer"]:
		for bad in [null,true,{},[],"bad"]:
			var broken:=record.duplicate(true);broken[field]=bad
			check(not Hold.invalid_reason(build,catalog,broken).is_empty(),"reject malformed "+field+":"+str(bad))
			check(not Hold.describe(build,catalog,broken).valid,"safe invalid summary "+field+":"+str(bad))
	for mode in ["arena","rooms"]:
		setup(mode)
		var old:=snapshot();var generation:int=game.shop_generation
		for bad in [null,true,{},[],"0",0.5]:
			game._on_intent("reserve_offer",{"index":bad,"generation":generation})
			game._on_intent("reserve_offer",{"index":0,"generation":bad})
			check(snapshot()==old,"new reserve payload rejects wrong types "+mode+str(bad))
		check(game._reserve_offer(0,generation),"actual reserve "+mode)
		var token:int=game.reserved_offer.token
		check(token==generation+1 and game.shop_generation==token,"generation issued token "+mode)
		var after:=snapshot();after.held={};after.generation=generation
		check(after==old,"reserve zero economy/RNG/stats/proc changes "+mode)
		var held_state:=snapshot()
		check(not game._reserve_offer(0,generation) and not game._reserve_offer(1,game.shop_generation),"no stale toggle or silent switch "+mode)
		check(not game._release_offer(token-1,game.shop_generation) and not game._release_offer(token,generation),"both release guards "+mode)
		check(snapshot()==held_state,"rejected action atomic "+mode)
		for bad in [null,true,{},[],str(token),0.5]:
			game._on_intent("release_offer",{"token":bad,"generation":game.shop_generation})
			game._on_intent("release_offer",{"token":token,"generation":bad})
			check(snapshot()==held_state,"new release payload rejects wrong types "+mode+str(bad))
		var view:Dictionary=game._view();view.offers[0].bias_reasons.append("external view")
		view.reserved_offer.token=-1
		check(snapshot()==held_state,"read-only detached view "+mode)
		game.build.coins=0;held_state=snapshot()
		check(not game._buy(0,game.shop_generation) and not game._refresh_shop(game.shop_generation),"unfunded actions fail "+mode)
		check(snapshot()==held_state,"unfunded preserves all state "+mode)
		game.build.coins=100
		check(game._buy(1,game.shop_generation),"other purchase "+mode)
		check(game.reserved_offer.token==token,"other buy keeps stable token "+mode)
		check(game._sell_item("power_coil",game.shop_generation) and game.reserved_offer.token==token,"sale keeps stable token "+mode)
		var coins:int=game.build.coins;var revision:int=game.build.revision;generation=game.shop_generation
		check(game._refresh_shop(generation),"paid refresh with hold "+mode)
		check(game.build.coins==coins-5 and game.build.revision==revision+1 and game.shop_generation==generation+1 and game.reserved_offer.token==token,"refresh old cost/one generation "+mode)
		check(game.shop_offers[0]==held_state.held.offer,"original slot and metadata retained "+mode)
		var before_release:=snapshot()
		check(game._release_offer(token,game.shop_generation),"current gen and stable old token accepted "+mode)
		var released:=snapshot();released.held=before_release.held;released.generation=before_release.generation
		check(released==before_release,"release no draw/reward "+mode)
		check(game._reserve_offer(2,game.shop_generation),"explicit switch after release "+mode)
		check(not game._release_offer(token,game.shop_generation),"old token cannot clear new reservation "+mode)
		setup(mode);game.build.weapons=["rivet_gun","cryo_sprayer","bankshot_driver","orbit_saw"];game._recompute()
		check(game._reserve_offer(0,game.shop_generation),"full weapon slots can reserve "+mode)
		held_state=snapshot()
		check(not game._buy(0,game.shop_generation,-1) and not game._buy(0,game.shop_generation,7),"failed replacement "+mode)
		check(snapshot()==held_state,"failed replacement atomic "+mode)
		check(game._buy(0,game.shop_generation,2),"actual held replacement "+mode)
		check(game.build.weapons[2]=="rail_lance" and game.reserved_offer.is_empty() and game.shop_offers[0].sold,"held purchase consumes exactly once "+mode)
		setup(mode);game._reserve_offer(2,game.shop_generation)
		game.build.items.feedback_diode=1;game.build.coins=0;game._recompute();held_state=snapshot()
		check(not game._refresh_shop(game.shop_generation) and snapshot()==held_state,"invalid max-stack not cleared by failed refresh "+mode)
		game.build.coins=100;generation=game.shop_generation
		check(game._refresh_shop(generation) and game.reserved_offer.is_empty() and game.shop_generation==generation+1,"successful draw clears invalid hold once "+mode)
		check(game.shop_message.contains("owned maximum reached") and not game.shop_message=="New stock.","precise invalidation notice survives "+mode)
		setup(mode);game._reserve_offer(0,game.shop_generation)
		var rail:Dictionary=Rules.catalog_entry(game.catalog,"rail_lance");var price:Variant=rail.price;rail.price=43
		held_state=snapshot();check(not game._buy(0,game.shop_generation) and snapshot()==held_state,"no changed catalog price charge "+mode)
		check(game._view().offers[0].price==42 and not game._view().offers[0].can_buy,"original price shown invalid "+mode)
		rail.price=price
		setup(mode);game._reserve_offer(2,game.shop_generation)
		game.reserved_offer.id="unknown_corrupted_identity";held_state=snapshot()
		check(not game._buy(2,game.shop_generation) and snapshot()==held_state,"malformed held ID cannot bypass original-card price/identity guard "+mode)
		check(game._view().offers[2].reserved and not game._view().offers[2].can_buy,"malformed held ID still exposes release on original card "+mode)
		check(game._release_offer(game.reserved_offer.token,game.shop_generation),"malformed identity can be explicitly released "+mode)
		setup(mode);game._reserve_offer(0,game.shop_generation);token=game.reserved_offer.token
		game._leave_shop(game.shop_generation);game._clear_transients()
		check(game.reserved_offer.token==token,"deploy/transient cleanup retains "+mode)
		game._on_intent("pause",{});game._on_intent("inventory",{});game._on_intent("close_inventory",{});game._on_intent("resume",{})
		check(game.reserved_offer.token==token,"pause/inventory retains "+mode)
		game._open_shop();check(game.shop_offers[0].id=="rail_lance" and game.reserved_offer.token==token,"later shop carries held record "+mode)
		game._finish(false);check(game.reserved_offer.is_empty(),"death clears "+mode)
		game._on_intent("retry",{});check(game.reserved_offer.is_empty(),"retry clears "+mode)
		game._open_shop();game._reserve_offer(0,game.shop_generation);game._finish(true);check(game.reserved_offer.is_empty(),"victory clears "+mode)
		setup(mode);game._reserve_offer(0,game.shop_generation);game._title();check(game.reserved_offer.is_empty(),"title clears "+mode)
		for size in [Vector2i(960,540),Vector2i(1280,720)]:
			root.size=size
			for full in [false,true]:
				setup(mode)
				if full:game.build.weapons=["rivet_gun","cryo_sprayer","bankshot_driver","orbit_saw"];game._recompute()
				game._reserve_offer(0,game.shop_generation)
				await process_frame;await process_frame
				var first_buy:Button;var release:Button
				for b in buttons(game.ui.modal):
					if first_buy==null and (b.text.begins_with("BUY") or b.text.begins_with("REPLACE")):first_buy=b
					if b.text=="RELEASE":release=b
				check(first_buy!=null and visible_in_scroll(first_buy),"first held purchase visible "+mode+str(size)+str(full))
				check(release!=null and visible_in_scroll(release),"held release visible "+mode+str(size)+str(full))
	game.queue_free();await process_frame
	print(JSON.stringify({"reservation_passed":passed,"failures":failures,"scope":"Controlled pure stock policy, actual reservation/purchase/lifecycle handlers and headless UI geometry; native acceptance separate."}))
	quit(0 if failures.is_empty() else 1)
