extends SceneTree
## Same external trace must run unchanged on accepted v28 and candidate.
## Controlled finite choice/continuation/reservation projection; no ordinary-run claim.
const Rules=preload("res://scripts/rules.gd")
var g
var cases:Array=[]
var failures:Array=[]
func clean(v:Variant)->Variant:
 match typeof(v):
  TYPE_VECTOR2:return [v.x,v.y]
  TYPE_COLOR:return [v.r,v.g,v.b,v.a]
  TYPE_ARRAY:
   var a:Array=[]
   for x in v:a.append(clean(x))
   return a
  TYPE_DICTIONARY:
   var d:Dictionary={}
   for k in v:
    if k!="sprite":d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<presentation-object>"
  _:return v
func snapshot()->Dictionary:
 return clean({"state":g.state,"build":g.build,"stats":g.stats,"wave":g.wave,"level":g.level,"xp":g.xp,"pending":g.upgrade_pending,"shop_pending":g.shop_pending,"choice_generation":g.choice_generation,"choices":g.choices,"shop_generation":g.shop_generation,"offers":g.shop_offers,"reserved":g.reserved_offer,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks,"bullets":g.bullets,"pending_blasts":g.pending_blasts,"effects":{"epoch":g.effects.epoch,"active":g.effects.active,"cooldowns":g.effects.cooldowns,"shield":g.effects.shield,"feedback_armed":g.effects.feedback_armed,"echo_hits":g.effects.echo_hits,"phase_charge":g.effects.phase_charge}})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for seed_value in [0,17,128,433,29001]:
   for route in range(4):
    g._title();g._select_mode(mode);g._start_run(seed_value)
    g.build.coins=37;g.build.coin_fraction=.3
    if route>=2:
     g.build.weapons=["rivet_gun","bankshot_driver","cryo_sprayer"]
     g.build.items={"power_coil":1,"fracture_coil":1,"pulse_boots":1,"feedback_diode":1}
    g._recompute();g.stats.hp=41.0;g.stats.dash_time=.04;g.stats.dash_cooldown=1.7
    g.weapon_clocks.fill(.23)
    if route%2==1:
     g._open_shop()
     if not g._reserve_offer(0,g.shop_generation):failures.append("setup reservation")
     g._leave_shop(g.shop_generation)
    g.shop_pending=route>=2;g.upgrade_pending=3;g._show_upgrades()
    var steps:Array=[{"label":"first page","state":snapshot()}]
    for page in range(3):
     var generation:int=g.choice_generation
     var before:=snapshot()
     g._take_upgrade(0,generation-1)
     if snapshot()!=before:failures.append("old stale choice unexpectedly mutates")
     var pick:int=(page+route)%3
     var selected:String=g.choices[pick].id
     g._take_upgrade(pick,generation)
     steps.append({"label":"take "+selected,"state":snapshot()})
     var after:=snapshot();g._take_upgrade(pick,generation)
     if snapshot()!=after:failures.append("old duplicate choice unexpectedly mutates")
    cases.append({"mode":mode,"seed":seed_value,"route":route,"steps":steps})
    await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"No salvage calls. Controlled actual three queued upgrade selections and stale callbacks, normal playing/shop continuation, held offer and legal mixed build. Old-state projection includes all existing authority fields named here, not UI metadata/node identity. Same script/output compared across versions; no ordinary acquisition/balance claim.","cases":cases,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"cases":cases.size(),"failures":failures,"case_sha256":JSON.stringify(cases).sha256_text()}))
 quit(0 if failures.is_empty() else 1)
