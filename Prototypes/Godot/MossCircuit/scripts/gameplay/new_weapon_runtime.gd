extends RefCounted
## Two bounded opt-in attacks. Old eight weapons remain in WeaponCombat unchanged.
const Rules=preload("res://scripts/rules.gd")
const Profiles=preload("res://scripts/gameplay/new_weapon_profiles.gd")
const Geometry=preload("res://scripts/gameplay/pulse_wave_geometry.gd")
const Defense=preload("res://scripts/gameplay/primary_defense.gd")
const Temper=preload("res://scripts/gameplay/weapon_tempering.gd")
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
var weapons:Dictionary={}
var memory:Dictionary={}
var collar:Dictionary={}
func configure(catalog:Dictionary)->void:
	weapons.clear();memory.clear();collar.clear()
	for entry in catalog.get("weapons",[]):
		var profile:Dictionary=Profiles.weapon(entry)
		if not profile.is_empty():weapons[entry.id]=profile
	for entry in catalog.get("items",[]):
		var profile:Dictionary=Profiles.module(entry)
		if profile.is_empty():continue
		if entry.id=="lock_memory":memory=profile
		elif entry.id=="return_collar":collar=profile

func clear(world:RefCounted)->void:
	world.clear_new_attacks()

func step(frame:RefCounted,dt:float,tick_serial:int)->void:
	if frame.session.state!="playing" or not is_finite(dt) or dt<=0.0:return
	var world=frame.world
	if tick_serial<=world.new_weapon_last_tick:return
	world.new_weapon_last_tick=tick_serial
	world.pulse_beams.sort_custom(func(a,b):return a.slot_id<b.slot_id)
	for beam in world.pulse_beams.duplicate():
		if not _owner(frame,beam) or not _advance_beam(frame,beam,dt):world.pulse_beams.erase(beam)
	world.seismic_waves.sort_custom(func(a,b):return a.slot_id<b.slot_id if a.slot_id!=b.slot_id else a.sequence<b.sequence)
	for wave in world.seismic_waves.duplicate():
		if not _owner(frame,wave) or not _advance_wave(frame,wave,dt):world.seismic_waves.erase(wave)
	for slot in range(frame.session.build.weapons.size()):
		var id:String=frame.session.build.weapons[slot]
		if not weapons.has(id):continue
		if slot>=world.weapon_clocks.size():continue
		world.weapon_clocks[slot]-=dt
		if world.weapon_clocks[slot]>0.0:continue
		var weapon:Dictionary=weapons[id]
		var interval:float=Rules.weapon_interval(weapon,world.stats)
		world.weapon_clocks[slot]=interval
		_launch(frame,weapon,slot,interval)

func _owner(frame:RefCounted,entity:Dictionary)->bool:
	var slot:int=int(entity.get("slot_id",-1))
	return entity.get("epoch",-1)==frame.world.new_weapon_epoch and slot>=0 and slot<frame.session.build.weapons.size() and frame.session.build.weapons[slot]==entity.get("weapon_id","")

func _target(frame:RefCounted,reach:float,focus:bool)->Dictionary:
	var living:Array=frame.world.enemies.filter(func(e):return Focus.living(e) and e.pos.distance_to(frame.world.player_pos)<=reach)
	if focus:
		var preferred:Dictionary=Focus.find(living,frame.world.focus_enemy_id)
		if not preferred.is_empty():return preferred
	living.sort_custom(func(a,b):
		var da:float=a.pos.distance_squared_to(frame.world.player_pos)
		var db:float=b.pos.distance_squared_to(frame.world.player_pos)
		return a.id<b.id if da==db else da<db)
	return {} if living.is_empty() else living[0]

