extends SceneTree
## External controlled oracle: run unchanged against the accepted baseline and candidate.
## Projects are selected through --path; optional output is the first user argument.
const Rules=preload("res://scripts/rules.gd")
var g
var cases:Array=[]
var draws:Array=[]
var failures:Array=[]
var marks:Array=[]
var samples:Array=[]
var profiles:Array=[
 {"weapons":["rivet_gun"],"items":{}},
 {"weapons":["cryo_sprayer","rivet_gun"],"items":{"fracture_coil":1,"cooling_fan":2,"power_coil":2}},
 {"weapons":["bankshot_driver","rail_lance","return_disc","orbit_saw"],"items":{"bounce_guide":1,"return_spool":1,"pulse_boots":1,"feedback_diode":1}},
 {"weapons":["scrap_shotgun","shock_mortar"],"items":{"dash_resin":1,"pulse_boots":1,"phase_capacitor":1,"blast_fuse":1,"gravity_anchor":1,"scrap_mine":1,"blood_valve":1,"kill_cell":1}}
]
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
func projection()->Dictionary:
 return clean({"state":g.state,"build":g.build,"stats":g.stats,"offers":g.shop_offers,"shop_generation":g.shop_generation,"choice_generation":g.choice_generation,"choices":g.choices,"wave":g.wave,"xp":g.xp,"level":g.level,"upgrade_pending":g.upgrade_pending,"shop_pending":g.shop_pending,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"weapon_clocks":g.weapon_clocks,"effects":{"epoch":g.effects.epoch,"last_sequence":g.effects.last_sequence,"runtime_sequence":g.effect_runtime.sequence,"active":g.effects.active,"cooldowns":g.effects.cooldowns,"shield":g.effects.shield,"shield_spent":g.effects.shield_spent,"echo_hits":g.effects.echo_hits,"phase_charge":g.effects.phase_charge,"feedback_armed":g.effects.feedback_armed},"affinity":Rules.shop_affinity(g.build,g.catalog),"tag_status":Rules.tag_synergy_status(g.build,g.catalog)})
func mark(label:String,result:Variant=null)->void:
 var p:=projection()
 marks.append({"step":label,"result":result,"sha256":JSON.stringify(p).sha256_text()})
 if cases.is_empty():samples.append({"step":label,"state":p})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for pi in range(profiles.size()):
  var b:Dictionary=Rules.new_build(g.catalog)
  b.weapons=profiles[pi].weapons.duplicate();b.items=profiles[pi].items.duplicate()
  var hashes:Array=[]
  for seed_value in range(200):
   var r:=RandomNumberGenerator.new();r.seed=seed_value
   var offers:=Rules.draw_shop(b,g.catalog,r,4)
   hashes.append(JSON.stringify({"seed":seed_value,"offers":offers,"rng":r.state}).sha256_text())
   if offers.size()!=4:failures.append("short legal pool "+str(pi)+":"+str(seed_value))
  draws.append({"profile":pi,"pool":Rules.weighted_pool(b,g.catalog),"affinity":Rules.shop_affinity(b,g.catalog),"hashes":hashes})
 for mode in ["arena","rooms"]:
  for pi in range(profiles.size()):
   for seed_value in [0,1,2,17,86,128,433,2701,28001,2147483647]:
    marks=[]
    g._title();g._select_mode(mode);g._start_run(seed_value)
    g.build.weapons=profiles[pi].weapons.duplicate();g.build.items=profiles[pi].items.duplicate()
    g.build.coins=200;g.build.revision+=1;g._recompute()
    g._open_shop();mark("open")
    var gen:int=g.shop_generation
    mark("stale buy",g._buy(0,gen-1))
    mark("invalid buy index",g._buy(-1,gen))
    mark("stale refresh",g._refresh_shop(gen-1))
    var entry:Dictionary=Rules.catalog_entry(g.catalog,g.shop_offers[0].id)
    var replace:int=1 if entry.kind=="weapon" and g.build.weapons.size()==4 else -1
    mark("buy first",g._buy(0,gen,replace))
    mark("duplicate old buy",g._buy(0,gen,replace))
    g._on_intent("inventory",{});mark("inventory")
    g._on_intent("close_inventory",{});mark("back to shop")
    if g.build.weapons.size()>1:mark("sell last weapon",g._sell_weapon(g.build.weapons.size()-1,g.shop_generation))
    if not g.build.items.is_empty():mark("sell first item",g._sell_item(str(g.build.items.keys()[0]),g.shop_generation))
    mark("refresh",g._refresh_shop(g.shop_generation))
    mark("negative replacement",g._buy(1,g.shop_generation,-2))
    g.build.coins=0
    mark("unfunded refresh",g._refresh_shop(g.shop_generation))
    mark("unfunded buy",g._buy(2,g.shop_generation))
    g._leave_shop(g.shop_generation);mark("deploy")
    g._on_intent("pause",{});mark("pause")
    g._on_intent("resume",{});mark("resume")
    g._open_shop();mark("later shop")
    g._leave_shop(g.shop_generation)
    g.upgrade_pending=1;g._show_upgrades();mark("earned choice")
    g._take_upgrade(1,g.choice_generation);mark("take choice")
    g._finish(true);mark("terminal")
    g._on_intent("retry",{});mark("retry")
    cases.append({"mode":mode,"profile":pi,"seed":seed_value,"steps":marks.duplicate(true)})
    await process_frame
 g.queue_free();await process_frame
 var output:Dictionary={"scope":"No reservation used. Controlled existing shop/transaction/menu/choice/retry paths and isolated seeded weighted draws; not ordinary acquisition or a full campaign. Explicit old-state projection excludes new reservation fields, UI copy and rendering identity. All profiles obey equipment slot caps; seeded shop outcomes/RNG are compared byte-for-byte between projects.","shop_draws":800,"cases":cases,"draws":draws,"first_case_states":samples,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(output,"  ")+"\n")
 print(JSON.stringify({"cases":cases.size(),"shop_draws":800,"failures":failures,"case_sha256":JSON.stringify(cases).sha256_text(),"draw_sha256":JSON.stringify(draws).sha256_text()}))
 quit(0 if failures.is_empty() else 1)
