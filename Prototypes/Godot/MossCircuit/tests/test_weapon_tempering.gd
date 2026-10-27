extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Temper=preload("res://scripts/gameplay/weapon_tempering.gd")
const Readout=preload("res://scripts/weapon_readout.gd")
var game
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode_id:String,ids:Array=["rivet_gun","rivet_gun","rail_lance","rivet_gun"])->void:
	game._title();game._select_mode(mode_id);game._start_run(33128);game.set_process(false)
	game.build.weapons=ids.duplicate();game.build.items={"mirror_shell":1,"echo_chamber":1,"phase_capacitor":1,"medic_seed":1,"arc_relay":1,"kill_cell":1,"dash_resin":1,"pulse_boots":1}
	game.build.coins=113;game.build.coin_fraction=.375;game._recompute();game.weapon_clocks=[]
	for index in range(ids.size()):game.weapon_clocks.append([.375,-.125,0.0,1.125][index])
	game.state="shop";game.stats.hp=53.25;game.stats.dash_time=.125;game.stats.dash_cooldown=1.25;game.hurt_clock=.2
	game.shop_offers=[{"id":"rail_lance","sold":false,"weight_multiplier":2.0,"bias_reasons":["fixed fixture"]},{"id":"power_coil","sold":false,"weight_multiplier":1.0,"bias_reasons":[]}]
	game._reserve_offer(0,game.shop_generation)
	game.effects.echo_hits=3;game.effects.phase_charge=2;game.effects.medic_damage=14.5;game.effects.chain_charges=2
	game.effects.cooldowns={"arc_relay":24.0,"dash_resin":29.0};game.effects.shield_spent=true;game.effects.shield=0
	game.hazards=[{"kind":"trail","life":1.7,"radius":70.0,"next_tick":22.0,"slow":true,"pos":Vector2(100,100)}]
	for index in range(game.weapon_rig.slots.size()):
		var record:Dictionary=game.weapon_rig.slots[index]
		record.age=.02+index*.01;record.aim=Vector2.from_angle(index*.3);record.pose={"sentinel":index}
	game.weapon_rig.visible_clock=4.125;game.weapon_rig.last_shot={"slot":0,"id":ids[0],"historical":true}
func authority()->Dictionary:
	return {"build":game.build.duplicate(true),"stats":game.stats.duplicate(true),"clocks":game.weapon_clocks.duplicate(true),"state":game.state,"message":game.shop_message,"generation":game.shop_generation,
	"hold":game.reserved_offer.duplicate(true),"offers":game.shop_offers.duplicate(true),"rng":[game.rng.state,game.shop_rng.state,game.loot_rng.state],
	"time":[game.elapsed,game.wave_time,game.hurt_clock,game.upgrade_pending,game.choice_generation],"shots":game.bullets.duplicate(true),"blasts":game.pending_blasts.duplicate(true),"visuals":game.effect_visuals.duplicate(true),"hazards":game.hazards.duplicate(true),"pickups":game.pickups.duplicate(true),
	"effects":[game.effects.epoch,game.effects.last_sequence,game.effect_runtime.sequence,game.effects.active.duplicate(true),game.effects.echo_hits,game.effects.phase_charge,game.effects.medic_damage,game.effects.chain_charges,game.effects.cooldowns.duplicate(true),game.effects.feedback_armed,game.effects.shield,game.effects.shield_spent]}
func rig_state()->Dictionary:
	var rows:Array=[]
	for slot in game.weapon_rig.slots:rows.append({"id":slot.id,"slot":slot.slot,"age":slot.age,"aim":slot.aim,"pose":slot.pose.duplicate(true),"sprite":slot.sprite.get_instance_id()})
	return {"rows":rows,"clock":game.weapon_rig.visible_clock,"generation":game.weapon_rig.generation,"last_shot":game.weapon_rig.last_shot.duplicate(true)}
func whole()->Dictionary:return {"authority":authority(),"rig":rig_state()}
func buttons(node:Node)->Array:
	var found:Array=[]
	if node is Button:found.append(node)
	for child in node.get_children():found.append_array(buttons(child))
	return found
