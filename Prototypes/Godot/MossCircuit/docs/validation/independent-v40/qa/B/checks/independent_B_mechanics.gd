extends SceneTree
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
var checks:=0
var failures:Array=[]
var r
var seq:=0
var tick:=0
var now:=0.0
var enemies:Array=[]
var area:Dictionary={"width":800,"height":600}
var player:=Vector2(300,300)
var owned:Dictionary={}
var weapons:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<0.00001
func catalog()->Dictionary:
 return {"weapon_slots":4,"item_slots":8,"weapons":[{"id":"rivet_gun","kind":"weapon","max_stack":4},{"id":"scrap_shotgun","kind":"weapon","max_stack":4},{"id":"return_disc","kind":"weapon","max_stack":4}],"items":[{"id":"crossfire_pin","kind":"item","price":28,"max_stack":1,"effects":{},"mark_seconds":1.5,"pull_distance":45.0,"cooldown":1.0,"requires_distinct_weapon_types":2},{"id":"salvage_capacitor","kind":"item","price":28,"max_stack":1,"effects":{},"charge_limit":3,"field_limit":2,"field_radius":80.0,"field_seconds":1.8,"field_speed_factor":0.7,"pickup_sources":["normal"]},{"id":"medic_winch","kind":"item","price":24,"max_stack":1,"effects":{},"pickup_count":5,"max_pulls_per_step":1,"medical_range":220.0,"pull_distance":80.0,"pickup_sources":["normal"]}]}
func enemy(id:int,pos:Vector2)->Dictionary:return {"id":id,"pos":pos,"hp":50.0,"boss":false,"ai_state":"move","kind":"crawler","behavior":"crawler","velocity":Vector2.ZERO,"timer":0.4}
func setup(item:String,ws:Array=["rivet_gun","scrap_shotgun"])->void:
 r=Runtime.new();seq=0;tick=0;now=0.0;area={"width":800,"height":600};player=Vector2(300,300);enemies=[enemy(7,Vector2(200,200))];owned={item:1};weapons=ws.duplicate()
 ck(r.clear_run(1),"setup epoch")
 ck(r.configure(catalog()).get("ok",false),"setup exact literal catalog")
 ck(r.sync_build(owned,weapons,now),"setup ownership")
 ck(r.begin_step(now,tick,enemies,area),"setup initial batch")
func ctx(dashing:bool=false)->Dictionary:return {"playing":true,"time":now,"effect_epoch":1,"step_serial":tick,"player_pos":player,"dash_active":dashing,"enemies":enemies,"area":area}
func send(kind:String,source:String,extra:Dictionary={})->Array:
 seq+=1
 var e={"kind":kind,"source":source,"depth":0,"epoch":1,"sequence":seq}
 e.merge(extra,true)
 return r.process(e,ctx(kind=="dash"))
func hit(w:String="rivet_gun",id:int=7)->Array:return send("hit","primary",{"weapon":w,"target":id,"damage":0.0})
func pickup(n:int,source:String="normal")->void:
 for i in n:send("pickup",source)
func step(t:float)->void:
 now=t;tick+=1
 ck(r.begin_step(now,tick,enemies,area),"next valid batch")
