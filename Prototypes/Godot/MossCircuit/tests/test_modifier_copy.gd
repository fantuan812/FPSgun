extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var checks:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func tree_nodes(node:Node)->Array:
 var result:Array=[node]
 for child in node.get_children():result.append_array(tree_nodes(child))
 return result
func labels(node:Node)->Array:
 var result:Array=[]
 for child in tree_nodes(node):
  if child is Label:result.append(child.text)
 return result
func entry(c:Dictionary,id:String)->Dictionary:return Rules.catalog_entry(c,id)
func _initialize()->void:call_deferred("run")
func run()->void:
 var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v21_modifier_baseline.json"))
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var balance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
 var changes:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/V22_MODIFIER_COPY.json"))
 check(baseline.baseline_manifest_sha256=="6db84a927b27cebfe16770a70036fe6b8979b9e13fa11c039c60d678203fcf25","pinned immutable v21 baseline")
 check(changes.allowed_text_changes.size()==4,"exactly four reviewed copy fields")
 var masked_catalog:Dictionary=catalog.duplicate(true)
 var masked_balance:Dictionary=balance.duplicate(true)
 # v23 adds exactly one reviewed weapon/module/pair/link; old definitions remain strict.
 var additions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/V23_CATALOG_ADDITIONS.json"))
 check(entry(catalog,"bankshot_driver")==additions.weapon and entry(catalog,"bounce_guide")==additions.item,"exact v23 additions separately asserted")
 check(catalog.version==5,"explicit new content version")
 var v26:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/V26_CATALOG_ADDITIONS.json"))
 check(entry(catalog,"feedback_diode")==v26.item,"exact v26 module separately asserted")
 check(masked_catalog.mechanism_synergies[-1]==v26.pair and masked_catalog.affinity_links[-1]==v26.link,"only reviewed v26 appended pair/link")
 masked_catalog.items=masked_catalog.items.filter(func(x):return x.id!="feedback_diode")
 masked_catalog.mechanism_synergies.pop_back();masked_catalog.affinity_links.pop_back()
 masked_catalog.version=baseline.catalog.version
 masked_catalog.weapons=masked_catalog.weapons.filter(func(x):return x.id!="bankshot_driver")
 masked_catalog.items=masked_catalog.items.filter(func(x):return x.id!="bounce_guide")
 check(masked_catalog.mechanism_synergies[-1]==additions.pair and masked_catalog.affinity_links[-1]==additions.link,"only reviewed appended pair/link")
 masked_catalog.mechanism_synergies.pop_back();masked_catalog.affinity_links.pop_back()
 var paths:Array=[]
 for change in changes.allowed_text_changes:
  check(change.field=="description","only description field")
  paths.append(change.file+":"+change.id)
  if change.file=="data/catalog.json":
   check(change.id in ["power_coil","cryo_sprayer","fracture_coil"],"reviewed catalog entry")
   check(entry(baseline.catalog,change.id).description==change.before,"baseline copy "+change.id)
   check(entry(catalog,change.id).description==change.after,"new copy "+change.id)
   # Restore only the reviewed field. Every other field must equal the frozen baseline.
   entry(masked_catalog,change.id).description=change.before
  else:
   check(change.file=="data/balance.json" and change.id=="haste","reviewed upgrade entry")
   var old:Dictionary=baseline.balance.upgrades.filter(func(u):return u.id=="haste")[0]
   var current:Dictionary=balance.upgrades.filter(func(u):return u.id=="haste")[0]
   check(old.description==change.before,"baseline Rapid copy")
   check(current.description==change.after,"new Rapid copy")
   for upgrade in masked_balance.upgrades:
    if upgrade.id=="haste":upgrade.description=change.before
 paths.sort()
 check(paths==["data/balance.json:haste","data/catalog.json:cryo_sprayer","data/catalog.json:fracture_coil","data/catalog.json:power_coil"],"exact allowlist without duplicates")
 check(masked_catalog==baseline.catalog,"all pre-v23 catalog IDs/numbers/tags/weights/other text exact")
 check(masked_balance==baseline.balance,"all balance numbers/rules/other upgrade text exact")
 check(Rules.validate_catalog(catalog).is_empty(),"catalog still valid")
 check(entry(catalog,"power_coil").description=="Weapon damage +15%; fixed module damage unchanged.","damage scope explicit")
 check(entry(catalog,"cryo_sprayer").description.contains("Instant") and entry(catalog,"cryo_sprayer").description.contains("projectile bonuses do not"),"cone no-projectile scope explicit")
 check(entry(catalog,"fracture_coil").description.contains("fixed 16") and entry(catalog,"fracture_coil").description.contains("weapon bonuses do not scale"),"fixed module scope explicit")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
 for size in [Vector2i(960,540),Vector2i(1280,720)]:
  root.size=size
  for mode in ["arena","rooms"]:
   game._title();game._select_mode(mode);game._start_run(433);game.build.coins=100;game._open_shop()
   for id in ["power_coil","cryo_sprayer","fracture_coil"]:
    var view:Dictionary=game._view();var offer:Dictionary=entry(catalog,id).duplicate(true)
    offer.merge({"index":0,"sold":false,"can_buy":true});view.offers=[offer]
    var before:String=JSON.stringify(view)
    game.ui.show_shop(view);await process_frame;await process_frame
    check(str(offer.description) in labels(game.ui.modal),mode+" exact shop description "+id)
    var buy:Button
    for node in tree_nodes(game.ui.modal):
     if node is Button and node.text.begins_with("BUY"):buy=node;break
    check(buy!=null and not buy.disabled,mode+" first BUY enabled "+id)
    if buy!=null:
     var scroll:Node=buy.get_parent()
     while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
     check(scroll!=null,"offer scroll found")
     if scroll!=null:
      scroll.scroll_vertical=0;await process_frame
      var rect:Rect2=buy.get_global_rect();var clip:Rect2=scroll.get_global_rect()
      check(rect.position.y>=clip.position.y and rect.end.y<=clip.end.y,mode+" BUY remains initially visible "+id)
    check(JSON.stringify(view)==before,"copy render does not mutate view")
   var rapid:Dictionary=balance.upgrades.filter(func(u):return u.id=="haste")[0]
   game.ui.show_upgrade([rapid],17);await process_frame;await process_frame
   check("Attack rate +15% (additive)." in labels(game.ui.modal),mode+" upgrade shows additive rate")
   check(not "Fire interval -15%" in labels(game.ui.modal),"old inaccurate rate absent")
   var view:Dictionary=game._view();view.weapons=[entry(catalog,"cryo_sprayer").duplicate(true)];view.weapons[0].slot=0
   view.items=[entry(catalog,"power_coil").duplicate(true),entry(catalog,"fracture_coil").duplicate(true)]
   for item in view.items:item.count=1
   game.ui.show_inventory(view);await process_frame;await process_frame
   for id in ["power_coil","cryo_sprayer","fracture_coil"]:check(entry(catalog,id).description in labels(game.ui.modal),"shared inventory exact copy "+id)
 game.queue_free();await process_frame
 print(JSON.stringify({"modifier_copy_checks":checks,"failures":failures,"scope":"v22 four-field copy preservation within the old catalog; exact v23/v26 additions separately asserted; native appearance separate"}))
 quit(0 if failures.is_empty() else 1)
