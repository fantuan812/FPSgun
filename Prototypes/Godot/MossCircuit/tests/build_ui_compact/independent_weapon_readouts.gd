extends SceneTree
const EXPECTED={"rivet_gun":[15.0,.4,500.0,"per contact","Acquisition / range limit"],"scrap_shotgun":[9.0,.85,300.0,"per pellet contact","Acquisition / range limit"],"rail_lance":[30.0,1.15,650.0,"per contact","Acquisition / range limit"],"orbit_saw":[20.0,.65,105.0,"per target / sweep","Sweep radius"],"return_disc":[18.0,.9,330.0,"per contact","Acquisition / outbound reach"],"shock_mortar":[36.0,1.5,500.0,"per target / blast","Acquisition reach"],"cryo_sprayer":[9.0,.65,190.0,"per target / cone","Cone reach"],"bankshot_driver":[18.0,.85,900.0,"per contact","Acquisition reach"]}
var g
var checks:=0
var failures:Array=[]
var records:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.0001
func texts(n:Node)->Array:
 var out:Array=[]
 if n is Label:out.append(n.text)
 for child in n.get_children():out.append_array(texts(child))
 return out
func snapshot()->Dictionary:return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"catalog":g.catalog.duplicate(true)}
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 # Explicit original8/30/3 fixture; actual A catalog is separately validated.
 var legacy_input:Dictionary=preload("res://tests/support/v39_legacy_inputs.gd").install(g)
 if not legacy_input.pass:push_error(str(legacy_input.errors));quit(1);return
 var ids:Array=g.catalog.weapons.map(func(w):return w.id);ids.sort();var expected_ids:Array=EXPECTED.keys();expected_ids.sort();check(ids==expected_ids,"exact eight weapon IDs")
 for mode in ["arena","rooms"]:
  for modified in [false,true]:
   for id in EXPECTED:
    g._title();g._select_mode(mode);g._start_run(24900)
    g.build.weapons=[id];g.build.items={"power_coil":2,"cooling_fan":1,"lens":1,"capacitor":2,"gear":2,"pellet_pouch":2,"fracture_coil":1,"echo_chamber":1} if modified else {};g.build.revision+=1;g._recompute()
    g.shop_offers=[{"id":id,"sold":false}]
    var before:Dictionary=snapshot();var view:Dictionary=g._view();var label:String=mode+"/"+str(modified)+"/"+id
    check(view.weapons[0].has("weapon_readout") and view.offers[0].has("weapon_readout"),label+" controller supplies both readouts")
    var own:Dictionary=view.weapons[0].weapon_readout;var offer:Dictionary=view.offers[0].weapon_readout
    var damage:float=EXPECTED[id][0]*(1.3 if modified else 1.0)
    if modified and id in ["rail_lance","orbit_saw"]:damage*=1.7
    var interval:float=EXPECTED[id][1]/(1.12 if modified else 1.0)
    var reach:float=EXPECTED[id][2]*(1.15 if modified and id!="orbit_saw" else 1.0)
    check(own.scope=="CURRENT" and offer.scope=="BASE",label+" explicit scope")
    check(near(own.damage,damage) and near(own.interval,interval) and near(own.reach,reach),label+" independent current oracle")
    check(near(offer.damage,EXPECTED[id][0]) and near(offer.interval,EXPECTED[id][1]) and near(offer.reach,EXPECTED[id][2]),label+" base excludes current and future synergy")
    check(own.damage_unit==EXPECTED[id][3] and own.reach_label==EXPECTED[id][4],label+" behavior-specific units")
    check(str(own.note).contains("module procs are separate") and str(own.note).contains("not guaranteed DPS"),label+" excludes secondary and DPS claim")
    if id=="scrap_shotgun":check(own.pellets==(8 if modified else 5) and offer.pellets==5,label+" actual pellet count not total volley damage")
    else:check(not own.has("pellets") and not offer.has("pellets"),label+" no inappropriate pellets")
    if id=="bankshot_driver":check(near(own.total_path,reach) and near(offer.total_path,900) and str(own.note).contains("not a fresh range per bounce"),label+" one scaled path")
    else:check(not own.has("total_path"),label+" no invented total path")
    if id=="orbit_saw":check(own.reach==105 and str(own.note).contains("Focus Lens does not"),label+" orbit range exception")
    if id=="return_disc":check(str(own.note).contains("Not total round-trip"),label+" return reach qualifier")
    if id=="shock_mortar":check(str(own.note).contains("not blast radius"),label+" mortar radius qualifier")
    if id=="cryo_sprayer":check(str(own.note).contains("projectile and pierce bonuses do not apply"),label+" instant cone qualifier")
    g.ui.show_inventory(view);_open_build_disclosures(g.ui);var labels:Array=texts(g.ui.root)
    check(labels.has("CURRENT WEAPON STATS") and labels.has("BASE BEHAVIOR"),label+" generated equipped scope labels")
    check(labels.has("%.2f damage %s  /  %.3f s attack interval" % [damage,EXPECTED[id][3],interval]),label+" actual generated numeric line")
    check(not labels.any(func(t):return str(t).to_lower().begins_with("damage: ") or str(t).to_lower().begins_with("fire interval: ")),label+" no generic misleading weapon values")
    check(labels.has("Global weapon-damage bonus: +%d%%" % (30 if modified else 0)) and labels.has("Additive attack-rate bonus: +%d%%" % (12 if modified else 0)),label+" meaningful global modifiers")
    g.ui.show_shop(g._view());labels=texts(g.ui.root)
    check(labels.has("BASE WEAPON STATS") and labels.has("CURRENT WEAPON STATS") and labels.has("No build bonuses; not a post-purchase preview."),label+" actual shop source distinctions")
    for n in range(3):g.ui.show_inventory(g._view());_open_build_disclosures(g.ui)
    check(snapshot()==before,label+" repeated view/UI no catalog/build/stats/RNG/clock mutation")
    records.append({"mode":mode,"modified":modified,"weapon":id,"owned":own,"offer":offer})
   await process_frame
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"scope":"Independent expected-unit/value/generated-card/read-only assertions; controlled headless, not native appearance","checks":checks,"failures":failures,"records":records}
 print(JSON.stringify({"checks":checks,"failures":failures,"cases":records.size()}));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)

