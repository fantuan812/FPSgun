extends SceneTree
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
const AudioTeardown=preload("res://tests/support/audio_teardown.gd")
var game
var passed:int=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func nodes(node:Node,type:String)->Array:
	var found:Array=[]
	if node.is_class(type):found.append(node)
	for child in node.get_children():found.append_array(nodes(child,type))
	return found
func _initialize()->void:call_deferred("run")
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	game._start_run(37037);game.set_process(false)
	game.build.coins=100;game.build.weapons=["return_disc","rivet_gun","rail_lance","cryo_sprayer"];game.build.items={"scavenger_reel":1};game._recompute()
	game.state="shop";game.shop_offers=[{"id":"orbit_saw","sold":false},{"id":"fracture_coil","sold":false}];game.shop_generation+=1
	var original:Dictionary=game.build.duplicate(true)
	var generation:int=game.shop_generation
	var rng_state:int=game.rng.state
	var one:Dictionary=game._offer_forecast(0,generation,0)
	check(one.available and one.coins_after==62,"replacement uses real price")
	check(one.removed.id=="return_disc" and one.added.id=="orbit_saw" and one.added.tier==0,"replacement explicit destroyed and standard")
	check(one.mechanisms.any(func(row):return row.change=="disables" and row.after.name=="SCAVENGER RETURN"),"last disc loss visible")
	var two:Dictionary=game._offer_forecast(0,generation,1)
	check(two.available and not two.mechanisms.any(func(row):return row.after.name=="SCAVENGER RETURN"),"keeping disc does not lose reel")
	check(game._offer_forecast(1,generation).mechanisms.any(func(row):return row.change=="enables" and row.after.name=="Cold Snap"),"different type supplied to fracture")
	for bad in [false,0.0,"0",-2,4]:check(not game._offer_forecast(0,generation,bad).available,"strict slot "+str(bad))
	check(not game._offer_forecast(0,float(generation),0).available,"strict preview generation")
	check(not game._offer_forecast("0",generation,0).available,"strict preview index")
	game.ui.show_shop(game._view());await process_frame
	var selectors:Array=nodes(game.ui.root,"OptionButton")
	check(selectors.size()==1,"one existing full-bag selector")
	var selector:OptionButton=selectors[0]
	selector.grab_focus();selector.select(1);selector.item_selected.emit(1);await process_frame
	check(selector.has_focus(),"forecast update retains selector focus")
	var forecasts:Array=[]
	for node in nodes(game.ui.root,"VBoxContainer"):
		if node.name=="BuildForecast":forecasts.append(node)
	check(forecasts.size()==2,"one forecast per offer")
	check(forecasts[0].get_meta("forecast_slot")==1,"selector updates only local selected slot")
	check(forecasts[0].get_meta("forecast_report")==two,"rendered selected projection exact")
	check(game.build==original and game.shop_generation==generation and game.rng.state==rng_state,"view and selector no authority mutation")
	one.mechanisms.clear();one.weapons.clear()
	check(game.build==original,"consumer report detached")
	check(game._buy(0,generation,1),"real original buy authority")
	check(game.build.coins==two.coins_after and game.build.weapons[1]==two.added.id and game.build.weapons[0]=="return_disc","real selected-slot result agrees")
	var teardown=AudioTeardown.new();teardown.prepare([game]);game.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"Author finite pure forecast and local selector smoke; not full regression"}));quit(0 if failures.is_empty() else 1)
