extends SceneTree
## External native observer: actual main/CombatRuntime, controlled inputs, not ordinary play.
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
var image_dir:String=""
var current_case:String=""
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(current_case+" / "+label)
func near(a:float,b:float)->bool:return absf(a-b)<.00001
func authority()->Dictionary:
 var enemies:Array=[]
 for e in g.enemies:enemies.append({"id":e.id,"pos":e.pos,"hp":e.hp,"state":e.ai_state})
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"enemies":enemies,"beams":g.combat.pulse_beams.duplicate(true),"waves":g.combat.seismic_waves.duplicate(true),"elapsed":g.elapsed,"clocks":g.weapon_clocks.duplicate(),"epoch":g.combat.new_weapon_epoch,"recoil":g.effects.recoil_cooldown.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state]}
func record(phase:String,held:Dictionary={})->void:
 var before:Dictionary=authority()
 # Production presentation seams only; no _process(0), which would simulate another tick.
 g.hero.position=g.player_pos.round()
 for e in g.enemies:e.sprite.position=e.pos.round()
 g.camera.position=FieldLayout.camera_position(g.player_pos,g.config.arena)
 g._sync_weapon_rig();g._update_hud();g._sync_telegraphs();g.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 var im:Image=root.get_texture().get_image();var name:String=current_case+"_"+phase+".png"
 ck(im.save_png(image_dir.path_join(name))==OK,"snapshot saved "+phase)
 ck(var_to_bytes(authority())==var_to_bytes(before),"presentation read-only "+phase)
 observations.append({"case":current_case,"phase":phase,"image":name,"os_size":str(DisplayServer.window_get_size()),"root_size":str(root.size),"logical_rect":str(root.get_visible_rect()),"image_size":str(im.get_size()),"authority":before,"held_entity":held.duplicate(true),"hud":g.ui.hud_action.text})
func setup(mode:String,weapon:String,items:Dictionary)->void:
 g._title();g._select_mode(mode)
 ck(g._start_run(39003),"actual main start")
 g.build.weapons=[weapon];g.build.weapon_temper=[0];g.build.items=items.duplicate(true);g._recompute()
 g.elapsed=10.0;g.spawn_clock=999.0;g.weapon_clocks.fill(999.0);g.player_pos=Vector2(400,300);g.stats.hp=100.0;g.stats.max_hp=100.0;g.stats.dash_time=0.0;g.hurt_clock=0.0;g.combat_frame.area=g.config.arena
 ck(g.state=="playing" and g.combat.pulse_beams.is_empty() and g.combat.seismic_waves.is_empty(),"clean actual controlled setup")
func spawn(kind:String,pos:Vector2,hp:float=100.0)->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,pos);e.speed=0.0;e.damage=0.0;e.hp=hp;e.max_hp=hp;e.anim_hp=hp;return e
func step(dt:float)->void:
 g.elapsed+=dt;Combat.step(g.combat_frame,dt)
func launch()->void:
 g.weapon_clocks[0]=0.0;step(.001);g.weapon_clocks[0]=999.0
