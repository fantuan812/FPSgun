extends SceneTree
# Independent literal C2 timing/ownership oracle; mock emission/presentation only.
# Real NewWeaponRuntime/CombatState/RunSession/PrimaryDefense execute. Full Runtime
# and actual proc integration are separately required, not claimed by this file.
const NewRuntime=preload("res://scripts/gameplay/new_weapon_runtime.gd")
const World=preload("res://scripts/gameplay/combat_state.gd")
const Session=preload("res://scripts/gameplay/run_session.gd")
class Recorder extends RefCounted:
 var events:Array=[]
 var session:RefCounted
 func emit_event(kind:String,event:Dictionary)->void:
  events.append({"kind":kind,"event":event.duplicate(true),"elapsed":session.elapsed})
class Presentation extends RefCounted:
 var calls:Array=[]
 func fire(id:String,slot:int,pos:Vector2,radial:bool=false)->void:
  calls.append({"id":id,"slot":slot,"pos":pos,"radial":radial})
class Weapons extends RefCounted:
 var presentation=Presentation.new()
class Frame extends RefCounted:
 var world=World.new()
 var session=Session.new()
 var catalog:Dictionary
 var procs=Recorder.new()
 var weapons=Weapons.new()
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<0.0000001
func enemy(id:int=1,pos:Vector2=Vector2(100,0),hp:float=100)->Dictionary:
 return {"id":id,"pos":pos,"hp":hp,"scale":1.0,"kind":"crawler","behavior":"chase","boss":false}
func frame(id:String="tether_emitter")->Frame:
 var f=Frame.new()
 f.catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 f.session.state="playing";f.session.elapsed=10.0
 f.session.build={"weapons":[id],"items":{},"weapon_temper":[0]}
 f.procs.session=f.session
 f.world.player_pos=Vector2.ZERO;f.world.weapon_clocks=[100.0]
 f.world.stats={"damage_bonus":0.0,"electric_bonus":0.0,"melee_bonus":0.0,"haste":0.0,"range_bonus":0.0}
 f.world.enemies=[enemy()]
 return f
func runtime(f:Frame)->RefCounted:
 var r=NewRuntime.new();r.configure(f.catalog);return r
func beam(f:Frame,interval:float=1.2,grace:float=0.0)->Dictionary:
 var b={"epoch":f.world.new_weapon_epoch,"slot_id":0,"weapon_id":"tether_emitter","target_id":1,"damage":10.0,"range":280.0,"interval":interval,"tier":0,"pulse_count":4,"pulse_index":0,"active_age":0.0,"wall_age":0.0,"memory_grace":grace,"grace_left":0.0,"grace_spent":false,"was_outside":false}
 f.world.pulse_beams.append(b);return b
func wave(f:Frame,age:float=0.0)->Dictionary:
 var w={"epoch":f.world.new_weapon_epoch,"slot_id":0,"weapon_id":"seismic_drum","sequence":1,"center":Vector2.ZERO,"damage":22.0,"range":180.0,"initial_radius":24.0,"half_width":12.0,"outward_seconds":0.6,"return_enabled":true,"inward_seconds":0.45,"inward_damage_scale":0.5,"age":age,"hit_out":{},"hit_in":{},"outward_done":false}
 f.world.seismic_waves.append(w);return w
