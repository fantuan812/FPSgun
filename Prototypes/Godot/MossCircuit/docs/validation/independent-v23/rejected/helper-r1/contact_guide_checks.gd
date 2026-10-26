extends SceneTree
const Shot=preload("res://scripts/gameplay/boundary_shot.gd")
var checks:=0
var failures:Array=[]
var rows:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.001
func enemy(id:int,x:float,y:float,scale:float=1.0,hp:float=1000)->Dictionary:
 return {"id":id,"pos":Vector2(x,y),"hp":hp,"scale":scale}
func step(b:Dictionary,distance:float,enemies:Array,ids:Array,events:Array)->void:
 Shot.advance(b,distance/470.0,enemies,func(e,shot):e.hp-=shot.damage;ids.append(e.id);events.append("hit"+str(e.id)),func(e):events.append(e.kind))
func _initialize()->void:
 for size in [Vector2(1440,960),Vector2(960,640)]:
  var w:float=size.x;var y:float=size.y*.5;var area={"width":w,"height":size.y};var label=str(int(w))+"/"
  var b:Dictionary=Shot.spawn(Vector2(w-120,y),Vector2.RIGHT,area,18,470,240,0,false)
  var targets:Array=[enemy(1,w-80,y),enemy(2,w-40,y)];var ids:Array=[];var events:Array=[]
  step(b,240,targets,ids,events)
  check(ids==[1,2],label+" spent first leg cannot hit second target; reflection re-arms")
  check(targets[0].hp==982 and targets[1].hp==982 and b.total_hits==2,label+" actual quota damage")
  check(events==["hit1","reflection","hit2"],label+" positive segment hit/boundary order")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,200,0,false);targets=[enemy(1,w-40,y)];ids=[];events=[]
  step(b,200,targets,ids,events)
  check(ids==[1,1] and targets[0].hp==964,label+" same target can be hit on separated return")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,200,0,false);targets=[enemy(1,w-10,y)];ids=[];events=[]
  step(b,200,targets,ids,events)
  check(ids==[1],label+" hit overlapping circle not re-hit at boundary")
  check(b.blocked_overlap.is_empty(),label+" exited overlap block released")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,200,0,false);targets=[enemy(1,w-50,y),enemy(2,w-5,y)];ids=[];events=[]
  step(b,200,targets,ids,events)
  check(ids==[1,2],label+" never-damaged overlapping target remains eligible")
  b=Shot.spawn(Vector2(w-10,y),Vector2.RIGHT,area,18,470,100,0,false);b.blocked_overlap=[1];targets=[enemy(1,w-10,y)];ids=[];events=[]
  step(b,100,targets,ids,events)
  check(ids.is_empty() and b.blocked_overlap.is_empty(),label+" prior overlapping block carried then released")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,3*w,0,false);targets=[enemy(1,w-10,y)];ids=[];events=[]
  step(b,3*w,targets,ids,events)
  check(ids==[1,1] and b.end_reason=="third_boundary",label+" blocked target eligible after exit and later separated leg")
  b=Shot.spawn(Vector2(w,y),Vector2.RIGHT,area,18,470,50,0,false);targets=[enemy(1,w-5,y)];ids=[];events=[]
  step(b,50,targets,ids,events)
  check(ids==[1] and events==["reflection","hit1"],label+" initial outward contact precedes untouched overlap damage")
  b=Shot.spawn(Vector2(10,y),Vector2.RIGHT,area,18,470,3*w,100,false);targets=[];ids=[];events=[]
  for i in range(6):targets.append(enemy(i+1,w*(.2+.1*i),y))
  step(b,3*w,targets,ids,events)
  check(b.leg_quota==6 and ids==[1,2,3,4,5,6,6,5,4,3,2,1,1,2,3,4,5,6],label+" quota capped at six and maximum eighteen contacts")
  check(b.total_hits==18 and b.reflections==2 and b.end_reason=="third_boundary",label+" bounded third-boundary termination")
  b=Shot.spawn(Vector2(20,y),Vector2.RIGHT,area,18,470,180,5,false);targets=[enemy(5,100,y),enemy(1,100,y)];ids=[];events=[]
  step(b,180,targets,ids,events);check(ids==[1,5],label+" exact contact tie uses ID not array order")
  b=Shot.spawn(Vector2(20,y),Vector2.RIGHT,area,18,470,180,5,false);targets=[enemy(1,130,y,.5),enemy(2,140,y,2.0)];ids=[];events=[]
  step(b,180,targets,ids,events);check(ids==[2,1],label+" circle entry order not center distance")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,200,0,false);targets=[enemy(1,w+16,y)];ids=[];events=[]
  step(b,200,targets,ids,events);check(events==["hit1","reflection"],label+" enemy exactly at positive boundary endpoint hit first")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,100,0,true);targets=[enemy(1,w+16,y)];ids=[];events=[]
  step(b,100,targets,ids,events)
  check(ids==[1] and b.reflections==0 and not b.guide_checked and events==["hit1"],label+" budget endpoint hit then expiry without free reflection/guide")
  for extra in [0.0,.01]:
   b=Shot.spawn(Vector2(20,y),Vector2.RIGHT,area,18,470,100,0,false);targets=[enemy(1,136+extra,y)];ids=[];events=[]
   step(b,100,targets,ids,events);check(ids==([1] if extra==0 else []),label+" exact/outside budget circle entry "+str(extra))
  b=Shot.spawn(Vector2(w-120,y),Vector2.RIGHT,area,18,470,240,0,false);targets=[enemy(1,w-80,y),enemy(2,w-40,y)];ids=[];events=[]
  var killed_target:Dictionary=targets[1]
  Shot.advance(b,240/470.0,targets,func(e,shot):e.hp-=shot.damage;ids.append(e.id);killed_target.hp=0,Callable())
  check(ids==[1,1] and b.total_hits==2,label+" proc-killed later target skipped without quota")
  # Guide selects after hits; kill the initial on-path target so it cannot win the search.
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,350,0,true);targets=[enemy(1,w-50,y,1,18),enemy(2,w-40,y+80)];ids=[];events=[]
  step(b,100,targets,ids,events)
  check(ids==[1] and targets[0].hp==0 and b.guided_once,label+" guide uses current living targets after primary damage")
  check(near(b.dx,-1.0/sqrt(5.0)) and near(b.dy,2.0/sqrt(5.0)),label+" guide one chosen center direction")
  var old_direction:Vector2=Vector2(b.dx,b.dy);targets[1].pos=Vector2(w-400,y-100)
  step(b,10,targets,ids,events);check(old_direction==Vector2(b.dx,b.dy),label+" moving target does not cause homing")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,350,0,true);targets=[enemy(7,w-30,y+40),enemy(2,w-30,y-40)];ids=[];events=[]
  step(b,100,targets,ids,events)
  check(b.guided_once and near(b.dx,-.6) and near(b.dy,-.8),label+" guide distance tie uses lower ID")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,350,0,true);targets=[enemy(1,w-10,y),enemy(2,w-50,y+50)];ids=[];events=[]
  step(b,100,targets,ids,events)
  check(b.blocked_overlap==[1] and b.guided_once and near(b.dx,-sqrt(.5)) and near(b.dy,sqrt(.5)),label+" guide excludes carried overlapping hit")
  b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,w+300,0,true);ids=[];events=[]
  step(b,100,[],ids,events)
  check(b.guide_checked and not b.guided_once,label+" empty first guide opportunity consumed")
  step(b,w,[enemy(1,40,y+60)],ids,events)
  check(b.reflections==2 and not b.guided_once and near(b.dx,1) and near(b.dy,0),label+" no deferred guide at second reflection")
  for kind in ["boundary","outside","center-beyond-budget","dead"]:
   b=Shot.spawn(Vector2(w-100,y),Vector2.RIGHT,area,18,470,190,0,true)
   var e:Dictionary=enemy(1,w,y+50)
   if kind=="outside":e.pos.x=w+1
   elif kind=="center-beyond-budget":e.pos=Vector2(w-60,y+80)
   elif kind=="dead":e=enemy(1,w-30,y+40,1,0)
   ids=[];events=[];step(b,100,[e],ids,events)
   check(b.guide_checked and not b.guided_once and near(b.dx,-1) and near(b.dy,0),label+" guide rejects "+kind)
  b=Shot.spawn(Vector2(w-100,size.y-100),Vector2.ONE,area,18,470,400,0,true);ids=[];events=[]
  step(b,sqrt(20000),[enemy(1,w-30,size.y-40)],ids,events)
  check(b.reflections==1 and b.guided_once and near(b.dx,-.6) and near(b.dy,-.8),label+" corner guide inward on both axes")
  rows.append({"field_width":w,"checks_so_far":checks})
 var report={"checks":checks,"failures":failures,"rows":rows,"scope":"independent pure helper contact/guide cases; callback damage and death mutation controlled, not full effect runtime or GUI"}
 FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
