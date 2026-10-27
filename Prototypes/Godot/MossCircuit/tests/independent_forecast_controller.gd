extends SceneTree
# Frozen from C3 and v36 call graph, not from v37 implementation output.
const Rules=preload("res://scripts/rules.gd")
const Readout=preload("res://scripts/weapon_readout.gd")
const Temper=preload("res://scripts/gameplay/weapon_tempering.gd")
var g
var actual
var checks:int=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func clean(v:Variant)->Variant:
	if v is Object:return {"instance_id":v.get_instance_id()} if is_instance_valid(v) else {"freed":true}
	if v is Array:
		var a:Array=[]
		for x in v:a.append(clean(x))
		return a
	if v is Dictionary:
		var d:Dictionary={}
		for k in v:d[k]=clean(v[k])
		return d
	return v
func props(obj:Object)->Dictionary:
	var d:Dictionary={}
	for p in obj.get_script().get_script_property_list():d[p.name]=clean(obj.get(p.name))
	return d
func snap(n)->Dictionary:
	return {"run":props(n.run),"combat":props(n.combat),"effects":props(n.effects),"mode":props(n.mode),"sequence":n.effect_runtime.sequence,"rng":[n.rng.state,n.loot_rng.state,n.shop_rng.state],"catalog":n.catalog.duplicate(true),"config":n.config.duplicate(true),"settings":n.settings.duplicate(true),"rig":{"slots":clean(n.weapon_rig.slots),"generation":n.weapon_rig.generation,"clock":n.weapon_rig.visible_clock,"last":clean(n.weapon_rig.last_shot),"discs":clean(n.weapon_rig.disc_sprites),"mortars":clean(n.weapon_rig.mortar_marks)}}
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func offer(n,id:String)->Dictionary:
	var entry:Dictionary=Rules.catalog_entry(n.catalog,id).duplicate(true);entry.sold=false;return entry
func setup(n,mode:String,ids:Array,items:Dictionary,tiers:Array=[])->void:
	n._title();n._select_mode(mode);n._start_run(3701)
	n.build.weapons=ids.duplicate(true);n.build.items=items.duplicate(true)
	if not tiers.is_empty():n.build.weapon_temper=tiers.duplicate(true)
	n._recompute();n._open_shop();n.build.coins=200;n.build.coin_fraction=.3;n.build.revision=9;n.reserved_offer={}
	n.stats.hp=37.;n.stats.dash_time=.04;n.stats.dash_cooldown=1.4;n.hurt_clock=.2
	n.effects.cooldowns={"arc_relay":12.7};n.effects.echo_hits=3;n.effects.phase_charge=1;n.effects.chain_charges=2;n.effects.feedback_armed=true;n.effects.shield_spent=true;n.effects.shield=0
	n.hazards=[{"kind":"trail","pos":Vector2(20,20),"life":1.3,"radius":70.,"slow":true}]
	n.pickups=[{"source":"normal","pos":Vector2(50,60),"xp":2,"coins":1}]
func reject(index:Variant,generation:Variant,slot:Variant,why:String)->void:
	var before:Dictionary=snap(g)
	ck(g._offer_forecast(index,generation,slot)=={"available":false,"reason":why},"guard "+why+" / "+str(index)+" / "+str(generation))
	ck(same(before,snap(g)),"guard full authority pure")
