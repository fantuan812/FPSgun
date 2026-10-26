extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const TAGS={"rail_lance":"electric","capacitor":"electric","orbit_saw":"melee","gear":"melee","scrap_shotgun":"spread","pellet_pouch":"spread"}
const EXPECTED_RULES=[{"id":"arc_grid","tag":"electric","threshold":3,"description":"3 electric tags: +20% electric damage"},{"id":"saw_rig","tag":"melee","threshold":3,"description":"3 melee tags: +20% melee damage"},{"id":"scatter_rig","tag":"spread","threshold":3,"description":"3 spread tags: +1 pellet"}]
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.0001
func _initialize()->void:call_deferred("run")
func setup(mode:String,weapons:Array,items:Dictionary)->void:
 g._title();g._select_mode(mode);g._start_run(25025)
 g.build.weapons=weapons.duplicate();g.build.items=items.duplicate();g.build.coins=1000;g.build.revision+=1;g._recompute();g.elapsed=10;g.spawn_clock=999
func counts()->Dictionary:
 var out={"electric":0,"melee":0,"spread":0}
 for id in g.build.weapons:
  if TAGS.has(id):out[TAGS[id]]+=1
 for id in g.build.items:
  if TAGS.has(id):out[TAGS[id]]+=int(g.build.items[id])
 return out
func expected_active(c:Dictionary)->Array:
 var out:Array=[]
 if c.electric>=3:out.append("ARC GRID")
 if c.melee>=3:out.append("SAW RIG")
 if c.spread>=3:out.append("SCATTER RIG")
 return out
