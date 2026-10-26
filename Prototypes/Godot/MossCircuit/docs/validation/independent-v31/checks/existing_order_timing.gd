extends SceneTree
## Source-grounded design premise through the existing actual shared runtime.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,ids:Array)->Dictionary:
 g._title();g._select_mode(mode);g._start_run(30001)
 g.build.weapons=ids.duplicate();g.build.items={"fracture_coil":1};g._recompute()
 g.elapsed=10;g.combat_frame.area=g.config.arena;g.weapon_clocks.fill(0.0)
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(90,0))
 e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999
 return e
func mark(e:Dictionary)->bool:return e.get("chill_until",0.0)>g.elapsed
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for ids in [["cryo_sprayer","orbit_saw"],["orbit_saw","cryo_sprayer"]]:
   var e:=setup(mode,ids);var rng_before:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
   Runtime.step(g.combat_frame,0.0)
   var first:Dictionary={"hp":e.hp,"mark":mark(e),"clocks":g.weapon_clocks.duplicate()}
   var cryo_first:bool=ids[0]=="cryo_sprayer"
   ck(e.hp==(955.0 if cryo_first else 971.0),"fresh-target order damage "+mode+str(ids))
   ck(mark(e)==not cryo_first,"fresh-target order mark "+mode+str(ids))
   ck(g.weapon_clocks==[.65,.65],"both existing intervals")
   g.elapsed+=.65;Runtime.step(g.combat_frame,.65)
   var second:Dictionary={"hp":e.hp,"mark":mark(e),"clocks":g.weapon_clocks.duplicate()}
   ck(first.hp-e.hp==45.0,"second aligned cycle not a universal DPS improvement")
   ck(mark(e)==not cryo_first,"reverse reapplies current chill")
   ck([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rng_before,"timing consumes no RNG")
   records.append({"mode":mode,"ids":ids,"first":first,"second":second})
  for ids in [["cryo_sprayer","rivet_gun"],["rivet_gun","cryo_sprayer"]]:
   var e:=setup(mode,ids);Runtime.step(g.combat_frame,0.0)
   ck(e.hp==991.0 and mark(e),"projectile has not contacted at launch at90")
   ck(g.bullets.size()==1,"exact one Rivet projectile")
   g.weapon_combat.advance_bullet(g.bullets[0],.3)
   ck(e.hp==960.0 and not mark(e),"later Rivet consumes Cryo irrespective of slot order")
   records.append({"mode":mode,"ids":ids,"after_later_contact":{"hp":e.hp,"mark":mark(e)}})
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"Controlled actual existing combat semantics only; no reorder action or ordinary acquisition. Fresh stationary target90units away, base stats, Coil, both clocks0; second cycle .65later. Conditional timing example, not balance/DPS guarantee.","checks":checks,"failures":failures,"records":records}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"checks":checks,"failures":failures,"cases":records.size()}));quit(0 if failures.is_empty() else 1)
