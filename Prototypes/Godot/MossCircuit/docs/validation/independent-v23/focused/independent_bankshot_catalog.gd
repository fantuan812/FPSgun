extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const OLD_WEAPONS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer"]
const OLD_ITEMS=["power_coil","cooling_fan","iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear","pellet_pouch","recycler","arc_relay","kill_cell","dash_resin","mirror_shell","thorn_crown","blood_valve","scrap_mine","pulse_boots","return_spool","blast_fuse","echo_chamber","gravity_anchor","medic_seed","phase_capacitor","fracture_coil"]
var checks:=0
var failures:Array=[]
var g
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func pair()->Dictionary:
 return g._view().synergy_status.filter(func(s):return s.name=="BANKED VECTOR")[0]
func fresh(mode:String,weapons:Array=["rivet_gun"],items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(27423);g.build.weapons=weapons.duplicate();g.build.items=items.duplicate();g.build.coins=1000;g._recompute()
func offer(id:String)->void:
 g._open_shop();g.shop_offers=[{"id":id,"sold":false,"weight_multiplier":1.0,"bias_reasons":[]}];g._render_shop()
func weight(id:String)->float:
 for e in Rules.weighted_pool(g.build,g.catalog):
  if e.id==id:return e.weight
 return -1
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var c:Dictionary=g.catalog
 check(Rules.validate_catalog(c).is_empty(),"valid catalog accepted")
 check(c.weapons.map(func(e):return e.id)==OLD_WEAPONS+["bankshot_driver"],"exact ordered8 weapon IDs")
 check(c.items.map(func(e):return e.id)==OLD_ITEMS+["bounce_guide"],"exact ordered28 item IDs")
 for spec in [["bankshot_driver","projectiles"],["bankshot_driver","spread"],["bankshot_driver","pierce"],["bounce_guide","max_stack"]]:
  for bad_value in ["1",true,false,null,[],{},NAN,INF,-INF,-1.0,0.5]:
   var bad:Dictionary=c.duplicate(true);Rules.catalog_entry(bad,spec[0])[spec[1]]=bad_value
   check(not Rules.validate_catalog(bad).is_empty(),"safe reject "+str(spec)+" type="+str(typeof(bad_value))+" value="+str(bad_value))
  var missing:Dictionary=c.duplicate(true);Rules.catalog_entry(missing,spec[0]).erase(spec[1]);check(not Rules.validate_catalog(missing).is_empty(),"reject missing "+str(spec))
 for mode in ["arena","rooms"]:
  fresh(mode,["bankshot_driver"])
  check(not pair().active and "bounce_guide" in Rules.shop_affinity(g.build,c).missing_ids,"weapon missing partner "+mode)
  check(is_equal_approx(weight("bounce_guide"),3.85),"weapon→guide exact1+.35+2.5 weight "+mode)
  check(is_equal_approx(weight("bankshot_driver"),2.2),"duplicate Bankshot1+.7+.5 weight "+mode)
  fresh(mode,[],{"bounce_guide":1})
  check(not pair().active and "bankshot_driver" in Rules.shop_affinity(g.build,c).missing_ids,"Guide only inactive/missing "+mode)
  check(is_equal_approx(weight("bankshot_driver"),3.85) and weight("bounce_guide")==-1,"Guide→weapon3.85/unique filtered "+mode)
  fresh(mode);g.build.coins=41;offer("bankshot_driver");var gen:int=g.shop_generation;var before:Dictionary=g.build.duplicate(true)
  check(not g._buy(0,gen) and g.build==before and not g.shop_offers[0].sold,"insufficient42 atomic "+mode)
  g.build.coins=42;check(g._buy(0,gen) and g.build.coins==0 and g.build.weapons==["rivet_gun","bankshot_driver"],"exact42 purchase "+mode)
  check(not g._buy(0,gen) and g.build.coins==0,"stale sold offer "+mode)
  g.build.coins=25;offer("bounce_guide");gen=g.shop_generation;before=g.build.duplicate(true)
  check(not g._buy(0,gen) and g.build==before,"insufficient26 atomic "+mode)
  g.build.coins=26;check(g._buy(0,gen) and g.build.coins==0 and pair().active,"exact26 pair active "+mode)
  g.build.coins=100;offer("bounce_guide");gen=g.shop_generation;before=g.build.duplicate(true)
  check(not g._buy(0,gen) and before==g.build,"unique duplicate atomic "+mode)
  check(g._sell_item("bounce_guide",gen) and g.build.coins==113 and not pair().active,"sellGuide13 deactivates "+mode)
  check(not g._sell_item("bounce_guide",gen) and g.build.coins==113,"stale sell no duplication "+mode)
  gen=g.shop_generation;check(g._sell_weapon(1,gen) and g.build.coins==134 and g.build.weapons==["rivet_gun"],"sellBankshot21 "+mode)
  fresh(mode,["rivet_gun","rail_lance","cryo_sprayer","return_disc"]);offer("bankshot_driver");gen=g.shop_generation;before=g.build.duplicate(true)
  check(not g._buy(0,gen) and g.build==before,"full weapons explicit replacement "+mode)
  check(not g._buy(0,gen,4) and g.build==before,"invalid replacement atomic "+mode)
  check(g._buy(0,gen,2) and g.build.coins==958 and g.build.weapons==["rivet_gun","rail_lance","bankshot_driver","return_disc"],"replace no refund "+mode)
  fresh(mode,["bankshot_driver","bankshot_driver","bankshot_driver","bankshot_driver"]);offer("bankshot_driver");gen=g.shop_generation
  check(weight("bankshot_driver")==-1,"four-copy normalpool excludes "+mode)
  check(g._buy(0,gen,1) and g.build.weapons.size()==4 and g.build.coins==958,"same-type replacement stays copycap "+mode)
  fresh(mode,["rivet_gun"],{"power_coil":1,"cooling_fan":1,"iron_plate":1,"moss_patch":1,"running_boots":1,"salvage_magnet":1,"lucky_chip":1,"lens":1});offer("bounce_guide");gen=g.shop_generation;before=g.build.duplicate(true)
  check(not g._buy(0,gen) and g.build==before,"full8 modules rejects Guide atomic "+mode)
  check(g._sell_item("lens",gen),"free module slot "+mode);gen=g.shop_generation
  check(g._buy(0,gen) and g.build.items.bounce_guide==1 and not pair().active,"Guide can buy beforeweapon remains inactive "+mode)
  var saved:Dictionary=g.build.duplicate(true);var states:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state]
  for i in range(3):g.ui.show_shop(g._view());g.ui.show_inventory(g._view())
  check(saved==g.build and states==[g.rng.state,g.loot_rng.state,g.shop_rng.state],"views read-only "+mode)
  var a:=RandomNumberGenerator.new();var b:=RandomNumberGenerator.new();a.seed=98765;b.seed=98765
  for i in range(25):
   var drawn:Array=Rules.draw_shop(g.build,c,a);check(drawn==Rules.draw_shop(g.build,c,b) and a.state==b.state,"expanded deterministic "+mode+str(i))
   var seen:Dictionary={}
   for e in drawn:check(not seen.has(e.id),"without replacement "+mode+str(i)+e.id);seen[e.id]=true
 g.queue_free();await process_frame
 var out:Dictionary={"checks":checks,"failures":failures,"scope":"independent controlled actual main shop handlers, exact ID sets, invalid new fields, seeded expanded-pool replay; not ordinary acquisition"}
 if not OS.get_cmdline_user_args().is_empty():FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
 print(JSON.stringify(out));quit(0 if failures.is_empty() else 1)