func snap()->Dictionary:return r.debug_snapshot()
func pin_cases()->void:
 setup("crossfire_pin");hit();ck(snap().mark=={"target_id":7,"weapon":"rivet_gun","position":Vector2(200,200),"expires":1.5},"pin first zero-damage primary exact mark")
 step(.2);enemies[0].pos=Vector2(260,200);var cmds=hit("scrap_shotgun")
 ck(cmds.size()==1 and snap().mark==null and near(snap().pin_ready_at,1.2),"pin second consumes exact CD")
 var before=enemies[0].duplicate(true);var moved=r.apply_control(cmds[0],enemies,area) if cmds.size()==1 else {}
 before.pos=Vector2(215,200)
 ck(moved.get("moved",false) and enemies[0]==before,"pin live position pull45 only position changes")
 setup("crossfire_pin");hit();var mark=snap().mark.duplicate(true);step(.2);enemies[0].pos=Vector2(260,200)
 ck(hit().is_empty(),"same weapon no pull")
 enemies.append(enemy(8,Vector2(220,200)));step(.4);ck(hit("scrap_shotgun",8).is_empty() and snap().mark==mark,"other target no overwrite or refresh")
 step(4.0);ck(snap().mark==null and near(snap().pin_ready_at,5.0),"observed expiry starts cooldown now not deadline")
 setup("crossfire_pin",["rivet_gun","scrap_shotgun","return_disc"]);hit();now=.5
 ck(r.sync_build(owned,["scrap_shotgun","return_disc"],now) and snap().mark==null and near(snap().pin_ready_at,1.5),"origin loss clears even two other types remain")
 setup("crossfire_pin",["rivet_gun","rivet_gun","scrap_shotgun"]);hit();mark=snap().mark.duplicate(true)
 ck(r.sync_build(owned,["rivet_gun","scrap_shotgun"],0.0) and snap().mark==mark,"one duplicate removed retains origin type")
 setup("crossfire_pin",["rivet_gun","rivet_gun"]);ck(hit().is_empty() and snap().mark==null,"two copies not two types")
 setup("crossfire_pin");enemies[0].hp=0;ck(hit().is_empty() and snap().mark==null and snap().pin_ready_at==null,"old proc killed before first no mark or CD")
 setup("crossfire_pin");hit();enemies[0].hp=0;step(.6);ck(hit("scrap_shotgun").is_empty() and snap().mark==null and near(snap().pin_ready_at,1.6),"old proc killed before second cancels no resurrection")
 setup("crossfire_pin");enemies[0].boss=true;ck(hit().is_empty() and snap().mark==null,"boss not marked")
 setup("crossfire_pin");enemies.append(enemy(7,Vector2(220,200)));ck(hit().is_empty() and snap().mark==null,"duplicate live ID failclosed")
 setup("crossfire_pin",["scrap_shotgun","return_disc"]);ck(hit().is_empty() and snap().mark==null,"sold in-flight origin excluded from B")
 setup("crossfire_pin");hit();step(.25);cmds=hit("scrap_shotgun");moved=r.apply_control(cmds[0],enemies,area) if cmds.size()==1 else {}
 ck(not moved.get("moved",true) and enemies[0].pos==Vector2(200,200) and near(snap().pin_ready_at,1.25),"zero-distance consumes without position movement")
 var out=enemy(7,Vector2(-50,200));before=out.duplicate(true)
 moved=r.apply_control({"kind":"pin_pull","target_id":7,"anchor":Vector2(100,200),"distance":45.0,"source_item":"crossfire_pin"},[out],area)
 ck(not moved.get("moved",true) and out==before,"inset cannot turn45 into70 displacement")
 setup("crossfire_pin");hit();ck(r.reset_encounter(.5) and snap().mark==null and snap().pin_ready_at==null,"room clearing active mark creates no cooldown")
 setup("crossfire_pin");step(6.0);hit();enemies[0].pos=Vector2(260,200);hit("scrap_shotgun")
 ck(near(snap().pin_ready_at,7.0) and r.reset_encounter(6.0) and near(snap().pin_ready_at,7.0),"room preserves existing finite cooldown")
 setup("crossfire_pin");step(1e308);ck(hit().is_empty() and snap().mark==null and snap().pin_ready_at==null,"unrepresentable future does not create mark/infinite timer")
