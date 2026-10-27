extends SceneTree
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.00001
func _initialize()->void:call_deferred("run")
func setup(mode:String,row:Dictionary)->Dictionary:
 g._title();g._select_mode(mode);g._start_run(39073);g.set_process(false)
 g.build.weapons=["tether_emitter","seismic_drum"];g.build.weapon_temper=[0,0];g.build.items={"crossfire_pin":1}
 if row.id=="old_proc_death":g.build.items["echo_chamber"]=1
 g._recompute();g.enemies.clear();g.bullets.clear();g.pickups.clear();g.hazards.clear()
 g.player_pos=Vector2(400,300);g.elapsed=10.0;g.combat_frame.area=g.config.arena;g.weapon_clocks=[0.0,0.0]
 var e:Dictionary=g._spawn_kind("crawler",Vector2(row.x,300));e.speed=0.0;e.damage=0.0;e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.scale=.1
 g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
 g.new_weapon_runtime.step(g.combat_frame,.001,g.combat.combat_tick_serial)
 ck(g.combat.pulse_beams.size()==1 and g.combat.seismic_waves.size()==1,mode+row.id+" actual runtime launches both attacks")
 var beam:Dictionary=g.combat.pulse_beams[0];var wave:Dictionary=g.combat.seismic_waves[0]
 # Controlled preexisting age/mark fixture; launch entities themselves come from real runtime.
 beam.active_age=.29;beam.wall_age=.29;wave.age=row.age;g.weapon_clocks=[999.0,999.0]
 e.pos=Vector2(row.anchor,300)
 g._effect_event("hit",{"target":e.id,"pos":e.pos,"weapon":"seismic_drum","source":"primary","depth":0,"damage":0.0})
 ck(g.effect_runtime.build_items.mark!=null and g.effect_runtime.build_items.mark.position==e.pos,mode+row.id+" real first-weapon event establishes mark")
 e.pos=Vector2(row.x,300)
 g.combat.new_weapon_motion.clear()
 if row.id!="no_motion":g.combat.new_weapon_motion[e.id]={"p0":e.pos,"p1":e.pos,"final_pos":e.pos,"has_segment":true}
 if row.id=="old_proc_death":e.hp=11.0;g.effects.echo_hits=4
 return {"enemy":e,"beam":beam,"wave":wave}
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var cases=[
  {"id":"pull_in","x":535.0,"anchor":500.0,"age":.3,"dt":.01,"to":500.0,"hp":968.0,"wave_hit":true,"pulses":1},
  {"id":"pull_out_keeps_segment","x":500.0,"anchor":455.0,"age":.3,"dt":.01,"to":455.0,"hp":968.0,"wave_hit":true,"pulses":1},
  {"id":"control_chord_not_swept","x":535.0,"anchor":490.0,"age":.3,"dt":.01,"to":490.0,"hp":990.0,"wave_hit":false,"pulses":1},
  {"id":"expired_no_endpoint","x":535.0,"anchor":580.0,"age":.59,"dt":.02,"to":580.0,"hp":990.0,"wave_hit":false,"pulses":1},
  {"id":"old_proc_death","x":535.0,"anchor":500.0,"age":.3,"dt":.01,"to":535.0,"hp":-11.0,"wave_hit":false,"pulses":1},
  {"id":"multiple_overdue","x":535.0,"anchor":500.0,"age":0.0,"dt":.61,"to":500.0,"hp":948.0,"wave_hit":true,"pulses":3},
  {"id":"no_motion","x":535.0,"anchor":500.0,"age":.3,"dt":.01,"to":500.0,"hp":968.0,"wave_hit":true,"pulses":1}
 ]
 for mode in ["arena","rooms"]:
  for row in cases:
   var state:Dictionary=setup(mode,row);var e:Dictionary=state.enemy;var wave:Dictionary=state.wave;var beam:Dictionary=state.beam
   g.elapsed+=row.dt;g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
   g.new_weapon_runtime.step(g.combat_frame,row.dt,g.combat.combat_tick_serial)
   var motion:Dictionary=g.combat.new_weapon_motion.get(e.id,{})
   ck(e.pos==Vector2(row.to,300),mode+row.id+" accepted destination or dead no-op")
   ck(near(e.hp,row.hp),mode+row.id+" literal primary/proc/wave HP")
   ck(wave.hit_out.has(e.id)==row.wave_hit,mode+row.id+" exact wave contact membership")
   ck(beam.pulse_index==row.pulses,mode+row.id+" scheduled primary pulse count")
   if row.id=="no_motion":
    ck(motion.is_empty(),mode+row.id+" absent record stays absent")
    ck(not g.combat.new_weapon_motion.has(e.id),mode+row.id+" no fabricated normal segment")
   else:
    ck(motion.p0==Vector2(row.x,300) and motion.p1==Vector2(row.x,300) and motion.has_segment==true,mode+row.id+" normal segment unchanged")
    ck(motion.final_pos==e.pos,mode+row.id+" final endpoint matches actual position")
   ck((g.effect_runtime.build_items.pin_ready_at is int or g.effect_runtime.build_items.pin_ready_at is float) and near(g.effect_runtime.build_items.pin_ready_at,11.0+row.dt),mode+row.id+" single cooldown from actual time; marked death housekeeping consumes mark without pull")
   observations.append({"mode":mode,"case":row.id,"hp":e.hp,"position":[e.pos.x,e.pos.y],"motion":motion.duplicate(true),"pulse_index":beam.pulse_index,"wave_hit":wave.hit_out.has(e.id),"pin_ready_at":g.effect_runtime.build_items.pin_ready_at})
 g._title();var helper=load("evidence-workspace/moss-v39-B-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"independent_B_pin_ring_checks":checks,"failures":failures,"observations":observations,"scope":"Controlled real runtime launch and beam -> old/A proc -> Pin -> ring phase integration. Preexisting ages/mark and normal-motion samples are explicit fixture inputs, not ordinary play or physical CCD."}))
 quit(0 if failures.is_empty() else 1)
