extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float,tolerance:float=.001)->bool:return absf(a-b)<tolerance
func fresh(mode:String,weapons:Array=["bankshot_driver"],items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(27423)
 g.build.weapons=weapons.duplicate();g.build.items=items.duplicate();g.build.coins=1000;g.build.revision+=1;g._recompute()
 g.player_pos=Vector2(g.config.arena.width*.7,g.config.arena.height*.5);g.elapsed=10.0;g.spawn_clock=999
 g.stats.max_hp=100;g.stats.hp=20;g.combat_frame.area=g.config.arena
 for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999.0
func foe(offset:Vector2,hp:float=100)->Dictionary:
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+offset);e.hp=hp;e.max_hp=hp;e.anim_hp=hp;e.speed=0;e.cooldown_left=999;return e
func fire(slot:int=0)->Dictionary:
 var count:int=g.bullets.size();g._fire_weapon("bankshot_driver",slot)
 if g.bullets.size()!=count+1:
  check(false,"actual fire produced no shot");return {}
 return g.bullets[-1]
func advance(b:Dictionary,dt:float=.35)->void:g.weapon_combat.advance_bankshot(b,dt)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for slot in range(4):
   for left in [false,true]:
    fresh(mode,["bankshot_driver","bankshot_driver","bankshot_driver","bankshot_driver"]);foe(Vector2.ZERO);g.hero.flip_h=left
    var b:Dictionary=fire(slot);var pose:Dictionary=g.weapon_rig.last_shot.pose
    check(near(b.dx,1,.000001) and near(b.dy,0,.000001),mode+" coincident exact RIGHT slot"+str(slot)+" initialLeft"+str(left))
    check(pose.direction.distance_to(Vector2.RIGHT)<.000001,mode+" coincident mount and shot share exact direction slot"+str(slot)+" initialLeft"+str(left))
    observations.append({"mode":mode,"slot":slot,"initial_left":left,"dx":b.dx,"dy":b.dy,"mount_direction":str(pose.direction)})
  fresh(mode);var e:Dictionary=foe(Vector2(-90,0));var rng:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
  var b:Dictionary=fire();advance(b)
  check(e.hp==82 and e.last_source=="primary",mode+" actual fire and primary damage route")
  check(b.field_width==g.config.arena.width and b.field_height==g.config.arena.height,mode+" actual current field dimensions")
  check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rng,mode+" firing and contact draw no RNG")
  fresh(mode,["bankshot_driver"],{"power_coil":1,"cooling_fan":1,"lens":1,"pellet_pouch":1,"capacitor":1,"gear":1});e=foe(Vector2(-90,0));b=fire()
  check(near(b.damage,20.7) and g.bullets.size()==1,mode+" weapon damage applies; no pellet/electric/melee effect")
  check(near(b.launch_budget,900*(1+g.stats.range_bonus)) and near(b.launch_life,b.launch_budget/b.speed),mode+" range once and TTL snapshot")
  g.bullets.clear();g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0)
  check(near(g.weapon_clocks[0],.85/(1+g.stats.haste)),mode+" actual shared additive attack-rate clock")
  fresh(mode,["cryo_sprayer","bankshot_driver"],{"fracture_coil":1});e=foe(Vector2(-90,0),100)
  g._fire_weapon("cryo_sprayer",0);check(e.hp==91 and e.has("chill_until"),mode+" actual Cryo marks before projectile")
  b=fire(1);advance(b)
  check(e.hp==57 and e.last_source=="fracture" and not e.has("chill_until"),mode+" actual Bankshot18 then fixed Fracture16")
  check(g.bullets.size()==1 and b.total_hits==1,mode+" fracture creates no recursive bullet/contact")
  fresh(mode,["bankshot_driver"],{"echo_chamber":1});g.stats.pierce=5
  var targets:Array=[]
  for i in range(6):targets.append(foe(Vector2(-90-i*35,0)))
  b=fire();var unit:Vector2=b.velocity.normalized()
  for i in range(6):targets[i].pos=b.pos+unit*(40+i*32)
  advance(b,.6)
  check(b.total_hits==6 and g.effects.echo_hits==1,mode+" six actual primary contacts count once each for Echo")
  for i in range(6):check(near(targets[i].hp,70 if i==4 else 82),mode+" fixed Echo only fifth actual contact "+str(i))
  check(g.bullets.size()==1,mode+" Echo does not spawn ricochets")
  fresh(mode,["bankshot_driver"],{"arc_relay":1,"blood_valve":1});e=foe(Vector2(-90,0));var side1:Dictionary=foe(Vector2(-90,45));var side2:Dictionary=foe(Vector2(-90,-70));var far_side:Dictionary=foe(Vector2(-90,120))
  b=fire();advance(b)
  check(near(side1.hp,92.8) and near(side2.hp,92.8) and far_side.hp==100,mode+" existing Arc40% exactly two off-path targets")
  check(g.stats.hp==23 and g.bullets.size()==1,mode+" Valve heals three and secondary no recursive shot")
  b=fire();advance(b)
  check(near(side1.hp,92.8) and g.stats.hp==23,mode+" repeated primary respects Arc and Valve global cooldowns")
  g.elapsed=10.6;b=fire();advance(b)
  check(near(side1.hp,85.6) and g.stats.hp==23,mode+" Arc ready at .6, Valve not until1")
  g.elapsed=11.0;b=fire();advance(b)
  check(g.stats.hp==26 and near(side1.hp,85.6),mode+" Valve ready at1, Arc still cooling")
  fresh(mode,["bankshot_driver"],{"kill_cell":1});e=foe(Vector2(-90,0),18);b=fire();advance(b);Runtime.step(g.combat_frame,0)
  check(g.kills==1 and g.pickups.any(func(p):return p.get("source","")=="energy"),mode+" actual primary lethal retains Kill Cell ownership")
  fresh(mode,["cryo_sprayer","bankshot_driver"],{"kill_cell":1,"fracture_coil":1});e=foe(Vector2(-90,0),40);g._fire_weapon("cryo_sprayer",0);b=fire(1);advance(b);Runtime.step(g.combat_frame,0)
  check(g.kills==1 and not g.pickups.any(func(p):return p.get("source","")=="energy"),mode+" actual Fracture lethal excluded from primary Kill Cell")
  fresh(mode,["bankshot_driver","rivet_gun"],{"bounce_guide":1,"power_coil":1});foe(Vector2(-90,0));b=fire();g._fire_weapon("rivet_gun",1)
  var snapshot:Dictionary=b.duplicate(true)
  g.build.weapons=["rivet_gun"];g.build.items={};g._recompute()
  check(g.bullets.size()==1 and g.bullets[0]==snapshot,mode+" loadout edit keeps Bankshot snapshot but clears old projectile")
  g._on_intent("pause",{});g._process(10.0);check(g.bullets[0]==snapshot,mode+" pause keeps full projectile state")
  g._on_intent("resume",{});g._title();check(g.bullets.is_empty(),mode+" title cleanup clears even snapshotted shot")
  fresh(mode,["bankshot_driver"]);foe(Vector2(-90,0));b=fire();g.build.items={"bounce_guide":1};g._recompute();var next:Dictionary=fire()
  check(not b.guide and next.guide,mode+" adding Guide changes only future launches")
  g.build.items={};g._recompute();var after:Dictionary=fire();check(next.guide and not after.guide,mode+" selling Guide does not rewrite existing launch")
  if mode=="rooms":g._begin_room_clear()
  else:g.enemies.clear();g.wave_time=31;g._complete_wave()
  check(g.bullets.is_empty(),mode+" actual settlement/room-clear cleanup removes shots")
  fresh(mode);g.build.weapons=["rivet_gun"];g._recompute();foe(Vector2(-90,0));g._fire_weapon("rivet_gun",0);check(not g.bullets.is_empty(),mode+" old cleanup probe non-vacuous")
  g.build.weapons=["rail_lance"];g._recompute();check(g.bullets.is_empty(),mode+" no Bankshot old loadout cleanup unchanged")
  await process_frame
 g._title();g.queue_free();await process_frame
 var report={"checks":checks,"failures":failures,"observations":observations,"scope":"controlled actual weapon firing, shared proc/clock/cleanup pipeline; no injected helper projectile or fabricated hit event; not ordinary play or GUI"}
 var args=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
