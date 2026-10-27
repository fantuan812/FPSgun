extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func setup(mode:String,ids:Array=["return_disc"],items:Dictionary={"scavenger_reel":1})->void:
 g._title();g._select_mode(mode);g._start_run(3603);g.build.weapons=ids.duplicate();g.build.items=items.duplicate(true);g._recompute();g.weapon_clocks=[]
 for _id in ids:g.weapon_clocks.append(999.)
 g.spawn_clock=999;g.elapsed=10.;g.combat_frame.area=g.config.arena
func nodes(n:Node)->Array:
 var result:Array=[n]
 for child in n.get_children():result.append_array(nodes(child))
 return result
func text()->String:
 var strings:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:strings.append(n.text)
 return "\n".join(strings)
func authority()->Dictionary:return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"bullets":g.bullets.duplicate(true),"pickups":g.pickups.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"sequence":g.effect_sequence,"xp":g.xp,"effects":[g.effects.epoch,g.effects.last_sequence,g.effects.cooldowns.duplicate(true)]}
func row(v:Dictionary)->Dictionary:
 for x in v.synergy_status:
  if x.name=="SCAVENGER RETURN":return x
 return {}
func wording(content:String,label:String)->void:
 var s:=content.to_lower()
 for word in ["return disc","return leg","3","normal/energy","immediate","medicine"]:ck(s.contains(word),label+" includes "+word)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var original_catalog:Dictionary=g.catalog
 for mode in ["arena","rooms"]:
  for spec in [[["return_disc"],{},false],[["rivet_gun"],{"scavenger_reel":1},false],[["return_disc"],{"scavenger_reel":1},true]]:
   setup(mode,spec[0],spec[1]);var before:=authority();var v:Dictionary=g._view();var mechanism:Dictionary=row(v)
   ck(not mechanism.is_empty() and mechanism.active==spec[2],"actual owned prerequisite state "+mode+str(spec[2]));wording(mechanism.get("description",""),"mechanism");ck(same(authority(),before),"view no authority mutation")
  setup(mode,["return_disc"],{});var no_module:Dictionary=g.stats.duplicate(true);g.build.items.scavenger_reel=1;g._recompute();ck(g.stats==no_module,"new tags add no fourth stat threshold "+mode)
  # Existing validation does not require IDs on historical mechanism rows.
  var compatibility:Dictionary=g.catalog.duplicate(true);compatibility.mechanism_synergies[0].erase("id");g.catalog=compatibility
  ck(Rules.validate_catalog(g.catalog).is_empty(),"old mechanism optional id remains valid")
  var legacy:Dictionary=g._view();ck(legacy.synergy_status[0].description==compatibility.mechanism_synergies[0].description,"optional id legacy view unchanged")
  g.catalog=original_catalog
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size;setup(mode);g._open_shop()
   var e:Dictionary=Rules.catalog_entry(g.catalog,"scavenger_reel").duplicate(true);e.sold=false;g.shop_offers=[e];var before:=authority();g._render_shop();await process_frame;await process_frame
   wording(text(),"shop "+mode+str(size));ck(same(authority(),before),"shop render authority exact")
   var icon:Texture2D=g.ui.icon("scavenger_reel");ck(icon!=null and icon.get_width()==64 and icon.get_height()==64,"actual reel icon loaded64")
   g._leave_shop(g.shop_generation);g._present_inventory();before=authority();await process_frame
   wording(text(),"inventory "+mode+str(size));ck(same(authority(),before),"inventory render authority exact");g._resume()
  setup(mode);g.player_pos=Vector2(300,300);g.stats.pickup_radius=0.;g.stats.bullet_speed=100.;g.pickups=[];g.bullets=[]
  for i in range(10):g.pickups.append({"pos":Vector2(350,300),"xp":1,"coins":1})
  for _i in range(2):g.bullets.append({"pos":Vector2(400,300),"velocity":Vector2.LEFT*100,"life":2.,"damage":1.,"pierce":99,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.,"scavenger":{"radius":18.,"remaining":8,"maximum":8,"sources":["normal","energy"]}})
  Runtime.step(g.combat_frame,.8);var pulses:Array=g.effect_visuals.filter(func(p):return p.kind=="scavenger_pickup")
  ck(g.pickups.is_empty() and pulses.size()==8,"ten interceptions bounded to eight visual records "+mode)
  ck(pulses.all(func(p):return p.life==.16),"new pulse lifetime .16")
  for reduced in [false,true]:
   g.settings.reduced_flashes=reduced;var before:=authority();var visual:Array=g.effect_visuals.duplicate(true);g.queue_redraw();await process_frame
   ck(same(authority(),before) and same(g.effect_visuals,visual),"drawing reduced-flash state never settles or advances "+str(reduced))
  for state in ["paused","inventory","dead","won","title"]:
   g.state=state;var before:=authority();g.queue_redraw();await process_frame;ck(same(authority(),before),"draw frozen/terminal no settlement "+state)
 g.catalog=original_catalog
 var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled data/UI ownership, actual text/icon, no authority from rendering, bounded pulse records. Native pip appearance and clipping remain separate visual checks."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
