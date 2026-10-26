extends SceneTree
const Loadouts=preload("res://scripts/gameplay/starting_loadouts.gd")
const Rules=preload("res://scripts/rules.gd")
var checks:=0
var failures:Array=[]
var g
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func snapshot()->String:
	return var_to_str({"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"seed":g.run_seed,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"state":g.state,"draft":g.selected_loadout_id,"generation":g.title_generation,"origin":g.run.starting_loadout_id,"clocks":g.weapon_clocks.duplicate(),"bullets":g.bullets.duplicate(true),"blasts":g.pending_blasts.duplicate(true),"time":g.elapsed,"pos":g.player_pos})
func _initialize()->void:call_deferred("run")
func run()->void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/starting_loadouts.json"))
	check(Loadouts.validate(data,catalog).is_empty(),"shipped registry valid")
	check(data.loadouts.map(func(r):return r.id)==["rivet","scatter","rail"],"three ordered starters")
	check(Loadouts.make_build(data,catalog,"rivet")==Rules.new_build(catalog),"default factory exact")
	var raw:=var_to_str(data)
	for id in ["rivet","scatter","rail"]:
		var e:=Loadouts.entry(data,catalog,id);check(e.starting_scrap is int,"normalized integer "+id)
		e.name="changed";e.starting_scrap=999
		var rows:=Loadouts.previews(data,catalog);rows[0].weapon_readout.damage=-1
		check(var_to_str(data)==raw,"detached entry and preview "+id)
	for bad in [null,true,"35",-1,1.5,INF,NAN,{},[],1000001]:
		var d:=data.duplicate(true);d.loadouts[1].starting_scrap=bad
		check(not Loadouts.validate(d,catalog).is_empty(),"bad scrap "+str(bad))
	for bad in [null,true,4,{},[],"unknown","rail"]:
		var d:=data.duplicate(true);d.default_id=bad
		check(not Loadouts.validate(d,catalog).is_empty(),"bad default "+str(bad))
	for bad in [null,true,4,{},[],"unknown",""]:
		var d:=data.duplicate(true);d.loadouts[1].weapon=bad
		check(not Loadouts.validate(d,catalog).is_empty(),"bad weapon "+str(bad))
	for key in ["id","name","strength","limitation"]:
		for bad in [null,true,4,{},[]," "]:
			var d:=data.duplicate(true);d.loadouts[1][key]=bad
			check(not Loadouts.validate(d,catalog).is_empty(),"bad text "+key)
	var duplicate:=data.duplicate(true);duplicate.loadouts[1].id="rivet"
	check(not Loadouts.validate(duplicate,catalog).is_empty(),"duplicate rejects")
	var empty:=data.duplicate(true);empty.loadouts=[]
	check(not Loadouts.validate(empty,catalog).is_empty(),"empty rejects")
	var floating:=data.duplicate(true);floating.loadouts[1].starting_scrap=23.0
	check(Loadouts.validate(floating,catalog).is_empty() and Loadouts.make_build(floating,catalog,"scatter").coins is int,"integral JSON float accepted")
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode in ["arena","rooms"]:
		for id in ["rivet","scatter","rail"]:
			g._title();g._select_mode(mode)
			if g.selected_loadout_id!=id:check(g._select_starting_loadout(id,g.title_generation),"select "+mode+id)
			var generation:int=g.title_generation
			check(g._start_selected_loadout(id,generation,31001),"guarded start "+mode+id)
			var row:=Loadouts.entry(data,catalog,id)
			check(g.build.weapons==[row.weapon] and g.build.coins==row.starting_scrap,"actual initial gear/coins "+mode+id)
			check(g.build.items.is_empty() and g.build.levels.is_empty() and g.build.revision==0 and g.build.coin_fraction==0.0,"fresh build "+mode+id)
			check(g.stats.hp==100 and g.stats.max_hp==100 and g.level==1 and g.xp==0 and g.elapsed==0 and g.kills==0,"fresh normal stats "+mode+id)
			check(g.weapon_clocks==[0.0] and g.run.starting_loadout_id==id,"fresh clock/origin "+mode+id)
			check(g._view().starting_loadout.id==id,"origin view "+mode+id)
			var before:=snapshot();check(not g._start_selected_loadout(id,generation,31001) and snapshot()==before,"queued start rejects "+mode+id)
			g.build.weapons=["cryo_sprayer","rivet_gun"];g.build.items={"fracture_coil":1};g.build.coins=999;g.state="dead"
			g._on_intent("retry",{})
			check(g.run_seed==31001 and g.build.weapons==[row.weapon] and g.build.coins==row.starting_scrap and g.build.items.is_empty(),"retry origin not current gear "+mode+id)
			g.state="won";g._on_intent("new_seed",{})
			check(g.run_seed==31002 and g.run.starting_loadout_id==id and g.build.weapons==[row.weapon],"new seed same origin "+mode+id)
			g._title();check(g.selected_loadout_id==id,"return title retains draft "+mode+id)
			g._on_intent("settings",{});g._on_intent("close_settings",{})
			check(g.selected_loadout_id==id and g.run_seed==31002,"settings retains draft/seed "+mode+id)
			g._on_intent("codex",{});g._on_intent("close_codex",{})
			check(g.selected_loadout_id==id,"guide retains draft "+mode+id)
			var same:=snapshot();check(not g._select_starting_loadout(id,g.title_generation) and snapshot()==same,"same selection no-op "+mode+id)
	g._title();g._start_run(31003)
	check(g.build==Rules.new_build(catalog) and g.run.starting_loadout_id=="rivet","one argument always old Rivet regardless draft")
	g._title();var other:String="rail" if g.selected_loadout_id!="rail" else "scatter"
	for bad in [null,true,1.0,"1",{},[]]:
		var before:=snapshot();check(not g._select_starting_loadout(other,bad) and snapshot()==before,"strict generation "+str(bad))
	for bad in [null,true,1,{},[],"unknown"]:
		var before:=snapshot();check(not g._select_starting_loadout(bad,g.title_generation) and snapshot()==before,"strict ID "+str(bad))
		check(not g._start_run(42,bad) and snapshot()==before,"invalid explicit start atomic "+str(bad))
	var old_generation:int=g.title_generation
	g.bullets=[{"sentinel":1}];g.pending_blasts=[{"sentinel":2}]
	var old_build:=g.build.duplicate(true);var states:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
	check(g._select_starting_loadout(other,old_generation),"title select")
	check(g.bullets==[{"sentinel":1}] and g.pending_blasts==[{"sentinel":2}] and g.build==old_build,"select no cleanup or equipment")
	check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==states,"selection no RNG")
	var before:=snapshot();check(not g._start_selected_loadout(other,old_generation,42) and snapshot()==before,"old title start atomic")
	for bad in [null,true,42.0,"42",{},[]]:
		before=snapshot();check(not g._start_selected_loadout(other,g.title_generation,bad) and snapshot()==before,"strict seed "+str(bad))
	g._on_intent("start_loadout",{"id":other,"generation":g.title_generation,"seed":42,"coins":9999,"weapon":"bankshot_driver"})
	var final_row:=Loadouts.entry(data,catalog,other)
	check(g.build.weapons==[final_row.weapon] and g.build.coins==final_row.starting_scrap,"caller coins/weapon ignored")
	print("Starting loadouts: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures:print("FAIL: "+str(failure))
	g.queue_free();quit(0 if failures.is_empty() else 1)