func salvage_cases()->void:
 setup("salvage_capacitor");pickup(1);pickup(1,"energy");pickup(1);pickup(1,"medical");pickup(2)
 ck(snap().charges==3,"normal-only capped charge")
 setup("salvage_capacitor");pickup(2);send("dash","primary",{"pos":Vector2(300,200)})
 ck(snap().charges==2 and snap().fields.is_empty(),"partial real dash retains charge")
 pickup(1);now=1.0;player=Vector2(370,200);send("dash","primary",{"pos":Vector2(300,200)})
 ck(snap().charges==0 and snap().fields==[{"pos":Vector2(300,200),"expires":2.8,"sequence":1}],"field uses saved pre-movement origin")
 step(1.0);ck(snap().fields.size()==1,"begin after dash does not erase new field")
 var e=enemy(1,Vector2(380,200));var before=snap()
 ck(near(r.movement_factor(e,2.0,area),.7),"radius boundary closed")
 e.pos=Vector2(380.01,200);ck(near(r.movement_factor(e,2.0,area),1.0),"outside radius neutral")
 e.pos=Vector2(300,200);ck(near(r.movement_factor(e,2.8,area),1.0),"expiry boundary excluded")
 e.boss=true;ck(near(r.movement_factor(e,2.0,area),1.0),"boss not slowed by new field")
 e.boss=false;e.ai_state="charging";ck(near(r.movement_factor(e,2.0,area),1.0),"committed charging not slowed")
 e.ai_state="move";ck(near(minf(.5,r.movement_factor(e,2.0,area)),.5),"existing stronger slow preserved")
 ck(snap()==before,"movement queries pure")
 setup("salvage_capacitor")
 for i in 3:
  if i>0:step(float(i)*.2)
  pickup(3);send("dash","primary",{"pos":Vector2(200+100*i,200)})
 ck(snap().fields.size()==2 and snap().fields[0].pos==Vector2(300,200) and snap().fields[1].pos==Vector2(400,200) and near(snap().fields[0].expires,2.0) and near(snap().fields[1].expires,2.2),"third field evicts only oldest with literal lifetimes")
 before=snap();pickup(3);area.width=40;send("dash","primary",{"pos":Vector2(500,200)})
 ck(snap().charges==0 and snap().fields==before.fields and snap().next_field_sequence==3,"bad area spends charge but cannot evict or increment creation ID")
 setup("salvage_capacitor");pickup(2);before=snap();ck(r.sync_build(owned,weapons,now) and snap()==before,"retained sync preserves charge")
 ck(r.sync_build({},weapons,now) and snap().charges==0 and snap().fields.is_empty(),"sale clears own stock and fields")
 r.sync_build(owned,weapons,now);pickup(3);send("dash","primary",{"pos":Vector2(300,300)});pickup(1)
 ck(r.reset_encounter(now) and snap().charges==0 and snap().fields.is_empty(),"room clears field and partial charge")
func med(pos:Vector2)->Dictionary:return {"pos":pos,"source":"medical","value":1,"life":100.0}
func winch_cases()->void:
 setup("medic_winch");pickup(5);var meds=[med(Vector2(460,300)),med(Vector2(140,300))]
 var result=r.flush_pickups(ctx(),meds)
 ck(result.get("accepted",false) and result.get("moved_index",-1)==0 and meds[0].pos==Vector2(380,300) and meds[1].pos==Vector2(140,300) and snap().winch_count==0,"nearest tie keeps first live array element")
 setup("medic_winch");pickup(5);player=Vector2(500,300);pickup(5);meds=[med(Vector2(500,300))];result=r.flush_pickups(ctx(),meds)
 ck(result.get("moved_index",-1)==0 and meds[0].pos==Vector2(420,300) and snap().winch_count==0,"two thresholds one batch only first origin pull")
 setup("medic_winch");pickup(7);ck(snap().winch_count==2 and snap().pending!=null,"seventh pickup leaves count2 plus one request")
 setup("medic_winch");pickup(5);result=r.flush_pickups(ctx(),[])
 ck(result.get("accepted",false) and result.get("moved_index",0)==-1 and snap().pending==null and snap().winch_count==0,"no medicine still consumes request threshold")
 for pair in [[Vector2(520,300),Vector2(440,300),0],[Vector2(520.1,300),Vector2(520.1,300),-1],[Vector2(330,300),Vector2(300,300),0],[Vector2(300,300),Vector2(300,300),-1]]:
  setup("medic_winch");pickup(5);meds=[med(pair[0])];result=r.flush_pickups(ctx(),meds)
  ck(result.get("moved_index",-2)==pair[2] and meds[0].pos==pair[1] and meds.size()==1,"closed range and no overshoot "+str(pair))
 setup("medic_winch");pickup(5);meds=[med(Vector2(400,300))];var before=meds[0].duplicate(true);before.pos=Vector2(320,300);result=r.flush_pickups(ctx(),meds)
 ck(meds.size()==1 and meds[0]==before and result.get("moved_index",-1)==0,"after prior removal only surviving medical moves no reward/remove mutation")
 setup("medic_winch");pickup(1,"energy");pickup(1,"medical")
 ck(snap().winch_count==0 and snap().pending==null,"non-normal pickups do not count; settlement has no callback")
 setup("medic_winch");step(1.0);pickup(5);before=snap();var wrong=ctx();wrong.step_serial=99;meds=[med(Vector2(460,300))]
 ck(not r.flush_pickups(wrong,meds).get("accepted",true) and snap()==before,"wrong flush context does not consume request")
 result=r.flush_pickups(ctx(),meds);ck(result.get("accepted",false) and meds[0].pos==Vector2(380,300),"matching batch accepted once")
 before=snap();ck(not r.flush_pickups(ctx(),meds).get("accepted",true) and snap()==before and meds[0].pos==Vector2(380,300),"repeat closed flush cannot move again")
 setup("medic_winch");pickup(5);r.cancel_pending()
 ck(snap().winch_count==0 and snap().pending==null and not r.flush_pickups(ctx(),[med(Vector2(460,300))]).get("accepted",true),"pause closes pending without refund or resumed flush")
