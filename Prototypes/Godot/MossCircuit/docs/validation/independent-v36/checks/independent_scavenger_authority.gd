extends SceneTree
## Frozen before implementation: independent paper expectations, not copied candidate output.
const Reel=preload("res://scripts/gameplay/scavenger_reel.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
var g
var checks:=0
var failures:Array=[]
var base:=Vector2(300,300)
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func setup(mode:String="arena",items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(3601)
 g.build.weapons=["return_disc"];g.build.items=items.duplicate(true);g._recompute();g.weapon_clocks=[999.0]
 g.player_pos=base;g.hero.position=base;g.spawn_clock=999;g.elapsed=10;g.stats.pickup_radius=0.;g.stats.bullet_speed=100.
 g.build.coins=0;g.build.coin_fraction=.0;g.stats.coin_bonus=.0;g.xp=0;g.combat_frame.area=g.config.arena
func meta(quota:int=3)->Dictionary:return {"radius":18.,"remaining":quota,"maximum":3,"sources":["normal","energy"]}
func bullet(pos:Vector2=Vector2(100,0),quota:int=3)->Dictionary:
 return {"pos":base+pos,"velocity":Vector2(100,0),"life":2.,"damage":1.,"pierce":999,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.,"scavenger":meta(quota)}
func pickup(id:String,pos:Vector2=Vector2(50,0),source:Variant="normal")->Dictionary:
 var p:Dictionary={"identity":id,"pos":base+pos,"xp":1,"coins":1}
 if not (source is String and source=="absent"):p.source=source
 return p
func sweep(b:Dictionary,start:Vector2=Vector2(100,0),end:Vector2=Vector2.ZERO)->Dictionary:return {"disc":b,"start":base+start,"end":base+end}
func profile_tests()->void:
 var owned:Dictionary={"items":{"scavenger_reel":1},"weapons":["return_disc"]}
 var profile:Dictionary=Reel.profile(owned,g.catalog)
 ck(profile.get("radius")==18. and profile.get("maximum")==3 and typeof(profile.get("maximum"))==TYPE_INT,"canonical normalized config")
 ck(Reel.profile({"items":{}},g.catalog).is_empty(),"unowned disabled")
 var old:Dictionary=g.catalog.duplicate(true);old.items=old.items.filter(func(v):return v.id!="scavenger_reel")
 ck(Reel.profile(owned,old).is_empty(),"historical catalog absent disabled")
 for quota in [1,1.,3.,8,8.]:
  var c:Dictionary=g.catalog.duplicate(true)
  for item in c.items:
   if item.id=="scavenger_reel":item.return_pickup_limit=quota
  ck(Reel.profile(owned,c).get("maximum")==int(quota),"JSON-compatible finite integer quota "+str(quota))
 for field in ["return_pickup_limit","return_pickup_radius","pickup_sources"]:
  var bads:Array=[null,true,false,"3",{},[],NAN,INF,-INF,0,-1,9,2.5] if field=="return_pickup_limit" else ([null,true,false,"18",{},[],NAN,INF,-INF,0,-1,65] if field=="return_pickup_radius" else [null,{},"normal",[],["normal"],["normal","normal"],["normal","medical"],["energy",1]])
  for bad in bads:
   var c:Dictionary=g.catalog.duplicate(true)
   for item in c.items:
    if item.id=="scavenger_reel":item[field]=bad
   ck(Reel.profile(owned,c).is_empty(),"reject catalog "+field+str(bad))
   ck(not Rules.validate_catalog(c).is_empty(),"catalog validator agrees "+field+str(bad))
 var a:Dictionary=Reel.snapshot(owned,g.catalog);var b:Dictionary=Reel.snapshot(owned,g.catalog)
 a.remaining=0;a.sources.clear();ck(b.remaining==3 and b.sources==["normal","energy"],"independent snapshot ownership")
func geometry_tests()->void:
 var b:Dictionary=bullet()
 for row in [[Vector2(50,17),true],[Vector2(50,18),false],[Vector2(120,0),false],[Vector2(0,17),true],[Vector2(0,18),false],[Vector2(100,17),true],[Vector2(50,-17),true]]:
  var sw:Dictionary=sweep(b);var p:Dictionary=pickup("x",row[0]);var before:Dictionary={"sweep":sw.duplicate(true),"pickup":p.duplicate(true)}
  ck(Reel.eligible(sw,p)==row[1],"strict closed segment "+str(row[0]));ck(same(before,{"sweep":sw,"pickup":p}),"eligibility pure")
 ck(not Reel.eligible(sweep(b,Vector2.ZERO,Vector2.ZERO),pickup("zero",Vector2.ZERO)),"zero excluded")
 for source in ["medical","unknown",null,true,1,[],{}]:ck(not Reel.eligible(sweep(b),pickup("source",Vector2(50,0),source)),"invalid remote source "+str(source))
 for source in ["normal","energy","absent"]:ck(Reel.eligible(sweep(b),pickup("source",Vector2(50,0),source)),"allowed source "+str(source))
 for field in ["remaining","maximum"]:
  for bad in [null,true,3.,"3",-1,0,9,NAN,INF]:
   var changed:Dictionary=bullet();changed.scavenger[field]=bad;ck(not Reel.eligible(sweep(changed),pickup("invalid")),"invalid runtime actual-int "+field+str(bad))
 for bad in [NAN,INF,-INF]:
  ck(not Reel.eligible(sweep(b,Vector2(bad,0)),pickup("endpoint")),"nonfinite endpoint")
  ck(not Reel.eligible(sweep(b),pickup("position",Vector2(bad,0))),"nonfinite pickup")
 ck(Reel.eligible(sweep(b,Vector2(100,100),Vector2.ZERO),pickup("diag",Vector2(50,60))),"diagonal inside margin")
 ck(not Reel.eligible(sweep(b,Vector2(100,100),Vector2.ZERO),pickup("diag",Vector2(50,80))),"diagonal outside margin")
func integration_tests()->void:
 for mode in ["arena","rooms"]:
  for row in [[.2,.03,false,.01,Vector2(101,0),Vector2(99,0)],[.015,.03,false,.01,Vector2(101,0),Vector2(100.5,0)],[.005,.03,false,.01,null,null],[0.,.03,true,0.,null,null],[.2,0.,true,0.,null,null]]:
   setup(mode);var b:Dictionary=bullet();b.life=row[0];b.returning=row[2];b.outbound_left=row[3]
   var result:Array=g.weapon_combat.advance_disc(b,row[1]);var count:int=0 if row[4]==null else 1
   ck(result.size()==count,mode+" actual suffix count "+str(row));ck(b.scavenger.remaining==3,"advance never debits quota")
   if count==1 and result.size()==1:
    ck(result[0].start.is_equal_approx(base+row[4]) and result[0].end.is_equal_approx(base+row[5]),"actual return-piece endpoints")
    result[0].disc.scavenger.remaining=2;ck(b.scavenger.remaining==2,"row references actual disc")
  setup(mode);var arrival:Dictionary=bullet(Vector2(10,0));ck(g.weapon_combat.advance_disc(arrival,.1).is_empty(),"arrival before motion no sweep")
  setup(mode);var d:Dictionary=bullet();g.bullets=[d];g.pickups=[pickup("P0"),pickup("P1"),pickup("P2"),pickup("P3")]
  var sequence:int=g.effect_sequence;var randoms:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
  Runtime.step(g.combat_frame,1.)
  ck(g.pickups.size()==1 and g.pickups[0].identity=="P0","reverse pickup quota leaves P0 "+mode);ck(d.scavenger.remaining==0 and g.bullets.is_empty(),"valid retiring last segment credits three "+mode)
  ck(g.xp==3 and g.build.coins==3 and g.effect_sequence==sequence+3,"single RunFlow/event credit each "+mode);ck(randoms==[g.rng.state,g.loot_rng.state,g.shop_rng.state],"pickup geometry no RNG "+mode)
  Runtime.step(g.combat_frame,0.);ck(g.pickups.size()==1 and g.xp==3,"no retired sweep next tick "+mode)
  setup(mode);var a:Dictionary=bullet(Vector2(100,0),1);var b:Dictionary=bullet(Vector2(100,0),1);g.bullets=[a,b];g.pickups=[pickup("P0"),pickup("P1"),pickup("P2")]
  Runtime.step(g.combat_frame,1.);ck(a.scavenger.remaining==0 and b.scavenger.remaining==0 and g.pickups.size()==1 and g.pickups[0].identity=="P0","two per-disc quotas distinct "+mode)
  setup(mode);a=bullet(Vector2(100,0),1);b=bullet(Vector2(100,0),1);g.bullets=[a,b];g.pickups=[pickup("only")]
  Runtime.step(g.combat_frame,1.);ck(b.scavenger.remaining==0 and a.scavenger.remaining==1,"descending bullet-index tie "+mode)
  setup(mode);g.stats.pickup_radius=30.;g.stats.bullet_speed=600.;d=bullet(Vector2(0,30));g.bullets=[d];g.pickups=[pickup("moved",Vector2(20,0))]
  Runtime.step(g.combat_frame,.05);ck(g.pickups.is_empty() and d.scavenger.remaining==2,"post-magnet coordinate remote not stale preposition "+mode)
  setup(mode);g.stats.pickup_radius=30.;g.pickups=[pickup("moved",Vector2(20,0))];Runtime.step(g.combat_frame,.05)
  ck(g.pickups.size()==1 and g.pickups[0].pos.is_equal_approx(base+Vector2(7,0)) and g.xp==0,"saved local distance not moved contact "+mode)
  setup(mode);g.stats.pickup_radius=30.;d=bullet();g.bullets=[d];g.pickups=[pickup("local",Vector2(13,0))];Runtime.step(g.combat_frame,1.)
  ck(g.pickups.is_empty() and d.scavenger.remaining==3 and g.xp==1,"local precedence no debit "+mode)
  setup(mode);d=bullet();g.bullets=[d];g.pickups=[pickup("n"),pickup("e",Vector2(50,0),"energy"),pickup("m",Vector2(50,0),"medical")]
  Runtime.step(g.combat_frame,1.);ck(g.pickups.size()==1 and g.pickups[0].identity=="m" and d.scavenger.remaining==1 and g.xp==2,"source exclusion normal energy only "+mode)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 profile_tests();setup();geometry_tests();integration_tests()
 var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 var report:Dictionary={"checks":checks,"failures":failures,"scope":"Independent controlled core profile/geometry/return suffix/Runtime pickup ownership; no ordinary, full lifecycle, presentation or balance claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
