extends SceneTree
## Controlled actual primary paths; fixed arithmetic expected independently of tier helpers.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const DAMAGE={"rivet_gun":15.0,"scrap_shotgun":9.0,"rail_lance":30.0,"orbit_saw":20.0,"return_disc":18.0,"shock_mortar":36.0,"cryo_sprayer":9.0,"bankshot_driver":18.0}
var g
var checks:=0
var failures:Array=[]
var hits:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func eq(a:float,b:float,label:String)->void:ck(absf(a-b)<.0001,label+" got="+str(a)+" expected="+str(b))
func capture(kind:String,data:Dictionary)->bool:
 if kind=="hit":hits.append(data.duplicate(true))
 return g._effect_event(kind,data)
func setup(mode:String,id:String,items:Dictionary={},tiers:Variant=[1,0])->void:
 g._title();g._select_mode(mode);g._start_run(3302);g.build.weapons=[id,id];g.build.items=items.duplicate(true)
 if tiers!=null:g.build.weapon_temper=tiers.duplicate(true) if tiers is Array else tiers
 g._recompute();g.elapsed=10;g.spawn_clock=999;g.weapon_clocks=[999.0,999.0];g.hurt_clock=0
 g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.combat_frame.area=g.config.arena;g.weapon_combat.effect_event=capture;hits.clear()
func spawn(pos:Vector2,front:bool=false,kind:String="charger")->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,pos);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0;e.cooldown_left=999;e.warning_left=999;e.ai_state="warning";e.attack="charge";e.aim=Vector2.LEFT if front else Vector2.RIGHT
 return e
func advance(dt:float)->void:
 for b in g.bullets:
  if b.get("behavior","")=="field_bankshot":g.weapon_combat.advance_bankshot(b,dt)
  elif b.weapon=="return_disc":g.weapon_combat.advance_disc(b,dt)
  else:g.weapon_combat.advance_bullet(b,dt)
