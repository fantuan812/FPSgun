extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const EXPECTED={
 "rivet_gun":[15.0,.4,500.0,1],"scrap_shotgun":[9.0,.85,300.0,5],"rail_lance":[30.0,1.15,650.0,1],"orbit_saw":[20.0,.65,105.0,0],
 "return_disc":[18.0,.9,330.0,1],"shock_mortar":[36.0,1.5,500.0,0],"cryo_sprayer":[9.0,.65,190.0,0],"bankshot_driver":[18.0,.85,900.0,1]}
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.0001
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var ids:Array=g.catalog.weapons.map(func(w):return w.id);ids.sort();var expected_ids:Array=EXPECTED.keys();expected_ids.sort();check(ids==expected_ids,"exact eight weapon IDs")
 var cases:Array=[
  {"name":"base","items":{},"levels":{},"boss":false},
  {"name":"generic","items":{"power_coil":2,"cooling_fan":1,"lens":1},"levels":{},"boss":false},
  {"name":"tag_thresholds","items":{"capacitor":2,"gear":2,"pellet_pouch":2},"levels":{},"boss":false},
  {"name":"haste_floor","items":{},"levels":{"haste":100},"boss":false},
  {"name":"range_pierce_cap","items":{"lens":3},"levels":{"pierce":10},"boss":false},
  {"name":"reward_and_upgrade","items":{"power_coil":1,"cooling_fan":1},"levels":{"damage":2,"haste":2},"boss":true}]
 for mode in ["arena","rooms"]:
  for c in cases:
   for id in EXPECTED:
    g._title();g._select_mode(mode);g._start_run(24800)
    g.build.weapons=[id];g.build.items=c.items.duplicate();g.build.levels=c.levels.duplicate();g.build.boss_protocol=c.boss;g.build.revision+=1;g._recompute()
    g.elapsed=10;g.spawn_clock=999;g.combat_frame.area=g.config.arena
    var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(-90,0));e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999
    var rng_before:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
    var bonus:float=.15*c.items.get("power_coil",0)+.25*c.levels.get("damage",0)+(.1 if c.boss else 0.0)
    var haste:float=.12*c.items.get("cooling_fan",0)+.15*c.levels.get("haste",0)
    var radius_bonus:float=.15*c.items.get("lens",0)
    var expect_damage:float=EXPECTED[id][0]*(1+bonus)
    if id=="rail_lance":expect_damage*=1+.25*c.items.get("capacitor",0)+(.2 if c.items.get("capacitor",0)>=2 else 0.0)
    if id=="orbit_saw":expect_damage*=1+.25*c.items.get("gear",0)+(.2 if c.items.get("gear",0)>=2 else 0.0)
    var expect_interval:float=maxf(.09,EXPECTED[id][1]/(1+haste))
    var expect_reach:float=EXPECTED[id][2]*(1 if id=="orbit_saw" else 1+radius_bonus)
    var expect_count:int=int(EXPECTED[id][3])
    if id=="scrap_shotgun":expect_count+=int(c.items.get("pellet_pouch",0))+(1 if c.items.get("pellet_pouch",0)>=2 else 0)
    g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0)
    var shot_damage:float=1000-e.hp
    var observed_reach:float=-1
    var projectile_count:int=g.bullets.size()
    if not g.bullets.is_empty():
     var b:Dictionary=g.bullets[0];shot_damage=b.damage
     if id=="bankshot_driver":
      observed_reach=b.launch_budget;g.weapon_combat.advance_bankshot(b,.35)
     elif id=="return_disc":g.weapon_combat.advance_disc(b,.35)
     else:g.weapon_combat.advance_bullet(b,.35)
    elif id=="shock_mortar":
     shot_damage=g.pending_blasts[0].damage;g.effect_runtime.advance_mortars(.61)
    elif id=="cryo_sprayer":observed_reach=g.effect_visuals.filter(func(v):return v.kind=="cryo_cone")[0].radius
    elif id=="orbit_saw":observed_reach=g.flashes.filter(func(v):return v.has("radius"))[0].radius
    var label:String=mode+"/"+c.name+"/"+id
    check(near(shot_damage,expect_damage),label+" primary damage independent oracle")
    check(near(g.weapon_clocks[0],expect_interval),label+" actual scheduled clock")
    check(projectile_count==expect_count,label+" actual projectile/pellet count")
    check(near(1000-e.hp,expect_damage),label+" one actual primary contact/target")
    check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rng_before,label+" no extra combat RNG")
    if observed_reach>=0:check(near(observed_reach,expect_reach),label+" actual cone/sweep/path reach")
    records.append({"mode":mode,"case":c.name,"weapon":id,"primary_damage":shot_damage,"actual_hp_loss":1000-e.hp,"scheduled_interval":g.weapon_clocks[0],"projectile_count":projectile_count,"observed_reach":observed_reach,"expected_reach":expect_reach,"stats":{"damage_bonus":g.stats.damage_bonus,"haste":g.stats.haste,"range_bonus":g.stats.range_bonus,"electric_bonus":g.stats.electric_bonus,"melee_bonus":g.stats.melee_bonus,"extra_pellets":g.stats.extra_pellets,"pierce":g.stats.pierce},"rng_after":[g.rng.state,g.loot_rng.state,g.shop_rng.state]})
   await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"Controlled actual-fire/clock/contact matrix, eight pinned weapons, six modifier setups, both modes; not ordinary/native play","checks":checks,"failures":failures,"records":records}
 print(JSON.stringify({"checks":checks,"failures":failures,"cases":records.size()}));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
