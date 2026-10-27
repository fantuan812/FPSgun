extends SceneTree
# Controlled actual runtime paths. Setup mutates state deliberately; never ordinary-play evidence.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
const Boundary=preload("res://scripts/gameplay/boundary_shot.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
var g
var checks:=0
var failures:Array=[]
var hits:Array=[]
var cases:Array=[]
const DAMAGE={"rivet_gun":15.0,"scrap_shotgun":9.0,"rail_lance":30.0,"orbit_saw":20.0,"return_disc":18.0,"shock_mortar":36.0,"cryo_sprayer":9.0,"bankshot_driver":18.0}
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func eq(a:float,b:float,label:String)->void:ck(is_equal_approx(a,b),label+" actual="+str(a)+" expected="+str(b))
func capture(kind:String,data:Dictionary)->bool:
 if kind=="hit":hits.append(data.duplicate(true))
 return g._effect_event(kind,data)
func setup(mode:String,weapon:String="rivet_gun",items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(3201)
 g.build.weapons=[weapon];g.build.items=items.duplicate(true);g._recompute()
 g.elapsed=10;g.spawn_clock=999;g.weapon_clocks=[999.0];g.hurt_clock=0
 g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.combat_frame.area=g.config.arena;g.weapon_combat.effect_event=capture;hits.clear()
func spawn(pos:Vector2,aim:Vector2=Vector2.RIGHT,kind:String="charger")->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,pos)
 e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999;e.warning_left=999
 e.ai_state="warning";e.attack="charge";e.aim=aim
 return e
func shot(id:String,origin:Vector2,velocity:Vector2,damage:float,pierce:int=0)->Dictionary:
 return {"weapon":id,"pos":origin,"velocity":velocity,"life":3.0,"damage":damage,"pierce":pierce,"hit":[],"returning":false,"outbound_left":1.0,"slot":0}
func advance_all(dt:float)->void:
 for b in g.bullets:
  if b.get("behavior","")=="field_bankshot":g.weapon_combat.advance_bankshot(b,dt)
  elif b.weapon=="return_disc":g.weapon_combat.advance_disc(b,dt)
  else:g.weapon_combat.advance_bullet(b,dt)
func step(dt:float)->void:
 g.elapsed+=dt;Runtime.step(g.combat_frame,dt)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for id in DAMAGE:
   for front in [true,false]:
    setup(mode,id)
    var e:Dictionary=spawn(g.player_pos+Vector2(80,0),Vector2.LEFT if front else Vector2.RIGHT)
    var seq:int=g.effect_sequence
    g._fire_weapon(id,0)
    if id=="shock_mortar":
     ck(g.pending_blasts.size()==1,"actual mortar fire schedules once")
     var blast:Dictionary=g.pending_blasts[0]
     var fixed:Vector2=blast.pos
     # Delayed blast remains at original point; offset target while warning is active.
     e.pos=fixed+Vector2(50,0);e.aim=Vector2.LEFT if front else Vector2.RIGHT
     g._update_mortars(.6)
     eq(e.hp,1000.0-36.0*(.5 if front else 1.0),mode+" actual delayed offset mortar "+str(front))
     eq(blast.damage,36,"stored blast nominal unchanged")
     ck(g.pending_blasts.is_empty() and g.effect_sequence==seq+2,"one mortar hit and old mortar event")
    else:
     var nominal:Array=[]
     for b in g.bullets:nominal.append(float(b.damage))
     advance_all(.3)
     var count:int=hits.size()
     ck(count>0,mode+" actual fire/advance hit "+id)
     eq(e.hp,1000.0-float(DAMAGE[id])*(.5 if front else 1.0)*count,mode+" actual fire amount "+id+" front="+str(front))
     for hit in hits:eq(float(hit.damage),float(DAMAGE[id])*(.5 if front else 1.0),"resolved nominal event "+id)
     ck(g.effect_sequence==seq+count,"one original primary event per contact "+id)
     for b in g.bullets:eq(float(b.damage),float(DAMAGE[id]),"stored shot never reduced "+id)
     if id=="scrap_shotgun":ck(g.bullets.size()==5 and count<=5,"five actual distinct pellets, bounded hits")
     if id=="cryo_sprayer":ck(e.get("chill_until",0)==11.2 and e.chill_weapon=="cryo_sprayer","surviving guarded Cryo still marks")
    cases.append({"mode":mode,"weapon":id,"front":front,"remaining_hp":e.hp,"recorded_weapon_hit_events":hits.size()})
    await process_frame
  # Old weapon/stat math precedes one defense factor; no global stat rewrite.
  setup(mode,"rail_lance",{"power_coil":1});var e:Dictionary=spawn(g.player_pos+Vector2(80,0),Vector2.LEFT)
  g._fire_weapon("rail_lance",0);advance_all(.3)
  eq(e.hp,1000-30*1.15*.5,mode+" Power scales first then brace")
  eq(g.bullets[0].damage,34.5,"Power stored nominal34.5")
  # Nonhosts and inactive phases retain their exact old primary amounts.
  for kind in ["crawler","spitter","flanker","brood_keeper","boss_warden","boss_core"]:
   setup(mode,"orbit_saw");e=spawn(g.player_pos+Vector2(60,0),Vector2.LEFT,kind)
   g._fire_weapon("orbit_saw",0);eq(e.hp,980,mode+" no brace on "+kind)
  for state in ["move","charging","recover"]:
   setup(mode,"orbit_saw");e=spawn(g.player_pos+Vector2(60,0),Vector2.LEFT);e.ai_state=state
   g._fire_weapon("orbit_saw",0);eq(e.hp,980,mode+" full in "+state)
  # Rail contacts preserve per-target state, stored30 and deterministic old ordering.
  setup(mode,"rail_lance");var center:Vector2=g.player_pos
  var a:Dictionary=spawn(center+Vector2(20,0),Vector2.RIGHT)
  var b:Dictionary=spawn(center-Vector2(60,0),Vector2.LEFT)
  var rail:Dictionary=shot("rail_lance",center+Vector2(150,0),Vector2(-470,0),30,3)
  g.weapon_combat.hit_segment(rail,rail.pos,center-Vector2(100,0))
  eq(a.hp,985,"first pierced braced15");eq(b.hp,970,"later pierced rear30")
  ck(rail.damage==30 and rail.hit==[a.id,b.id] and hits.size()==2,"pierce state/order not rewritten")
  # Exact entry-circle split versus unsplit, stationary target; no moving-world generalization.
  for rotation in range(8):
   var results:Array=[]
   for split in [false,true]:
    setup(mode);center=g.player_pos;var dir:=Vector2.from_angle(rotation*PI/4)
    e=spawn(center,dir);var projectile:Dictionary=shot("rivet_gun",center+dir*100,-dir*470,15)
    if split:
     var at_entry:Vector2=center+dir*19.2
     g.weapon_combat.hit_segment(projectile,projectile.pos,at_entry)
     g.weapon_combat.hit_segment(projectile,at_entry,center)
    else:g.weapon_combat.hit_segment(projectile,projectile.pos,center)
    results.append({"hp":e.hp,"hits":hits.size(),"damage":hits[0].damage if not hits.is_empty() else -1})
   ck(results[0]==results[1] and results[0].hp==992.5 and results[0].hits==1,mode+" static entry partition r"+str(rotation))
  # Strict-interior and zero segment are explicit exceptions; dt0 bridge remains old behavior.
  setup(mode);center=g.player_pos;e=spawn(center,Vector2.RIGHT)
  var ordinary:Dictionary=shot("rivet_gun",center+Vector2(5,0),Vector2.LEFT*470,15)
  g.weapon_combat.hit_segment(ordinary,ordinary.pos,center);eq(e.hp,985,"inside-origin full")
  setup(mode);center=g.player_pos;e=spawn(center,Vector2.RIGHT)
  ordinary=shot("rivet_gun",center,Vector2.LEFT*470,15);g.weapon_combat.hit_segment(ordinary,center,center)
  eq(e.hp,985,"old zero segment hit full")
  for id in ["rivet_gun","return_disc"]:
   setup(mode,id);center=g.player_pos;e=spawn(center,Vector2.RIGHT)
   ordinary=shot(id,center,Vector2.LEFT*470,DAMAGE[id]);ordinary.launch_start=center+Vector2(50,0)
   if id=="return_disc":g.weapon_combat.advance_disc(ordinary,0)
   else:g.weapon_combat.advance_bullet(ordinary,0)
   eq(e.hp,1000-float(DAMAGE[id])*.5,"nonzero dt0 launch bridge "+id)
   ck(not ordinary.has("launch_start") and hits.size()==1,"launch bridge once "+id)
  # Return direction reverses defense; outbound/return each retain original18.
  setup(mode,"return_disc");center=g.player_pos;e=spawn(center+Vector2(80,0),Vector2.RIGHT)
  var disc:Dictionary=shot("return_disc",center,Vector2.RIGHT*470,18,99)
  disc.outbound_left=200.0/470.0
  g.weapon_combat.advance_disc(disc,200.0/470.0)
  eq(e.hp,982,"outbound enters rear full18")
  g.weapon_combat.advance_disc(disc,140.0/470.0)
  eq(e.hp,973,"return enters front half9")
  ck(disc.returning and disc.damage==18 and hits.size()==2,"current return segment not stored launch aim")
  # Actual Bankshot callbacks use reflected and guided current legs, not player position.
  for guide in [false,true]:
   setup(mode,"bankshot_driver");center=Vector2(100,g.config.arena.height*.5)
   e=spawn(center,Vector2.RIGHT)
   var bank:Dictionary=Boundary.spawn(Vector2(200,center.y),Vector2.LEFT,g.config.arena,18,470,900,0,guide)
   var unchanged:Dictionary=bank.duplicate(true);g.weapon_combat.advance_bankshot(bank,0)
   ck(bank==unchanged and e.hp==1000,"Bankshot dt0 inert")
   g.weapon_combat.advance_bankshot(bank,350.0/470.0)
   eq(e.hp,973,"Bankshot first front9 then reflected rear18 guide="+str(guide))
   ck(bank.reflections==1 and bank.damage==18 and bank.total_hits==2,"Bankshot quota/rearm/damage preserved")
   ck(bank.guided_once==guide,"actual first-bounce guide selection")
  # Mortar center is strict interior even when player is frontal, not a muzzle source.
  setup(mode,"shock_mortar");e=spawn(g.player_pos+Vector2(80,0),Vector2.LEFT)
  g._fire_weapon("shock_mortar",0);g._update_mortars(.6);eq(e.hp,964,"direct-center mortar full36")
  # Same-tick transitions use actual damage-site state, not one frame-wide snapshot.
  for entering in [false,true]:
   setup(mode,"orbit_saw");center=g.player_pos;e=spawn(center+Vector2(60,0),Vector2.LEFT)
   e.ai_state="move" if entering else "warning";e.cooldown_left=0 if entering else 999;e.warning_left=.01
   g.weapon_clocks=[0.0]
   ordinary=shot("rivet_gun",center,Vector2.RIGHT*470,15);g.bullets.append(ordinary)
   step(.2)
   eq(e.hp,972.5 if entering else 975,mode+" actual phase order entering="+str(entering))
   ck(e.ai_state==("warning" if entering else "charging"),"one old AI transition")
   ck(hits.size()==2,"instant and projectile original events")
   if hits.size()==2:
    eq(hits[0].damage,20 if entering else 10,"pre-AI instant amount")
    eq(hits[1].damage,7.5 if entering else 15,"post-AI projectile amount")
  # Fractional overkill remains nominal; primary death/drop path runs once.
  setup(mode,"orbit_saw",{"kill_cell":1});e=spawn(g.player_pos+Vector2(60,0),Vector2.LEFT);e.hp=1;g.weapon_clocks=[0.0]
  step(0);ck(g.kills==1 and g.enemies.is_empty(),"guarded primary kill processed once")
  ck(hits.size()==1 and hits[0].damage==10,"nominal overkill10 not HP1")
  ck(g.pickups.size()==2 and g.pickups.any(func(p):return p.get("source","")=="energy"),"old primary kill-cell plus normal drop")
  step(0);ck(g.kills==1,"no duplicate kill")
  # Fixed procs bypass brace; Arc alone derives from resolved initiating primary.
  setup(mode,"cryo_sprayer",{"fracture_coil":1});center=g.player_pos;e=spawn(center+Vector2(60,0),Vector2.LEFT)
  g._fire_weapon("cryo_sprayer",0);eq(e.hp,995.5,"guarded Cryo4.5")
  ck(e.get("chill_until",0)>g.elapsed,"Cryo mark before subsequent weapon")
  ordinary=shot("rivet_gun",center,Vector2.RIGHT*470,15);g.weapon_combat.hit_segment(ordinary,center,e.pos)
  eq(e.hp,972,"Rivet7.5 plus fixed Fracture16")
  ck(e.last_source=="fracture" and e.get("chill_until",0)<=g.elapsed and hits.size()==2,"one consume no recursive hit")
  setup(mode,"rivet_gun",{"echo_chamber":1});e=spawn(g.player_pos+Vector2(60,0),Vector2.LEFT);g.effects.echo_hits=4
  ordinary=shot("rivet_gun",g.player_pos,Vector2.RIGHT*470,15);g.weapon_combat.hit_segment(ordinary,g.player_pos,e.pos)
  eq(e.hp,980.5,"guarded primary7.5 + fixed Echo12");ck(g.effects.echo_hits==0 and hits.size()==1,"Echo old fifth-hit count once")
  setup(mode,"rivet_gun",{"arc_relay":1});center=g.player_pos;a=spawn(center+Vector2(60,0),Vector2.LEFT);b=spawn(center+Vector2(60,80),Vector2.UP)
  ordinary=shot("rivet_gun",center,Vector2.RIGHT*470,15);g.weapon_combat.hit_segment(ordinary,center,a.pos)
  eq(a.hp,992.5,"Arc initiating guarded7.5");eq(b.hp,997,"Arc derives3 not6 and not re-braced1.5")
  ck(hits.size()==1 and b.last_source=="chain","Arc no recursive primary")
  setup(mode,"rivet_gun",{"phase_capacitor":1});e=spawn(g.player_pos+Vector2(60,0),Vector2.LEFT);g.effects.phase_charge=1
  ordinary=shot("rivet_gun",g.player_pos,Vector2.RIGHT*470,15);g.weapon_combat.hit_segment(ordinary,g.player_pos,e.pos)
  eq(e.hp,980.5,"Phase fixed12 bypass");ck(g.effects.phase_charge==0 and hits.size()==1,"one phase consume")
  setup(mode,"return_disc",{"return_spool":1,"blood_valve":1});center=g.player_pos;e=spawn(center+Vector2(60,0),Vector2.LEFT);g.stats.hp=20
  ordinary=shot("return_disc",center,Vector2.RIGHT*470,18);ordinary.returning=true
  g.weapon_combat.hit_segment(ordinary,center,e.pos)
  eq(e.hp,991,"guarded returning9");eq(g.stats.hp,24,"old return1 plus Blood3 on positive guarded hit")
  # Feedback actual hostile-contact pipeline retains fixed24 and its independent allowance.
  setup(mode,"rivet_gun",{"feedback_diode":1});center=g.player_pos;e=spawn(center+Vector2(100,0),Vector2.LEFT)
  var accepted:bool=Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0)
  if accepted:g._effect_event("dash",{"pos":center,"angle":0.0})
  g.enemy_bullets.append({"owner":e.id,"pos":center+Vector2(5,0),"velocity":Vector2.LEFT*145,"life":1.0,"damage":8.0})
  step(.01);eq(e.hp,976,"fixed Feedback24 bypasses front brace")
  ck(not g.effects.feedback_armed and g.enemy_bullets.is_empty() and g.stats.hp==100,"old contact/dash/one allowance")
  setup(mode);center=g.player_pos;e=spawn(center+Vector2(60,0),Vector2.LEFT)
  g.hazards.append({"kind":"mine","pos":e.pos,"life":5.0,"age":.3,"tick":0.0,"radius":70.0,"slow":false})
  g._update_hazards(0);eq(e.hp,976,"fixed mine24 bypass")
  # A secondary lethal retains old last-source attribution and cannot create a primary kill-cell orb.
  setup(mode,"cryo_sprayer",{"fracture_coil":1,"kill_cell":1});center=g.player_pos;e=spawn(center+Vector2(60,0),Vector2.LEFT);e.hp=20
  g._fire_weapon("cryo_sprayer",0)
  ordinary=shot("rivet_gun",center,Vector2.RIGHT*470,15);g.weapon_combat.hit_segment(ordinary,center,e.pos)
  ck(e.hp<0 and e.last_source=="fracture","fixed secondary lethal source")
  step(0);ck(g.kills==1 and g.pickups.size()==1 and not g.pickups[0].has("source"),"secondary kill normal drop only, no primary orb")
  # Natural warning entry locks aim. Hurt/menus/real push do not retarget or restart it.
  setup(mode,"rivet_gun",{"pulse_boots":1});center=g.player_pos;e=spawn(center+Vector2(80,-20),Vector2.RIGHT)
  e.ai_state="move";e.cooldown_left=0;step(0)
  var locked:Vector2=(center-e.pos).normalized()
  ck(e.ai_state=="warning" and e.attack=="charge" and e.aim.is_equal_approx(locked),"natural locked warning")
  eq(e.warning_left,.65,"existing warning duration");eq(e.cooldown_left,3.2,"existing start cooldown")
  g._sync_telegraphs()
  var braces:Array=g.telegraphs.markers.filter(func(m):return m.kind=="brace")
  var lanes:Array=g.telegraphs.markers.filter(func(m):return m.kind=="line")
  ck(braces.size()==1 and lanes.size()==1,"one additive brace plus old charge lane")
  if not braces.is_empty():
   ck(braces[0].direction.is_equal_approx(locked) and braces[0].pos==e.pos,"cue uses locked2D center")
   eq(braces[0].radius,38.4,"cue radius only38.4")
  if not lanes.is_empty():eq(lanes[0].width,56.4,"old charge collider lane width unchanged")
  var old_pos:Vector2=e.pos
  g._effect_event("dash",{"pos":center,"angle":0.0})
  ck(e.pos!=old_pos and e.aim==locked,"actual Pulse Boots moves center but keeps aim")
  g.actor_anim.trigger(e.id,"hurt");g.actor_anim.advance(.1);g._sync_telegraphs()
  ck(e.ai_state=="warning" and e.warning_left==.65 and g.telegraphs.markers.any(func(m):return m.kind=="brace" and m.pos==e.pos),"hurt overlay retains authority and new center")
  g.actor_anim.advance(.2);ck(g.actor_anim.actors[e.id].reaction=="" and e.aim==locked,"hurt returns to current phase")
  g._on_intent("pause",{});var frozen_warning:float=e.warning_left;var frozen_pos:Vector2=e.pos
  g._process(.5)
  ck(g.state=="paused" and e.warning_left==frozen_warning and e.pos==frozen_pos,"actual paused process freezes actor")
  ck(g.telegraphs.markers.any(func(m):return m.kind=="brace"),"paused cue remains visible")
  g._on_intent("inventory",{});g._process(.5)
  ck(g.state=="inventory" and e.warning_left==frozen_warning and g.telegraphs.markers.any(func(m):return m.kind=="brace"),"inventory freezes cue/timer")
  g._on_intent("close_inventory",{});g._resume();g.player_pos=center-Vector2(100,0)
  e.warning_left=.01;step(.02);g._sync_telegraphs()
  ck(e.ai_state=="charging" and e.aim==locked and not g.telegraphs.markers.any(func(m):return m.kind=="brace"),"actual charge transition opens brace without retarget")
  # Terminal and reset resynchronization cannot resurrect a new live cue from retained actors.
  for terminal in ["won","dead","title"]:
   setup(mode);e=spawn(g.player_pos+Vector2(80,0),Vector2.LEFT);g._sync_telegraphs()
   if terminal=="title":g._title()
   else:g._finish(terminal=="won")
   g._sync_telegraphs();ck(not g.telegraphs.markers.any(func(m):return m.kind=="brace"),"no brace after "+terminal)
  setup(mode);e=spawn(g.player_pos+Vector2(80,0),Vector2.LEFT);e.hp=0;g._sync_telegraphs()
  ck(not g.telegraphs.markers.any(func(m):return m.kind=="brace"),"dead actor cue absent before cleanup")
  step(0);g._sync_telegraphs();ck(not g.telegraphs.markers.any(func(m):return m.kind=="brace"),"removed actor cue absent")
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"cases":cases,"scope":"Controlled real shared hit/AI/proc pipelines, all eight weapons and both modes; no ordinary/native/balance certification"}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"checks":checks,"failures":failures,"cases":cases.size()}));quit(0 if failures.is_empty() else 1)
