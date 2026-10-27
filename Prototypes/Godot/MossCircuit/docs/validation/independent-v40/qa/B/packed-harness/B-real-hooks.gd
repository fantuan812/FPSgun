extends SceneTree
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.00001
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary)->void:
 g._title();g._select_mode(mode);g._start_run(39081);g.set_process(false)
 g.build.weapons=["rivet_gun","rail_lance"];g.build.weapon_temper=[0,0];g.build.items=items.duplicate(true);g._recompute()
 g.enemies.clear();g.bullets.clear();g.pickups.clear();g.hazards.clear();g.player_pos=Vector2(400,300);g.weapon_clocks=[999.0,999.0];g.spawn_clock=999.0;g.combat_frame.area=g.config.arena
func begin()->void:
 g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
func target(pos:Vector2)->Dictionary:
 var e:Dictionary=g._spawn_kind("crawler",pos);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0.0;e.damage=0.0;return e
func hit(e:Dictionary,weapon:String,source:String="primary")->void:
 g._effect_event("hit",{"target":e.id,"pos":e.pos,"weapon":weapon,"source":source,"depth":0,"damage":0.0})
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode,{"crossfire_pin":1});begin();var e:Dictionary=target(Vector2(500,300));var random_before=g.rng.state
  hit(e,"rivet_gun");ck(g.effect_runtime.build_items.mark.position==Vector2(500,300),mode+" zero primary actual mark")
  e.pos=Vector2(560,300);hit(e,"rivet_gun");ck(e.pos==Vector2(560,300),mode+" same weapon no pull")
  hit(e,"rail_lance","chain");ck(e.pos==Vector2(560,300),mode+" secondary no pull")
  hit(e,"rail_lance");ck(e.pos==Vector2(515,300) and e.hp==1000.0,mode+" actual45 control no damage")
  ck(g.effect_runtime.build_items.mark==null and near(g.effect_runtime.build_items.pin_ready_at,1.0),mode+" consumed mark/current-clock CD")
  ck(g.rng.state==random_before,mode+" actual Pin no RNG")
  var live:Dictionary=g.effect_runtime.build_items.debug_snapshot();var build:Dictionary=g.build.duplicate(true);var clocks:Array=g.weapon_clocks.duplicate();var rngs=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
  Forecast.project(g.config.player,g.build,g.catalog,"medic_winch")
  ck(g.effect_runtime.build_items.debug_snapshot()==live and g.build==build and g.weapon_clocks==clocks and [g.rng.state,g.loot_rng.state,g.shop_rng.state]==rngs,mode+" real forecast whole-live detached")
  g.state="shop";g.build.coins=100.0
  ck(g._sell_item("crossfire_pin",g.shop_generation) and g.build.coins==114.0,mode+" actual Pin sale refund14")
  ck(near(g.effect_runtime.build_items.pin_ready_at,1.0),mode+" sale preserves cooldown")
  g.shop_offers=[{"id":"crossfire_pin","sold":false}]
  ck(g._buy(0,g.shop_generation) and g.build.coins==86.0,mode+" actual Pin rebuy28")
  ck(near(g.effect_runtime.build_items.pin_ready_at,1.0),mode+" actual rebuy cannot refresh cooldown")
  g.shop_offers=[{"id":"crossfire_pin","sold":false}];live=g.effect_runtime.build_items.debug_snapshot();build=g.build.duplicate(true)
  ck(not g._buy(0,g.shop_generation) and g.build==build and g.effect_runtime.build_items.debug_snapshot()==live,mode+" actual duplicate rejection atomic")
  setup(mode,{"salvage_capacitor":1,"medic_winch":1});g.stats.hp=50.0
  g.pickups=[{"pos":Vector2(560,300),"xp":0,"coins":0,"heal":8.0,"source":"medical"},{"pos":Vector2(240,300),"xp":0,"coins":0,"heal":8.0,"source":"medical"}]
  for i in range(5):g.pickups.append({"pos":g.player_pos,"xp":1,"coins":1})
  var coins:float=g.build.coins;var xp:int=g.xp;Combat.step(g.combat_frame,0.0)
  ck(g.build.coins==coins+5 and g.xp==xp+5,mode+" five real normal rewards once")
  ck(g.effect_runtime.build_items.charges==3 and g.effect_runtime.build_items.winch_count==0,mode+" cap3 threshold remainder0")
  ck(g.pickups.size()==2 and g.pickups[0].pos==Vector2(480,300) and g.pickups[1].pos==Vector2(240,300),mode+" deferred stable tie first only80")
  ck(g.stats.hp==50.0,mode+" no same-pass collection or invented heal")
  g.player_pos=Vector2(480,300);Combat.step(g.combat_frame,0.0)
  ck(g.pickups.size()==1 and g.pickups[0].pos==Vector2(240,300) and g.stats.hp==58.0,mode+" later real pass normal medicine heal8")
  ck(g.effect_runtime.build_items.charges==3 and g.effect_runtime.build_items.winch_count==0,mode+" medicine not normal pickup quota")
  g.player_pos=Vector2(400,300);var origin:Vector2=g.player_pos;g.elapsed=.1
  ck(Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,.01),mode+" real Motor dash start")
  g._effect_event("dash",{"pos":origin,"angle":0.0})
  ck(g.player_pos!=origin and g.effect_runtime.build_items.fields.size()==1 and g.effect_runtime.build_items.fields[0].pos==origin,mode+" saved origin not post-move position")
  ck(g.effect_runtime.build_items.charges==0 and near(g.effect_runtime.build_items.fields[0].expires,1.9),mode+" field actual TTL and spend3")
  g.player_pos=Vector2(400,300);e=target(Vector2(460,300));e.speed=100.0;g.elapsed=.2;Combat.step(g.combat_frame,.1)
  ck(e.pos.distance_to(Vector2(453,300))<.0001 and e.speed==100.0,mode+" actual AI70 percent and base speed restored")
  e.slow_until=1.0;g.elapsed=.3;Combat.step(g.combat_frame,.1)
  ck(e.pos.distance_to(Vector2(447.5,300))<.0001,mode+" existing55 percent min not product")
  setup(mode,{"medic_winch":1});begin()
  for i in range(5):g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
  ck(g.effect_runtime.build_items.pending!=null,mode+" pending created by actual trusted ingress")
  g.state="paused";g._present_pause();ck(g.effect_runtime.build_items.pending==null,mode+" actual pause cancels pending")
  live=g.effect_runtime.build_items.debug_snapshot();var old_time:float=g.elapsed;g._simulate(.5)
  ck(g.effect_runtime.build_items.debug_snapshot()==live and g.elapsed==old_time,mode+" paused simulation no clock or state change")
  setup(mode,{"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1});begin();e=target(Vector2(500,300));hit(e,"rivet_gun");e.pos=Vector2(560,300);hit(e,"rail_lance")
  g._effect_event("pickup",{"source":"normal","pos":g.player_pos});var seq:int=g.effect_sequence;coins=g.build.coins
  g.enemies.clear();g.pickups=[{"pos":Vector2(700,300),"xp":1,"coins":2}];g.boss_defeated=true
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=float(g.mode.profile.clear_delay)
  g._complete_wave()
  ck(g.effect_sequence==seq and g.pickups.is_empty(),mode+" actual main settlement no pickup proc")
  ck(g.build.coins>coins and g.effect_runtime.build_items.charges==0 and g.effect_runtime.build_items.winch_count==0 and g.effect_runtime.build_items.fields.is_empty(),mode+" actual main reset B inventory with existing reward")
  ck(near(g.effect_runtime.build_items.pin_ready_at,1.0),mode+" actual boundary preserves prior cooldown")
  live=g.effect_runtime.build_items.debug_snapshot();coins=g.build.coins;g._complete_wave()
  ck(g.effect_runtime.build_items.debug_snapshot()==live and g.build.coins==coins,mode+" ignored second controller no reward/state change")
  g._start_run(39082)
  ck(g.elapsed==0.0 and g.effect_runtime.build_items.pin_ready_at==null and g.effect_runtime.build_items.last_sequence==0 and g.effect_runtime.build_items.charges==0,mode+" real newrun resets only at newrun")
  observations.append({"mode":mode,"normal_pickup_delta_coins":5,"normal_pickup_delta_xp":5,"pin_destination":[515,300],"newrun_snapshot":g.effect_runtime.build_items.debug_snapshot()})
 g._title();var helper=load("evidence-workspace/moss-v39-B-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"independent_B_real_hook_checks":checks,"failures":failures,"observations":observations,"scope":"Controlled actual main/runtime/AI/Motor/transactions. Notifications, actors and eligibility setup explicit; not ordinary acquisition or directFlow B ownership."}))
 quit(0 if failures.is_empty() else 1)
