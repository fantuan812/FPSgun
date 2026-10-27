extends SceneTree
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func catalog()->Dictionary:
 return {"weapon_slots":4,"item_slots":8,"weapons":[{"id":"rivet_gun","kind":"weapon","max_stack":4},{"id":"scrap_shotgun","kind":"weapon","max_stack":4},{"id":"return_disc","kind":"weapon","max_stack":4}],"items":[{"id":"crossfire_pin","kind":"item","price":28,"max_stack":1,"effects":{},"mark_seconds":1.5,"pull_distance":45.0,"cooldown":1.0,"requires_distinct_weapon_types":2},{"id":"salvage_capacitor","kind":"item","price":28,"max_stack":1,"effects":{},"charge_limit":3,"field_limit":2,"field_radius":80.0,"field_seconds":1.8,"field_speed_factor":0.7,"pickup_sources":["normal"]},{"id":"medic_winch","kind":"item","price":24,"max_stack":1,"effects":{},"pickup_count":5,"max_pulls_per_step":1,"medical_range":220.0,"pull_distance":80.0,"pickup_sources":["normal"]}]}
func _initialize()->void:
 var mutations:Array=[]
 var c=catalog();c.items.append(c.items[0].duplicate(true));mutations.append(["duplicate ID",c])
 c=catalog();c.items[0].max_stack=true;mutations.append(["bool max_stack",c])
 c=catalog();c.items[1].charge_limit=3.5;mutations.append(["fraction structural count",c])
 c=catalog();c.items[0].mark_seconds=0.0;mutations.append(["zero duration",c])
 c=catalog();c.items[0].mark_seconds=INF;mutations.append(["nonfinite duration",c])
 c=catalog();c.items[1].pickup_sources=["energy"];mutations.append(["unknown source array",c])
 c=catalog();c.items[1].field_speed_factor=0.0;mutations.append(["zero factor",c])
 c=catalog();c.items[1].field_speed_factor=1.01;mutations.append(["factor exceeds1",c])
 c=catalog();c.items[2].erase("medical_range");mutations.append(["missing field",c])
 for m in mutations:
  var r=Runtime.new();var before=r.debug_snapshot()
  ck(not r.configure(m[1]).get("ok",true),"initial bad config "+m[0])
  ck(r.debug_snapshot()==before,"initial atomic config "+m[0])
  ck(r.clear_run(1) and r.configure(catalog()).get("ok",false),"valid config before newrun "+m[0])
  ck(r.clear_run(2),"newrun opens valid prior config "+m[0])
  before=r.debug_snapshot()
  ck(not r.configure(m[1]).get("ok",true),"newrun bad config "+m[0])
  ck(r.debug_snapshot()==before,"prior config and open window exactly retained "+m[0])
 var r=Runtime.new();c=catalog();c.weapon_slots=4.0;c.item_slots=8.0
 for row in c.weapons:row.max_stack=4.0
 for row in c.items:row.max_stack=1.0
 c.items[0].requires_distinct_weapon_types=2.0;c.items[1].charge_limit=3.0;c.items[1].field_limit=2.0;c.items[2].pickup_count=5.0;c.items[2].max_pulls_per_step=1.0
 ck(r.clear_run(1) and r.configure(c).get("ok",false),"JSON integral config accepted without bool coercion")
 var s=r.debug_snapshot()
 ck(typeof(s.registry.crossfire_pin.max_stack)==TYPE_INT and typeof(s.definitions.crossfire_pin.requires_distinct_weapon_types)==TYPE_INT and typeof(s.definitions.salvage_capacitor.field_limit)==TYPE_INT,"config counts normalized actual ints")
 var before=s.duplicate(true)
 c.items[0].mark_seconds=99.0;c.items[1].pickup_sources.append("energy")
 ck(r.debug_snapshot()==before,"configured data detached from source catalog")
 s.definitions.salvage_capacitor.pickup_sources.append("medical");s.registry.crossfire_pin.max_stack=99
 ck(r.debug_snapshot()==before,"nested snapshot definitions arrays and registry detached")
 ck(not r.configure(catalog()).get("ok",true) and r.debug_snapshot()==before,"closed live configuration cannot refresh data or state")
 c=catalog();c.items=[];var legacy=Runtime.new()
 ck(legacy.clear_run(1) and legacy.configure(c).get("ok",false),"old valid catalog no B rows allowed")
 ck(legacy.debug_snapshot().definitions=={"crossfire_pin":{},"salvage_capacitor":{},"medic_winch":{}},"absent definitions exact disabled schemas")
 print(JSON.stringify({"checks":checks,"failures":failures,"configuration_mutations":mutations.size(),"scope":"Independent frozen atomic configuration boundaries and JSON integral count domain"}))
 quit(0 if failures.is_empty() else 1)
