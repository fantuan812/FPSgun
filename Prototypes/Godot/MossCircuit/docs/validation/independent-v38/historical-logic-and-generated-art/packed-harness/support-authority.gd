extends SceneTree
# Independent hand expectations from frozen C2; no target implementation consulted.
const Support=preload("res://scripts/gameplay/enemy_support.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func actor(id:int,hp:float=10.0,maximum:float=20.0,pos:Vector2=Vector2(40,0))->Dictionary:
 return {"id":id,"kind":"crawler","behavior":"chase","boss":false,"parent_id":-1,"pos":pos,"hp":hp,"max_hp":maximum,"anim_hp":hp}
func drone(id:int=10)->Dictionary:
 var s:=actor(id,34,34,Vector2.ZERO)
 s.merge({"kind":"stitch_drone","behavior":"support_repair","support_radius":150.,"support_channel":1.2,"support_cooldown":5.,"support_retry":1.,"support_heal":10.,"support_max_alive":1,"ai_state":"move","cooldown_left":.8,"warning_left":0.,"recover_left":0.,"support_target_id":-1,"support_start_hp":0.,"support_due":false,"support_cancel_pending":{},"support_target_pos":Vector2.ZERO,"support_channel_token":null},true)
 return s
func arm(s:Dictionary,t:Dictionary,left:float=0.0)->Dictionary:
 s.ai_state="warning";s.support_target_id=t.id;s.support_start_hp=s.hp;s.warning_left=left;s.support_due=left<=0;s.support_target_pos=t.pos;s.support_channel_token=RefCounted.new()
 return {"source_id":s.id,"channel_token":s.support_channel_token}
func cleared(s:Dictionary)->bool:
 return s.support_target_id==-1 and s.support_start_hp==0 and not s.support_due and s.support_channel_token==null
func values_only(v:Variant)->bool:
 if v is Object:return false
 if v is Dictionary:
  for x in v.values():
   if not values_only(x):return false
 if v is Array:
  for x in v:
   if not values_only(x):return false
 return true
func _initialize()->void:call_deferred("run")
func run()->void:
 var s:=drone();var a:=actor(2,5,10,Vector2(60,0));var b:=actor(3,10,20,Vector2(40,0));var world:Array=[s,a,b]
 var before:=world.duplicate(true)
 ck(Support.select_target(s,world)==3,"equal ratios nearest")
 ck(world==before,"selection is pure")
 a.pos=Vector2(40,0)
 ck(Support.select_target(s,[b,s,a])==2,"exact distance tie smallest stableID independent order")
 var c:=actor(4,5,20,Vector2(149,0));ck(Support.select_target(s,[s,a,b,c])==4,"ratio precedes distance")
 for point in [Vector2(150,0),Vector2(90,120)]:
  a.pos=point;ck(Support.select_target(s,[s,a])==2,"inclusive Euclidean radius "+str(point))
 a.pos=Vector2(150.0001,0);ck(Support.select_target(s,[s,a])==-1,"just outside radius")
 for spec in [["hp",20.],["hp",0.],["hp",-1.],["boss",true],["parent_id",10],["kind","stitch_drone"],["behavior","support_repair"]]:
  a=actor(2);a[spec[0]]=spec[1];ck(Support.select_target(s,[s,a])==-1,"recipient exclusion "+str(spec))
 ck(Support.select_target(s,[s])==-1,"no self repair")
 for spec in [["hp",true],["hp",NAN],["max_hp",INF],["max_hp",0.],["pos",Vector2(INF,0)],["pos",[0,0]],["id",true],["id",2.5],["id",0]]:
  a=actor(2);a[spec[0]]=spec[1];ck(Support.select_target(s,[s,a])==-1,"malformed recipient failsclosed "+str(spec[0]))
 a=actor(2);b=actor(2);ck(Support.select_target(s,[s,a,b])==-1,"duplicate global IDs failclosed")
 a=actor(2);ck(not Support.can_repair(s,a),"can_repair requires active channel")
 var ticket:=arm(s,a,1.2);before=[s,a].duplicate(true)
 ck(Support.can_repair(s,a),"manual exact active schema valid")
 ck([s,a]==before,"can_repair pure including token identity")
 s.hp-=.000001;ck(not Support.can_repair(s,a),"small actual HP loss no epsilon")
 s=drone();a=actor(2,17,20);ticket=arm(s,a)
 var records:Array=Support.settle([a,s],[ticket],true)
 ck(a.hp==20 and a.anim_hp==20,"heal clamp and future hurt baseline")
 ck(records.size()==1 and records[0].kind=="complete" and records[0].amount==3,"actual nonzero amount not proposed10")
 ck(values_only(records),"detached public records no token/actor")
 ck(s.ai_state=="recover" and s.cooldown_left==5 and s.recover_left==.7 and cleared(s),"success resets lifecycle exactly")
 ck(Support.settle([s,a],[ticket],true).is_empty() and a.hp==20,"used ticket cannot heal twice")
 s=drone();a=actor(2,17,20);ticket=arm(s,a,1.2);a.hp=12
 ck(Support.can_repair(s,a),"target nonlethal injury is not source interruption")
 var due:Array=Support.advance([s,a],1.2,true)
 records=Support.settle([s,a],due,true)
 ck(a.hp==20 and records.size()==1 and records[0].amount==8,"target actual HP clamp after injury")
 for bad_ticket in [{"source_id":10,"channel_token":RefCounted.new()},{"source_id":999,"channel_token":RefCounted.new()},{"source_id":true,"channel_token":RefCounted.new()},17,{}]:
  s=drone();a=actor(2);ticket=arm(s,a)
  ck(Support.settle([s,a],[bad_ticket],true).is_empty() and a.hp==10,"forged malformed ticket rejects")
  ck(s.ai_state=="warning" and s.support_due,"missing exact ticket leaves valid due pending")
  ck(Support.settle([s,a],[ticket,ticket],true).size()==1 and a.hp==20,"duplicate authentic ticket heals once")
 s=drone();a=actor(2,5,100);ticket=arm(s,a);var old_token:RefCounted=s.support_channel_token
 Support.settle([s,a],[ticket],true);arm(s,a)
 ck(s.support_channel_token!=old_token,"new channel fresh identity")
 ck(Support.settle([s,a],[ticket],true).is_empty() and a.hp==15,"old channel ID ticket cannot heal new channel")
 for dead_source in [false,true]:
  s=drone();a=actor(2);ticket=arm(s,a)
  if dead_source:s.hp=0
  else:a.hp=0
  records=Support.settle([s,a],[ticket],true)
  ck(a.hp==0 if not dead_source else a.hp==10,"dead-but-present never repaired")
  ck(records.is_empty() if dead_source else records.size()==1 and records[0].kind=="cancel","dead source no burst; living source targetdeath cancel")
 s=drone();a=actor(2);ticket=arm(s,a,1.2);s.hp=33
 due=Support.advance([s,a],0,true)
 ck(due.is_empty() and s.ai_state=="recover" and cleared(s),"A source-loss cancels without reacquisition")
 ck(not s.support_cancel_pending.is_empty(),"A stores detached pending cancel")
 records=Support.settle([s,a],due,true)
 ck(records.size()==1 and records[0].kind=="cancel" and records[0].amount==0,"B drains A cancel once")
 ck(s.support_cancel_pending.is_empty() and Support.settle([s,a],[],true).is_empty(),"no duplicate cancellation")
 s=drone();a=actor(2);due=Support.advance([s,a],.8,true)
 ck(due.is_empty() and s.ai_state=="warning" and s.warning_left==1.2,"entry tick not subtracted from channel")
 ck(a.hp==10 and Support.settle([s,a],due,true).is_empty(),"acquisition does not immediately repair")
 due=Support.advance([s,a],100,true)
 ck(due.size()==1 and s.warning_left<=0,"large dt produces one ticket; negative remaining valid")
 records=Support.settle([s,a],due,true)
 ck(records.size()==1 and a.hp==20 and s.cooldown_left==5,"large dt no catchup / new cooldown not aged")
 s=drone();due=Support.advance([s],.8,true)
 ck(due.is_empty() and s.ai_state=="move" and s.cooldown_left==1,"no recipient retry1")
 s=drone();a=actor(2);s.hp=33;due=Support.advance([s,a],.8,true)
 ck(s.support_start_hp==33 and Support.can_repair(s,a),"pre-entry damage is baseline")
 s.hp=32;records=Support.settle([s,a],due,true)
 ck(records.size()==1 and records[0].kind=="cancel" and a.hp==10,"late same-entry tick HP loss cancels")
 for endpoint in [Vector2(150.001,0),Vector2(1000,0)]:
  s=drone();a=actor(2);ticket=arm(s,a);a.pos=endpoint
  records=Support.settle([s,a],[ticket],true)
  ck(a.hp==10 and records.size()==1 and records[0].kind=="cancel","late current endpoint not clamped for eligibility")
 for initial_hp in [75.,95.]:
  for reverse in [false,true]:
   s=drone(10);var s2:=drone(11);a=actor(2,initial_hp,100)
   var t1:=arm(s,a);var t2:=arm(s2,a)
   records=Support.settle([a,s2,s] if reverse else [s,a,s2],[t2,t1,t2],true)
   ck(a.hp==95 if initial_hp==75 else a.hp==100,"multi-source clamps liveHP")
   ck(records.size()==2 and records[0].source_id==10 and records[1].source_id==11,"stable source order not input/ticket order")
   ck(records[0].kind=="complete" and records[1].kind==("complete" if initial_hp==75 else "cancel"),"second pulse sees first actual heal")
 for invalid_dt in [-1.,NAN,INF]:
  s=drone();a=actor(2);arm(s,a,1.2);before=[s,a].duplicate(true)
  ck(Support.advance([s,a],invalid_dt,true).is_empty() and [s,a]==before,"invalid dt no progression")
 s=drone();a=actor(2);ticket=arm(s,a)
 ck(Support.settle([s,a],[ticket],false).is_empty() and a.hp==10 and cleared(s),"terminal suppresses repair and transitions")
 # Config diagnostics: seven old kinds need no new fields; support declaration is strict.
 ck(Support.validate_entry({"id":"crawler","behavior":"chase"}).is_empty(),"old row no support config")
 var entry:Dictionary=drone();entry.id="stitch_drone"
 ck(Support.validate_entry(entry).is_empty(),"exact new declared config")
 entry.support_max_alive=1.0;ck(Support.validate_entry(entry).is_empty(),"integral JSON numeric count accepted")
 for key in ["support_radius","support_channel","support_cooldown","support_retry","support_heal","support_max_alive"]:
  var missing:Dictionary=entry.duplicate(true);missing.erase(key);ck(not Support.validate_entry(missing).is_empty(),"missing required support field "+key)
  for value in [true,NAN,INF,0.,-1.]:
   var malformed:Dictionary=entry.duplicate(true);malformed[key]=value;ck(not Support.validate_entry(malformed).is_empty(),"invalid support numeric "+key+"/"+str(value))
 entry.support_max_alive=1.5;ck(not Support.validate_entry(entry).is_empty(),"fractional support cap rejected")
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Independent C2 hand policy and lifecycle cases; actual runtime integration/asset/native evidence separate."}))
 quit(0 if failures.is_empty() else 1)
