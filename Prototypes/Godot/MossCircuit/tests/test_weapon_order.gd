extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var game
var passed:=0
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func setup(mode_id:String,ids:Array=["cryo_sprayer","orbit_saw","rivet_gun","return_disc"])->void:
	game._title();game._select_mode(mode_id);game._start_run(30128);game.set_process(false)
	game.build.weapons=ids.duplicate();game.build.items={"fracture_coil":1};game._recompute()
	game.weapon_clocks=[]
	for index in range(ids.size()):game.weapon_clocks.append([.375,-.125,0.0,1.125][index])
	game.build.coins=73;game.build.coin_fraction=.1;game.stats.hp=53
	game.shop_offers=[{"id":"rail_lance","sold":false,"weight_multiplier":1.0,"bias_reasons":[]},{"id":"power_coil","sold":true,"weight_multiplier":1.0,"bias_reasons":[]}]
	game.state="shop";game.shop_message="Original stock"
	game._reserve_offer(0,game.shop_generation)
	game.effects.echo_hits=3;game.effects.phase_charge=2;game.effects.cooldowns={"arc_relay":24.0}
	for index in range(game.weapon_rig.slots.size()):
		var record:Dictionary=game.weapon_rig.slots[index]
		record.age=.02+index*.01;record.aim=Vector2.from_angle(index*.3);record.pose={"sentinel":index}
	game.weapon_rig.visible_clock=4.125;game.weapon_rig.last_shot={"slot":0,"id":ids[0],"historical":true}
func authority()->Dictionary:
	return {"build":game.build.duplicate(true),"stats":game.stats.duplicate(true),"clocks":game.weapon_clocks.duplicate(true),
	"state":game.state,"message":game.shop_message,"generation":game.shop_generation,
	"hold":game.reserved_offer.duplicate(true),"offers":game.shop_offers.duplicate(true),
	"rng":[game.rng.state,game.shop_rng.state,game.loot_rng.state],
	"time":[game.elapsed,game.wave_time,game.hurt_clock,game.upgrade_pending,game.choice_generation],
	"shots":game.bullets.duplicate(true),"blasts":game.pending_blasts.duplicate(true),
	"visuals":game.effect_visuals.duplicate(true),"hazards":game.hazards.duplicate(true),
	"effects":[game.effects.epoch,game.effects.last_sequence,game.effect_runtime.sequence,game.effects.echo_hits,game.effects.phase_charge,game.effects.cooldowns.duplicate(true),game.effects.feedback_armed]}
func rig_state()->Dictionary:
	var rows:Array=[]
	for slot in game.weapon_rig.slots:
		rows.append({"id":slot.id,"slot":slot.slot,"age":slot.age,"aim":slot.aim,"pose":slot.pose.duplicate(true),"sprite":slot.sprite.get_instance_id()})
	return {"rows":rows,"clock":game.weapon_rig.visible_clock,"generation":game.weapon_rig.generation,"last_shot":game.weapon_rig.last_shot.duplicate(true)}
func whole()->Dictionary:return {"authority":authority(),"rig":rig_state()}
func buttons(node:Node)->Array:
	var found:Array=[]
	if node is Button:found.append(node)
	for child in node.get_children():found.append_array(buttons(child))
	return found
