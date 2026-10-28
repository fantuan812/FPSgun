extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var result:Array=[n]
 for child in n.get_children():result.append_array(nodes(child))
 return result
func _initialize()->void:call_deferred("run")
func run()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).player
 var before_catalog:String=JSON.stringify(c)
 check(Rules.validate_catalog(c).is_empty(),"current fixed catalog valid")
 for bad_value in [null,{},[],[{}],c.synergies+[c.synergies[0]]]:
  var bad:Dictionary=c.duplicate(true);bad.synergies=bad_value
  check(not Rules.validate_catalog(bad).is_empty(),"invalid rule list rejected")
 for i in range(3):
  for key in ["id","tag","threshold","description"]:
   var bad:Dictionary=c.duplicate(true);bad.synergies[i].erase(key)
   check(not Rules.validate_catalog(bad).is_empty(),"missing fixed field rejected "+key)
  for value in [null,true,"3",0,2,4,3.5,INF,NAN]:
   var bad:Dictionary=c.duplicate(true);bad.synergies[i].threshold=value
   check(not Rules.validate_catalog(bad).is_empty(),"bad threshold rejected")
  for key in ["id","tag"]:
   var bad:Dictionary=c.duplicate(true);bad.synergies[i][key]="unknown"
   check(not Rules.validate_catalog(bad).is_empty(),"unknown fixed rule rejected")
 var reordered:Dictionary=c.duplicate(true);reordered.synergies.reverse()
 check(not Rules.validate_catalog(reordered).is_empty(),"fixed authority order validated")
 var profiles:Array=[
  [["rivet_gun"],{},[0,0,0],[0.0,0.0,0]],
  [["rail_lance"],{},[1,0,0],[0.0,0.0,0]],
  [["rail_lance","rail_lance"],{},[2,0,0],[0.0,0.0,0]],
  [["rail_lance","rail_lance","rail_lance"],{},[3,0,0],[.2,0.0,0]],
  [["rail_lance","rail_lance","rail_lance","rail_lance"],{},[4,0,0],[.2,0.0,0]],
  [["rail_lance"],{"capacitor":1},[2,0,0],[.25,0.0,0]],
  [["rail_lance"],{"capacitor":2},[3,0,0],[.7,0.0,0]],
  [["rail_lance"],{"capacitor":3},[4,0,0],[.95,0.0,0]],
  [["rivet_gun"],{"capacitor":3},[3,0,0],[.95,0.0,0]],
  [["orbit_saw"],{"gear":1},[0,2,0],[0.0,.25,0]],
  [["orbit_saw"],{"gear":2},[0,3,0],[0.0,.7,0]],
  [["orbit_saw","orbit_saw","orbit_saw","orbit_saw"],{},[0,4,0],[0.0,.2,0]],
  [["rivet_gun"],{"gear":3},[0,3,0],[0.0,.95,0]],
  [["scrap_shotgun"],{"pellet_pouch":1},[0,0,2],[0.0,0.0,1]],
  [["scrap_shotgun"],{"pellet_pouch":2},[0,0,3],[0.0,0.0,3]],
  [["scrap_shotgun","scrap_shotgun","scrap_shotgun"],{},[0,0,3],[0.0,0.0,1]],
  [["scrap_shotgun","scrap_shotgun","scrap_shotgun","scrap_shotgun"],{},[0,0,4],[0.0,0.0,1]],
  [["rail_lance","orbit_saw","scrap_shotgun"],{"capacitor":2,"gear":2,"pellet_pouch":2},[3,3,3],[.7,.7,3]]]
 for profile in profiles:
  var b:Dictionary=Rules.new_build(c);b.weapons=profile[0].duplicate();b.items=profile[1].duplicate()
  var before:String=JSON.stringify(b)
  var stats:Dictionary=Rules.derive(base,b,c)
  var rows:Array=Rules.tag_synergy_status(b,c)
  check(rows.size()==3,"exactly three progress rows")
  var expected_active:Array=[]
  for i in range(3):
   var row:Dictionary=rows[i]
   check(row.id==c.synergies[i].id and row.tag==c.synergies[i].tag and row.threshold==3,"fixed catalog identity")
   check(row.count==profile[2][i] and row.active==(profile[2][i]>=3),"unclamped copy counts/activation")
   check(row.description==c.synergies[i].description,"catalog effect description reused")
   if row.active:expected_active.append(row.name)
   var matches:int=0
   for id in b.weapons:
    if row.tag in Rules.catalog_entry(c,id).tags:matches+=1
   check(row.matching_weapons.size()==matches,"matching equipped slots not prerequisite")
  check(stats.synergies==expected_active,"existing active name/order preserved")
  check(is_equal_approx(stats.electric_bonus,profile[3][0]) and is_equal_approx(stats.melee_bonus,profile[3][1]) and stats.extra_pellets==profile[3][2],"exact intended once-only additive effects")
  check(Rules.tag_synergy_status(b,c)==rows and JSON.stringify(b)==before,"read-only idempotence")
  rows[0].count=999;rows[0].matching_weapons.append("fake")
  check(Rules.tag_synergy_status(b,c)[0].count==profile[2][0],"returned rows cannot mutate source")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 for mode in ["arena","rooms"]:
  game._title();game._select_mode(mode);game._start_run(86)
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for profile in [profiles[0],profiles[6],profiles[8],profiles[12],profiles[17]]:
    game.build.weapons=profile[0].duplicate();game.build.items=profile[1].duplicate();game._recompute()
    var before:String=JSON.stringify([game.build,game.stats,game.shop_offers,game.rng.state])
    var view:Dictionary=game._view();game.ui.show_inventory(view);_open_build_disclosures(game.ui);await process_frame;await process_frame
    var labels:Array=[]
    for node in nodes(game.ui.modal):
     if node is Label:labels.append(node.text)
    check("TAG SYNERGY PROGRESS" in labels and not "ACTIVE TAG SYNERGIES" in labels,"new progress heading replaces names-only section")
    for row in view.tag_synergy_status:
     var expected:String="%s / %s / %d / %d %s" % [row.name,"ACTIVE" if row.active else "INACTIVE",int(row.count),int(row.threshold),row.tag]
     check(expected in labels and row.description in labels and row.qualifier in labels,"complete row present "+row.id)
     if row.active and row.matching_weapons.is_empty():check(("Active, but no equipped %s weapon currently benefits." % row.tag) in labels,"active without matching weapon honestly shown")
    check(JSON.stringify([game.build,game.stats,game.shop_offers,game.rng.state])==before,"view/render doesn't mutate authority or RNG")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([game])
 game.queue_free();await process_frame
 await audio_teardown.finish(self)
 check(JSON.stringify(c)==before_catalog,"catalog bytes/data unchanged")
 print(JSON.stringify({"tag_synergy_progress_checks":checks,"failures":failures}))
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