func step(dt:float)->void:g.elapsed+=dt;Runtime.step(g.combat_frame,dt)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for id in DAMAGE:
   for slot in [0,1]:
    for front in [false,true]:
     setup(mode,id);var e:Dictionary=spawn(g.player_pos+Vector2(80,0),front);var initial_seq:int=g.effect_sequence
     var expected:float=float(DAMAGE[id])*(1.6 if slot==0 else 1.0)
     g._fire_weapon(id,slot)
     if id=="shock_mortar":
      ck(g.pending_blasts.size()==1,"one mortar scheduled");var blast:Dictionary=g.pending_blasts[0];eq(blast.damage,expected,"mortar snapshot")
      e.pos=blast.pos+Vector2(50,0);g._update_mortars(.6)
      eq(e.hp,1000.0-expected*(.5 if front else 1),mode+" actual mortar tier/brace "+str(slot)+str(front));ck(g.effect_sequence==initial_seq+2,"old mortar hit+burst events")
     else:
      for b in g.bullets:eq(b.damage,expected,"actual launch snapshot "+id)
      advance(.3);ck(not hits.is_empty(),"actual primary contacts "+id)
      eq(e.hp,1000.0-expected*(.5 if front else 1)*hits.size(),mode+" actual "+id+" slot"+str(slot)+" front"+str(front))
      for h in hits:ck(h.weapon==id,"same primary identity "+id);eq(h.damage,expected*(.5 if front else 1),"nominal event not double tier")
      ck(g.effect_sequence==initial_seq+hits.size(),"same event count per contact")
      for b in g.bullets:eq(b.damage,expected,"stored nominal not altered by defense")
      if id=="scrap_shotgun":ck(g.bullets.size()==5,"tier changes no pellet count")
     await process_frame
  # Copies use separate timers; tier alone changes no scheduled interval.
  for id in DAMAGE:
   setup(mode,id);var e:Dictionary=spawn(g.player_pos+Vector2(60,0));g.weapon_clocks=[0.0,.2]
   step(.1);eq(g.weapon_clocks[1],.1,"unfired copy exact remaining clock "+id)
   var interval:float={"rivet_gun":.4,"scrap_shotgun":.85,"rail_lance":1.15,"orbit_saw":.65,"return_disc":.9,"shock_mortar":1.5,"cryo_sprayer":.65,"bankshot_driver":.85}[id]
   # Catalog intervals separately pinned by data preservation; direct literal assertion below.
   eq(g.weapon_clocks[0],interval,"unchanged tier cadence "+id)
  # One finite equal-target cadence window is a trade-off, not a universal DPS upgrade.
  for fused in [false,true]:
   setup(mode,"orbit_saw",{},null);var e:Dictionary=spawn(g.player_pos+Vector2(60,0));g.weapon_clocks=[0.0,0.0]
   if fused:
    g._open_shop();ck(g._temper_weapon(0,1,g.shop_generation,"orbit_saw","orbit_saw"),"actual temper before cadence window");g.state="playing"
   step(0);step(.65);step(.65)
   eq(e.hp,904 if fused else 880,"equal 1.30s target window, fused="+str(fused));ck(hits.size()==(3 if fused else 6),"one versus two primary opportunities")
  # Actual launch retains modified nominal after tier/stat edits; no projectile schema lookup.
  for id in ["rivet_gun","scrap_shotgun","rail_lance","return_disc","bankshot_driver","shock_mortar"]:
   setup(mode,id);var e:Dictionary=spawn(g.player_pos+Vector2(80,0));g._fire_weapon(id,0)
   g.build.weapon_temper=[0,0];g.stats.damage_bonus=5.0
   if id=="shock_mortar":
    g._update_mortars(.6);eq(e.hp,1000-57.6,"mortar immutable tier snapshot")
   else:
    advance(.3);ck(not hits.is_empty(),"snapshot contact exists "+id)
    for h in hits:eq(h.damage,float(DAMAGE[id])*1.6,"snapshot not current tier/stats "+id)
  # Direct-fire mismatched/out-of-range owned slot is old STANDARD, not boosted or rejected.
  for pair in [["orbit_saw",0],["cryo_sprayer",-1],["cryo_sprayer",3]]:
   setup(mode,"rivet_gun");var e:Dictionary=spawn(g.player_pos+Vector2(60,0));g._fire_weapon(pair[0],pair[1]);eq(e.hp,1000-float(DAMAGE[pair[0]]),"legacy direct fire standard fallback")
  for bad in [[1.0,0],[true,0],[1],{},"x"]:
   setup(mode,"orbit_saw",{},bad);var e:Dictionary=spawn(g.player_pos+Vector2(60,0));g._fire_weapon("orbit_saw",0);eq(e.hp,980,"malformed tier no boost actual fire")
  # Independent global+tag arithmetic and threshold preview anchors are not helper tautologies.
  setup(mode,"rail_lance",{"power_coil":1});var a:Dictionary=spawn(g.player_pos+Vector2(80,0),true)
  g._fire_weapon("rail_lance",0);advance(.3);eq(a.hp,1000-30*1.15*1.6*.5,"global then tier then brace")
  # Derived Arc uses reduced nominal once, its secondary target does not reapply tier/brace.
  setup(mode,"rivet_gun",{"arc_relay":1});a=spawn(g.player_pos+Vector2(60,0),true);var b:Dictionary=spawn(g.player_pos+Vector2(60,80),true)
  g._fire_weapon("rivet_gun",0);advance(.2);eq(a.hp,988,"tier primary24 front12");eq(b.hp,995.2,"Arc exactly4.8");ck(hits.size()==1 and b.last_source=="chain","Arc secondary no recursive primary")
  # Same ID even at different tiers cannot consume Cryo; other type consumes fixed16.
  setup(mode,"cryo_sprayer",{"fracture_coil":1});a=spawn(g.player_pos+Vector2(60,0),true)
  g._fire_weapon("cryo_sprayer",0);g._fire_weapon("cryo_sprayer",1)
  eq(a.hp,1000-7.2-4.5,"two-tier same Cryo not other type");ck(a.get("chill_until",0)>g.elapsed and a.chill_weapon=="cryo_sprayer","mark remains same ID")
  g.build.weapons.append("orbit_saw");g.build.weapon_temper.append(1);g.weapon_clocks.append(999.0);g._recompute()
  g._fire_weapon("orbit_saw",2);eq(a.hp,1000-7.2-4.5-16-16,"tempered saw16 plus fixed fracture16");ck(a.last_source=="fracture" and a.get("chill_until",0)<=g.elapsed and hits.size()==3,"one fixed nonrecursive consume")
  setup(mode,"orbit_saw",{"echo_chamber":1,"phase_capacitor":1});a=spawn(g.player_pos+Vector2(60,0),true);g.effects.echo_hits=4;g.effects.phase_charge=1
  g._fire_weapon("orbit_saw",0);eq(a.hp,960,"tempered guarded16 +fixed Echo12 +Phase12");ck(hits.size()==1 and g.effects.echo_hits==0 and g.effects.phase_charge==0,"one original primary proc opportunity")
  setup(mode,"rivet_gun",{"feedback_diode":1});a=spawn(g.player_pos+Vector2(100,0),true)
  var dash:bool=Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0)
  if dash:g._effect_event("dash",{"pos":g.player_pos,"angle":0.0})
  g.enemy_bullets=[{"owner":a.id,"pos":g.player_pos+Vector2(5,0),"velocity":Vector2.LEFT*145,"life":1.0,"damage":8.0}];step(.01)
  eq(a.hp,976,"Feedback stays24 with tempered equipment")
  setup(mode,"orbit_saw",{"kill_cell":1});a=spawn(g.player_pos+Vector2(60,0),true);a.hp=1;g.weapon_clocks=[0.0,999.0];step(0)
  ck(hits.size()==1 and hits[0].damage==16 and g.kills==1,"nominal16 overkill/one death");ck(g.pickups.size()==2,"one old energy+normal drop")
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled all-eight actual primary paths, mixed-copy cadence, snapshot, brace, derived/fixed proc and same-ID Cryo checks; no ordinary/balance/Windows claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
