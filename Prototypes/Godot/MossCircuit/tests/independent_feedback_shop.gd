extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
var g
var checks:=0
var failures:Array=[]
const ITEMS=["power_coil","cooling_fan","iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear","pellet_pouch","recycler","arc_relay","kill_cell","dash_resin","mirror_shell","thorn_crown","blood_valve","scrap_mine","pulse_boots","return_spool","blast_fuse","echo_chamber","gravity_anchor","medic_seed","phase_capacitor","fracture_coil","bounce_guide","feedback_diode"]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(826);g.build.items=items.duplicate();g._recompute();g.build.coins=200
func shop(ids:Array=["feedback_diode","feedback_diode","pulse_boots"])->void:
 g.state="shop";g.shop_offers=[]
 for id in ids:g.shop_offers.append({"id":id,"sold":false})
 g.shop_generation+=1;g._render_shop()
func cross()->Dictionary:return g._view().synergy_status.filter(func(s):return s.name=="CROSSCURRENT")[0]
func dash()->void:
 g.stats.dash_cooldown=0
 if Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0):g._effect_event("dash",{"pos":g.player_pos,"angle":0.0})
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 ck(g.catalog.items.map(func(e):return e.id)==ITEMS,"exact 29 module IDs and order")
 ck(g.catalog.weapons.map(func(e):return e.id)==["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"],"exact 8 weapon IDs")
 ck(g.ui.icon("feedback_diode")!=null,"actual integrated icon resource")
 var icon=g.ui.icon("feedback_diode");ck(icon.get_width()>0 and icon.get_height()>0,"nonempty actual icon")
 for mode in ["arena","rooms"]:
  setup(mode);shop();ck(not cross().active and cross().missing==["Feedback Diode","Pulse Boots"],mode+" pair empty missing both")
  var gen:int=g.shop_generation;var before:String=JSON.stringify(g.build)
  ck(not g._buy(0,gen-1) and JSON.stringify(g.build)==before,mode+" stale buy inert")
  g.build.coins=27;before=JSON.stringify(g.build);ck(not g._buy(0,gen) and JSON.stringify(g.build)==before,mode+" unaffordable atomic")
  g.build.coins=200;ck(g._buy(0,gen),mode+" actual purchase")
  ck(g.build.coins==172 and g.build.items.feedback_diode==1 and not g.effects.feedback_armed,mode+" exact price unique and unarmed")
  ck(not g._buy(0,gen) and g.build.coins==172,mode+" repeated stale purchase no charge")
  ck(not g._buy(1,g.shop_generation) and g.build.coins==172 and not g.shop_offers[1].sold,mode+" unique duplicate rejected")
  ck(not g._view().offers[1].can_buy,mode+" duplicate UI disabled")
  ck(not cross().active and cross().missing==["Pulse Boots"],mode+" missing partner explicit")
  ck("pulse_boots" in Rules.shop_affinity(g.build,g.catalog).missing_ids,mode+" diode biases partner")
  ck(g._buy(2,g.shop_generation),mode+" actual partner purchase")
  ck(cross().active and cross().missing.is_empty(),mode+" complementary pair active")
  ck("no extra multiplier" in cross().description,mode+" no invented bonus copy")
  var stats:Dictionary=g.stats.duplicate(true)
  var only:Dictionary=g.build.duplicate(true);only.items.erase("feedback_diode")
  var compare:Dictionary=Rules.derive(g.config.player,only,g.catalog)
  for key in compare:
   if key not in ["hp","dash_time","dash_cooldown"]:ck(stats.get(key)==compare[key],mode+" no hidden stats "+str(key))
  gen=g.shop_generation;ck(not g._sell_item("feedback_diode",gen-1),mode+" stale sell rejected")
  var expected:int=floori(28*g.stats.resale);var coins:int=g.build.coins
  ck(g._sell_item("feedback_diode",gen),mode+" actual sale")
  ck(g.build.coins==coins+expected and not g.build.items.has("feedback_diode") and not cross().active,mode+" refund/current pair recalculated")
  ck("feedback_diode" in Rules.shop_affinity(g.build,g.catalog).missing_ids,mode+" boots biases diode after sale")
  # Full slots do not silently replace or discard an existing module.
  var full:Dictionary={};for id in ITEMS.slice(0,8):full[id]=1
  setup(mode,full);shop();before=JSON.stringify(g.build)
  ck(not g._buy(0,g.shop_generation) and JSON.stringify(g.build)==before,mode+" full-slot rejection atomic")
  ck(not g._view().offers[0].can_buy,mode+" full-slot disabled")
  ck(g._sell_item("power_coil",g.shop_generation) and g._buy(0,g.shop_generation),mode+" sale opens real slot for new module")
  ck(g.build.items.size()==8 and g.build.items.has("feedback_diode"),mode+" exactly eight slots remain")
  # Neither buying while dash active nor selling/rebuying an armed module creates allowance.
  setup(mode);dash();ck(not g.effects.feedback_armed,mode+" unowned dash unarmed")
  shop();ck(g._buy(0,g.shop_generation) and not g.effects.feedback_armed,mode+" mid-dash buy unarmed")
  ck(g._view().mechanics.feedback_status=="UNARMED THIS DASH",mode+" truthful mid-dash status")
  g.state="playing";g.stats.dash_time=0;dash();ck(g.effects.feedback_armed,mode+" next successful equipped dash arms")
  ck(g._view().mechanics.feedback_status=="READY THIS DASH",mode+" ready status")
  shop();ck(g._sell_item("feedback_diode",g.shop_generation) and not g.effects.feedback_armed,mode+" sell clears allowance")
  ck(g._buy(0,g.shop_generation) and not g.effects.feedback_armed,mode+" rebuy cannot restore old allowance")
  g.stats.dash_time=0;ck(g._view().mechanics.feedback_status=="ARMS ON NEXT DASH",mode+" resting status")
  # View/render calls are read-only and do not change RNG/coins/window.
  var state_before:String=JSON.stringify({"build":g.build,"stats":g.stats,"armed":g.effects.feedback_armed,"rng":[g.rng.state,g.shop_rng.state,g.loot_rng.state]})
  for i in range(5):
   var v:Dictionary=g._view();g.ui.show_inventory(v);g.ui.show_shop(v)
  ck(state_before==JSON.stringify({"build":g.build,"stats":g.stats,"armed":g.effects.feedback_armed,"rng":[g.rng.state,g.shop_rng.state,g.loot_rng.state]}),mode+" read-only repeated view/render")
  await process_frame
 g.queue_free();await process_frame
 var result={"checks":checks,"failures":failures,"scope":"controlled actual transactions/view/resource; no ordinary acquisition claim"}
 var args=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