func _initialize()->void:call_deferred("run")
func run()->void:
 if DisplayServer.get_name()=="headless":push_error("native observer rejects headless");quit(2);return
 var args=OS.get_cmdline_user_args()
 if args.size()!=1 or not DirAccess.dir_exists_absolute(args[0]):push_error("existing output image directory required");quit(2);return
 image_dir=args[0];g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for row in [{"mode":"arena","size":Vector2i(960,540)},{"mode":"rooms","size":Vector2i(1280,720)}]:
  root.size=row.size;await process_frame;await process_frame
  var mode:String=row.mode
  current_case=mode+"_memory_reacquire";setup(mode,"tether_emitter",{"lock_memory":1})
  var target:Dictionary=spawn("crawler",Vector2(500,300));launch()
  ck(g.combat.pulse_beams.size()==1,"real launch creates one beam")
  if g.combat.pulse_beams.is_empty():break
  var beam:Dictionary=g.combat.pulse_beams[0]
  await record("launch",beam)
  step(.3);ck(near(target.hp,90.0) and beam.pulse_index==1,"first real 10 damage pulse")
  await record("pulse1",beam)
  target.pos=Vector2(681,300);step(.1)
  ck(near(target.hp,90.0) and near(beam.active_age,.3) and near(beam.grace_left,.1) and beam.was_outside,"observed loss pauses active age and spends grace")
  await record("outside",beam)
  target.pos=Vector2(500,300);step(.3)
  ck(near(target.hp,80.0) and beam.pulse_index==2 and near(beam.active_age,.6) and not beam.was_outside,"same-target recovery resumes real pulse schedule")
  await record("recovered",beam)
  target.pos=Vector2(681,300);step(.01)
  ck(g.combat.pulse_beams.is_empty() and near(target.hp,80.0),"second range loss cancels, no second grace")
  await record("second_loss",beam)

  current_case=mode+"_memory_hardlife";setup(mode,"tether_emitter",{"lock_memory":1})
  target=spawn("crawler",Vector2(500,300));launch()
  ck(g.combat.pulse_beams.size()==1,"real launch for hardlife")
  if g.combat.pulse_beams.is_empty():break
  beam=g.combat.pulse_beams[0];await record("launch",beam)
  step(.9);ck(beam.pulse_index==3 and near(target.hp,70.0),"three actual pulses before grace")
  await record("pulse3",beam)
  target.pos=Vector2(681,300);step(.2)
  ck(g.combat.pulse_beams.size()==1 and near(beam.wall_age,1.1) and near(beam.grace_left,0.0) and near(target.hp,70.0),"inclusive zero grace retained without outside damage")
  await record("grace_zero",beam)
  target.pos=Vector2(500,300);step(.4)
  ck(g.combat.pulse_beams.is_empty() and near(beam.wall_age,1.4) and near(beam.active_age,1.2) and beam.pulse_index==4 and near(target.hp,60.0),"hardlife clips oversized step before fourth endpoint/removal")
  await record("hardclip",beam)
  step(.1);ck(near(target.hp,60.0) and g.combat.pulse_beams.is_empty(),"no fifth or post-hardlife damage")

  current_case=mode+"_drum_collar";setup(mode,"seismic_drum",{"return_collar":1})
  target=spawn("crawler",Vector2(500,300));launch()
  ck(g.combat.seismic_waves.size()==1 and near(target.hp,100.0),"real outward wave born without filled-blast hit")
  if g.combat.seismic_waves.is_empty():break
  var wave:Dictionary=g.combat.seismic_waves[0];await record("launch",wave)
  step(.3);ck(near(target.hp,78.0) and wave.hit_out.size()==1 and wave.hit_in.is_empty(),"outward real22 once")
  await record("outward",wave)
  step(.3);ck(wave.outward_done and near(wave.age,.6) and near(target.hp,78.0),"turnaround no repeat outward or premature inner hit")
  await record("turnaround",wave)
  step(.225);ck(near(target.hp,67.0) and wave.hit_in.size()==1,"real inward half11 once")
  await record("inward",wave)
  step(.225);ck(g.combat.seismic_waves.is_empty() and near(target.hp,67.0),"wave finishes without third hit")
  await record("finished",wave)

  current_case=mode+"_recoil";setup(mode,"tether_emitter",{"recoil_plate":1})
  target=spawn("crawler",Vector2(480,300));var far:Dictionary=spawn("crawler",Vector2(501,300));var boss:Dictionary=spawn("boss_warden",Vector2(470,300))
  g.effect_runtime.recoil_area=g.config.arena
  await record("before")
  g._hurt(1.0)
  ck(near(g.stats.hp,99.0) and target.pos==Vector2(535,300),"true surviving HP loss pushes55")
  ck(far.pos==Vector2(501,300) and boss.pos==Vector2(470,300),"outside radius and boss unchanged")
  ck(near(target.hp,100.0) and near(g.effects.recoil_cooldown.ready_at,12.0),"no enemy damage; real simulation cooldown")
  await record("push")
  target.pos=Vector2(480,300);g.elapsed=11.0;g.hurt_clock=0.0;g._hurt(1.0)
  ck(target.pos==Vector2(480,300) and near(g.effects.recoil_cooldown.ready_at,12.0),"cooldown rejects second push")
  await record("cooldown")
  g.elapsed=12.0;g.hurt_clock=0.0;g._hurt(1.0)
  ck(target.pos==Vector2(535,300) and boss.pos==Vector2(470,300) and near(g.effects.recoil_cooldown.ready_at,14.0),"exact expiry pushes again, boss still immune")
  await record("ready_again")
 g._title();var helper=load("<WORKSPACE>/moss-v39-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"scope":"Eight controlled native mechanism cases; actual launches and main/CombatRuntime damage. Logical960 at both OS sizes; no natural acquisition, ordinaryplay, hardware input or Windows claim."}))
 quit(0 if failures.is_empty() else 1)
