extends SceneTree
const Geometry=preload("res://scripts/gameplay/pulse_wave_geometry.gd")
const CASES_PATH="res://tests/fixtures/v39_geometry_api_cases.json"
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func call_case(a:Dictionary)->Dictionary:
 return Geometry.first_contact(Vector2(a.center[0],a.center[1]),Vector2(a.p0[0],a.p0[1]),Vector2(a.p1[0],a.p1[1]),a.frame_dt,a.t_start,a.t_end,a.r_start,a.r_end,a.half_width,a.enemy_radius)
func _initialize()->void:call_deferred("run")
func run()->void:
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CASES_PATH))
 for row in data.cases:
  var original:String=JSON.stringify(row.api_args)
  var result:Dictionary=call_case(row.api_args)
  ck(result.size()==2 and result.get("hit") is bool and result.get("time") is float,"exact schema "+row.input.name)
  ck(result.get("hit")==row.reference.hit,"independent Decimal90 contact "+row.input.name)
  if row.reference.hit:
   ck(is_finite(float(result.time)) and absf(float(result.time)-float(row.reference.time))<=1e-7,"earliest contact not midpoint "+row.input.name)
  else:ck(result.get("time")==0.0,"miss canonical zero "+row.input.name)
  ck(JSON.stringify(row.api_args)==original,"pure input unchanged "+row.input.name)
  observations.append({"name":row.input.name,"hit":result.get("hit"),"time":result.get("time")})
 var base:Dictionary={"center":[0.0,0.0],"p0":[60.0,0.0],"p1":[60.0,0.0],"frame_dt":1.0,"t_start":0.0,"t_end":1.0,"r_start":60.0,"r_end":60.0,"half_width":12.0,"enemy_radius":16.0}
 for key in ["frame_dt","t_start","t_end","r_start","r_end","half_width","enemy_radius"]:
  for bad in [-1.0,NAN,INF]:
   var a:Dictionary=base.duplicate(true);a[key]=bad
   ck(call_case(a)=={"hit":false,"time":0.0},"invalid scalar failclosed "+key+" "+str(bad))
 for key in ["center","p0","p1"]:
  for bad in [NAN,INF]:
   var a:Dictionary=base.duplicate(true);a[key]=[bad,0.0]
   ck(call_case(a)=={"hit":false,"time":0.0},"invalid vector failclosed "+key)
 var reversed:Dictionary=base.duplicate(true);reversed.t_start=.8;reversed.t_end=.2
 ck(call_case(reversed)=={"hit":false,"time":0.0},"reversed query interval")
 var beyond:Dictionary=base.duplicate(true);beyond.t_end=1.1
 ck(call_case(beyond)=={"hit":false,"time":0.0},"query beyond fullframe")
 var zero:Dictionary=base.duplicate(true);zero.t_start=.5;zero.t_end=.5;zero.r_end=61.0
 ck(call_case(zero)=={"hit":false,"time":0.0},"zero query unequal radius")
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Independent pretarget Decimal90 reference205 cases + invalid boundary controls. Actual represented Vector2 domain; 1e-7seconds comparison, not physicalCCD or fullruntime acceptance."}))
 quit(0 if failures.is_empty() else 1)