func guard_cases()->void:
 setup("crossfire_pin");seq=7;send("hit","chain",{"weapon":"rivet_gun","target":7})
 ck(snap().last_sequence==8 and snap().mark==null,"typed wrong source spends sequence")
 var e={"kind":"hit","source":"primary","depth":0,"epoch":1,"sequence":8,"weapon":"rivet_gun","target":7};var before=snap()
 ck(r.process(e,ctx()).is_empty() and snap()==before,"corrected source same spent sequence rejected")
 e.sequence=9;e.source=null;ck(r.process(e,ctx()).is_empty() and snap()==before,"null source PRE preserves full state")
 e.source="primary";r.process(e,ctx());ck(snap().last_sequence==9 and snap().mark!=null,"same sequence correction after PRE admitted once")
 e.sequence=12;e.source="chain";r.process(e,ctx());ck(r.bind_epoch(2,0.0) and snap().last_sequence==12,"forward trusted epoch keeps consumed sequence")
 var c=ctx();c.effect_epoch=2;e.epoch=2;before=snap();ck(r.process(e,c).is_empty() and snap()==before,"old sequence not replayable after new epoch")
 e.epoch=99;e.sequence=13;c.effect_epoch=99;ck(r.process(e,c).is_empty() and snap()==before,"untrusted event cannot bind epoch")
 setup("medic_winch");tick=4;now=2.0;ck(r.begin_step(now,tick,enemies,area),"controlled serial4 setup")
 pickup(5);before=snap();ck(not r.begin_step(now,tick,enemies,area) and snap()==before,"repeated step preserves pending")
 c=ctx();c.time=1.0;e={"kind":"pickup","source":"normal","depth":0,"epoch":1,"sequence":6}
 ck(r.process(e,c).is_empty() and snap()==before,"backward time entire state unchanged")
 for bad in [{"not_registered":1},{"medic_winch":0},{"medic_winch":true},{"medic_winch":.5}]:
  ck(not r.sync_build(bad,weapons,now) and snap()==before,"invalid item sync atomic "+str(bad))
 for bad in [["not_registered"],["rivet_gun","rivet_gun","rivet_gun","rivet_gun","scrap_shotgun"]]:
  ck(not r.sync_build(owned,bad,now) and snap()==before,"invalid weapons sync atomic "+str(bad))
 ck(r.clear_run(3),"newrun reset accepted")
 var s=snap();ck(s.last_sequence==0 and s.last_step_serial==-1 and s.mark==null and s.charges==0 and s.fields.is_empty() and s.winch_count==0 and s.configuration_open,"only newrun resets replay/inventory together")
func _initialize()->void:
 pin_cases();salvage_cases();winch_cases();guard_cases()
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"Independent literal B hand-sequence runtime policy, controlled current-world/pickup arrays; no main/Effects integration, no natural pickups or old damage claims"}))
 quit(0 if failures.is_empty() else 1)
