extends SceneTree
# External controlled stock/build; actual shop presentation and intent authority.
const Rules=preload("res://scripts/rules.gd")
const Teardown=preload("<QA_ROOT>/native-support/audio_teardown.gd")
var g
var index:int=0
var ready_case:bool=false
var previous:String=""
var actions:Array=[]
var errors:Array=[]
class Driver extends Node:
	var next:Callable
	var tick:Callable
	var close:Callable
	func _input(event:InputEvent)->void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode==KEY_N:next.call();get_viewport().set_input_as_handled()
			elif event.keycode==KEY_F9:close.call();get_viewport().set_input_as_handled()
	func _process(_dt:float)->void:tick.call()
func nodes(n:Node)->Array:
	var result:Array=[n]
	for child in n.get_children():result.append_array(nodes(child))
	return result
func _initialize()->void:call_deferred("boot")
func boot()->void:
	root.title="Moss v37 CONTROLLED Build Forecast / actual UI / N next / F9 close"
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	g.ui.intent.connect(func(action:String,payload:Dictionary):
		actions.append({"action":action,"payload":payload.duplicate(true)})
		print(JSON.stringify({"actual_ui_intent":action,"payload":payload,"case":index+1})))
	var driver:=Driver.new();driver.next=advance;driver.tick=tick;driver.close=finish;root.add_child(driver)
	await process_frame;show_case()
func advance()->void:
	if ready_case and index<7:index+=1;show_case()
func show_case()->void:
	ready_case=false;previous="";actions=[]
	var kind:int=index%4
	root.size=Vector2i(960,540) if index<4 else Vector2i(1280,720)
	await process_frame;await process_frame
	g._title();g._select_mode("arena" if kind%2==0 else "rooms");g._start_run(3707);g.set_process(false)
	var id:String="scavenger_reel"
	if kind==0:
		g.build.weapons=["return_disc","rivet_gun","rail_lance","orbit_saw"];g.build.weapon_temper=[1,1,0,1];g.build.items={"scavenger_reel":1};id="cryo_sprayer"
	elif kind==2:
		g.build.weapons=["cryo_sprayer"];g.build.items={};id="fracture_coil"
	else:g.build.weapons=["return_disc"];g.build.items={}
	g.build.coins=10 if kind==3 else 100;g._recompute();g.weapon_clocks=[]
	for _w in g.build.weapons:g.weapon_clocks.append(999.)
	g.spawn_clock=999.;g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g._sync_weapon_rig();g._open_shop();g.reserved_offer={}
	var e:Dictionary=Rules.catalog_entry(g.catalog,id).duplicate(true);e.sold=false;g.shop_offers=[e];g._render_shop()
	await process_frame;await process_frame;ready_case=true
	print(JSON.stringify({"controlled_case":index+1,"kind":["last-return-loss-and-local-select","pair-completion","compound-still-needs","affordability-unavailable"][kind],"mode":g.mode.id,"requested_window":[960,540] if index<4 else [1280,720],"actual_window":[root.size.x,root.size.y],"supplied_build":g.build.duplicate(true),"supplied_offer":id,"scope":"Controlled supplied stock/ownership/funds. Use actual selector/disclosure/buy; N next bounded case, F9 close. Not ordinary acquisition."}));tick()
func tick()->void:
	if not ready_case or not is_instance_valid(g):return
	g._update_hud();g.queue_redraw()
	var forecasts:Array=[]
	for n in nodes(g.ui.modal):
		if n is VBoxContainer and n.name=="BuildForecast":forecasts.append({"slot":n.get_meta("forecast_slot",-999),"report":n.get_meta("forecast_report",{})})
	var state:Dictionary={"case":index+1,"mode":g.mode.id,"state":g.state,"build":g.build.duplicate(true),"generation":g.shop_generation,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"forecasts":forecasts,"ui_actions":actions.size()}
	var current:String=JSON.stringify(state)
	if current!=previous:print(JSON.stringify({"observed":state}));previous=current
func finish()->void:
	ready_case=false;print(JSON.stringify({"fixture_terminal":true,"last_case":index+1,"errors":errors,"scope":"Controlled UI visual/intent session, not ordinary run"}))
	var observer=Teardown.new();observer.prepare([g]);g.queue_free();await process_frame;await observer.finish(self);quit(0)
