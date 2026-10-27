from pathlib import Path
r=Path('evidence-workspace/moss-v39-work')
p=r/'scripts/gameplay/combat_state.gd';s=p.read_text();s+='''
# New A attacks are bounded and owned only within this epoch; old arrays remain unchanged.
var pulse_beams:Array=[]
var seismic_waves:Array=[]
var new_weapon_epoch:int=0
var new_wave_sequence:int=0
var combat_tick_serial:int=0
var new_weapon_last_tick:int=-1
var new_weapon_motion:Dictionary={}
func clear_new_attacks()->void:
	pulse_beams.clear();seismic_waves.clear();new_weapon_motion.clear()
	new_weapon_epoch+=1
''';p.write_text(s)
p=r/'scripts/gameplay/combat_context.gd';s=p.read_text();s+='var new_weapons:RefCounted\n';p.write_text(s)
p=r/'scripts/gameplay/new_weapon_runtime.gd';s=p.read_text().replace('world.pulse_beams.clear();world.seismic_waves.clear();world.new_weapon_motion.clear()\n\tworld.new_weapon_epoch+=1','world.clear_new_attacks()');p.write_text(s)
p=r/'scripts/gameplay/combat_runtime.gd';s=p.read_text();s=s.replace('\t_prune_focus(frame.world)\n','\t_prune_focus(frame.world)\n\tframe.world.combat_tick_serial+=1\n\tframe.world.new_weapon_motion.clear()\n',1)
s=s.replace('\t\tframe.world.weapon_clocks[slot] -= dt','\t\tvar scheduled:Dictionary=Rules.catalog_entry(frame.catalog,frame.session.build.weapons[slot])\n\t\tif scheduled.get("behavior","") in ["tether_pulse","expanding_ring"]:continue\n\t\tframe.world.weapon_clocks[slot] -= dt',1)
s=s.replace('\t\tvar events: Array = EnemyAI.tick','\t\tvar motion_start:Vector2=e.pos\n\t\tvar events: Array = EnemyAI.tick',1)
needle='\t\te.pos = e.pos.clamp(Vector2(20,20),Vector2(frame.area.width - 20,frame.area.height - 20))'
s=s.replace(needle,needle+'\n\t\tframe.world.new_weapon_motion[e.id]={"p0":motion_start,"p1":e.pos,"final_pos":e.pos,"has_segment":true}',1)
needle='\t_sync_support(frame)\n\tvar living_owners:'
repl='''	_sync_support(frame)
	for enemy in frame.world.enemies:
		if frame.world.new_weapon_motion.has(enemy.id):frame.world.new_weapon_motion[enemy.id].final_pos=enemy.pos
		else:frame.world.new_weapon_motion[enemy.id]={"p0":enemy.pos,"p1":enemy.pos,"final_pos":enemy.pos,"has_segment":false}
	if frame.new_weapons!=null:frame.new_weapons.step(frame,dt,frame.world.combat_tick_serial)
	var living_owners:'''
assert needle in s;s=s.replace(needle,repl,1);p.write_text(s)
p=r/'scripts/gameplay/run_flow.gd';s=p.read_text().replace('session.state="transition" # Reentrant/repeated requests cannot credit twice.','session.state="transition" # Reentrant/repeated requests cannot credit twice.\n\tworld.clear_new_attacks()');p.write_text(s)
p=r/'scripts/main.gd';s=p.read_text();s=s.replace('extends Node2D','extends Node2D\nconst NewWeaponRuntime=preload("res://scripts/gameplay/new_weapon_runtime.gd")\nconst NewWeaponVisuals=preload("res://scripts/gameplay/new_weapon_visuals.gd")\nvar new_weapon_runtime=NewWeaponRuntime.new()',1)
s=s.replace('combat_frame.world=combat;combat_frame.session=run;combat_frame.catalog=catalog','new_weapon_runtime.configure(catalog)\n\tcombat_frame.new_weapons=new_weapon_runtime\n\tcombat_frame.world=combat;combat_frame.session=run;combat_frame.catalog=catalog',1)
for signature in ['func _title() -> void:','func _finish(won: bool) -> void:','func _recompute() -> void:']:
 assert signature in s;s=s.replace(signature,signature+'\n\tnew_weapon_runtime.clear(combat)',1)
s=s.replace('if fresh_build.is_empty():return false','if fresh_build.is_empty():return false\n\tnew_weapon_runtime.clear(combat)',1)
s=s.replace('func _begin_room_clear()->void:\n\tif state!="playing":return','func _begin_room_clear()->void:\n\tif state!="playing":return\n\tnew_weapon_runtime.clear(combat)',1)
s=s.replace('elif not bullets.is_empty() or not pending_blasts.is_empty(): reason = "Weapon shots are still active;', 'elif not bullets.is_empty() or not pending_blasts.is_empty() or not combat.pulse_beams.is_empty() or not combat.seismic_waves.is_empty(): reason = "Weapon shots are still active;')
s=s.replace('\tweapon_rig.sync_loadout(build.weapons)\n\tvar moved_id:', '\tnew_weapon_runtime.clear(combat)\n\tweapon_rig.sync_loadout(build.weapons)\n\tvar moved_id:',1)
s=s.replace('if projected.is_empty(): return false\n\tweapon_rig.sync_loadout', 'if projected.is_empty(): return false\n\tnew_weapon_runtime.clear(combat)\n\tweapon_rig.sync_loadout',1)
s=s.replace('if visual.kind in ["annulus_impact","support_complete","support_cancel"]:', 'if visual.kind in ["annulus_impact","support_complete","support_cancel","tether_break"]:',1)
s=s.replace('\tfor blast in pending_blasts:\n\t\tdraw_circle', '\tif state not in ["title","dead","won"]:NewWeaponVisuals.draw(self,combat,settings.reduced_flashes)\n\tfor blast in pending_blasts:\n\t\tdraw_circle',1)
p.write_text(s)