func run()->void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	check(game.catalog.weapons.size()==8 and game.catalog.items.size()==29,"catalog count unchanged")
	for mode_id in ["arena","rooms"]:
		for count in [2,3,4]:
			var ids:Array=["cryo_sprayer","orbit_saw","rivet_gun","return_disc"].slice(0,count)
			for slot in range(count):
				for step in [-1,1]:
					setup(mode_id,ids);var before:=whole();var generation:int=game.shop_generation
					var target:int=slot+step;var accepted:bool=game._move_weapon(slot,step,generation,ids[slot])
					if target<0 or target>=count:
						check(not accepted and whole()==before,"boundary atomic "+mode_id+str([count,slot,step]));continue
					check(accepted,"valid adjacent "+mode_id+str([count,slot,step]))
					var expected:Dictionary=before.authority.duplicate(true)
					expected.build.weapons[slot]=ids[target];expected.build.weapons[target]=ids[slot]
					expected.clocks[slot]=before.authority.clocks[target];expected.clocks[target]=before.authority.clocks[slot]
					expected.build.revision+=1;expected.generation+=1;expected.message=game.shop_message
					check(authority()==expected,"only declared authority delta "+mode_id+str([count,slot,step]))
					var expected_rig:Dictionary=before.rig.duplicate(true)
					expected_rig.rows[slot]=before.rig.rows[target].duplicate(true);expected_rig.rows[target]=before.rig.rows[slot].duplicate(true)
					expected_rig.rows[slot].slot=slot;expected_rig.rows[target].slot=target
					expected_rig.rows[slot].pose={};expected_rig.rows[target].pose={}
					check(rig_state()==expected_rig,"copy records and historical rig state "+mode_id+str([count,slot,step]))
					var current:=whole()
					check(not game._move_weapon(slot,step,generation,ids[slot]) and whole()==current,"queued duplicate stale "+mode_id)
					check(not game._buy(0,generation) and whole()==current,"old buy invalidated "+mode_id)
					check(not game._release_offer(game.reserved_offer.token,generation) and whole()==current,"old release invalidated "+mode_id)
		for same_clock in [false,true]:
			setup(mode_id,["rivet_gun","rivet_gun"])
			if same_clock:game.weapon_clocks=[.375,.375]
			var old_clocks:Array=game.weapon_clocks.duplicate();var old_gen:int=game.shop_generation
			check(game._move_weapon(0,1,old_gen,"rivet_gun"),"duplicate copy move accepted "+mode_id+str(same_clock))
			check(game.weapon_clocks==[old_clocks[1],old_clocks[0]] and game.shop_generation==old_gen+1,"duplicate exact clocks "+mode_id)
		setup(mode_id)
		var old:=whole();var payload:Dictionary={"slot":0,"step":1,"generation":game.shop_generation,"id":"cryo_sprayer"}
		for key in ["slot","step","generation","id"]:
			for bad in [null,true,false,{},[],"0",1.0,1.5]:
				var invalid:Dictionary=payload.duplicate();invalid[key]=bad
				game._on_intent("move_weapon",invalid)
				check(whole()==old,"raw type rejection "+mode_id+key+str(bad))
		for step in [-2,0,2,999]:
			check(not game._move_weapon(0,step,game.shop_generation,"cryo_sprayer") and whole()==old,"invalid step "+mode_id+str(step))
		check(not game._move_weapon(0,1,game.shop_generation,"orbit_saw") and whole()==old,"wrong copy ID "+mode_id)
		for state in ["title","playing","paused","inventory","upgrade","dead","won","room_clear"]:
			setup(mode_id);game.state=state;old=whole()
			check(not game._move_weapon(0,1,game.shop_generation,"cryo_sprayer") and whole()==old,"wrong state "+mode_id+state)
		for bad_clocks in [[],[0],[0,0,0,0,0],[0,0,0,"0"],[0,0,0,true],[0,0,0,NAN],[0,0,0,INF]]:
			setup(mode_id);game.weapon_clocks=bad_clocks.duplicate();old=whole()
			check(not game._move_weapon(0,1,game.shop_generation,"cryo_sprayer"),"malformed clocks rejected "+mode_id+str(bad_clocks))
			# NAN is unequal to itself; separately compare all other state and serialized exact values.
			check(var_to_bytes(whole())==var_to_bytes(old),"malformed rejection byte-atomic "+mode_id)
		for kind in ["rivet_gun","return_disc","bankshot_driver","mortar"]:
			setup(mode_id)
			if kind=="mortar":game.pending_blasts=[{"weapon":"shock_mortar","delay":.4,"damage":17}]
			else:game.bullets=[{"weapon":kind,"life":.8,"slot":0,"pos":Vector2(500,300),"velocity":Vector2(100,0)}]
			old=whole();check(not game._move_weapon(0,1,game.shop_generation,"cryo_sprayer") and whole()==old,"flight not cleared "+mode_id+kind)
			check(not game._weapon_order_view().available,"flight disabled "+mode_id+kind)
		for size in [Vector2i(960,540),Vector2i(1280,720)]:
			setup(mode_id);root.size=size;game._render_shop();await process_frame;await process_frame
			var moves:Array=buttons(game.ui.modal).filter(func(b):return b.text.begins_with("MOVE "))
			check(moves.size()==8,"eight adjacent controls "+mode_id+str(size))
			check(moves[0].disabled and moves[7].disabled,"boundary UI disabled "+mode_id+str(size))
			check(game.ui.first_focus!=null and not game.ui.first_focus.text.begins_with("MOVE "),"move never default "+mode_id+str(size))
			var snapshot:=authority();game._view();game._render_shop();check(authority()==snapshot,"view/render readonly "+mode_id+str(size))
			game.state="inventory";game.ui.show_inventory(game._view())
			check(buttons(game.ui.modal).filter(func(b):return b.text.begins_with("MOVE ")).is_empty(),"ordinary inventory has no order action "+mode_id+str(size))
		setup(mode_id);game.shop_offers=[];game.reserved_offer.clear();game._render_shop();await process_frame
		check(game.ui.first_focus!=null and not game.ui.first_focus.text.begins_with("MOVE "),"empty-stock move not default "+mode_id)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failed":failures.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 1)