func run()->void:
	g=load("res://scenes/main.tscn").instantiate();actual=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);root.add_child(actual);g.set_process(false);actual.set_process(false)
	for mode in ["arena","rooms"]:
		setup(g,mode,["return_disc","rivet_gun","rail_lance","orbit_saw"],{"scavenger_reel":1,"fracture_coil":1},[1,1,0,1])
		g.shop_offers=[offer(g,"cryo_sprayer"),offer(g,"power_coil")]
		var generation:int=g.shop_generation
		for state in ["title","playing","inventory","dead","won"]:
			g.state=state;reject(-1,generation,-2,"Shop view expired")
		g.state="shop"
		for gen in [generation-1,generation+1,true,float(generation),str(generation),null]:reject(0,gen,-1,"Shop view expired")
		for index in [-1,2,true,0.0,"0",null]:reject(index,generation,-1,"Offer unavailable")
		g.shop_offers[0].sold=true;g.build.weapon_temper=[2]
		reject(0,generation,-2,"Offer already sold")
		g.shop_offers[0].sold=false
		reject(0,generation,-2,"Weapon tier data does not match the loadout.")
		g.build.weapon_temper=[1,1,0,1]
		g.reserved_offer={"id":"cryo_sprayer","price":43,"slot":0,"token":1,"offer":g.shop_offers[0].duplicate(true)}
		reject(0,generation,-2,"Reserved offer unavailable: catalog price changed")
		g.reserved_offer.price=44
		reject(0,generation,-2,"Invalid replacement slot")
		g.reserved_offer={}
		var before:Dictionary=snap(g)
		for _i in range(12):
			var v:Dictionary=g._view()
			ck(v.offers[0].forecast_options.size()==4 and v.offers[1].forecast_options.size()==1,"all full-bag choices / item append")
			for slot in range(4):
				var row:Dictionary=v.offers[0].forecast_options[slot]
				ck(row.replace_slot==slot and row.report==g._offer_forecast(0,generation,slot),"view binds ordered slot to exact generation")
			ck(v.offers[1].forecast_options[0].replace_slot==-1,"item append only")
			v.offers[0].forecast_options[0].report.added.name="mutated detached view"
		ck(same(before,snap(g)),"12 repeated views/projections deeply preserve world/effects/rig/RNG")
		# Separate real instance is the authority comparator, never a saved golden.
		for spec in [[["return_disc"],{},[],"scavenger_reel",-1],[["return_disc","rivet_gun","rail_lance","orbit_saw"],{"scavenger_reel":1},[1,1,0,1],"cryo_sprayer",0],[["cryo_sprayer"],{"fracture_coil":1},[1],"rivet_gun",-1],[["rail_lance","rivet_gun"],{"capacitor":2},[1,1],"rail_lance",0]]:
			setup(g,mode,spec[0],spec[1],spec[2]);setup(actual,mode,spec[0],spec[1],spec[2])
			g.shop_offers=[offer(g,spec[3])];actual.shop_offers=[offer(actual,spec[3])]
			before=snap(g)
			var report:Dictionary=g._offer_forecast(0,g.shop_generation,spec[4])
			ck(report.available,"controlled realbuy eligible")
			actual._buy(0,actual.shop_generation,spec[4])
			ck(actual.shop_offers[0].sold and actual.build.revision==10,"actual buy committed once")
			ck(report.coins_after==actual.build.coins and report.weapon_count_after==actual.build.weapons.size() and report.item_count_after==actual.build.items.size(),"projection vs real resulting counts/funds")
			for row in report.weapons:
				var entry:Dictionary=Rules.catalog_entry(actual.catalog,actual.build.weapons[row.slot])
				ck(row.id==entry.id and row.tier==Temper.tier_at(actual.build,row.slot,entry.id),"actual surviving copy identity/tier")
				ck(row.after==Readout.describe(entry,actual.stats,true,Temper.multiplier(actual.build,actual.catalog,row.slot,entry.id)),"projection vs actual equipped numeric adapter")
			ck(same(before,snap(g)),"real transaction on other instance never touches preview instance")
			ck(actual._offer_forecast(0,actual.shop_generation-1,spec[4])=={"available":false,"reason":"Shop view expired"},"committed generation invalidates stale preview")
	var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g,actual]);g.queue_free();actual.queue_free();await process_frame;await teardown.finish(self)
	print(JSON.stringify({"checks":checks,"failures":failures,"scope":"C3 independent controller guard/full-state purity + separate-instance real purchases; UI selector/focus and native separate"}))
	quit(0 if failures.is_empty() else 1)
func _initialize()->void:call_deferred("run")
