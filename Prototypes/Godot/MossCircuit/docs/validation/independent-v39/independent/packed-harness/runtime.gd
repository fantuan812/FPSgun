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
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode,{"arc_relay":1,"echo_chamber":1})
  var target=spawn("crawler",Vector2(500,300));var other=spawn("crawler",Vector2(580,300));arm_beam(target);step(1.2)
  ck(near(target.hp,960.0) and near(other.hp,996.0),mode+" overdue four primary / only one real Arc 4damage")
  var hits:Array=g.effects.trace.filter(func(x):return x.event.kind=="hit")
  ck(hits.size()==4 and g.effects.echo_hits==4,mode+" exact four primary count not recursive")
  ck(hits.all(func(x):return near(x.time,11.2) and x.event.source=="primary" and x.event.depth==0 and x.event.weapon=="tether_emitter"),mode+" actual shared elapsed / compatible event")
  ck(g.effects.trace.reduce(func(total,x):return total+x.commands.filter(func(c):return c.kind=="chain").size(),0)==1,mode+" actual engine chain count one")
  arm_beam(target);step(.3)
  ck(near(target.hp,938.0) and near(other.hp,996.0) and g.effects.echo_hits==0,mode+" fifth primary real Echo12; Arc still cooling")
  ck(target.last_source=="echo",mode+" proc owns final last_source no primary overwrite")
  observations.append({"mode":mode,"case":"real_arc_echo","target_hp":target.hp,"other_hp":other.hp,"trace":g.effects.trace.duplicate(true)})
  setup(mode,{})
  var drone=spawn("stitch_drone",Vector2(500,300),34);var recipient=spawn("crawler",Vector2(500,390),50);recipient.max_hp=100.0
  arm_support(drone,recipient);arm_beam(drone);step(.3)
  ck(near(drone.hp,24.0) and near(recipient.hp,50.0),mode+" primary pulse interrupts due repair before settlement")
  ck(drone.ai_state!="warning" and drone.support_channel_token==null,mode+" true support cancel cleanup")
  setup(mode,{})
  drone=spawn("stitch_drone",Vector2(500,300),5);recipient=spawn("crawler",Vector2(500,390),50);recipient.max_hp=100.0
  arm_support(drone,recipient);arm_beam(drone);step(.3)
  ck(not g.enemies.has(drone) and near(recipient.hp,50.0),mode+" lethal newprimary removed before repair")
  ck(drone.support_channel_token==null and drone.support_target_id==-1 and not drone.support_due,mode+" held dead metadata disposed")
  setup(mode,{"recoil_plate":1})
  var near_enemy=spawn("crawler",Vector2(480,300));var far_enemy=spawn("crawler",Vector2(501,300));var boss=spawn("boss_warden",Vector2(470,300))
  g._hurt(1.0)
  ck(near(g.stats.hp,99.0) and near_enemy.pos==Vector2(535,300),mode+" actual positive hurt pushes exactly55")
  ck(far_enemy.pos==Vector2(501,300) and boss.pos==Vector2(470,300),mode+" outside100 and boss excluded")
  ck(near(near_enemy.hp,1000.0) and near(g.effects.recoil_cooldown.ready_at,12.0),mode+" no enemy damage and actualelapsed tombstone")
  var cooldown:Dictionary=g.effects.recoil_cooldown.duplicate(true)
  g.build.items={};g._recompute();g.build.items={"recoil_plate":1};g._recompute();g.elapsed=11.0;g.hurt_clock=0.0;near_enemy.pos=Vector2(480,300);g._hurt(1.0)
  ck(near_enemy.pos==Vector2(480,300) and g.effects.recoil_cooldown==cooldown,mode+" remove/reacquire does not refresh run cooldown")
  g.effects.reset(g.build.items);g.elapsed=11.5;g.hurt_clock=0.0;g._hurt(1.0)
  ck(near_enemy.pos==Vector2(480,300) and g.effects.recoil_cooldown==cooldown,mode+" actual encounter Effects.reset preserves new cooldown")
  g.elapsed=12.0;g.hurt_clock=0.0;g._hurt(1.0)
  ck(near_enemy.pos==Vector2(535,300) and near(g.effects.recoil_cooldown.ready_at,14.0),mode+" exact expiry ready again")
  setup(mode,{"recoil_plate":1});near_enemy=spawn("crawler",Vector2(480,300));g.stats.hp=1.0;g._hurt(1.0)
  ck(near_enemy.pos==Vector2(480,300) and g.effects.recoil_cooldown.is_empty(),mode+" lethal player loss does not recoil")
  setup(mode,{"recoil_plate":1});near_enemy=spawn("crawler",Vector2(480,300));g._hurt(0.0)
  ck(near_enemy.pos==Vector2(480,300) and g.effects.recoil_cooldown.is_empty(),mode+" zero HP loss no recoil")
  setup(mode,{"recoil_plate":1,"mirror_shell":1});near_enemy=spawn("crawler",Vector2(480,300));g._hurt(9.0)
  ck(g.stats.hp==100.0 and near_enemy.pos==Vector2(480,300) and g.effects.recoil_cooldown.is_empty(),mode+" actual shieldblock no recoil")
  setup(mode,{"recoil_plate":1});target=spawn("crawler",Vector2(500,300));arm_beam(target)
  var before:String=var_to_str(g.combat.pulse_beams);var epoch:int=g.combat.new_weapon_epoch;var m=ModeStub.new();m.valid=false
  ck(Flow.settle(g.combat,g.run,m,g.config,g.effects,g.encounters)=="invalid",mode+" invalid direct settle rejection")
  ck(var_to_str(g.combat.pulse_beams)==before and g.combat.new_weapon_epoch==epoch,mode+" invalid settle does not clear new flight")
  m.valid=true;var result:String=Flow.settle(g.combat,g.run,m,g.config,g.effects,g.encounters)
  ck(result=="next" and g.combat.pulse_beams.is_empty() and g.combat.seismic_waves.is_empty() and g.combat.new_weapon_epoch>epoch,mode+" valid direct settle clears new entities")
  ck(g.elapsed==10.0,mode+" room settlement preserves run time")
 g._title()
 var helper=load("<WORKSPACE>/moss-v39-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Independent real main/CombatRuntime/Effects/RunFlow integration; controlled actor fixtures, no ordinary play claim"}))
 quit(0 if failures.is_empty() else 1)
