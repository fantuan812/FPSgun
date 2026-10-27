extends SceneTree
# Pre-implementation C3 hand oracle. No Rules/Readout used for expectations.
const Forecast = preload("res://scripts/gameplay/build_forecast.gd")
var checks:int=0
var failures:Array=[]
var c:Dictionary
var base:Dictionary
func ck(value:bool,label:String)->void:
	checks+=1
	if not value: failures.append(label)
func build(ids:Array=["rivet_gun"],items:Dictionary={},coins:int=200)->Dictionary:
	return {"weapons":ids.duplicate(true),"items":items.duplicate(true),"coins":coins,"revision":7,"levels":{},"boss_protocol":false}
func failure(b:Dictionary,id:String,slot:Variant,reason:String)->void:
	var before:Dictionary=b.duplicate(true)
	ck(Forecast.project(base,b,c,id,slot)=={"available":false,"reason":reason},"reject "+id+" / "+str(slot)+" / "+reason)
	ck(b==before,"rejection input pure")
func changes(r:Dictionary)->Array:
	var out:Array=[]
	for row in r.get("mechanisms",[]):out.append([row.index,row.change,row.before.active,row.after.active,row.after.missing])
	return out
func run()->void:
	c=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	base=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).player
	var original_c:Dictionary=c.duplicate(true)
	var original_base:Dictionary=base.duplicate(true)
	var b:Dictionary=build(["return_disc"])
	var r:Dictionary=Forecast.project(base,b,c,"scavenger_reel")
	ck(r.available and r.coins_before==200 and r.coins_after==172,"Reel funds")
	ck(r.weapon_count_before==1 and r.weapon_count_after==1 and r.item_count_before==0 and r.item_count_after==1,"distinct occupancy")
	ck(r.removed=={} and r.added=={"kind":"item","id":"scavenger_reel","name":"Scavenger Reel","slot":-1,"tier":0},"item descriptors")
	ck(changes(r)==[[11,"enables",false,true,[]]],"Reel enables exact relation")
	var keys:Array=r.keys();keys.sort()
	var expected:Array=["available","reason","id","replace_slot","coins_before","coins_after","weapon_count_before","weapon_count_after","item_count_before","item_count_after","removed","added","mechanisms","tags","weapons","weapon_readouts_available","weapon_readout_warning"];expected.sort()
	ck(keys==expected,"exact success keys")
	for row in r.mechanisms:
		for status in [row.before,row.after]:
			var k:Array=status.keys();k.sort();ck(k==["active","description","missing","name","requires"],"legacy exact status keys")
	r=Forecast.project(base,build(["rivet_gun"], {"scavenger_reel":1}),c,"return_disc")
	ck(changes(r)==[[4,"needs",false,false,["Return Spool"]],[11,"enables",false,true,[]]],"reverse component purchase")
	r=Forecast.project(base,build(["return_disc"],{"scavenger_reel":1}),c,"rivet_gun",0)
	ck(changes(r)==[[11,"disables",true,false,["Return Disc"]]],"destroy last Return disables")
	r=Forecast.project(base,build(["return_disc","return_disc"],{"scavenger_reel":1}),c,"rivet_gun",0)
	ck(changes(r)==[],"one of two Returns retains")
	r=Forecast.project(base,build(["cryo_sprayer"]),c,"fracture_coil")
	ck(changes(r)==[[8,"needs",false,false,["a weapon type other than Cryo Sprayer"]]],"compound still needs")
	r=Forecast.project(base,build(["cryo_sprayer"],{"fracture_coil":1}),c,"rivet_gun")
	ck(changes(r)==[[8,"enables",false,true,[]]],"implicit other weapon enables")
	r=Forecast.project(base,build(["cryo_sprayer","rivet_gun"],{"fracture_coil":1}),c,"cryo_sprayer",1)
	ck(changes(r)==[[8,"disables",true,false,["a weapon type other than Cryo Sprayer"]]],"duplicate Cryo disables")
	b=build(["rivet_gun"],{"power_coil":1})
	r=Forecast.project(base,b,c,"power_coil")
	ck(r.item_count_before==1 and r.item_count_after==1 and is_equal_approx(r.weapons[0].before.damage,17.25) and is_equal_approx(r.weapons[0].after.damage,19.5),"stack occupancy and damage")
	# All eight behavior primary values: hand arithmetic with 2 coils, 2 fans,
	# 2 lenses, 2 capacitors, 2 gears, 1 pouch. Buy second pouch.
	var ids:Array=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
	var damage:Array=[19.5,11.7,66.3,44.2,23.4,46.8,11.7,23.4]
	var intervals:Array=[.4,.85,1.15,.65,.9,1.5,.65,.85]
	var reach:Array=[650.0,390.0,845.0,105.0,429.0,650.0,247.0,1170.0]
	for i in range(ids.size()):
		b=build([ids[i]],{"power_coil":2,"cooling_fan":2,"lens":2,"capacitor":2,"gear":2,"pellet_pouch":1})
		b.weapon_temper=[1]
		r=Forecast.project(base,b,c,"pellet_pouch")
		ck(r.available and r.weapon_readouts_available and r.weapon_readout_warning=="","behavior success "+ids[i])
		var a:Dictionary=r.weapons[0].after
		# Electric/melee thresholds activate only with the corresponding weapon.
		var d:float=damage[i]
		ck(is_equal_approx(a.damage,d*1.6),"hand primary tempered "+ids[i])
		ck(is_equal_approx(a.interval,intervals[i]/1.24),"hand interval "+ids[i])
		ck(is_equal_approx(a.reach,reach[i]),"hand reach "+ids[i])
		ck(a.scope=="CURRENT" and "not guaranteed DPS" in a.note,"numeric scope and limits "+ids[i])
		if i==1:ck(a.pellets==8 and r.weapons[0].before.pellets==6,"Scatter threshold + pouch independent")
		else:ck(not a.has("pellets"),"no generic pellet inflation")
		if i==7:ck(a.total_path==a.reach,"Bankshot total path")
	b=build(["rail_lance","rivet_gun"],{"capacitor":2});b.weapon_temper=[1,1]
	r=Forecast.project(base,b,c,"rail_lance",0)
	ck(r.removed=={"slot":0,"id":"rail_lance","name":"Rail Lance","tier":1} and r.added.tier==0,"tempered destroyed copy recorded")
	ck(r.weapons[0].tier==0 and is_equal_approx(r.weapons[0].before.damage,81.6) and is_equal_approx(r.weapons[0].after.damage,51.0),"same ID resets only replaced tier")
	ck(r.weapons[1].tier==1 and r.weapons[1].before==r.weapons[1].after,"other tier retained")
	for slot in [-2,1,true,0.0,"0",null]:failure(build(),"rivet_gun",slot,"Invalid replacement slot")
	failure(build(),"power_coil",0,"Item purchases do not replace weapons")
	failure(build(),"missing",false,"Unknown item")
	failure(build(["rivet_gun"],{},0),"scavenger_reel",-1,"Not enough scrap")
	failure(build(["rivet_gun"],{"scavenger_reel":1}),"scavenger_reel",-1,"Stack limit reached")
	failure(build(["rivet_gun","rail_lance","orbit_saw","return_disc"]),"bankshot_driver",-1,"Weapon slots full: select replacement")
	failure(build(["rivet_gun"],{"power_coil":1,"cooling_fan":1,"lens":1,"capacitor":1,"gear":1,"pellet_pouch":1,"iron_plate":1,"moss_patch":1}),"scavenger_reel",-1,"Item slots full: sell an item")
	for bad in [[],[true],[2],"bad"]:
		b=build();b.weapon_temper=bad
		var why:String="Weapon tier data does not match the loadout." if bad is Array and bad.is_empty() else "Weapon tier data is invalid."
		failure(b,"rivet_gun",-1,why)
		r=Forecast.project(base,b,c,"power_coil")
		ck(r.available and not r.weapon_readouts_available and r.weapons==[] and r.weapon_readout_warning==why,"item valid despite bad tiers")
	b=build(["rivet_gun"],{"capacitor":2})
	r=Forecast.project(base,b,c,"capacitor")
	ck(r.tags.size()==1 and r.tags[0].index==0 and r.tags[0].before.count==2 and not r.tags[0].before.active and r.tags[0].after.count==3 and r.tags[0].after.active and r.tags[0].after.matching_weapons==[],"Arc activates without equipped beneficiary")
	ck(r.weapons[0].before==r.weapons[0].after,"electric threshold does not boost ballistic")
	b=build(["rail_lance"],{"capacitor":3})
	r=Forecast.project(base,b,c,"capacitor")
	ck(r.tags[0].before.active and r.tags[0].after.active and r.tags[0].after.count==5,"no fourth/fifth extra threshold")
	ck(is_equal_approx(r.weapons[0].before.damage,58.5) and is_equal_approx(r.weapons[0].after.damage,66.0),"threshold applied once not multiplied")
	# Nested returned data must not alias caller data or another report.
	b=build(["return_disc"],{"return_spool":1});b.weapon_temper=[1]
	var before:Dictionary=b.duplicate(true)
	r=Forecast.project(base,b,c,"scavenger_reel")
	var independent:Dictionary=Forecast.project(base,b,c,"scavenger_reel")
	var saved:Dictionary=independent.duplicate(true)
	r.added.name="corrupt";r.weapons[0].after.damage=-100;r.mechanisms[0].after.requires.append("corrupt")
	ck(b==before and c==original_c and base==original_base and independent==saved,"deep alias attack")
	var legacy:Dictionary=c.duplicate(true)
	for pair in legacy.mechanism_synergies:pair.erase("id")
	ck(Forecast.mechanism_status(b,legacy).size()==12,"optional IDs remain accepted")
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"C3 preimplementation hand oracle; no target-derived goldens; pure projection only"}))
	quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("run")
