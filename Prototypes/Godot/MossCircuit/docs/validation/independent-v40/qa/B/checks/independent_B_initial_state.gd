extends SceneTree
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func initial()->Dictionary:
 return {"configuration_open":true,"registry":{},"slot_caps":{},"definitions":{"crossfire_pin":{},"salvage_capacitor":{},"medic_winch":{}},"owned_items":{},"weapon_counts":{},"equipped_types":[],"mark":null,"pin_ready_at":null,"charges":0,"fields":[],"next_field_sequence":0,"winch_count":0,"pending":null,"winch_requested_this_batch":false,"bound_epoch":-1,"last_sequence":0,"last_now":0.0,"last_step_serial":-1,"batch_serial":-1,"batch_time":0.0,"batch_open":false}
func _initialize()->void:
 var r=Runtime.new()
 var expected=initial()
 var s=r.debug_snapshot()
 ck(s==expected,"construction exact twenty-two-key state")
 ck(s.size()==22,"no omitted or extra state keys")
 s.definitions.crossfire_pin["injected"]=true
 s.registry["injected"]={"kind":"item","max_stack":1}
 s.fields.append({"pos":Vector2(1,2),"expires":2.0,"sequence":1})
 s.equipped_types.append("injected")
 ck(r.debug_snapshot()==expected,"observation deep detached and pure")
 for v in [null,true,false,1.0,"1",-1,[],{}]:
  ck(not r.clear_run(v),"invalid actual epoch rejected "+str(v))
  ck(r.debug_snapshot()==expected,"invalid clear unchanged "+str(v))
 ck(r.clear_run(7),"trusted newrun epoch accepted")
 expected.bound_epoch=7
 ck(r.debug_snapshot()==expected,"newrun exact state")
 var before=r.debug_snapshot()
 ck(not r.sync_build({},[],0.0),"configuration window disallows sync")
 ck(not r.begin_step(0.0,0,[],{"width":800,"height":600}),"configuration window disallows step")
 ck(r.process({"kind":"pickup","source":"normal","depth":0,"epoch":7,"sequence":1},{"playing":true,"time":0.0,"effect_epoch":7,"step_serial":0,"player_pos":Vector2(300,300),"dash_active":false,"enemies":[],"area":{"width":800,"height":600}}).is_empty(),"configuration window disallows process")
 ck(r.debug_snapshot()==before,"configuration window rejects without state writes")
 r.cancel_pending()
 ck(r.debug_snapshot()==before,"empty cancel exact no collateral state")
 ck(r.bind_epoch(8,0.0),"forward trusted epoch in config window")
 expected.bound_epoch=8
 ck(r.debug_snapshot()==expected,"forward epoch preserves all initial guards")
 ck(not r.bind_epoch(7,0.0),"rollback epoch rejected")
 ck(r.debug_snapshot()==expected,"rollback no writes")
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"Independent frozen observable initial/reset/detachment contract; no scene, no gameplay integration"}))
 quit(0 if failures.is_empty() else 1)