func fuse(slot:int,donor:int)->bool:return game._temper_weapon(slot,donor,game.shop_generation,game.build.weapons[slot],game.build.weapons[donor])
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	check(Rules.validate_catalog(game.catalog).is_empty(),"catalog valid")
	check(game.catalog.weapon_tempering.max_tier==1 and game.catalog.weapon_tempering.primary_damage_multiplier==1.6,"authored profile")
	for value in [null,true,false,{},[],"1.6",0,-1,1,2,INF,NAN]:
		var profile:Dictionary=game.catalog.weapon_tempering.duplicate();profile.primary_damage_multiplier=value
		check(not Temper.validate_profile(profile).is_empty(),"bad multiplier "+str(value))
	for value in [null,true,false,{},[],"1",0,2,1.5,INF,NAN]:
		var profile:Dictionary=game.catalog.weapon_tempering.duplicate();profile.max_tier=value
		check(not Temper.validate_profile(profile).is_empty(),"bad maximum "+str(value))
	for mode_id in ["arena","rooms"]:
		for count in [2,3,4]:
			for slot in range(count):
				var ids:Array=[]
				for _copy in range(count):ids.append("rivet_gun")
				setup(mode_id,ids);var old:=whole();var donor:int=1 if slot==0 else 0
				var generation:int=game.shop_generation
				check(fuse(slot,donor),"valid exact survivor "+str([mode_id,count,slot]))
				var expected:Dictionary=old.authority.duplicate(true)
				expected.build=Temper.projected_build(old.authority.build,slot,donor);expected.build.revision+=1
				expected.clocks.remove_at(donor);expected.generation+=1;expected.message=game.shop_message
				check(authority()==expected,"only declared authority delta "+str([mode_id,count,slot]))
				var expected_rig:Dictionary=old.rig.duplicate(true);expected_rig.rows.remove_at(donor)
				for i in range(donor,expected_rig.rows.size()):expected_rig.rows[i].slot=i;expected_rig.rows[i].pose={}
				check(rig_state()==expected_rig,"retain exact clock/aim/sprite/recoil "+str([mode_id,count,slot]))
				var stable:=whole()
				check(not game._temper_weapon(slot,donor,generation,"rivet_gun","rivet_gun") and whole()==stable,"duplicate callback stale")
				check(not game._buy(0,generation) and not game._sell_weapon(0,generation) and not game._move_weapon(0,1,generation,"rivet_gun") and whole()==stable,"old other callbacks stale")
		setup(mode_id);var before:=whole();game._view();game._render_shop();check(whole()==before,"preview/render pure")
		var payload:Dictionary={"slot":0,"donor_slot":1,"generation":game.shop_generation,"id":"rivet_gun","donor_id":"rivet_gun"}
		for key in payload:
			for bad in [null,true,false,{},[],"0",0.0,1.5]:
				var invalid:Dictionary=payload.duplicate();invalid[key]=bad;game._on_intent("temper_weapon",invalid)
				check(whole()==before,"raw payload rejection "+key+str(bad))
		for values in [[0,0],[0,3],[2,0],[-1,0],[5,0],[0,5]]:
			check(not game._temper_weapon(values[0],values[1],game.shop_generation,"rivet_gun","rivet_gun") and whole()==before,"invalid or nondeterministic donor "+str(values))
		for wrong_state in ["title","playing","paused","inventory","upgrade","dead","won","room_clear"]:
			setup(mode_id);game.state=wrong_state;before=whole()
			check(not fuse(0,1) and whole()==before,"wrong state "+wrong_state)
		for bad in [null,true,{},"0",[],[0],[0,0,0],[0,0,0,0,0],[0,0,0,0.0],[0,0,0,true],[0,0,0,2],[0,0,0,-1]]:
			setup(mode_id);game.build.items.erase("pulse_boots");game._recompute();game.build.weapon_temper=bad;before=whole()
			check(not fuse(0,1) and not game._buy(0,game.shop_generation) and not game._sell_weapon(0,game.shop_generation) and not game._move_weapon(0,1,game.shop_generation,"rivet_gun") and whole()==before,"invalid tiers alignments atomic "+str(bad))
			check(Temper.multiplier(game.build,game.catalog,0,"rivet_gun")==1.0,"invalid tiers no damage boost")
			game._view();check(whole()==before,"invalid view does not repair")
			check(game._buy(1,game.shop_generation),"invalid tiers do not blanket-lock module buy")
		for bad in [[],[0,0,0],[0,0,0,true],[0,0,0,NAN],[0,0,0,INF]]:
			setup(mode_id);game.weapon_clocks=bad;before=whole()
			check(not fuse(0,1) and var_to_bytes(whole())==var_to_bytes(before),"bad clocks atomic")
		for kind in ["ordinary","return_disc","bankshot_driver","mortar"]:
			setup(mode_id)
			if kind=="mortar":game.pending_blasts=[{"damage":19,"delay":.4}]
			else:game.bullets=[{"weapon":kind,"damage":19,"slot":0,"life":.3}]
			before=whole();check(not fuse(0,1) and whole()==before,"in-flight atomic "+kind)
		setup(mode_id,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
		check(fuse(0,1) and game.build.weapon_temper==[1,0,0],"first independent pair")
		check(fuse(1,2) and game.build.weapon_temper==[1,1],"second independent pair")
		before=whole();check(not fuse(0,1) and whole()==before,"no tier ladder")
		game.build.coins=500;game.shop_offers=[{"id":"rivet_gun","sold":false}]
		check(game._buy(0,game.shop_generation) and game.build.weapon_temper==[1,1,0],"purchase appends standard")
		check(game._move_weapon(0,1,game.shop_generation,"rivet_gun") and game.build.weapon_temper==[1,1,0],"same ID move valid")
		game.shop_offers=[{"id":"rivet_gun","sold":false}]
		check(game._buy(0,game.shop_generation,0) and game.build.weapon_temper==[0,1,0],"same ID replacement standard")
		check(game._move_weapon(1,1,game.shop_generation,"rivet_gun") and game.build.weapon_temper==[0,0,1],"tier follows identical ID move")
		var coins:int=game.build.coins;var quote:int=floori(24*game.stats.resale)
		check(game._sell_weapon(2,game.shop_generation) and game.build.coins==coins+quote and game.build.weapon_temper==[0,0],"tier sale one ordinary value")
		for id in ["rivet","scatter","rail"]:
			check(game._start_run(3301,id) and not game.build.has("weapon_temper"),"starter standard "+id)
		# R2: truthful single-copy feedback, without changing availability or guard precedence.
		setup(mode_id,["rivet_gun"])
		check(game._weapon_temper_view(0).reason=="Requires another STANDARD copy of this weapon.","single standard donor hint unchanged "+mode_id)
		setup(mode_id,["rivet_gun","rivet_gun"]);check(fuse(0,1),"single tempered hint setup "+mode_id)
		var hint_before:Dictionary=whole();var hint:Dictionary=game._weapon_temper_view(0)
		check(not hint.available and hint.donor_slot==-1 and hint.reason=="TEMPERED / maximum tier. Cannot be fused again.","single tempered maximum-tier reason "+mode_id)
		check(game._view().weapons[0].tempering.reason==hint.reason and whole()==hint_before,"actual view truthful and pure "+mode_id)
		check(not game._temper_weapon(0,1,game.shop_generation,"rivet_gun","rivet_gun") and whole()==hint_before,"single tempered action remains rejected "+mode_id)
		check(not game._temper_weapon(0,1,game.shop_generation-1,"rivet_gun","rivet_gun") and whole()==hint_before,"single tempered stale remains rejected "+mode_id)
		game.bullets=[{"weapon":"rivet_gun","life":.3}]
		check(game._weapon_temper_view(0).reason=="Weapon shots are still active; tempering is unavailable.","single tempered flight reason precedence "+mode_id)
		game.bullets=[];game.build.weapon_temper=[1.0]
		check(game._weapon_temper_view(0).reason=="Weapon tier data is invalid.","single malformed reason precedence "+mode_id)
		# All three tag thresholds and detached projected base, not derived stats.
		for id in ["rail_lance","orbit_saw","scrap_shotgun"]:
			setup(mode_id,[id,id,id]);game.build.items={};game._recompute();game.build.levels={"damage":1};game._recompute()
			var view:Dictionary=game._view();var preview:Dictionary=view.weapons[0].tempering.preview
			var base_damage:float=Rules.catalog_entry(game.catalog,id).damage
			check(is_equal_approx(preview.damage,base_damage*1.25*1.6),"preview loss threshold/original base "+id)
			check(fuse(0,1),"threshold fusion "+id)
			check(game._view().weapons[0].weapon_readout==preview,"preview equals actual readout "+id)
			if id=="scrap_shotgun":check(view.weapons[0].weapon_readout.pellets==6 and preview.pellets==5,"pellet threshold loss")
		for size in [Vector2i(960,540),Vector2i(1280,720)]:
			setup(mode_id);root.size=size;game._render_shop();await process_frame;await process_frame
			var fusions:Array=buttons(game.ui.modal).filter(func(b):return b.text.begins_with("TEMPER /"))
			check(fusions.size()==3,"eligible copies only UI")
			check(game.ui.first_focus!=null and not game.ui.first_focus.text.begins_with("TEMPER"),"fusion not default")
			before=whole();game._view();game._render_shop();check(whole()==before,"UI repeated pure")
			game.state="inventory";game.ui.show_inventory(game._view())
			check(buttons(game.ui.modal).filter(func(b):return b.text.begins_with("TEMPER /")).is_empty(),"inventory readonly")
	game.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failed":failures.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
