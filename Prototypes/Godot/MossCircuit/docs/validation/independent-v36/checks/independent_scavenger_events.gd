extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
class Probe extends "res://scripts/gameplay/effect_runtime.gd":
 var observed:Array=[]
 var append_once:Dictionary={}
 func emit_event(kind:String,data:Dictionary)->bool:
  observed.append({"kind":kind,"data":data.duplicate(true)})
  var result:bool=super.emit_event(kind,data)
  if kind=="pickup" and not append_once.is_empty():
   world.pickups.append(append_once.duplicate(true));append_once.clear()
  return result
var g
var probe:Probe
var checks:=0
var failures:Array=[]
var base:=Vector2(300,300)
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func setup(mode:String="arena",items:Dictionary={"scavenger_reel":1})->void:
 g._title();g._select_mode(mode);g._start_run(3602);g.build.weapons=["return_disc"];g.build.items=items.duplicate(true);g._recompute();g.weapon_clocks=[999.]
 g.player_pos=base;g.hero.position=base;g.spawn_clock=999.;g.elapsed=10.;g.stats.pickup_radius=0.;g.stats.bullet_speed=100.;g.build.coins=0;g.build.coin_fraction=.0;g.stats.coin_bonus=.0;g.xp=0;g.combat_frame.area=g.config.arena;probe.observed.clear();probe.append_once.clear()
func bullet(pos:Vector2=Vector2(100,0))->Dictionary:return {"pos":base+pos,"velocity":Vector2(100,0),"life":2.,"damage":1.,"pierce":999,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.,"scavenger":{"radius":18.,"remaining":3,"maximum":3,"sources":["normal","energy"]}}
func pickup(id:String,pos:Vector2=Vector2(50,0),source:String="normal")->Dictionary:return {"identity":id,"pos":base+pos,"xp":1,"coins":1,"source":source}
func enemy(pos:Vector2=Vector2(100,0))->Dictionary:
 var e:Dictionary=g._spawn_kind("crawler",base+pos);e.hp=1000.;e.max_hp=1000.;e.anim_hp=1000.;e.speed=0.;e.cooldown_left=999.;return e
func only_pickups()->Array:return probe.observed.filter(func(e):return e.kind=="pickup")
func launch_tests()->void:
 for mode in ["arena","rooms"]:
  setup(mode,{});enemy();g._fire_weapon("return_disc",0);ck(g.bullets.size()==1 and not g.bullets[0].has("scavenger"),"actual legacy launch no metadata "+mode)
  var old:Dictionary=g.bullets[0];g.build.items.scavenger_reel=1;g._recompute();ck(not old.has("scavenger"),"buy/sync cannot upgrade live disc "+mode)
  g._fire_weapon("return_disc",0);ck(g.bullets.size()==2 and g.bullets[1].has("scavenger"),"actual owned launch snapshot "+mode)
  if g.bullets.size()<2 or not g.bullets[1].has("scavenger"):continue
  var owned:Dictionary=g.bullets[1];owned.scavenger.remaining=2;g._fire_weapon("return_disc",0)
  ck(g.bullets.size()==3 and g.bullets[2].scavenger.remaining==3 and owned.scavenger.remaining==2,"new launch does not share quota "+mode)
  owned.scavenger.sources.reverse();ck(g.bullets[2].scavenger.sources==["normal","energy"],"nested source snapshots independent "+mode)
  var frozen:Dictionary=owned.duplicate(true);g._open_shop();ck(g._sell_item("scavenger_reel",g.shop_generation),"actual sale accepted "+mode);ck(same(owned,frozen),"sale neither retracts nor refills live snapshot "+mode)
  g._leave_shop(g.shop_generation);g._fire_weapon("return_disc",0);ck(not g.bullets[-1].has("scavenger"),"after sale new launch disabled "+mode)
  # Supported modal process routes do not progress the active snapshots.
  var before:Array=g.bullets.duplicate(true);g._on_intent("pause",{});g._process(.1);ck(same(g.bullets,before),"paused no progress "+mode);g._resume()
  g._on_intent("inventory",{});g._process(.1);ck(same(g.bullets,before),"inventory no progress "+mode);g._resume()
  g._title();ck(g.bullets.is_empty() and g.pickups.is_empty(),"title clears discs and pickups "+mode)
