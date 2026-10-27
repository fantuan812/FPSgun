extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Readout=preload("res://scripts/weapon_readout.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func nodes(node:Node)->Array:
	var result:Array=[node]
	for child in node.get_children():result.append_array(nodes(child))
	return result
func _initialize()->void:call_deferred("run")
func run()->void:
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var balance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	var original_catalog:String=JSON.stringify(catalog)
	var expected:Array=[["rivet_gun",15.0,.4,500.0],["scrap_shotgun",9.0,.85,300.0],["rail_lance",30.0,1.15,650.0],["orbit_saw",20.0,.65,105.0],["return_disc",18.0,.9,330.0],["shock_mortar",36.0,1.5,500.0],["cryo_sprayer",9.0,.65,190.0],["bankshot_driver",18.0,.85,900.0]]
	var build:Dictionary=Rules.new_build(catalog)
	var stats:Dictionary=Rules.derive(balance.player,build,catalog)
	for row in expected:
		var w:Dictionary=Rules.catalog_entry(catalog,row[0])
		var readout:Dictionary=Readout.describe(w,stats,false)
		check(readout.scope=="BASE" and readout.damage==row[1] and readout.interval==row[2] and readout.reach==row[3],"base explicit values "+row[0])
	for profile in [{"damage_bonus":0.0,"electric_bonus":0.0,"melee_bonus":0.0,"haste":0.0,"range_bonus":0.0,"extra_pellets":0},{"damage_bonus":.55,"electric_bonus":.7,"melee_bonus":.7,"haste":.39,"range_bonus":.45,"extra_pellets":3},{"damage_bonus":.85,"electric_bonus":1.2,"melee_bonus":1.2,"haste":8.0,"range_bonus":.15,"extra_pellets":1}]:
		var before:String=JSON.stringify(profile)
		for w in catalog.weapons:
			# Test oracle is the exact pre-extraction expressions, not a second production calculation.
			var old_damage:float=w.damage*(1.0+profile.damage_bonus)
			if "electric" in w.tags:old_damage*=1.0+profile.electric_bonus
			if "melee" in w.tags:old_damage*=1.0+profile.melee_bonus
			var old_interval:float=maxf(.09,w.interval/(1.0+profile.haste))
			var old_reach:float=float(w.range) if w.behavior=="orbit" else w.range*(1.0+profile.range_bonus)
			var old_count:int=w.projectiles+(int(profile.extra_pellets) if w.behavior=="spread" else 0)
			var readout:Dictionary=Readout.describe(w,profile,true)
			check(readout.damage==old_damage and Rules.weapon_damage(w,profile)==old_damage,"exact old damage "+w.id)
			check(readout.interval==old_interval and Rules.weapon_interval(w,profile)==old_interval,"exact old interval "+w.id)
			check(readout.reach==old_reach and Rules.weapon_reach(w,profile)==old_reach,"exact old reach "+w.id)
			check(Rules.weapon_projectiles(w,profile)==old_count,"exact old projectile count "+w.id)
			check(readout==Readout.describe(w,profile,true),"idempotent "+w.id)
			check(Readout.describe(w,profile,false).damage==w.damage,"base excludes all build bonuses "+w.id)
			if w.behavior=="spread":check(readout.pellets==old_count and readout.damage_unit.contains("pellet"),"pellet unit and count")
			else:check(not readout.has("pellets"),"no false pellet count "+w.id)
			if w.behavior=="field_bankshot":check(readout.total_path==old_reach and readout.note.contains("all legs"),"one bankshot budget")
			check(readout.note.contains("Primary damage only") and not readout.has("dps"),"no proc/DPS aggregation "+w.id)
		check(JSON.stringify(profile)==before,"stat input read-only")
	check(JSON.stringify(catalog)==original_catalog,"catalog untouched")
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	for viewport in [Vector2i(960,540),Vector2i(1280,720)]:
		root.size=viewport
		for mode in ["arena","rooms"]:
			game._title();game._select_mode(mode);game._start_run(86)
			game.build.weapons=["rail_lance","scrap_shotgun","orbit_saw","bankshot_driver"]
			game.build.items={"power_coil":1,"cooling_fan":1,"capacitor":2,"pellet_pouch":2,"lens":1}
			game._recompute();game.build.coins=1000;game._open_shop()
			for w in catalog.weapons:
				game.shop_offers=[{"id":w.id,"sold":false,"weight_multiplier":1.0,"bias_reasons":[]}]
				var view:Dictionary=game._view();var before:String=JSON.stringify(view)
				check(view.offers[0].weapon_readout.scope=="BASE" and view.offers[0].weapon_readout.damage==w.damage,"offer not purchase preview "+w.id)
				check(view.weapons[0].weapon_readout.scope=="CURRENT" and is_equal_approx(view.weapons[0].weapon_readout.damage,58.65),"equipped Rail actual bonuses")
				game.ui.show_shop(view);await process_frame;await process_frame
				var buy:Button
				var all:Array=nodes(game.ui.modal)
				for node in all:
					if node is Button and node.text.begins_with("REPLACE"):buy=node;break
				check(buy!=null and not buy.disabled,"replacement first action "+w.id)
				if buy!=null:
					var scroll:Node=buy.get_parent()
					while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
					check(scroll!=null,"offer scroll")
					if scroll!=null:
						scroll.scroll_vertical=0;await process_frame
						check(scroll.get_global_rect().encloses(buy.get_global_rect()),"first action visible "+mode+str(viewport)+w.id)
				check(JSON.stringify(view)==before,"render read-only "+w.id)
			var view:Dictionary=game._view();game.ui.show_inventory(view);await process_frame;await process_frame
			var labels:Array=[]
			for node in nodes(game.ui.modal):
				if node is Label:labels.append(node.text)
			check("CURRENT WEAPON STATS" in labels and "BASE BEHAVIOR" in labels,"owned stat/description scopes")
			check(not labels.any(func(s):return s.to_lower().begins_with("damage:") or s.to_lower().begins_with("fire interval:")),"no misleading starter damage/interval")
			check(labels.any(func(s):return s.begins_with("Global weapon-damage bonus:")) and labels.any(func(s):return s.begins_with("Additive attack-rate bonus:")),"modifiers labeled")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"weapon_readout_checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
