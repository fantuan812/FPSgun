extends "evidence-workspace/moss-v39-ui/B/native-r3/fixture.gd"
## Read-only size observer. Cases, assertions, runtime and inputs unchanged.
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_dimensions)
	super._initialize()
func _observe_dimensions()->void:
	var value:Dictionary={"logical":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale":str(root.content_scale_size),"os_size":str(DisplayServer.window_get_size()),"os_position":str(DisplayServer.window_get_position())}
	var encoded:String=JSON.stringify(value)
	if encoded!=observed_size:observed_size=encoded;print("B_NATIVE_DIMENSIONS "+encoded)

func scroll_group(first:Control,last:Control)->bool:
	var result:bool=await super.scroll_group(first,last)
	var scroll:ScrollContainer=scroll_of(first) if first!=null else null
	var row:Dictionary={"result":result,"budget":128,"first_exists":first!=null,"last_exists":last!=null,"scroll_exists":scroll!=null}
	if first!=null:row.first_text=first.text if first is Label else first.get_class()
	if scroll!=null and first!=null and last!=null:
		row.merged_rect=str(first.get_global_rect().merge(last.get_global_rect()));row.scroll_rect=str(scroll.get_global_rect());row.scroll_vertical=scroll.scroll_vertical;row.bar_max=scroll.get_v_scroll_bar().max_value;row.bar_page=scroll.get_v_scroll_bar().page
	print("B_SCROLL_FINAL "+JSON.stringify(row))
	return result

func gameplay_authority()->Dictionary:
	var enemies:Array=[]
	for e in g.enemies:enemies.append({"id":e.id,"pos":e.pos,"hp":e.hp,"state":e.ai_state,"speed":e.speed,"damage":e.damage})
	var old_effects:Dictionary={"epoch":g.effects.epoch,"sequence":g.effects.last_sequence,"active":g.effects.active.duplicate(true),"cooldowns":g.effects.cooldowns.duplicate(true),"shield":g.effects.shield,"shield_spent":g.effects.shield_spent,"echo_hits":g.effects.echo_hits,"phase_charge":g.effects.phase_charge,"medic_damage":g.effects.medic_damage,"chain_charges":g.effects.chain_charges,"feedback_armed":g.effects.feedback_armed,"recoil":g.effects.recoil_cooldown.duplicate(true)}
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"enemies":enemies,"player_pos":g.player_pos,"bullets":g.bullets.duplicate(true),"enemy_bullets":g.enemy_bullets.duplicate(true),"pickups":g.pickups.duplicate(true),"hazards":g.hazards.duplicate(true),"pending_blasts":g.pending_blasts.duplicate(true),"beams":g.combat.pulse_beams.duplicate(true),"waves":g.combat.seismic_waves.duplicate(true),"motion":g.combat.new_weapon_motion.duplicate(true),"elapsed":g.elapsed,"wave_time":g.wave_time,"clocks":g.weapon_clocks.duplicate(),"epoch":g.combat.new_weapon_epoch,"wave_sequence":g.combat.new_wave_sequence,"combat_serial":g.combat.combat_tick_serial,"last_tick":g.combat.new_weapon_last_tick,"session":[g.state,g.wave,g.level,g.xp,g.kills,g.run.upgrade_pending,g.run.shop_pending,g.run.boss_defeated,g.combat.focus_enemy_id],"effects":old_effects,"B":state(),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state]}
func refresh()->void:
	var before:PackedByteArray=var_to_bytes(gameplay_authority())
	await super.refresh()
	var after:PackedByteArray=var_to_bytes(gameplay_authority())
	print("B_PRESENTATION_AUTHORITY "+JSON.stringify({"scene":current.get("id",""),"before":hash_bytes(before),"after":hash_bytes(after),"unchanged":before==after,"scope":"Selected actual gameplay world/session/effects/B/RNG; rig pose/aim/hidden/sprite presentation intentionally excluded, not entire-object readonly."}))
func stage(name:String)->void:
	await super.stage(name)
	var slots:Array=[]
	for slot in g.weapon_rig.slots:
		var geometry:Dictionary=g.weapon_rig.geometry.get(slot.id,{})
		slots.append({"id":slot.id,"slot":slot.slot,"pose":slot.pose.duplicate(true),"sprite_scale":[slot.sprite.scale.x,slot.sprite.scale.y],"sprite_position":str(slot.sprite.position),"visible":slot.sprite.visible,"visible_length":geometry.get("visible_length",28),"reference_width":geometry.get("reference_width",geometry.get("region",[0,0,32,16])[2])})
	print("B_RIG_STAGE "+JSON.stringify({"scene":current.id,"stage":name,"image":prefix+"_"+str(current.id)+"_"+name+".png","slots":slots,"scope":"Actual presentation poses/scales, may update future presentation fallback aim; no simulation advance."}))
