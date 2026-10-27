extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var checks:=0
var failures:Array=[]
var g
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func cold(view:Dictionary)->Dictionary:
	for s in view.synergy_status:
		if s.name=="Cold Snap":return s
	return {}
func reset(weapons:Array,items:Dictionary={})->void:
	g._title();g._start_run(874205);g.build.weapons=weapons.duplicate();g.build.items=items.duplicate();g.build.coins=1000;g._recompute()
func offer(id:String)->void:
	g._open_shop();g.shop_offers=[{"id":id,"sold":false,"weight_multiplier":1.0,"bias_reasons":[]}];g._render_shop()
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	var c:Dictionary=g.catalog
	check(Rules.validate_catalog(c).is_empty(),"new catalog valid")
	check(c.weapons.size()==8 and c.items.size()==29 and Rules.catalog_entry(c,"feedback_diode").id=="feedback_diode" and Rules.catalog_entry(c,"bankshot_driver").id=="bankshot_driver" and Rules.catalog_entry(c,"bounce_guide").id=="bounce_guide","explicit v26 8+29 including reviewed additions")
	reset(["cryo_sprayer"])
	var aff:Dictionary=Rules.shop_affinity(g.build,c)
	check("fracture_coil" in aff.missing_ids,"Cryo missing partner bias")
	var pool:Array=Rules.weighted_pool(g.build,c);var coil:Dictionary=pool.filter(func(e):return e.id=="fracture_coil")[0]
	check(is_equal_approx(coil.weight,3.85),"exact Cryo→Coil tag+partner weight")
	check(not cold(g._view()).active,"Cryo alone inactive")
	g.build.items={"fracture_coil":1};g._recompute();var status:Dictionary=cold(g._view())
	check(not status.active and not status.missing.is_empty(),"Cryo+Coil needs distinct weapon")
	g.build.weapons=["cryo_sprayer","cryo_sprayer"];g._recompute();check(not cold(g._view()).active,"duplicate type not prerequisite")
	g.build.weapons.append("rivet_gun");g._recompute();check(cold(g._view()).active,"mixed-type pair active")
	check(not Rules.weighted_pool(g.build,c).any(func(e):return e.id=="fracture_coil"),"unique owned Coil filtered")
	reset(["rivet_gun"],{"fracture_coil":1});aff=Rules.shop_affinity(g.build,c)
	check("cryo_sprayer" in aff.missing_ids and not cold(g._view()).active,"Coil alone declares missing setup")
	for e in Rules.weighted_pool(g.build,c):check(e.weight>0 and e.weight<=6,"positive capped exploration "+e.id)
	var rng1:=RandomNumberGenerator.new();var rng2:=RandomNumberGenerator.new();rng1.seed=4242;rng2.seed=4242
	for i in range(50):
		var stock:Array=Rules.draw_shop(g.build,c,rng1);check(stock==Rules.draw_shop(g.build,c,rng2),"expanded seeded replay "+str(i))
		var ids:Array=[]
		for entry in stock:check(not entry.id in ids,"without replacement "+str(i)+"/"+entry.id);ids.append(entry.id)
	reset(["rivet_gun"]);g.build.coins=43;offer("cryo_sprayer");var gen:int=g.shop_generation;var old:Dictionary=g.build.duplicate(true)
	check(not g._buy(0,gen) and g.build==old and not g.shop_offers[0].sold,"insufficient buy atomic")
	g.build.coins=44;check(g._buy(0,gen) and g.build.coins==0 and g.build.weapons==["rivet_gun","cryo_sprayer"],"exact-price weapon buy")
	check(not g._buy(0,gen) and g.build.coins==0,"stale click cannot double-buy")
	g.build.coins=28;offer("fracture_coil");gen=g.shop_generation;check(g._buy(0,gen) and g.build.coins==0 and g.build.items.fracture_coil==1,"exact-price Coil buy")
	check(cold(g._view()).active,"purchased mixed build active")
	g.build.coins=1000;offer("fracture_coil");gen=g.shop_generation;old=g.build.duplicate(true)
	check(not g._buy(0,gen) and g.build==old,"unique duplicate rejected atomically")
	reset(["rivet_gun","rail_lance","scrap_shotgun","return_disc"]);offer("cryo_sprayer");gen=g.shop_generation;old=g.build.duplicate(true)
	check(not g._buy(0,gen) and g.build==old,"full slots require explicit replacement")
	check(g._buy(0,gen,2) and g.build.weapons==["rivet_gun","rail_lance","cryo_sprayer","return_disc"] and g.build.coins==956,"explicit replacement has no refund")
	reset(["cryo_sprayer","rivet_gun"],{"fracture_coil":1});g._open_shop();gen=g.shop_generation;var money:int=g.build.coins
	check(g._sell_weapon(1,gen) and g.build.coins==money+12 and not cold(g._view()).active,"selling only different type deactivates pair")
	gen=g.shop_generation;money=g.build.coins;check(g._sell_item("fracture_coil",gen) and g.build.coins==money+14 and not g.build.items.has("fracture_coil"),"Coil sale exact50percent")
	check("fracture_coil" in Rules.shop_affinity(g.build,c).missing_ids,"sale affects next refresh affinity")
	var saved:Dictionary=g.build.duplicate(true);var states:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
	for i in range(3):g.ui.show_shop(g._view());g.ui.show_inventory(g._view())
	check(g.build==saved and states==[g.rng.state,g.loot_rng.state,g.shop_rng.state],"UI views do not mutate build/RNG")
	for field in ["cone_degrees","chill_duration","chill_speed"]:
		for bad_value in [-1.0,0.0,"not-number"]:
			var bad:Dictionary=c.duplicate(true)
			for weapon in bad.weapons:
				if weapon.id=="cryo_sprayer":weapon[field]=bad_value
			check(not Rules.validate_catalog(bad).is_empty(),"reject invalid Cryo "+field+"="+str(bad_value))
	var bad:Dictionary=c.duplicate(true)
	for item in bad.items:
		if item.id=="fracture_coil":item.fracture_damage=-1
	check(not Rules.validate_catalog(bad).is_empty(),"reject negative shatter damage")
	bad=c.duplicate(true)
	for pair in bad.mechanism_synergies:
		if pair.id=="cold_snap":pair.requires_other_weapon_than="unknown"
	check(not Rules.validate_catalog(bad).is_empty(),"reject unknown alternate-weapon prerequisite")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"independent controlled catalog/affinity/UI-view/transaction test; not native button interaction"}
	var outputs:PackedStringArray=OS.get_cmdline_user_args()
	if not outputs.is_empty():FileAccess.open(outputs[0],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