# External presentation-only adapter: expand the actual new disclosure buttons.
# Original assertions/counts/catalog adapters below remain unchanged; native input is separate.
func _disclosure_adapter_nodes(n:Node)->Array:
 var out:Array=[n]
 for c in n.get_children():out.append_array(_disclosure_adapter_nodes(c))
 return out
func _open_build_disclosures(ui:Node)->void:
 var found:Array=[]
 for n in _disclosure_adapter_nodes(ui.modal):
  if n is Button and n.toggle_mode and n.text.begins_with("SHOW "):
   if n.text.begins_with("SHOW WEAPON CARDS /") or n.text.begins_with("SHOW MODULE CARDS /") or n.text=="SHOW SYNERGIES / COOLDOWNS / STATS" or n.text=="SHOW MODULE STATUS DETAILS":
    found.append(n)
 assert(found.size()==3 or found.size()==4,"expected all new BUILD disclosures initially collapsed")
 for toggle in found:
  assert(toggle.is_visible_in_tree() and not toggle.disabled,"actual disclosure button accessible")
  toggle.button_pressed=true
  var content:Node=toggle.get_parent().get_child(toggle.get_index()+1)
  assert(toggle.text.begins_with("HIDE ") and content is VBoxContainer and content.is_visible_in_tree(),"real toggled handler expands content")
  for child in _disclosure_adapter_nodes(content):
   if child is Button and child.toggle_mode and child.text in ["SHOW STAT NOTES","SHOW ITEM DETAILS"]:
    assert(child.is_visible_in_tree() and not child.disabled,"existing nested disclosure accessible")
    child.button_pressed=true
    var nested:Node=child.get_parent().get_child(child.get_index()+1)
    assert(child.text.begins_with("HIDE ") and nested is VBoxContainer and nested.is_visible_in_tree(),"existing nested toggled handler expands content")
  for child in _disclosure_adapter_nodes(content):
   if child is Label:assert(child.is_visible_in_tree(),"prior label assertion must not pass on collapsed content")
 print("DISCLOSURE_ADAPTER_OPEN "+str(found.size()))
