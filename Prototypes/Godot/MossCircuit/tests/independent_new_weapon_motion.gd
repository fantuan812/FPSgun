extends SceneTree
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
const Flow=preload("res://scripts/gameplay/run_flow.gd")
const Support=preload("res://scripts/gameplay/enemy_support.gd")
class TraceEffects:
 extends "res://scripts/effects.gd"
 var trace:Array=[]
 func process(event:Dictionary,context:Dictionary)->Array:
  var commands:Array=super.process(event,context)
  trace.append({"event":event.duplicate(true),"time":context.time,"commands":commands.duplicate(true)})
  return commands
class ModeStub extends RefCounted:
 var valid:bool=true
 func can_end(_session:RefCounted,_world:RefCounted,_encounters:Dictionary)->bool:return true
 func resolution(_session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:
  return {"terminal":false,"shop":false,"next_stage":2,"upgrades":0,"coins":0.0,"heal":0.0} if valid else {"terminal":"notbool"}
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.00001
func setup(mode:String,items:Dictionary,weapon:String="tether_emitter")->void:
 g._title();g._select_mode(mode);g._start_run(39003)
 g.build.weapons=[weapon];g.build.weapon_temper=[0];g.build.items=items.duplicate(true);g._recompute()
 var fx=TraceEffects.new();fx.configure(g.catalog);fx.reset(g.build.items);g.effects=fx;g.effect_runtime.engine=fx
 g.elapsed=10.0;g.spawn_clock=999.0;g.weapon_clocks.fill(999.0);g.player_pos=Vector2(400,300);g.hero.position=g.player_pos;g.stats.hp=100.0;g.stats.dash_time=0.0;g.hurt_clock=0.0;g.combat_frame.area=g.config.arena
func spawn(id:String,pos:Vector2,hp:float=1000.0)->Dictionary:
 var e:Dictionary=g._spawn_kind(id,pos);e.speed=0.0;e.damage=0.0;e.hp=hp;e.max_hp=hp;e.anim_hp=hp;return e
func step(dt:float)->void:
 g.elapsed+=dt;Combat.step(g.combat_frame,dt)
func arm_beam(target:Dictionary,damage:float=10.0)->Dictionary:
 var b={"epoch":g.combat.new_weapon_epoch,"slot_id":0,"weapon_id":"tether_emitter","target_id":target.id,"damage":damage,"range":280.0,"interval":1.2,"tier":0,"pulse_count":4,"pulse_index":0,"active_age":0.0,"wall_age":0.0,"memory_grace":0.0,"grace_left":0.0,"grace_spent":false,"was_outside":false}
 g.combat.pulse_beams.append(b);return b
func arm_support(source:Dictionary,target:Dictionary)->void:
 source.ai_state="warning";source.support_target_id=target.id;source.support_start_hp=source.hp;source.support_due=false;source.warning_left=0.0;source.support_target_pos=target.pos;source.support_channel_token=RefCounted.new();source.support_cancel_pending={}
func _initialize()->void:call_deferred("run")
func wave(age:float=0.0)->Dictionary:
 var w={"epoch":g.combat.new_weapon_epoch,"slot_id":0,"weapon_id":"seismic_drum","sequence":1,"center":g.player_pos,"damage":22.0,"range":180.0,"initial_radius":24.0,"half_width":12.0,"outward_seconds":0.6,"return_enabled":false,"inward_seconds":0.45,"inward_damage_scale":0.5,"age":age,"hit_out":{},"hit_in":{},"outward_done":false}
 g.combat.seismic_waves.append(w);return w
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode,{},"seismic_drum")
  var target=spawn("crawler",Vector2(500,300),100.0);target.speed=200.0;wave();step(.5)
  var motion:Dictionary=g.combat.new_weapon_motion[target.id]
  ck(motion.p0==Vector2(500,300) and motion.p1==Vector2(400,300) and motion.final_pos==target.pos and motion.has_segment,mode+" actual AI normal motion sampled before endpoint")
  ck(near(target.hp,78.0),mode+" normal moving target crosses growing ring though endpoint is inside hole")
  ck(g.effects.trace.filter(func(x):return x.event.kind=="hit").size()==1,mode+" actual primary callback exactly once")
  observations.append({"mode":mode,"case":"normal_segment","motion":motion.duplicate(true),"hp":target.hp})
  setup(mode,{"recoil_plate":1},"seismic_drum")
  target=spawn("crawler",Vector2(480,300),100.0);target.scale=.1
  var contact=spawn("crawler",Vector2(405,300),100.0);contact.damage=1.0
  wave(.3);step(.01);motion=g.combat.new_weapon_motion[target.id]
  ck(near(g.stats.hp,99.0) and target.pos==Vector2(535,300),mode+" later actor true contact triggers real Recoil55")
  ck(motion.p0==Vector2(480,300) and motion.p1==Vector2(480,300) and motion.final_pos==Vector2(535,300),mode+" earlier actor normal segment preserved separately from control displacement")
  ck(near(target.hp,100.0),mode+" no fictional Recoil chord across narrow annulus")
  ck(g.effects.trace.filter(func(x):return x.event.kind=="hit" and x.event.target==target.id).is_empty(),mode+" no primary event for control-only crossing")
  observations.append({"mode":mode,"case":"recoil_discontinuity","motion":motion.duplicate(true),"hp":target.hp,"player_hp":g.stats.hp})
 g._title()
 var helper=load("res://tests/support/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Independent finite real CombatRuntime AI normal sampling and later-contact Recoil discontinuity; controlled actors, not ordinary or universal CCD"}))
 quit(0 if failures.is_empty() else 1)
