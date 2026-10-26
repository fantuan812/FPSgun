extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.001
func _initialize()->void:call_deferred("run")
func reset(mode:String,items:Dictionary={},weapons:Array=["cryo_sprayer"])->void:
 g._title();g._select_mode(mode);g._start_run(433)
 g.build.items=items.duplicate();g.build.weapons=weapons.duplicate();g.build.revision+=1;g._recompute()
 g.elapsed=10.0;g.spawn_clock=999.0;g.stats.hp=100.0;g.stats.max_hp=100.0;g.combat_frame.area=g.config.arena
 for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999.0
func spawn(pos:Vector2,hp:float=500.0)->Dictionary:
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+pos);e.hp=hp;e.max_hp=hp;e.anim_hp=hp;return e
func group()->Array:
 var out:Array=[]
 for i in range(5):out.append(spawn(Vector2(100+i*10,0)))
 return out
func cone()->void:g._fire_weapon("cryo_sprayer",0)
func rivet(e:Dictionary)->void:
 var b:Dictionary={"hit":[],"damage":15.0*(1.0+g.stats.damage_bonus),"pierce":0,"life":1.0,"weapon":"rivet_gun"};g._hit_segment(b,e.pos,e.pos)
func take_haste()->void:
 g.upgrade_pending=1;g._show_upgrades()
 g.choices=[g.config.upgrades.filter(func(u):return u.id=="haste")[0]]
 g._take_upgrade(0,g.choice_generation)
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  reset(mode,{"power_coil":1});var e:Dictionary=spawn(Vector2(100,0));cone();check(near(e.hp,489.65),mode+" A Power Coil scales Cryo primary");check(near(e.chill_until,11.2),mode+" A damage doesnot scale status")
  reset(mode,{"power_coil":1,"fracture_coil":1},["cryo_sprayer","rivet_gun"]);e=spawn(Vector2(100,0));cone();var before:float=e.hp;rivet(e);check(near(before-e.hp,17.25+16.0),mode+" A powered Rivet plus fixed16 shatter");check(not Status.chilled(e,g.elapsed),mode+" A consume once")
  observations.append({"mode":mode,"case":"A","power_primary":10.35,"observed_shatter":before-e.hp-17.25,"advertised":"+15% all damage"})
  reset(mode,{"cooling_fan":1});e=spawn(Vector2(100,0));g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0);check(near(g.weapon_clocks[0],.65/1.12),mode+" B fan actual scheduledclock");check(near(e.chill_until,11.2),mode+" B fan not chillduration")
  reset(mode);take_haste();e=spawn(Vector2(100,0));g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0);check(g.build.levels.get("haste")==1 and g.state=="playing",mode+" C actual chooser consumed upgrade");check(near(g.weapon_clocks[0],.65/1.15),mode+" C rate15 actual interval");check(not near(g.weapon_clocks[0],.65*.85),mode+" C description interval15 not actual");observations.append({"mode":mode,"case":"C","observed_clock":g.weapon_clocks[0],"wording_expected_clock":.65*.85,"description":g.config.upgrades.filter(func(u):return u.id=="haste")[0].description})
  reset(mode,{"lens":1});e=spawn(Vector2(210,0));var outside:Dictionary=spawn(Vector2(220,0));cone();check(near(e.hp,491) and near(outside.hp,500),mode+" D actual rangeboundary");var visual:Dictionary=g.effect_visuals.filter(func(v):return v.kind=="cryo_cone")[0];check(near(visual.radius,218.5) and near(visual.half_angle,PI/6),mode+" D radiusonly")
  for id in ["capacitor","gear","pellet_pouch"]:
   reset(mode,{id:1});e=spawn(Vector2(100,0));cone();check(near(e.hp,491) and near(e.chill_until,11.2),mode+" E no inappropriate "+id+" scale");check(g.bullets.is_empty() and g.effect_visuals.filter(func(v):return v.kind=="cryo_cone").size()==1,mode+" E no projectile "+id)
  for n in [0,1,5]:
   reset(mode);g.build.levels={"pierce":n};g._recompute();var targets:Array=group();cone();check(targets.all(func(t):return near(t.hp,491)),mode+" F all cone targets once pierce"+str(n));check(g.bullets.is_empty(),mode+" F no bullets pierce"+str(n))
  reset(mode,{"echo_chamber":1});var targets:Array=group();cone();check(targets.slice(0,4).all(func(t):return near(t.hp,491)) and near(targets[4].hp,479),mode+" G fifth target fixed12 echo");check(g.effects.echo_hits==0,mode+" G no recursive hit count")
  reset(mode,{"echo_chamber":1,"power_coil":1});targets=group();cone();check(near(targets[4].hp,477.65),mode+" G PowerCoil leaves Echo12 fixed")
  reset(mode,{"arc_relay":1});targets=group();cone();check(near(targets[0].hp,491) and near(targets[1].hp,487.4) and near(targets[2].hp,487.4) and near(targets[3].hp,491) and near(targets[4].hp,491),mode+" H one chain2 per cone ICD");check(near(g.effects.cooldowns.arc_relay,10.6),mode+" H shared0.6ICD")
  reset(mode,{"arc_relay":1,"power_coil":1});e=spawn(Vector2(100,0));outside=spawn(Vector2(100,100));cone();check(near(outside.hp,495.86) and not Status.chilled(outside,g.elapsed),mode+" H chain40percent poweredprimary nosecondarymark")
  reset(mode,{"blood_valve":1});g.stats.hp=30;targets=group();cone();check(near(g.stats.hp,33),mode+" I multi target onlyoneheal");g.elapsed=10.99;cone();check(near(g.stats.hp,33),mode+" I beforeICD noheal");g.elapsed=11.0;cone();check(near(g.stats.hp,36),mode+" I atICD heal")
  reset(mode,{"blood_valve":1,"fracture_coil":1},["cryo_sprayer","rivet_gun"]);g.stats.hp=30;e=spawn(Vector2(100,0));cone();rivet(e);check(near(g.stats.hp,33),mode+" I shatterno additionalheal")
  reset(mode,{"kill_cell":1});e=spawn(Vector2(100,0),9);cone();Runtime.step(g.combat_frame,0.0);check(g.pickups.filter(func(p):return p.get("source","")=="energy").size()==1,mode+" J Cryoprimarykill energy")
  reset(mode,{"kill_cell":1,"fracture_coil":1},["cryo_sprayer","rivet_gun"]);e=spawn(Vector2(100,0),30);cone();rivet(e);check(e.hp<0 and e.last_source=="fracture",mode+" J fracturedeathattribution");Runtime.step(g.combat_frame,0.0);check(not g.pickups.any(func(p):return p.get("source","")=="energy"),mode+" J secondarykillnoenergy")
  reset(mode,{"phase_capacitor":1});targets=group();g._effect_event("dash",{"pos":g.player_pos,"angle":0.0});check(g.effects.phase_charge==1,mode+" K actualdashstorescharge");cone();check(targets.all(func(t):return near(t.hp,479)) and g.effects.phase_charge==0,mode+" K once12splashalltargets")
  reset(mode,{"dash_resin":1,"pulse_boots":1,"fracture_coil":1},["cryo_sprayer","rivet_gun"]);g._effect_event("dash",{"pos":g.player_pos,"angle":0.0});e=spawn(Vector2(40,0));g.effect_runtime.advance_hazards(.01);check(near(e.hp,492) and near(e.slow_until,10.6),mode+" L actualresinhazard applies oldslow");cone();check(near(Status.movement_factor(e,g.elapsed),.55),mode+" L stronger not multiplied");rivet(e);check(not Status.chilled(e,g.elapsed) and near(e.slow_until,10.6) and near(Status.movement_factor(e,g.elapsed),.55),mode+" L consume keepsresinslow");g.elapsed=10.61;check(near(Status.movement_factor(e,g.elapsed),1.0),mode+" L oldslow expiresindependently")
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"observations":observations,"scope":"frozen finite advertised compatibility matrix; controlled runtime in both modes; not GUI or balance"};print(JSON.stringify(result));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
