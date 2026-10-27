extends SceneTree
# Controlled integration oracle. No native/ordinary play claim.
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
const Effects=preload("res://scripts/effects.gd")
var g
var n:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 n+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={"feedback_diode":1})->void:
 g._title();g._select_mode(mode);g._start_run(826)
 g.build.items=items.duplicate(true);g._recompute();g.player_pos=Vector2(400,300);g.elapsed=10
 g.stats.hp=100;g.stats.max_hp=100;g.hurt_clock=0;g.combat_frame.area=g.config.arena
 for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999
func enemy(kind:String="spitter",offset:Vector2=Vector2(180,0),hp:float=200)->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset)
 e.hp=hp;e.max_hp=hp;e.anim_hp=hp;e.speed=0;e.cooldown_left=999
 return e
func move(dt:float,dir:Vector2=Vector2.ZERO,request:bool=false)->bool:
 var old:Vector2=g.player_pos
 var accepted:bool=Motor.step(g.combat,g.config.arena,dir,request,dt)
 if accepted:g._effect_event("dash",{"pos":old,"angle":dir.angle()})
 g.elapsed+=dt
 Runtime.step(g.combat_frame,dt)
 return accepted
func arm()->void:
 ck(move(0,Vector2.RIGHT,true),"actual accepted dash")
func projectile(id:int,start:Vector2,end:Vector2,dt:float=.01,life:float=1)->void:
 g.enemy_bullets.append({"owner":id,"pos":start,"velocity":(end-start)/dt,"life":life,"damage":17.0})