func state_projection()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"offers":g.shop_offers.duplicate(true),"effect_cooldowns":g.effects.cooldowns.duplicate(true)}
func verify(label:String,expected:Dictionary)->void:
 var c=counts();check(c==expected,label+" independent owned-copy counts")
 check(g.stats.synergies==expected_active(c),label+" exact active order and once-only activation")
 var electric=.25*g.build.items.get("capacitor",0)+(.2 if c.electric>=3 else 0.0)
 var melee=.25*g.build.items.get("gear",0)+(.2 if c.melee>=3 else 0.0)
 var pellets=int(g.build.items.get("pellet_pouch",0))+(1 if c.spread>=3 else 0)
 check(near(g.stats.electric_bonus,electric) and near(g.stats.melee_bonus,melee) and near(g.stats.extra_pellets,pellets),label+" additive numeric effects")
 var affinity:Dictionary=Rules.shop_affinity(g.build,g.catalog)
 for tag in c:check(int(affinity.tags.get(tag,0))==int(c[tag]),label+" shop counts match existing ownership "+tag)
 var before=state_projection();var catalog_before:Dictionary=g.catalog.duplicate(true)
 for n in range(3):g.ui.show_inventory(g._view())
 check(state_projection()==before and g.catalog==catalog_before,label+" repeated view no authority mutation")
 var rng:=RandomNumberGenerator.new();rng.seed=25025^92137;var stock=Rules.draw_shop(g.build,g.catalog,rng,4)
 records.append({"label":label,"counts":c,"state":state_projection(),"affinity":affinity,"weighted_pool":Rules.weighted_pool(g.build,g.catalog),"stock":stock,"stock_rng_after":rng.state})
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 check(g.catalog.synergies==EXPECTED_RULES,"exact unchanged ordered three catalog definitions")
 var tagged:Array=[]
 for e in g.catalog.weapons+g.catalog.items:
  if e.tags.any(func(t):return t in ["electric","melee","spread"]):tagged.append(e.id)
 tagged.sort();var wanted:Array=TAGS.keys();wanted.sort();check(tagged==wanted,"exact six shipped contributing IDs")
 var cases:Array=[
  ["zero",["rivet_gun"],{},[0,0,0]],
  ["rail1",["rail_lance"],{},[1,0,0]],
  ["rail2",["rail_lance","rail_lance"],{},[2,0,0]],
  ["rail3",["rail_lance","rail_lance","rail_lance"],{},[3,0,0]],
  ["rail4",["rail_lance","rail_lance","rail_lance","rail_lance"],{},[4,0,0]],
  ["rail_cap1",["rail_lance"],{"capacitor":1},[2,0,0]],
  ["rail_cap2",["rail_lance"],{"capacitor":2},[3,0,0]],
  ["rail_cap3",["rail_lance"],{"capacitor":3},[4,0,0]],
  ["cap_no_weapon",["rivet_gun"],{"capacitor":3},[3,0,0]],
  ["orbit_gear1",["orbit_saw"],{"gear":1},[0,2,0]],
  ["orbit_gear2",["orbit_saw"],{"gear":2},[0,3,0]],
  ["orbit4",["orbit_saw","orbit_saw","orbit_saw","orbit_saw"],{},[0,4,0]],
  ["gear_no_weapon",["rivet_gun"],{"gear":3},[0,3,0]],
  ["shot_pouch1",["scrap_shotgun"],{"pellet_pouch":1},[0,0,2]],
  ["shot_pouch2",["scrap_shotgun"],{"pellet_pouch":2},[0,0,3]],
  ["shot3",["scrap_shotgun","scrap_shotgun","scrap_shotgun"],{},[0,0,3]],
  ["shot4",["scrap_shotgun","scrap_shotgun","scrap_shotgun","scrap_shotgun"],{},[0,0,4]],
  ["all",["rail_lance","orbit_saw","scrap_shotgun"],{"capacitor":2,"gear":2,"pellet_pouch":2},[3,3,3]]]
 for mode in ["arena","rooms"]:
  for c in cases:
   setup(mode,c[1],c[2]);var label=mode+"/"+c[0];verify(label,{"electric":c[3][0],"melee":c[3][1],"spread":c[3][2]})
   var outputs:Array=[]
   for slot in g.build.weapons.size():
    g.enemies.clear();g.bullets.clear();g.flashes.clear();g.pending_blasts.clear();g.effect_visuals.clear()
    var id:String=g.build.weapons[slot];var enemy:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(-90,0));enemy.hp=1000;enemy.max_hp=1000;enemy.anim_hp=1000;enemy.speed=0;enemy.cooldown_left=999
    var rng_before:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state];g.weapon_combat.fire(id,slot,g.config.arena)
    var damage:float=1000-enemy.hp;var count:int=g.bullets.size()
    if count>0:damage=g.bullets[0].damage;g.weapon_combat.advance_bullet(g.bullets[0],.35)
    var expected_damage:float={"rivet_gun":15.0,"rail_lance":30.0,"orbit_saw":20.0,"scrap_shotgun":9.0}[id]
    if id=="rail_lance":expected_damage*=1+.25*g.build.items.get("capacitor",0)+(.2 if c[3][0]>=3 else 0.0)
    if id=="orbit_saw":expected_damage*=1+.25*g.build.items.get("gear",0)+(.2 if c[3][1]>=3 else 0.0)
    var expected_count:int=0 if id=="orbit_saw" else (5+int(g.build.items.get("pellet_pouch",0))+(1 if c[3][2]>=3 else 0) if id=="scrap_shotgun" else 1)
    check(near(damage,expected_damage) and near(1000-enemy.hp,expected_damage),label+" actual primary contact slot"+str(slot));check(count==expected_count,label+" actual projectile count slot"+str(slot));check([g.rng.state,g.loot_rng.state,g.shop_rng.state]==rng_before,label+" no extra combat RNG")
    outputs.append({"slot":slot,"weapon":id,"damage":damage,"hp_loss":1000-enemy.hp,"projectiles":count})
   records[-1].primary_outputs=outputs
   await process_frame
  setup(mode,["rivet_gun","rail_lance"],{"capacitor":1});g._open_shop();g.shop_offers=[{"id":"capacitor","sold":false}];var generation:int=g.shop_generation
  check(g._buy(0,generation),mode+" buy threshold success");verify(mode+"/buy_threshold",{"electric":3,"melee":0,"spread":0});var snap=state_projection();check(not g._buy(0,generation) and state_projection()==snap,mode+" stale buy ignored")
  generation=g.shop_generation;check(g._sell_item("capacitor",generation),mode+" sell one success");verify(mode+"/sell_one",{"electric":2,"melee":0,"spread":0});snap=state_projection();check(not g._sell_item("capacitor",generation) and state_projection()==snap,mode+" stale sell ignored")
  setup(mode,["rail_lance","rail_lance","rail_lance","rivet_gun"],{});g._open_shop();check(g._sell_weapon(1,g.shop_generation),mode+" duplicate weapon sale success");verify(mode+"/sell_weapon",{"electric":2,"melee":0,"spread":0})
  setup(mode,["rail_lance","rail_lance","rivet_gun","scrap_shotgun"],{"capacitor":1});g._open_shop();g.shop_offers=[{"id":"rivet_gun","sold":false}];check(g._buy(0,g.shop_generation,0),mode+" replace relevant weapon success");verify(mode+"/replacement",{"electric":2,"melee":0,"spread":1})
  setup(mode,["rail_lance","rail_lance","rivet_gun","scrap_shotgun"],{"capacitor":1});g._open_shop();g.shop_offers=[{"id":"rail_lance","sold":false}];check(g._buy(0,g.shop_generation,0),mode+" same-ID replacement success");verify(mode+"/same_replacement",{"electric":3,"melee":0,"spread":1})
  g.shop_offers=[{"id":"capacitor","sold":false}];g.build.coins=0;snap=state_projection();check(not g._buy(0,g.shop_generation) and state_projection()==snap,mode+" insufficient funds do not contribute offer tag")
  setup(mode,["rivet_gun"],{});verify(mode+"/reset",{"electric":0,"melee":0,"spread":0});await process_frame
 g.queue_free();await process_frame
 var result={"scope":"Controlled actual shared ownership/equipment transactions/primary contacts and seeded shop projection; no ordinary/native campaign claim","checks":checks,"failures":failures,"records":records}
 print(JSON.stringify({"checks":checks,"failures":failures,"cases":records.size()}));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