func _initialize()->void:call_deferred("run")
func run()->void:
 for row in [[1.2,.3,1],[1.2,.299,0],[.6,.3,2],[2.4,.6,1],[1.2,10.0,4]]:
  var f=frame();var r=runtime(f);var b=beam(f,row[0]);r.step(f,row[1],1)
  ck(f.procs.events.size()==row[2],"literal pulse count "+str(row))
  ck(near(f.world.enemies[0].hp,100.0-10.0*row[2]),"literal primary HP "+str(row))
  for event in f.procs.events:
   ck(event.elapsed==10.0 and event.kind=="hit" and event.event.source=="primary" and event.event.depth==0,"actual-time primary emission")
   ck(event.event.weapon=="tether_emitter" and event.event.weapon_id=="tether_emitter" and event.event.slot_id==0,"compatible contact metadata")
  if row[1]==10.0:ck(f.world.pulse_beams.is_empty(),"hardlife removal after four")
  observations.append({"case":"pulse","input":row,"events":f.procs.events,"hp":f.world.enemies[0].hp,"held":b})
 var f=frame();var r=runtime(f);var b=beam(f);f.world.enemies[0].hp=25.0;r.step(f,1.2,1)
 ck(f.procs.events.size()==3 and near(f.world.enemies[0].hp,-5.0) and f.world.pulse_beams.is_empty(),"dead after third prevents fourth")
 f=frame();r=runtime(f);f.world.weapon_clocks[0]=-2.0;r.step(f,4.0,1)
 ck(f.world.pulse_beams.size()==1 and f.procs.events.is_empty(),"launch at endpoint no catchup")
 ck(near(f.world.weapon_clocks[0],1.2) and f.world.pulse_beams[0].active_age==0.0,"launch clock/age")
 f=frame();r=runtime(f);b=beam(f);b.active_age=.9;b.wall_age=.9;b.pulse_index=3;f.world.weapon_clocks[0]=.3;r.step(f,.3,1)
 ck(f.procs.events.size()==1 and b.pulse_index==4 and f.world.pulse_beams.size()==1,"last old pulse then replace")
 ck(f.world.pulse_beams[0].pulse_index==0 and f.world.pulse_beams[0].active_age==0.0,"replacement is fresh endpoint")
 for dt in [.2,.3]:
  f=frame();r=runtime(f);b=beam(f,1.2,.2);f.world.enemies[0].pos=Vector2(281,0);r.step(f,dt,1)
  ck(f.procs.events.is_empty() and b.active_age==0.0,"outside freezes active age")
  ck(f.world.pulse_beams.is_empty()==(dt>.2),"first invalid step deducts its dt")
  if dt==.2:ck(near(b.grace_left,0.0),"exact grace zero retained")
 for row in [[0.0,true,true],[ -.001,true,false]]:
  f=frame();r=runtime(f);b=beam(f,1.2,.2);b.grace_left=row[0];b.grace_spent=true;b.was_outside=true;r.step(f,.1,1)
  ck((not f.world.pulse_beams.is_empty())==row[2],"zero resumes negative rejects")
  if row[2]:ck(near(b.active_age,.1) and b.grace_left==0.0,"valid recovery no further grace debit")
 f=frame();r=runtime(f);b=beam(f,1.2,.2);b.grace_spent=true;b.was_outside=false;f.world.enemies[0].pos=Vector2(281,0);r.step(f,.01,1)
 ck(f.world.pulse_beams.is_empty(),"second separation cancels")
 for active in [.9,.89]:
  f=frame();r=runtime(f);b=beam(f,1.2,.2);b.wall_age=1.1;b.active_age=active;b.pulse_index=3;r.step(f,.4,1)
  ck(near(b.wall_age,1.4) and near(b.active_age,active+.3),"wall clip before active advance")
  ck(f.procs.events.size()==(1 if active==.9 else 0) and f.world.pulse_beams.is_empty(),"hardclip fourth/no fourth")
 for kind in ["dead","missing","invalid_id"]:
  f=frame();r=runtime(f);b=beam(f,1.2,.2)
  if kind=="dead":f.world.enemies[0].hp=0.0
  elif kind=="missing":f.world.enemies.clear()
  else:b.target_id=0
  r.step(f,.1,1);ck(f.world.pulse_beams.is_empty() and f.procs.events.is_empty(),"invalid target no grace "+kind)
 for distance in [280,281]:
  f=frame();r=runtime(f);b=beam(f);f.world.player_pos=Vector2(20,20);f.world.enemies[0].pos=Vector2(20+distance,20);r.step(f,.3,1)
  ck(f.procs.events.size()==(1 if distance==280 else 0),"closed range uses live player")
 for focus in [9,0]:
  f=frame();r=runtime(f);f.world.weapon_clocks[0]=0.0;f.world.enemies=[enemy(8),enemy(3),enemy(9,Vector2(200,0))];f.world.focus_enemy_id=focus;r.step(f,.1,1)
  ck(f.world.pulse_beams[0].target_id==(9 if focus==9 else 3),"focus then nearest stable ID")
 f=frame();r=runtime(f);b=beam(f);f.world.enemies.append(enemy(3));f.world.focus_enemy_id=3;r.step(f,.3,7);r.step(f,.3,7)
 ck(b.target_id==1 and b.pulse_index==1,"no midbeam retarget or duplicate serial")
 r.step(f,.3,8);ck(b.pulse_index==2,"next fullstep identical dt advances")
 var serial:int=f.world.new_weapon_last_tick;r.clear(f.world);r.step(f,.3,8)
 ck(f.world.new_weapon_last_tick==serial and f.world.pulse_beams.is_empty(),"clear cannot reset serial guard")
 f=frame("seismic_drum");r=runtime(f);var w=wave(f);f.world.enemies=[enemy(1,Vector2(180,0))];r.step(f,.6,1)
 ck(near(f.world.enemies[0].hp,67.0) and w.hit_out.has(1) and w.hit_in.has(1),"turnpoint closed two legs outward then inward")
 f.world.enemies.append(enemy(2,Vector2(180,0)));r.step(f,.01,2)
 ck(near(f.world.enemies[0].hp,67.0) and near(f.world.enemies[1].hp,89.0),"no finished outward replay on newly entering enemy")
 ck(not w.hit_out.has(2) and w.hit_in.has(2),"outward_done carries prior closed endpoint")
 f=frame("seismic_drum");r=runtime(f);w=wave(f);f.world.enemies=[enemy(1,Vector2(180,0),20)];r.step(f,.6,1)
 ck(f.procs.events.size()==1 and near(f.world.enemies[0].hp,-2.0),"outward lethal suppresses inward")
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Independent pretarget literal beam/wave policy with recording sinks; not actual proc/full Runtime integration"}))
 quit(0 if failures.is_empty() else 1)