func contact(id:int)->void:projectile(id,g.player_pos-Vector2(5,0),g.player_pos+Vector2(5,0))
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  # Boundary table independent of author-selected 11.99 case, plus early-life clipping.
  for offset in [-12.01,-12.0,-11.999,0,11.999,12,12.01]:
   setup(mode);var e:Dictionary=enemy();arm()
   projectile(e.id,g.player_pos+Vector2(-20,offset),g.player_pos+Vector2(20,offset));move(.01)
   var hit:bool=absf(offset)<12
   ck(e.hp==(176 if hit else 200),mode+" strict swept radius "+str(offset))
   ck(g.effects.feedback_armed!=hit,mode+" exact allowance "+str(offset))
   ck(g.stats.hp==100,mode+" old dash immunity "+str(offset))
  for life in [0.0,-.01,.001,.005,.01]:
   setup(mode);var e:Dictionary=enemy();arm()
   projectile(e.id,g.player_pos-Vector2(20,0),g.player_pos+Vector2(20,0),.01,life);move(.01)
   var hit:bool=life>=.005
   ck(e.hp==(176 if hit else 200),mode+" life clipping "+str(life))
   ck(g.enemy_bullets.is_empty(),mode+" clipped shot expires "+str(life))
  # Boundary expiration in Motor, not manually forged dash_time.
  for dt in [.159,.16,.161]:
   setup(mode);var e:Dictionary=enemy();arm();contact(e.id);move(dt)
   ck(e.hp==(176 if dt<.16 else 200),mode+" post-motor timing "+str(dt))
   ck(g.stats.hp==(100 if dt<.16 else 83),mode+" unchanged timing damage "+str(dt))
   ck(not g.effects.feedback_armed,mode+" spent or expired "+str(dt))
  setup(mode);var e:Dictionary=enemy()
  ck(not move(0,Vector2.ZERO,true),mode+" directionless request rejected")
  ck(not g.effects.feedback_armed,mode+" rejected request does not arm")
  arm();contact(e.id);move(.01)
  ck(not move(0,Vector2.RIGHT,true),mode+" cooldown request rejected")
  ck(not g.effects.feedback_armed,mode+" cooldown request cannot rearm")
  contact(e.id);move(.01);ck(e.hp==176,mode+" no second feedback")
  move(2.5);ck(move(0,Vector2.RIGHT,true),mode+" cooldown elapsed accepted")
  contact(e.id);move(.01);ck(e.hp==152,mode+" next actual dash feedback")
  # Shot intersects old player position, not post-movement position.
  setup(mode);e=enemy();var old:Vector2=g.player_pos
  projectile(e.id,old-Vector2(4,0),old+Vector2(4,0),.08)
  ck(move(.08,Vector2.RIGHT,true),mode+" moving dash starts")
  ck(e.hp==200 and g.effects.feedback_armed,mode+" no swept previous player path trigger")
  # Reverse storage order, and dead/invalid owners cannot steal the allowance.
  for reverse in [false,true]:
   setup(mode);e=enemy();var other:Dictionary=enemy("spitter",Vector2(-180,0));arm()
   contact(other.id if reverse else e.id);contact(e.id if reverse else other.id)
   contact(-100);var dead:Dictionary=enemy("spitter",Vector2(0,-180));dead.hp=0;dead.last_source="feedback";contact(dead.id)
   move(.01)
   ck(e.hp==(176 if reverse else 200) and other.hp==(200 if reverse else 176),mode+" valid reverse-array winner "+str(reverse))
   ck(g.enemy_bullets.is_empty(),mode+" no orphan projectile after invalid/dead owners")
  # Coincident overlap with dt0 still exactly one and no clock advance.
  setup(mode);e=enemy();arm();g.enemy_bullets.append({"owner":e.id,"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":17.0})
  var elapsed:float=g.elapsed;move(0);ck(e.hp==176 and g.elapsed==elapsed,mode+" zero dt overlap")
  g.enemy_bullets.append({"owner":e.id,"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":17.0});move(0)
  ck(e.hp==176,mode+" zero dt duplicate bounded")
  # Pause / nested inventory / settings preserve window and don't re-arm after consumption.
  setup(mode);e=enemy();arm()
  for modal in ["inventory","settings"]:
   g._on_intent("pause",{});g._on_intent(modal,{})
   var t:float=g.stats.dash_time;var ep:float=g.elapsed;g._process(1)
   ck(g.stats.dash_time==t and g.elapsed==ep and g.effects.feedback_armed,mode+" freeze "+modal)
   g._on_intent("close_"+modal,{});g._on_intent("resume",{})
   ck(g.state=="playing" and g.effects.feedback_armed,mode+" return "+modal)
  contact(e.id);move(.01);g._on_intent("pause",{});g._on_intent("resume",{})
  ck(not g.effects.feedback_armed,mode+" resume does not rearm spent")
  # Primary secondary/proc isolation: use full relevant inventory deliberately beyond legal slot cap only for hook isolation.
  setup(mode,{"feedback_diode":1,"mirror_shell":1,"power_coil":5,"capacitor":4,"gear":4,"echo_chamber":1,"phase_capacitor":1,"arc_relay":1,"blood_valve":1,"fracture_coil":1,"return_spool":1,"kill_cell":1,"scrap_mine":1})
  e=enemy();var nearby:Dictionary=enemy("spitter",Vector2(180,10));g.stats.hp=20;arm();g.effects.echo_hits=4;g.effects.chain_charges=2;e.chill_until=50;e.chill_weapon="cryo_sprayer";e.chill_speed=.65
  var clocks:Dictionary=g.effects.cooldowns.duplicate();contact(e.id);move(.01)
  ck(e.hp==176 and nearby.hp==200,mode+" fixed hit no weapon scaling or chain")
  ck(g.stats.hp==20 and g.effects.shield==1 and not g.effects.shield_spent and g.hurt_clock==0,mode+" immunity shields healing untouched")
  ck(g.effects.echo_hits==4 and g.effects.phase_charge==1 and g.effects.chain_charges==2 and g.effects.cooldowns==clocks,mode+" no primary proc state")
  ck(e.chill_until==50 and g.hazards.is_empty() and g.pickups.is_empty(),mode+" no chill consume or proc drops")
  # Deferred lethal normal reward vs boss reward; same-owner remaining bullets safely cleaned.
  for kind in ["spitter","boss_core","boss_warden"]:
   setup(mode,{"feedback_diode":1,"kill_cell":1,"blood_valve":1,"scrap_mine":1});e=enemy(kind,Vector2(180,0),24);var expected_xp:float=e.xp;g.stats.hp=20;arm()
   contact(e.id);contact(e.id);g.enemy_bullets.append({"owner":e.id,"pos":e.pos,"velocity":Vector2.ZERO,"life":1.0,"damage":17.0})
   move(.01)
   ck(g.kills==1 and g.enemies.is_empty() and g.enemy_bullets.is_empty(),mode+" lethal deferred ownership "+kind)
   ck(g.pickups.size()==1 and g.pickups[0].xp==expected_xp and g.pickups[0].get("source","normal")=="normal",mode+" normal pickup only "+kind)
   ck(g.stats.hp==(minf(g.stats.max_hp,45) if kind=="boss_warden" else 20),mode+" standard boss heal only "+kind)
   ck(g.rewards.size()==(1 if kind.begins_with("boss_") else 0),mode+" standard reward once "+kind)
   move(0);ck(g.kills==1 and g.pickups.size()==1,mode+" no duplicate deferred reward "+kind)
  # Actual Warden blast produces only old immunity result, not feedback.
  setup(mode);e=enemy("boss_warden",Vector2(100,0));e.cooldown_left=0;e.attack_index=1;move(0)
  ck(e.attack=="blast" and e.ai_state=="warning",mode+" actual Warden chose blast")
  move(e.warning_left-.01);arm();move(.02)
  ck(e.hp==200 and g.effects.feedback_armed and g.stats.hp==100 and not g.flashes.is_empty(),mode+" actual blast no counter")
  # Actual AI spitter shot / Core ring emission + Motor dash contact, no manually appended shot.
  for kind in ["spitter","boss_core"]:
   setup(mode);var direction:Vector2=Vector2.RIGHT if kind=="spitter" else -Vector2.from_angle(.13)
   e=enemy(kind,direction*180,200);e.cooldown_left=0;var original_hp:float=e.hp
   var spawned:=false;var started:=false;var max_shots:=0;var saw_warning:=false;var contact_step:=-1
   for step in range(600):
    if e.ai_state=="warning":saw_warning=true
    if not g.enemy_bullets.is_empty():
     spawned=true;max_shots=maxi(max_shots,g.enemy_bullets.size())
     if not started and g.enemy_bullets.any(func(p):return p.pos.distance_to(g.player_pos)<42):
      started=move(.005,direction,true)
     else:move(.005,direction if started and g.stats.dash_time>0 else Vector2.ZERO)
    else:move(.005)
    if e.hp<original_hp:contact_step=step;break
   ck(saw_warning and spawned and max_shots==(1 if kind=="spitter" else 8),mode+" actual AI warning/emission "+kind)
   ck(started and contact_step>=0 and e.hp==original_hp-24 and e.last_source=="feedback",mode+" actual AI timed dash counter "+kind)
   ck(g.stats.hp==100 and not g.effects.feedback_armed,mode+" actual emission no immunity change "+kind)
   observations.append({"mode":mode,"enemy":kind,"emitted":max_shots,"contact_step":contact_step,"owner_hp":e.hp,"player_hp":g.stats.hp})
  for reset in ["title","result","retry","stage"]:
   setup(mode);arm()
   match reset:
    "title":g._title()
    "result":g._finish(false)
    "retry":g._finish(false);g._on_intent("retry",{})
    "stage":g._clear_transients()
   ck(not g.effects.feedback_armed,mode+" lifecycle clear "+reset)
  await process_frame
 # Pure protocol guard edges, independent of scene callback generation.
 var engine=Effects.new();engine.configure(g.catalog);engine.reset({"feedback_diode":1})
 var c:Dictionary={"time":1.0,"enemies":[{"id":7,"hp":100}],"pos":Vector2.ZERO,"dash_active":true}
 var dash:Dictionary={"kind":"dash","epoch":engine.epoch,"sequence":1}
 engine.process(dash,c);ck(engine.feedback_armed,"protocol dash arm")
 var event:Dictionary={"kind":"projectile_contact","source":"hostile_projectile","depth":0,"owner":7,"epoch":engine.epoch,"sequence":2}
 ck(engine.process(event,c).size()==1,"protocol first feedback")
 ck(engine.process(event,c).is_empty() and not engine.feedback_armed,"protocol duplicate contact")
 ck(engine.process(dash,c).is_empty() and not engine.feedback_armed,"protocol duplicate dash cannot rearm")
 engine.invalidate();event.sequence=99;ck(engine.process(event,c).is_empty(),"protocol stale epoch")
 dash.epoch=engine.epoch;dash.sequence=1;engine.process(dash,c)
 for bad in [{"source":"primary","depth":0},{"source":"hostile_projectile","depth":1},{"source":"hostile_projectile","depth":2}]:
  event.epoch=engine.epoch;event.sequence=engine.last_sequence+1;event.source=bad.source;event.depth=bad.depth
  ck(engine.process(event,c).is_empty() and engine.feedback_armed,"protocol wrong source/depth")
 engine.sync({});engine.sync({"feedback_diode":1});ck(not engine.feedback_armed,"protocol removal/rebuy no arm")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result={"checks":n,"failures":failures,"observations":observations,"scope":"Controlled shared-runtime and actual AI/Motor integration; proc isolation profile intentionally exceeds equipment slots; not native ordinary play"}
 var args=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
