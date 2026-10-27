extends SceneTree
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func catalog()->Dictionary:
 return {"weapon_slots":4,"item_slots":8,"weapons":[{"id":"rivet_gun","kind":"weapon","max_stack":4},{"id":"scrap_shotgun","kind":"weapon","max_stack":4}],"items":[]}
func setup():
 var r=Runtime.new()
 ck(r.clear_run(7),"valid trusted epoch setup")
 ck(r.configure(catalog()).get("ok",false),"valid legacy catalog without B accepted")
 ck(r.sync_build({},["rivet_gun","scrap_shotgun"],0.0),"valid registry ownership setup")
 ck(r.begin_step(0.0,0,[],{"width":800,"height":600}),"valid batch setup")
 return r
func context()->Dictionary:
 return {"playing":true,"time":0.0,"effect_epoch":7,"step_serial":0,"player_pos":Vector2(300,300),"dash_active":false,"enemies":[],"area":{"width":800,"height":600}}
func event()->Dictionary:
 return {"kind":"hit","source":"primary","depth":0,"epoch":7,"sequence":1,"weapon":"rivet_gun","target":7}
const ADMISSION_CASES=[
 {"field":"kind","value":null,"admitted":false},
 {"field":"kind","value":true,"admitted":false},
 {"field":"kind","value":0,"admitted":false},
 {"field":"kind","value":[],"admitted":false},
 {"field":"kind","value":{},"admitted":false},
 {"field":"source","value":null,"admitted":false},
 {"field":"source","value":true,"admitted":false},
 {"field":"source","value":0,"admitted":false},
 {"field":"source","value":[],"admitted":false},
 {"field":"source","value":{},"admitted":false},
 {"field":"depth","value":null,"admitted":false},
 {"field":"depth","value":true,"admitted":false},
 {"field":"depth","value":1.0,"admitted":false},
 {"field":"depth","value":"1","admitted":false},
 {"field":"depth","value":[],"admitted":false},
 {"field":"epoch","value":null,"admitted":false},
 {"field":"epoch","value":true,"admitted":false},
 {"field":"epoch","value":1.0,"admitted":false},
 {"field":"epoch","value":"1","admitted":false},
 {"field":"epoch","value":[],"admitted":false},
 {"field":"sequence","value":null,"admitted":false},
 {"field":"sequence","value":true,"admitted":false},
 {"field":"sequence","value":1.0,"admitted":false},
 {"field":"sequence","value":"1","admitted":false},
 {"field":"sequence","value":[],"admitted":false},
 {"field":"target","value":null,"admitted":false},
 {"field":"target","value":true,"admitted":false},
 {"field":"target","value":1.0,"admitted":false},
 {"field":"target","value":"1","admitted":false},
 {"field":"target","value":[],"admitted":false},
 {"field":"kind","value":"","admitted":true},
 {"field":"kind","value":"unknown","admitted":true},
 {"field":"source","value":"","admitted":true},
 {"field":"source","value":"chain","admitted":true},
 {"field":"depth","value":1,"admitted":true},
 {"field":"weapon","value":"","admitted":true},
 {"field":"weapon","value":"not_registered","admitted":true},
 {"field":"target","value":0,"admitted":true},
 {"field":"target","value":-1,"admitted":true},
]
func _initialize()->void:
 for c in ADMISSION_CASES:
  var r=setup()
  var before=r.debug_snapshot()
  var e=event()
  e[c.field]=c.value
  var result=r.process(e,context())
  ck(result.is_empty(),"no B effect under typed case "+str(c))
  var expected=before.duplicate(true)
  if c.admitted:expected.last_sequence=1
  ck(r.debug_snapshot()==expected,"exact admission snapshot "+str(c))
  var fixed=event()
  r.process(fixed,context())
  expected.last_sequence=1
  ck(r.debug_snapshot()==expected,"same sequence corrected or spent without other mutation "+str(c))
 for field in ["playing","time","effect_epoch","step_serial","player_pos","enemies","area"]:
  var r=setup()
  var before=r.debug_snapshot()
  var ctx=context()
  ctx[field]=null
  ck(r.process(event(),ctx).is_empty(),"context null rejected "+field)
  ck(r.debug_snapshot()==before,"context null no writes "+field)
 for value in [NAN,INF,-INF,-1.0]:
  var r=setup()
  var before=r.debug_snapshot()
  var ctx=context();ctx.time=value
  ck(r.process(event(),ctx).is_empty(),"invalid clock rejected "+str(value))
  ck(r.debug_snapshot()==before,"invalid clock no writes "+str(value))
 var r=setup()
 var before=r.debug_snapshot()
 for pos in [Vector2(NAN,0),Vector2(INF,0),Vector2(0,-INF)]:
  var e={"kind":"dash","source":"primary","depth":0,"epoch":7,"sequence":1,"pos":pos}
  ck(r.process(e,context()).is_empty(),"nonfinite dash origin PRE rejected")
  ck(r.debug_snapshot()==before,"nonfinite dash preserves sequence and entire state")
 print(JSON.stringify({"checks":checks,"failures":failures,"typed_matrix_cases":ADMISSION_CASES.size(),"scope":"Independent frozen 39 typed admissions and context clock/dash PRE guards, valid old catalog without B"}))
 quit(0 if failures.is_empty() else 1)
