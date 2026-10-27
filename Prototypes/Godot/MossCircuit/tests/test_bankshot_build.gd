extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Shot=preload("res://scripts/gameplay/boundary_shot.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
var g
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func fresh(mode:String,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(433)
 g.build.weapons=["bankshot_driver"];g.build.items=items.duplicate(true);g._recompute()
 g.player_pos=Vector2(150,180);g.spawn_clock=999
 if mode=="rooms":g.mode.spawn_clock=999
 g.weapon_clocks=[999.0]
func foe(pos:Vector2,hp:float=100)->Dictionary:
 var e:Dictionary=g._spawn_kind("crawler",pos);e.hp=hp;e.max_hp=hp;e.speed=0;e.cooldown_left=999;return e
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 check(Rules.validate_catalog(g.catalog).is_empty(),"catalog valid")
 var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/V23_CATALOG_ADDITIONS.json"))
 check(g.catalog.version==5 and g.catalog.weapons.size()==8 and g.catalog.items.size()==29 and Rules.catalog_entry(g.catalog,"feedback_diode").id=="feedback_diode","explicit content version/count")
 check(Rules.catalog_entry(g.catalog,"bankshot_driver")==expected.weapon,"entire reviewed weapon definition")
 check(Rules.catalog_entry(g.catalog,"bounce_guide")==expected.item,"entire reviewed guide definition")
 check(g.catalog.mechanism_synergies[-2]==expected.pair and g.catalog.affinity_links[-2]==expected.link,"exact additive pair/link")
 for bad_value in [-1,0.5,"bad",true,INF,NAN]:
  var bad:Dictionary=g.catalog.duplicate(true);Rules.catalog_entry(bad,"bankshot_driver").pierce=bad_value
  check(not Rules.validate_catalog(bad).is_empty(),"malformed Bankshot quota safely rejected "+str(bad_value))
 for field in ["projectiles","spread"]:
  for bad_value in [-1,0.5,"bad",true,INF,NAN]:
   var bad:Dictionary=g.catalog.duplicate(true);Rules.catalog_entry(bad,"bankshot_driver")[field]=bad_value
   check(not Rules.validate_catalog(bad).is_empty(),"malformed Bankshot launch field safely rejected "+field+str(bad_value))
 for bad_value in [-1,2,"bad",true,INF,NAN]:
  var bad:Dictionary=g.catalog.duplicate(true);Rules.catalog_entry(bad,"bounce_guide").max_stack=bad_value
  check(not Rules.validate_catalog(bad).is_empty(),"malformed Guide uniqueness safely rejected "+str(bad_value))
 for mode in ["arena","rooms"]:
  fresh(mode);g._fire_weapon("bankshot_driver",0)
  check(g.bullets.is_empty() and g.weapon_rig.last_shot.is_empty(),"no target no shot "+mode)
  var e:Dictionary=foe(Vector2(70,180))
  var rngs:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
  g._fire_weapon("bankshot_driver",0)
  check(g.bullets.size()==1,"one shot "+mode)
  var b:Dictionary=g.bullets[0]
  check(b.damage==18 and b.speed==470 and b.launch_budget==900 and b.leg_quota==1,"base snapshots")
  check(b.field_width==g.config.arena.width and b.field_height==g.config.arena.height,"shared current field")
  check(not b.has("launch_start") and not b.has("launch_end"),"no damaging muzzle bridge")
  g.weapon_combat.advance_bankshot(b,.3)
  check(e.hp==82 and e.last_source=="primary" and b.leg_hits.size()<=1,"actual primary contact")
  check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rngs,"no new RNG draws")
  fresh(mode,{"bounce_guide":1});e=foe(Vector2(60,180));g.stats.damage_bonus=.5;g.stats.range_bonus=.2;g.stats.pierce=99;g.stats.extra_pellets=20;g.stats.electric_bonus=20;g.stats.melee_bonus=20;g.stats.bullet_speed=600
  g._fire_weapon("bankshot_driver",0);b=g.bullets[0]
  check(g.bullets.size()==1 and b.damage==27 and b.launch_budget==1080 and b.speed==600 and b.leg_quota==6 and b.guide,"scoped modifiers and bounded quota")
  var snapshot:Array=[b.damage,b.speed,b.launch_budget,b.leg_quota,b.guide]
  g.build.items.clear();g.build.weapons=["rivet_gun"];g._recompute()
  check(g.bullets.size()==1 and [b.damage,b.speed,b.launch_budget,b.leg_quota,b.guide]==snapshot,"equipment edits preserve existing Bankshot snapshots")
  var prior:String=JSON.stringify(b);g._on_intent("pause",{});g._process(10)
  check(JSON.stringify(b)==prior,"pause freezes in-flight shot")
  g._title();check(g.bullets.is_empty(),"run cleanup clears shots")
  fresh(mode);e=foe(g.player_pos);g.hero.flip_h=true;g._fire_weapon("bankshot_driver",0)
  check(g.bullets[0].dx==1.0 and g.bullets[0].dy==0.0,"coincident target exact RIGHT geometry")
  g.build.weapons=["bankshot_driver","bankshot_driver","bankshot_driver","bankshot_driver"];g._recompute()
  for facing in [false,true]:
   for slot in range(4):
    g.hero.flip_h=facing;g._fire_weapon("bankshot_driver",slot)
    check(g.bullets[-1].dx==1.0 and g.bullets[-1].dy==0.0,"coincident exact RIGHT every slot/facing")
    check(g.weapon_rig.last_shot.pose.direction==Vector2.RIGHT,"coincident mount and authority direction agree")
  fresh(mode,{"fracture_coil":1,"echo_chamber":1,"kill_cell":1});e=foe(Vector2(70,180),30)
  Status.apply_chill(e,g.elapsed,Rules.catalog_entry(g.catalog,"cryo_sprayer"));g.effects.echo_hits=0
  b=Shot.spawn(Vector2(110,180),Vector2.LEFT,g.config.arena,18,470,900,0,false);g.bullets.append(b)
  g.weapon_combat.advance_bankshot(b,.1)
  check(e.hp==-4 and e.last_source=="fracture" and not e.has("chill_until"),"primary18 then fixed secondary16 consumes chill")
  check(g.effects.echo_hits==1 and g.bullets.size()==1,"one primary proc, no projectile recursion")
  g._process(.001)
  check(g.kills==1 and not g.pickups.any(func(p):return p.get("source","")=="energy"),"secondary kill no Kill Cell")
  fresh(mode,{"echo_chamber":1,"kill_cell":1});e=foe(Vector2(70,180),18)
  b=Shot.spawn(Vector2(110,180),Vector2.LEFT,g.config.arena,18,470,900,0,false);g.bullets.append(b);g.weapon_combat.advance_bankshot(b,.1);g._process(.001)
  check(g.kills==1 and g.pickups.any(func(p):return p.get("source","")=="energy"),"primary lethal owns Kill Cell")
  fresh(mode)
  for i in range(20):g.weapon_combat._bankshot_contact({"pos":Vector2.ZERO,"direction":Vector2.RIGHT,"guided":false,"reflected":true})
  check(g.effect_visuals.filter(func(v):return v.kind=="bankshot_contact").size()==12,"bounded contact visuals")
  g.build.coins=100;g._open_shop();g.shop_offers=[{"id":"bounce_guide","sold":false}];var gen:int=g.shop_generation
  check(g._buy(0,gen) and g.build.coins==74 and g.build.items.bounce_guide==1,"guide exact purchase")
  check(not g._buy(0,gen) and g.build.coins==74,"stale duplicate rejected")
  check(not Rules.weighted_pool(g.build,g.catalog).any(func(x):return x.id=="bounce_guide"),"unique owned guide excluded")
  check(g._view().synergy_status.filter(func(x):return x.name=="BANKED VECTOR")[0].active,"pair active")
  check(g._sell_item("bounce_guide",g.shop_generation) and g.build.coins==87,"guide sale half refund")
  check(not g._view().synergy_status.filter(func(x):return x.name=="BANKED VECTOR")[0].active,"pair updates after sale")
  g.build.weapons=["rivet_gun","rail_lance","cryo_sprayer","return_disc"];g._recompute();g.build.coins=100;g.shop_offers=[{"id":"bankshot_driver","sold":false}];gen=g.shop_generation
  check(not g._buy(0,gen) and g.build.coins==100,"full weapon slots require selection")
  check(g._buy(0,gen,2) and g.build.weapons[2]=="bankshot_driver" and g.build.coins==58,"explicit replacement exact price")
  check(g.ui.icon("bankshot_driver")!=null and g.ui.icon("bounce_guide")!=null and g.weapon_rig.assets.has("bankshot_driver"),"dedicated assets resolve")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 print(JSON.stringify({"bankshot_build_checks":checks,"failures":failures,"scope":"controlled integration; native appearance and ordinary acquisition separate"}))
 quit(0 if failures.is_empty() else 1)
