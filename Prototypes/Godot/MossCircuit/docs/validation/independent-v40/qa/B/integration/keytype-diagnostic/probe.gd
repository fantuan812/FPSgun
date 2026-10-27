extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g._title();g._select_mode("arena");g._start_run(39073);g.set_process(false)
 g.build.weapons=["tether_emitter","seismic_drum"];g.build.weapon_temper=[0,0];g.build.items={"crossfire_pin":1}
 g.build.items.echo_chamber=1
 var keys:Array=[]
 for key in g.build.items:keys.append({"key":str(key),"typeof":typeof(key),"type_name":type_string(typeof(key)),"is_String":key is String,"is_StringName":key is StringName,"value":g.build.items[key],"value_type":type_string(typeof(g.build.items[key]))})
 var weapon_types:Array=[]
 for id in g.build.weapons:weapon_types.append({"id":str(id),"type_name":type_string(typeof(id))})
 var before:Dictionary=g.effect_runtime.build_items.debug_snapshot();g._recompute()
 var after:Dictionary=g.effect_runtime.build_items.debug_snapshot()
 var bracket:Dictionary={"crossfire_pin":1};bracket["echo_chamber"]=1;var bracket_keys:Array=[]
 for key in bracket:bracket_keys.append({"key":str(key),"type_name":type_string(typeof(key)),"is_String":key is String})
 g._title();var helper=load("res://tests/support/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"type_probe_checks":1,"failures":[],"observations":[{"dot_keys":keys,"weapon_types":weapon_types,"bracket_keys":bracket_keys,"before":before,"after":after}],"scope":"One actual failing-setup key-type and sync snapshot diagnostic only, no gameplay acceptance"}))
 quit(0)
