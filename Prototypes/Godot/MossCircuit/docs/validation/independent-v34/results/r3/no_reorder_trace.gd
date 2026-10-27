extends SceneTree
## Same controlled finite old-state projection on accepted v29 and candidate.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
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
func snap()->Dictionary:
 return clean({"state":g.state,"build":g.build,"stats":g.stats,"wave":g.wave,"elapsed":g.elapsed,"level":g.level,"xp":g.xp,"pending":g.upgrade_pending,"shop_pending":g.shop_pending,"choice_generation":g.choice_generation,"choices":g.choices,"shop_generation":g.shop_generation,"offers":g.shop_offers,"reserved":g.reserved_offer,"message":g.shop_message,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks,"bullets":g.bullets,"pending_blasts":g.pending_blasts,"enemies":g.enemies,"enemy_bullets":g.enemy_bullets,"hazards":g.hazards,"pickups":g.pickups,"effects":{"epoch":g.effects.epoch,"sequence":g.effects.last_sequence,"runtime_sequence":g.effect_runtime.sequence,"active":g.effects.active,"cooldowns":g.effects.cooldowns,"shield":g.effects.shield,"feedback":g.effects.feedback_armed,"echo":g.effects.echo_hits,"phase":g.effects.phase_charge}})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var loadouts:Array=[["rivet_gun","rail_lance"],["orbit_saw","cryo_sprayer"],["scrap_shotgun","return_disc"],["shock_mortar","bankshot_driver"]]
 for mode in ["arena","rooms"]:
  for seed_value in [17,128,433]:
   for route in range(loadouts.size()):
    g._title();g._select_mode(mode);g._start_run(seed_value)
    g.build.weapons=loadouts[route].duplicate();g.build.items={"power_coil":1,"fracture_coil":1,"pulse_boots":1,"feedback_diode":1}
    g.build.coins=137;g.build.coin_fraction=.3;g._recompute();g.weapon_clocks=[.0,.17]
    g.elapsed=10;g.spawn_clock=999;g.combat_frame.area=g.config.arena
    var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(90,0));e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999
    var ranged:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(-180,25));ranged.hp=1000;ranged.max_hp=1000;ranged.anim_hp=1000;ranged.speed=0;ranged.cooldown_left=.1
    var steps:Array=[{"label":"prepared combat","state":snap()}]
    for tick in range(20):
     g.elapsed+=.05;Runtime.step(g.combat_frame,.05)
     if tick in [0,5,12,19]:steps.append({"label":"combat "+str(tick),"state":snap()})
    g._open_shop()
    if route%2==1:
     if not g._reserve_offer(0,g.shop_generation):failures.append("reservation setup")
    g._refresh_shop(g.shop_generation)
    steps.append({"label":"shop refresh","state":snap()})
    g._leave_shop(g.shop_generation);g.upgrade_pending=3;g.shop_pending=true;g._show_upgrades()
    for page in range(3):
     var generation:int=g.choice_generation;var before:=snap()
     g._take_upgrade(0,generation-1)
     if snap()!=before:failures.append("stale normal choice")
     if page==1:
      if not g._salvage_upgrade(generation,"salvage_upgrade"):failures.append("valid salvage")
     else:g._take_upgrade((page+route)%3,generation)
     steps.append({"label":"choice "+str(page),"state":snap()})
     var stable:=snap();g._take_upgrade(0,generation)
     if snap()!=stable:failures.append("duplicate choice")
    if g.state!="shop":failures.append("pending shop continuation")
    var generation:int=g.shop_generation
    g._buy(0,generation)
    steps.append({"label":"normal first buy","state":snap()})
    var stable:=snap();g._buy(0,generation-1)
    if snap()!=stable:failures.append("stale buy")
    g._sell_weapon(1,g.shop_generation)
    steps.append({"label":"normal slot1 sale","state":snap()})
    g._leave_shop(g.shop_generation)
    steps.append({"label":"deploy","state":snap()})
    cases.append({"mode":mode,"seed":seed_value,"route":route,"steps":steps})
    await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"No reorder calls. Controlled actual shared-combat, ordinary shop/reservation/refresh/buy/sell, mixed normal+salvage earned-choice queue and stale callbacks. Declared existing authority projection excludes UI metadata and presentation node identity; no ordinary-play or universal-state parity claim.","cases":cases,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"cases":cases.size(),"failures":failures,"case_sha256":JSON.stringify(cases).sha256_text()}))
 quit(0 if failures.is_empty() else 1)
