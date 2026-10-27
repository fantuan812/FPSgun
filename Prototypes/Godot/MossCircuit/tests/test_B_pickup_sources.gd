extends SceneTree
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
var origin:=Vector2(300,300)
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func setup(mode:String,reel:bool=false)->void:
 g._title();g._select_mode(mode);g._start_run(39031);g.set_process(false)
 g.build.weapons=["return_disc"] if reel else ["rivet_gun"]
 g.build.items={"salvage_capacitor":1,"medic_winch":1}
 if reel:g.build.items["scavenger_reel"]=1
 g._recompute();g.weapon_clocks=[999.0];g.player_pos=origin;g.hero.position=origin;g.spawn_clock=999.0
 g.elapsed=10.0;g.stats.pickup_radius=0.0;g.stats.bullet_speed=100.0;g.stats.coin_bonus=0.0;g.build.coins=0;g.build.coin_fraction=0.0;g.xp=0;g.stats.hp=g.stats.max_hp-20.0;g.combat_frame.area=g.config.arena
 ck(g.effect_runtime.build_items.owned_items==g.build.items,"actual setup B owned synchronized "+mode)
func item(distance:float,source:String="normal")->Dictionary:
 var result:Dictionary={"pos":origin+Vector2(distance,0),"xp":1,"coins":1}
 if source=="energy":result.merge({"source":"energy","xp":2},true)
 if source=="medical":result.merge({"source":"medical","xp":0,"coins":0,"heal":8.0},true)
 return result
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode);g.pickups=[item(10),item(10,"energy"),item(10,"medical")]
  Combat.step(g.combat_frame,0.0)
  ck(g.pickups.is_empty(),"local walk collects all three sources "+mode)
  ck(g.xp==3 and g.build.coins==2 and g.stats.hp==g.stats.max_hp-12.0,"local source rewards exactly once "+mode)
  ck(g.effect_runtime.build_items.charges==1 and g.effect_runtime.build_items.winch_count==1,"local only default normal counts for B "+mode)
  Combat.step(g.combat_frame,0.0)
  ck(g.xp==3 and g.build.coins==2 and g.effect_runtime.build_items.winch_count==1,"empty nextpass cannot duplicate local rewards "+mode)
  setup(mode);g.stats.pickup_radius=30.0;g.pickups=[item(20)]
  g.elapsed+=.05;Combat.step(g.combat_frame,.05)
  ck(g.pickups.size()==1 and g.pickups[0].pos.is_equal_approx(origin+Vector2(7,0)),"magnet moves13 but original distance gates collection "+mode)
  ck(g.xp==0 and g.build.coins==0 and g.effect_runtime.build_items.charges==0,"first magnet movement does not count pickup "+mode)
  Combat.step(g.combat_frame,0.0)
  ck(g.pickups.is_empty() and g.xp==1 and g.build.coins==1,"second magnet pass collects once "+mode)
  ck(g.effect_runtime.build_items.charges==1 and g.effect_runtime.build_items.winch_count==1,"actual magnet normal event counts once "+mode)
  setup(mode,true)
  var target:Dictionary=g._spawn_kind("crawler",origin+Vector2(300,0));target.hp=1000.0;target.max_hp=1000.0;target.anim_hp=1000.0;target.speed=0.0;target.cooldown_left=999.0
  g._fire_weapon("return_disc",0)
  ck(g.bullets.size()==1 and g.bullets[0].has("scavenger") and g.bullets[0].scavenger.remaining==3,"real owned launch creates fresh quota3 "+mode)
  if g.bullets.size()==1 and g.bullets[0].has("scavenger"):
   var disc:Dictionary=g.bullets[0]
   # Controlled return-phase placement, not an ordinary-play flight claim.
   disc.pos=origin+Vector2(100,0);disc.velocity=Vector2(100,0);disc.life=2.0;disc.returning=true;disc.outbound_left=0.0;disc.erase("launch_start")
   g.pickups=[item(50),item(60,"energy"),item(70,"medical")]
   g.elapsed+=1.0;Combat.step(g.combat_frame,1.0)
   ck(g.pickups.size()==1 and g.pickups[0].source=="medical" and disc.scavenger.remaining==1,"real return sweep normal+energy spend quota; medical excluded "+mode)
   ck(g.xp==3 and g.build.coins==2 and g.stats.hp==g.stats.max_hp-20.0,"remote source rewards once with no remote heal "+mode)
   ck(g.effect_runtime.build_items.charges==1 and g.effect_runtime.build_items.winch_count==1,"remote normal only counts for B "+mode)
   g.player_pos=origin+Vector2(60,0);Combat.step(g.combat_frame,0.0)
   ck(g.pickups.is_empty() and g.stats.hp==g.stats.max_hp-12.0 and g.xp==3 and g.build.coins==2,"excluded medical later locally collected normally "+mode)
   ck(g.effect_runtime.build_items.charges==1 and g.effect_runtime.build_items.winch_count==1 and disc.scavenger.remaining==1,"local medicine neither B stock nor remote quota "+mode)
 var helper=preload("res://tests/support/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"34 author controlled actual walk/magnet/ReturnDisc+Reel source and reward assertions, two modes; not natural acquisition"}))
 quit(0 if failures.is_empty() else 1)