func _launch(frame:RefCounted,weapon:Dictionary,slot:int,interval:float)->void:
	var world=frame.world
	var reach:float=Rules.weapon_reach(weapon,world.stats)
	var damage:float=Rules.weapon_damage(weapon,world.stats,Temper.multiplier(frame.session.build,frame.catalog,slot,weapon.id))
	if not is_finite(reach) or not is_finite(damage) or not is_finite(interval) or reach<=0 or damage<=0 or interval<=0:return
	var target:Dictionary=_target(frame,reach,weapon.behavior=="tether_pulse")
	if target.is_empty():return
	if weapon.behavior=="tether_pulse":
		if world.pulse_beams.any(func(b):return b.slot_id==slot):return
		var grace:float=float(memory.grace_seconds) if not memory.is_empty() and frame.session.build.items.get("lock_memory",0)>0 else 0.0
		world.pulse_beams.append({"epoch":world.new_weapon_epoch,"slot_id":slot,"weapon_id":weapon.id,"target_id":target.id,"damage":damage,"range":reach,"interval":interval,"tier":Temper.tier_at(frame.session.build,slot,weapon.id),"pulse_count":int(weapon.pulse_count),"pulse_index":0,"active_age":0.0,"wall_age":0.0,"memory_grace":grace,"grace_left":0.0,"grace_spent":false,"was_outside":false})
		frame.weapons.presentation.fire(weapon.id,slot,target.pos)
	else:
		if reach<=float(weapon.inner_start_radius):return
		if world.seismic_waves.filter(func(w):return w.slot_id==slot).size()>=int(weapon.max_live_per_slot):return
		world.new_wave_sequence+=1
		var returns:bool=not collar.is_empty() and frame.session.build.items.get("return_collar",0)>0
		world.seismic_waves.append({"epoch":world.new_weapon_epoch,"slot_id":slot,"weapon_id":weapon.id,"sequence":world.new_wave_sequence,"center":world.player_pos,"damage":damage,"range":reach,"initial_radius":float(weapon.inner_start_radius),"half_width":float(weapon.band_half_width),"outward_seconds":float(weapon.outward_seconds),"return_enabled":returns,"inward_seconds":float(collar.get("inward_seconds",0.45)),"inward_damage_scale":float(collar.get("inward_damage_scale",0.5)),"age":0.0,"hit_out":{},"hit_in":{},"outward_done":false})
		frame.weapons.presentation.fire(weapon.id,slot,world.player_pos+Vector2.RIGHT*reach,true)

func _hit(frame:RefCounted,entity:Dictionary,enemy:Dictionary,damage:float,origin:Vector2)->void:
	if enemy.hp<=0:return
	var resolved:float=Defense.resolve(enemy,damage,origin,origin-enemy.pos)
	enemy.hp-=resolved
	enemy.last_source="primary"
	frame.procs.emit_event("hit",{"source":"primary","depth":0,"weapon":entity.weapon_id,"weapon_id":entity.weapon_id,"slot_id":entity.slot_id,"target":enemy.id,"pos":enemy.pos,"damage":resolved})

func _break_beam(frame:RefCounted,beam:Dictionary)->void:
	var old:Array=frame.world.effect_visuals.filter(func(v):return v.kind=="tether_break")
	if old.size()>=4:frame.world.effect_visuals.erase(old[0])
	frame.world.effect_visuals.append({"kind":"tether_break","pos":frame.world.player_pos,"life":0.16,"slot_id":beam.slot_id})

func _advance_beam(frame:RefCounted,beam:Dictionary,dt:float)->bool:
	var enemy:Dictionary=Focus.find(frame.world.enemies,int(beam.target_id))
	if enemy.is_empty():_break_beam(frame,beam);return false
	var lifetime:float=float(beam.interval)+float(beam.memory_grace)
	var delta:float=minf(dt,maxf(0.0,lifetime-float(beam.wall_age)))
	beam.wall_age+=delta
	var inside:bool=enemy.pos.distance_to(frame.world.player_pos)<=float(beam.range)
	if not inside:
		if beam.memory_grace<=0.0 or (beam.grace_spent and not beam.was_outside):_break_beam(frame,beam);return false
		if not beam.grace_spent:
			beam.grace_spent=true;beam.grace_left=float(beam.memory_grace)
		beam.was_outside=true
		beam.grace_left-=delta
		if beam.grace_left<0.0:_break_beam(frame,beam);return false
	else:
		if beam.grace_spent and beam.grace_left<0.0:_break_beam(frame,beam);return false
		beam.was_outside=false
		beam.active_age+=delta
		while beam.pulse_index<int(beam.pulse_count):
			var due:float=float(beam.interval)*float(beam.pulse_index+1)/float(beam.pulse_count)
			if float(beam.active_age)+0.000000001<due:break
			if enemy.hp<=0:return false
			beam.pulse_index+=1
			_hit(frame,beam,enemy,float(beam.damage),frame.world.player_pos)
	return beam.wall_age<lifetime-0.000000001 and beam.pulse_index<int(beam.pulse_count) and enemy.hp>0

