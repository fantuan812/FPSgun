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
 f.world.new_weapon_motion[1]={"p0":Vector2(100,0),"p1":Vector2(100,0),"final_pos":Vector2(100,0),"has_segment":true}
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
 var f=frame("seismic_drum");var r=runtime(f)
 for i in range(3):
  var w=wave(f,.1);w.sequence=i+1
 f.world.new_wave_sequence=3;f.world.weapon_clocks[0]=0.0;r.step(f,.01,1)
 ck(f.world.seismic_waves.size()==3 and f.weapons.presentation.calls.is_empty(),"pretarget per-slot cap3 blocks fourth")
 ck(near(f.world.weapon_clocks[0],1.4),"failed cap attempt consumes full launch interval")
 ck(f.world.new_wave_sequence==3,"failed cap attempt creates no sequence")
 f=frame("seismic_drum");r=runtime(f)
 for i in range(3):
  var w=wave(f,1.04 if i==0 else .1);w.sequence=i+1
 f.world.new_wave_sequence=3;f.world.weapon_clocks[0]=0.0;r.step(f,.02,1)
 ck(f.world.seismic_waves.size()==3 and f.weapons.presentation.calls.size()==1,"old expiry frees cap before one attempt")
 ck(f.world.seismic_waves[-1].sequence==4 and f.world.seismic_waves[-1].age==0.0,"new wave endpoint only, unique nextsequence")
 ck(near(f.world.weapon_clocks[0],1.4),"successful replacement consumes one interval")
 f=frame("seismic_drum");r=runtime(f);f.session.build.weapons=["seismic_drum","seismic_drum"];f.session.build.weapon_temper=[0,0];f.world.weapon_clocks=[0.0,0.0]
 for i in range(3):
  var w=wave(f,.1);w.sequence=i+1
 f.world.new_wave_sequence=3;r.step(f,.01,1)
 ck(f.world.seismic_waves.filter(func(w):return w.slot_id==0).size()==3 and f.world.seismic_waves.filter(func(w):return w.slot_id==1).size()==1,"cap is per-copy slot not global")
 ck(f.weapons.presentation.calls.size()==1 and f.weapons.presentation.calls[0].slot==1,"only second slot launches")
 f=frame("seismic_drum");r=runtime(f);f.session.build.items={"return_collar":1};f.session.build.weapon_temper=[1];f.world.weapon_clocks[0]=0.0;r.step(f,.01,1)
 var held:Dictionary=f.world.seismic_waves[0]
 ck(near(held.damage,35.2) and held.return_enabled and near(held.inward_damage_scale,.5),"pretarget tempered snapshot35.2 outward, half inward")
 r.step(f,.6,2);ck(near(f.world.enemies[0].hp,64.8),"tempered outward primary once35.2")
 r.step(f,.45,3);ck(near(f.world.enemies[0].hp,47.2) and f.world.seismic_waves.is_empty(),"tempered inward exactly17.6, not double temper")
 ck(f.procs.events.size()==2 and near(f.procs.events[0].event.damage,35.2) and near(f.procs.events[1].event.damage,17.6),"actual resolved event damages")
 f=frame("seismic_drum");r=runtime(f);f.world.weapon_clocks[0]=-10.0;r.step(f,4.0,1)
 ck(f.world.seismic_waves.size()==1 and f.world.seismic_waves[0].age==0.0 and f.procs.events.is_empty(),"large dt at most one endpoint launch, no catchup damage")
 f=frame("seismic_drum");r=runtime(f);f.world.enemies.clear();f.world.weapon_clocks[0]=0.0;r.step(f,.1,1)
 ck(f.world.seismic_waves.is_empty() and near(f.world.weapon_clocks[0],1.4),"empty acquisition still consumes cadence")
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Independent remaining pretarget cap/tempered/cadence cases through actual NewRuntime and primary defense; recorder emission only, no scene/native claim"}))
 quit(0 if failures.is_empty() else 1)
