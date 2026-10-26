extends SceneTree
const Shot=preload("res://scripts/gameplay/boundary_shot.gd")
var checks:=0
var failures:Array=[]
var records:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float,tolerance:float=.001)->bool:return absf(a-b)<=tolerance
func v(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func _initialize()->void:
 var args=OS.get_cmdline_user_args()
 var fixture:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 for row in fixture.rows:
  var field:Dictionary={"width":row.size[0],"height":row.size[1]}
  var b:Dictionary=Shot.spawn(v(row.start),v(row.direction),field,18,470,row.budget,0,false)
  var contacts:Array=[]
  Shot.advance(b,row.advance,[],Callable(),func(e):contacts.append(e))
  var e:Dictionary=row.expected
  check(near(b.x,e.position[0]) and near(b.y,e.position[1]),row.case+" analytic endpoint")
  check(b.reflections==int(e.reflections),row.case+" reflection count")
  check(b.end_reason==("path_budget" if e.terminal=="budget" else e.terminal),row.case+" terminal reason")
  check(near(b.travelled,e.traveled),row.case+" accumulated travel")
  check(b.x>=0 and b.x<=field.width and b.y>=0 and b.y<=field.height,row.case+" inside field")
  check(b.total_hits==0 and b.life==0,row.case+" no enemy damage and finite expiry")
  var split:Dictionary=Shot.spawn(v(row.start),v(row.direction),field,18,470,row.budget,0,false)
  for i in range(2000):
   if split.life<=0:break
   Shot.advance(split,.007,[],Callable(),Callable())
  check(near(split.x,b.x) and near(split.y,b.y) and split.reflections==b.reflections and split.end_reason==b.end_reason,row.case+" frozen empty-field subdivision")
  records.append({"case":row.case,"x":b.x,"y":b.y,"travelled":b.travelled,"reflections":b.reflections,"end_reason":b.end_reason,"boundary_events":contacts.size()})
 var field={"width":960,"height":640}
 var b:Dictionary=Shot.spawn(Vector2(0,.00015),Vector2(-1,-1),field,18,470,100,0,false)
 Shot.advance(b,.00015/470.0,[],Callable(),Callable())
 check(b.reflections==1 and b.life>0,"tiny subdivision first outward reflection")
 Shot.advance(b,.001,[],Callable(),Callable())
 check(b.reflections==2 and b.life>0 and b.end_reason=="","progress accumulates across frames at near corner")
 var no_step:Dictionary=Shot.spawn(Vector2.ZERO,Vector2(-1,-1),field,18,470,100,0,true)
 var before:Dictionary=no_step.duplicate(true)
 Shot.advance(no_step,0,[],Callable(),Callable());Shot.advance(no_step,-1,[],Callable(),Callable())
 check(no_step==before,"nonpositive dt inert even outward corner")
 for invalid in [INF,NAN,-1.0,0.0]:
  check(Shot.spawn(Vector2.ZERO,Vector2.RIGHT,field,18,invalid,100,0,false).is_empty(),"invalid speed rejected "+str(invalid))
 b=Shot.spawn(Vector2(-30,200),Vector2.LEFT,field,18,470,100,0,false)
 check(b.x==0 and b.y==200 and b.travelled==0,"outside origin clamped without bridge travel")
 Shot.advance(b,INF,[],Callable(),Callable())
 check(b.life==0 and b.end_reason=="invalid_dt","nonfinite dt safe expiry")
 var out={"checks":checks,"failures":failures,"rows":records,"scope":"independent pre-authored static analytic vectors and finite input guards; pure trajectory helper only, not integration or GUI"}
 FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
