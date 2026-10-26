extends SceneTree
# Controlled actual shared-pipeline oracle. Geometry expectations are constants
# from the frozen contract, not copied from the implementation's helper result.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(2701)
 g.build.items=items.duplicate(true);g._recompute();g.elapsed=10;g.hurt_clock=0
 g.stats.hp=100;g.stats.max_hp=100;g.weapon_clocks=[999.0];g.spawn_clock=999
 g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.combat_frame.area=g.config.arena
func spawn()->Dictionary:
 var e:Dictionary=g._spawn_kind("brood_keeper",Vector2(g.config.arena.width*.5,g.config.arena.height*.5))
 e.speed=0;e.cooldown_left=0;e.hp=1000;e.max_hp=1000;e.anim_hp=1000
 return e
func step(dt:float)->void:
 g.elapsed+=dt;Runtime.step(g.combat_frame,dt)
func start(e:Dictionary)->void:
 step(0)
 ck(e.ai_state=="warning" and e.attack=="annulus" and e.attack_index==1,"natural pulse-first warning")
func release(e:Dictionary)->void:
 e.warning_left=0;step(0)
func echoes()->Array:return g.effect_visuals.filter(func(v):return v.kind=="annulus_impact")
func children(e:Dictionary)->Array:return g.enemies.filter(func(v):return v.get("parent_id",-1)==e.id and v.hp>0)
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for angle in range(8):
   for distance in [0.0,69.99,70.0,70.01,120.0,179.99,180.0,180.01]:
    setup(mode);var e:Dictionary=spawn();start(e)
    g.player_pos=e.pulse_center+Vector2.from_angle(angle*PI/4)*distance
    release(e)
    var hit:bool=distance>=70 and distance<=180
    var label:String=mode+" dir"+str(angle)+" radius"+str(distance)
    ck(g.stats.hp==(89 if hit else 100),label+" exact closed-band HP")
    ck(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7),label+" recovery enters once")
    ck(echoes().size()==1 and g.flashes.is_empty() and g.enemy_bullets.is_empty(),label+" one annulus echo, no filled blast/projectile")
    ck(echoes()[0].inner_radius==70 and echoes()[0].outer_radius==180 and echoes()[0].pos==e.pulse_center,label+" visual bounds match authority")
    g.hurt_clock=0;step(0);ck(g.stats.hp==(89 if hit else 100) and echoes().size()==1,label+" no repeated zero-delta release")
   await process_frame
  # Warning span, recovery and cooldown are combat time, not animation frames.
  setup(mode);var e:Dictionary=spawn();g.player_pos=e.pos+Vector2(120,0);start(e)
  ck(e.warning_left==1 and e.warning_span==1 and e.cooldown_left==6,mode+" full warning/start cooldown")
  step(.4);ck(g.stats.hp==100 and is_equal_approx(e.warning_left,.6),mode+" warning harmless")
  ck(is_equal_approx(g.actor_anim.actors[e.id].phase_progress,.4),mode+" pose normalized to 1 second")
  step(.6);ck(g.stats.hp==89 and e.ai_state=="recover" and is_equal_approx(e.cooldown_left,5),mode+" release at total1")
  step(.7);ck(e.ai_state=="move" and e.attack_index==1,mode+" recovery does not start next attack")
  step(4.3);ck(e.ai_state=="warning" and e.attack=="summon" and e.attack_index==2 and e.warning_left==.65,mode+" next start at6 seconds is summon")
  step(.65);ck(children(e).size()==1 and e.ai_state=="recover",mode+" real existing summon event")
  e.recover_left=0;step(0);e.cooldown_left=0;step(0)
  ck(e.attack=="annulus" and e.attack_index==3 and e.warning_left==1,mode+" third attack returns pulse")
  # Coarse ticks never consume future recovery or replay an attack.
  setup(mode);e=spawn();g.player_pos=e.pos+Vector2(120,0);e.cooldown_left=.8
  step(20);ck(e.ai_state=="warning" and e.warning_left==1 and g.stats.hp==100,mode+" coarse start does not bypass warning")
  step(20);ck(e.ai_state=="recover" and e.recover_left==.7 and g.stats.hp==89 and echoes().size()==1,mode+" coarse release emits once")
  step(20);ck(e.ai_state=="move" and e.attack_index==1,mode+" coarse recovery has no catch-up")
  step(0);ck(e.attack=="summon" and e.attack_index==2,mode+" expired zero-delta start exactly once")
  # Clamp at entry, then real Pulse Boots displacement cannot drag the mark.
  setup(mode,{"pulse_boots":1});e=spawn();e.pos=Vector2(-100,-100);g.player_pos=Vector2(80,20);start(e)
  ck(e.pulse_center==Vector2(20,20),mode+" locks after actual field clamp")
  setup(mode,{"pulse_boots":1});e=spawn();g.player_pos=e.pos+Vector2(100,0);start(e)
  var locked:Vector2=e.pulse_center
  g._effect_event("dash",{"pos":g.player_pos,"angle":0.0});ck(e.pos!=locked,mode+" actual Boots command displaces owner")
  step(.1);g._sync_telegraphs()
  var markers:Array=g.telegraphs.markers.filter(func(v):return v.kind=="annulus")
  ck(e.pos!=locked and e.pulse_center==locked and markers.size()==1 and markers[0].pos==locked,mode+" displaced mark stays fixed")
  g.player_pos=locked+Vector2(120,0);release(e);ck(g.stats.hp==89 and echoes()[0].pos==locked,mode+" release uses locked not displaced center")
  # Only endpoint position matters; passing through the band does not leave damage.
  for endpoint in [Vector2.ZERO,Vector2(200,0)]:
   setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);step(.5);g.player_pos=e.pulse_center+endpoint;step(.5)
   ck(g.stats.hp==100,mode+" release-only safe endpoint "+str(endpoint))
  # Existing dash window and Feedback allowance; actual Motor requests, not forged window.
  for left in [.159,.16,.161]:
   setup(mode,{"feedback_diode":1});e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0)
   var origin:Vector2=g.player_pos;var accepted:bool=Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0)
   if accepted:g._effect_event("dash",{"pos":origin,"angle":0.0})
   ck(accepted and g.effects.feedback_armed,mode+" real dash arms existing Diode")
   Motor.step(g.combat,g.config.arena,Vector2.ZERO,false,left);e.warning_left=0;step(0)
   ck(g.stats.hp==(100 if left<.16 else 89),mode+" exact post-Motor dash boundary "+str(left))
   ck(g.effects.feedback_armed==(left<.16) and e.hp==1000,mode+" annulus never consumes/returns Feedback "+str(left))
  setup(mode,{"mirror_shell":1});e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);release(e)
  ck(g.stats.hp==100 and g.effects.shield_spent and e.hp==1000 and is_equal_approx(g.hurt_clock,.25),mode+" Mirror blocks without lone-shell retaliation")
  setup(mode,{"mirror_shell":1,"thorn_crown":1});e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);release(e)
  ck(g.stats.hp==100 and g.effects.shield_spent and e.hp==982 and e.last_source=="thorns",mode+" existing Mirror/Thorns pair retaliates on block")
  setup(mode,{"thorn_crown":1});e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);release(e)
  ck(g.stats.hp==89 and e.hp==982 and e.last_source=="thorns",mode+" existing Thorns from actual HP loss")
  setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);g.hurt_clock=.1;release(e)
  ck(g.stats.hp==100 and g.hurt_clock==.1,mode+" existing hurt cooldown blocks")
  # Dead prior to AI release cancels; removal has no detached scheduled job.
  setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);e.warning_left=0;e.hp=0;step(0)
  ck(g.stats.hp==100 and echoes().is_empty() and g.kills==1 and g.enemies.is_empty(),mode+" prior owner death cancels exactly once")
  # Pause/nested modals preserve warning and index; actual title clears transients.
  for modal in ["inventory","settings"]:
   setup(mode);e=spawn();start(e);step(.4)
   g._on_intent("pause",{});g._on_intent(modal,{});var remaining:float=e.warning_left;var t:float=g.elapsed
   g._process(2);ck(e.warning_left==remaining and g.elapsed==t and e.attack_index==1,mode+" modal freeze "+modal)
   g._on_intent("close_"+modal,{});g._on_intent("resume",{});ck(g.state=="playing",mode+" modal resumes "+modal)
   g._title();g._sync_telegraphs();ck(echoes().is_empty() and g.telegraphs.markers.is_empty(),mode+" title clears warning "+modal)
  setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);release(e);g._title();g._sync_telegraphs()
  ck(echoes().is_empty() and g.telegraphs.markers.is_empty(),mode+" title clears impact")
  setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0);release(e);step(.2)
  ck(echoes().is_empty(),mode+" echo expires at0.2 combat seconds")
  setup(mode);e=spawn();start(e);g.player_pos=e.pulse_center+Vector2(120,0)
  var shooter:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(240,0));shooter.speed=0;shooter.cooldown_left=999
  g.enemy_bullets.append({"owner":shooter.id,"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":150.0})
  step(0);g._sync_telegraphs()
  ck(g.state=="dead" and g.stats.hp==0,mode+" actual hostile shot enters terminal state")
  ck(echoes().is_empty() and g.telegraphs.markers.filter(func(v):return v.kind=="annulus").is_empty(),mode+" terminal death cannot regenerate pending annulus warning")
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"controlled actual shared runtime, exact annulus geometry/timing/hurt/lock/lifecycle; not ordinary native or full campaign proof"}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