static func radius_at(wave:Dictionary,age:float,leg:int)->float:
	if leg==0:return lerpf(float(wave.initial_radius),float(wave.range),clampf(age/float(wave.outward_seconds),0.0,1.0))
	return lerpf(float(wave.range),float(wave.initial_radius),clampf((age-float(wave.outward_seconds))/float(wave.inward_seconds),0.0,1.0))

func _advance_wave(frame:RefCounted,wave:Dictionary,dt:float)->bool:
	var start_age:float=wave.age
	var duration:float=float(wave.outward_seconds)+(float(wave.inward_seconds) if wave.return_enabled else 0.0)
	var end_age:float=minf(duration,start_age+dt)
	for leg in range(2 if wave.return_enabled else 1):
		if leg==0 and wave.outward_done:continue
		var leg_start:float=0.0 if leg==0 else float(wave.outward_seconds)
		var leg_end:float=float(wave.outward_seconds) if leg==0 else duration
		var a:float=maxf(start_age,leg_start)
		var b:float=minf(end_age,leg_end)
		if b<a:continue
		var hitset:Dictionary=wave.hit_out if leg==0 else wave.hit_in
		var contacts:Array=[]
		for enemy in frame.world.enemies:
			if enemy.hp<=0 or hitset.has(enemy.id):continue
			var scale_value:float=float(enemy.get("scale",0.0))
			if not is_finite(scale_value) or scale_value<=0.0:continue
			var motion:Dictionary=frame.world.new_weapon_motion.get(enemy.id,{"p0":enemy.pos,"p1":enemy.pos,"final_pos":enemy.pos,"has_segment":false})
			var contact:Dictionary={"hit":false,"time":0.0}
			if motion.has_segment:
				# Subtracting absolute ages can round a legal clipped end slightly above dt.
				# Keep the pure geometry domain strict; normalize only this derived frame interval.
				var query_start:float=clampf(a-start_age,0.0,dt)
				var query_end:float=clampf(b-start_age,0.0,dt)
				contact=Geometry.first_contact(wave.center,motion.p0,motion.p1,dt,query_start,query_end,radius_at(wave,a,leg),radius_at(wave,b,leg),wave.half_width,16.0*scale_value)
			# Control displacement and newborns are endpoint-only, never a fictional chord.
			var actual_end:float=start_age+dt
			if not contact.hit and actual_end>=leg_start and actual_end<=leg_end:
				var radius:float=radius_at(wave,actual_end,leg)
				contact=Geometry.first_contact(wave.center,motion.final_pos,motion.final_pos,dt,dt,dt,radius,radius,wave.half_width,16.0*scale_value)
			if contact.hit:contacts.append({"enemy":enemy,"time":float(contact.time),"bucket":floor(float(contact.time)/0.000000001+0.5)})
		contacts.sort_custom(func(x,y):return x.enemy.id<y.enemy.id if x.bucket==y.bucket else x.bucket<y.bucket)
		for contact in contacts:
			var enemy:Dictionary=contact.enemy
			if enemy.hp<=0:continue
			hitset[enemy.id]=true
			_hit(frame,wave,enemy,float(wave.damage)*(float(wave.inward_damage_scale) if leg==1 else 1.0),wave.center)
		if leg==0 and end_age>=wave.outward_seconds:wave.outward_done=true
	wave.age=end_age
	return end_age<duration