func event_tests()->void:
 for mode in ["arena","rooms"]:
  setup(mode);var d:Dictionary=bullet();g.bullets=[d];g.pickups=[pickup("first")];probe.append_once=pickup("appended")
  Runtime.step(g.combat_frame,1.);ck(g.pickups.size()==1 and g.pickups[0].identity=="appended" and g.xp==1 and d.scavenger.remaining==2,"event append excluded original index range "+mode)
  ck(only_pickups().size()==1,"one appended test original event "+mode)
  setup(mode,{"scavenger_reel":1,"scrap_mine":1});g.stats.pickup_radius=30.;g.stats.bullet_speed=600.;d=bullet(Vector2(0,30));g.bullets=[d];g.pickups=[pickup("magnet",Vector2(20,0))]
  Runtime.step(g.combat_frame,.05);var events:Array=only_pickups();ck(events.size()==1 and events[0].data.source=="normal" and events[0].data.pos.is_equal_approx(base+Vector2(7,0)),"actual event postmagnet normal position "+mode)
  ck(g.hazards.size()==1 and g.hazards[0].kind=="mine" and g.hazards[0].pos.is_equal_approx(base+Vector2(7,0)) and g.hazards[0].age==0.,"normal remote mine created after hazard stage "+mode)
  setup(mode,{"scavenger_reel":1,"scrap_mine":1,"arc_relay":1,"kill_cell":1});d=bullet();g.bullets=[d];g.pickups=[pickup("energy",Vector2(50,0),"energy")]
  Runtime.step(g.combat_frame,1.);events=only_pickups();ck(events.size()==1 and events[0].data.source=="energy" and g.effects.chain_charges==1 and g.hazards.is_empty(),"energy distinct charge no normal mine "+mode)
  setup(mode);d=bullet();g.bullets=[d];var dead:Dictionary=enemy(Vector2(50,0));dead.hp=0;dead.anim_hp=0;dead.xp=2
  Runtime.step(g.combat_frame,1.);ck(g.enemies.is_empty() and g.pickups.is_empty() and g.xp==2 and d.scavenger.remaining==2,"death-pass drop current sweep eligible "+mode)
  ck(only_pickups().size()==1,"death drop single pickup event "+mode)
  setup(mode,{"scavenger_reel":1,"medic_seed":1});d=bullet();g.bullets=[d];var med:Dictionary=pickup("medicine",Vector2(10,0),"medical");med.xp=0;med.coins=0;med.heal=8.;g.pickups=[med];g.stats.hp=g.stats.max_hp-3
  Runtime.step(g.combat_frame,1.);ck(g.pickups.is_empty() and g.stats.hp==g.stats.max_hp and d.scavenger.remaining==3,"local medical capped healing no quota "+mode)
  setup(mode);d=bullet();g.bullets=[d];g.pickups=[pickup("fraction")];g.stats.coin_bonus=.25;g.build.coin_fraction=.9
  Runtime.step(g.combat_frame,1.);ck(g.build.coins==2 and absf(g.build.coin_fraction-.15)<.00001 and g.xp==1,"shared fractional bank reward authority "+mode)
  # Direct terminal calls are outside supported gameplay flow but may not remote-credit.
  for terminal in ["dead","won"]:
   setup(mode);d=bullet();g.bullets=[d];g.pickups=[pickup("terminal")];g.state=terminal;Runtime.step(g.combat_frame,1.)
   ck(g.xp==0 and g.build.coins==0 and g.pickups.size()==1 and d.scavenger.remaining==3,"terminal remote branch disabled "+mode+terminal)
  # Existing movement-then-hit retirement: the completed segment remains the pickup boundary.
  setup(mode);d=bullet();d.pierce=0;g.bullets=[d];enemy(Vector2(50,0));g.pickups=[pickup("last-hit",Vector2(70,0))]
  Runtime.step(g.combat_frame,1.);ck(g.bullets.is_empty() and g.pickups.is_empty() and d.scavenger.remaining==2,"last hit retirement retains executed return segment "+mode)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 probe=Probe.new(g.combat,g.run,g.effects,g.actor_anim,g._vfx,g._mechanism_vfx);g.effect_runtime=probe;g.combat_frame.procs=probe
 launch_tests();event_tests()
 # External observer holds gameplay references only; clear explicitly before scene teardown.
 probe.observed.clear();probe.append_once.clear();probe=null
 var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 var report:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled actual launches/sale and event-phase ownership with subtype observer; no ordinary acquisition or general balance claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
