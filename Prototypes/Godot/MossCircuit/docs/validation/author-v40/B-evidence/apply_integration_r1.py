from pathlib import Path
import json,shutil
root=Path('evidence-workspace/moss-v39-B-integration');stage=Path('evidence-workspace/moss-v39-items/B-staged')
for name in ['build_items_runtime.gd','build_items_adapter.gd']:shutil.copyfile(stage/'scripts/gameplay'/name,root/'scripts/gameplay'/name)
def edit(path,old,new,count=1):
 p=root/path;s=p.read_text();assert s.count(old)==count,(path,old,s.count(old));p.write_text(s.replace(old,new))
p='scripts/gameplay/effect_runtime.gd'
edit(p,'const RecoilPlate=', 'const BuildItemsRuntime=preload("res://scripts/gameplay/build_items_runtime.gd")\nconst BuildItemsAdapter=preload("res://scripts/gameplay/build_items_adapter.gd")\nvar build_items=BuildItemsRuntime.new()\nconst RecoilPlate=')
edit(p,'\tif session.state != "playing": return false','\tif session.state != "playing":\n\t\tbuild_items.cancel_pending()\n\t\treturn false')
edit(p,'\treturn blocked\n','\t# B observes the real world only after every old/A command has applied.\n\tif session.state == "playing" and build_items.bind_epoch(engine.epoch,session.elapsed):\n\t\tvar canonical:Dictionary=BuildItemsAdapter.canonical_event(kind,data,int(event.epoch),int(event.sequence))\n\t\tfor control in build_items.process(canonical,build_items_context()):\n\t\t\tbuild_items.apply_control(control,world.enemies,recoil_area)\n\telse:build_items.cancel_pending()\n\treturn blocked\n')
with (root/p).open('a') as f:f.write('''
# B-only lifecycle bridge; no changes to old Effects reset/sync or event sequence.
func build_items_context()->Dictionary:
	return {"playing":session.state=="playing","time":session.elapsed,"effect_epoch":engine.epoch,"step_serial":world.combat_tick_serial,"player_pos":world.player_pos,"dash_active":float(world.stats.get("dash_time",0.0))>0,"enemies":world.enemies,"area":recoil_area}
func start_build_items(catalog:Dictionary)->bool:
	if not build_items.clear_run(engine.epoch):return false
	if not build_items.configure(catalog).ok:return false
	return build_items.sync_build(session.build.items,session.build.weapons,session.elapsed)
func sync_build_items()->bool:
	if not build_items.bind_epoch(engine.epoch,session.elapsed):return false
	return build_items.sync_build(session.build.items,session.build.weapons,session.elapsed)
func reset_build_items_encounter()->void:
	build_items.reset_encounter(session.elapsed)
	build_items.bind_epoch(engine.epoch,session.elapsed)
func begin_build_items_step(area:Dictionary)->void:
	recoil_area=area
	if session.state!="playing":
		build_items.cancel_pending()
		return
	if build_items.bind_epoch(engine.epoch,session.elapsed):
		build_items.begin_step(session.elapsed,world.combat_tick_serial,world.enemies,area)
func flush_build_items_pickups()->Dictionary:
	return build_items.flush_pickups(build_items_context(),world.pickups)
''')
p='scripts/gameplay/combat_runtime.gd'
edit(p,'\tframe.world.combat_tick_serial+=1','\tframe.world.combat_tick_serial+=1\n\tframe.procs.begin_build_items_step(frame.area)')
edit(p,'e.speed *= Status.movement_factor(e,frame.session.elapsed)','e.speed *= minf(Status.movement_factor(e,frame.session.elapsed),frame.procs.build_items.movement_factor(e,frame.session.elapsed,frame.area))')
edit(p,'\t# B: all existing projectile, death and pickup callbacks precede repair.','\t# Item B defers medicine movement until the entire collection pass is over.\n\tframe.procs.flush_build_items_pickups()\n\t# B: all existing projectile, death and pickup callbacks precede repair.')
p='scripts/main.gd'
edit(p,'\telapsed = 0.0','\telapsed = 0.0\n\teffect_runtime.start_build_items(catalog)')
edit(p,'\tif outcome in ["invalid","ignored"]:return','\tif outcome in ["invalid","ignored"]:return\n\teffect_runtime.reset_build_items_encounter()')
edit(p,'\teffects.sync(build.items)','\teffects.sync(build.items)\n\teffect_runtime.sync_build_items()')
edit(p,'\tweapon_rig.swap_copies(slot,target)','\tweapon_rig.swap_copies(slot,target)\n\teffect_runtime.sync_build_items()')
edit(p,'\tweapon_rig.consume_copy(donor)','\tweapon_rig.consume_copy(donor)\n\teffect_runtime.sync_build_items()')
for signature in ['func _show_upgrades() -> void:','func _open_shop() -> void:','func _present_inventory() -> void:','func _present_pause() -> void:','func _clear_transients() -> void:']:
 edit(p,signature,signature+'\n\tif effect_runtime:effect_runtime.build_items.cancel_pending()')
for signature in ['func _title() -> void:','func _finish(won: bool) -> void:']:
 edit(p,signature,signature+'\n\tif effect_runtime:effect_runtime.reset_build_items_encounter()')
# Data rows remain top-level exact frozen helper schema; player descriptions can evolve separately.
c=root/'data/catalog.json';catalog=json.loads(c.read_text());rows=json.loads(Path('evidence-workspace/moss-v39-items/catalog_items_B.draft.json').read_text());assert not any(r['id'] in [x['id'] for x in catalog['items']] for r in rows);catalog['items'].extend(rows);c.write_text(json.dumps(catalog,indent=2)+'\n')
