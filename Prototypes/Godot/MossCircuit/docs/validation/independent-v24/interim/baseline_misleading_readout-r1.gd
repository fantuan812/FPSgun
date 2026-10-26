extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func labels(n:Node)->Array:
 var out:Array=[]
 if n is Label:out.append(n.text)
 for child in n.get_children():out.append_array(labels(child))
 return out
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for id in ["rail_lance","bankshot_driver"]:
   g._title();g._select_mode(mode);g._start_run(24700)
   g.build.weapons=[id];g.build.items={};g.build.levels={};g.build.revision+=1;g._recompute()
   g.elapsed=10;g.spawn_clock=999;g.combat_frame.area=g.config.arena
   var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(-90,0));e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999
   var before:Dictionary={"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate()}
   var view:Dictionary=g._view();g.ui.show_inventory(view)
   var texts:Array=labels(g.ui.root)
   check(g.build==before.build and g.stats==before.stats and g.weapon_clocks==before.clocks and [g.rng.state,g.loot_rng.state,g.shop_rng.state]==before.rng,mode+id+" view/UI read only")
   check(view.stats.damage==15 and view.stats.fire_interval==.4,mode+id+" generic starter-derived values")
   check(texts.has("Damage: 15") and texts.has("Fire interval: 0.4"),mode+id+" actual generated unqualified labels")
   g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0)
   var b:Dictionary=g.bullets[0]
   if id=="bankshot_driver":g.weapon_combat.advance_bankshot(b,.4)
   else:g.weapon_combat.advance_bullet(b,.4)
   var damage:float=30 if id=="rail_lance" else 18
   var interval:float=1.15 if id=="rail_lance" else .85
   check(absf((1000-e.hp)-damage)<.001,mode+id+" actual primary contact")
   check(absf(g.weapon_clocks[0]-interval)<.000001,mode+id+" actual scheduled clock")
   check(not texts.any(func(t):return "WEAPON STATS" in str(t)),mode+id+" no weapon numeric comparison section")
   records.append({"mode":mode,"weapon":id,"generic_labels":["Damage: 15","Fire interval: 0.4"],"observed_primary_damage":1000-e.hp,"observed_scheduled_interval":g.weapon_clocks[0],"controlled":true,"native_GUI":false})
   await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"Controlled baseline actual fire/clock/generated-label reproduction; not native GUI or ordinary play","checks":checks,"failures":failures,"records":records}
 print(JSON.stringify(result));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
