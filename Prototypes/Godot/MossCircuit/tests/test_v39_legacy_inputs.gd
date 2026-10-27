extends SceneTree
## Author integrity checks for explicit test-only old-data setup, not gameplay acceptance.
const Legacy=preload("res://tests/support/v39_legacy_inputs.gd")
const Catalog=preload("res://tests/support/v39_B_then_A_catalog_projection.gd")
const BProjection=preload("res://tests/support/v39_B_catalog_projection.gd")
const Kits=preload("res://tests/support/v39_loadout_projection.gd")
var checks:int=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var raw_c:String=FileAccess.get_file_as_string("res://data/catalog.json")
 var raw_k:String=FileAccess.get_file_as_string("res://data/starting_loadouts.json")
 var original_c:Dictionary=g.catalog.duplicate(true);var original_k:Dictionary=g.starting_loadouts.duplicate(true)
 ck(g.catalog.weapons.size()==10 and g.catalog.items.size()==36 and g.starting_loadouts.loadouts.size()==5,"actual current loader before history")
 var intermediate:Dictionary=BProjection.project(g.catalog,raw_c)
 ck(intermediate.pass and intermediate.catalog.items.size()==33 and intermediate.bytes.sha256_text()=="67eb30bf64c36191f5e7609126da42b0195cb53840e00e60afa15ed55e13cccc","strict B intermediate preserves exact A bytes and33 items")
 var bad:Dictionary=g.catalog.duplicate(true);bad.weapons[0].damage+=1
 ck(not Catalog.project(bad,raw_c).pass,"reject unrelated legacy field mutation")
 bad=g.catalog.duplicate(true);bad.weapons[-1].damage+=1
 ck(not Catalog.project(bad,raw_c).pass,"reject new declaration field mutation")
 ck(not Catalog.project(g.catalog,raw_c+" ").pass,"reject catalog raw identity change")
 bad=g.starting_loadouts.duplicate(true);bad.loadouts[0].starting_scrap+=1
 ck(not Kits.project(bad,raw_k).pass,"reject original starter mutation")
 bad=g.starting_loadouts.duplicate(true);bad.loadouts[-1].starting_scrap+=1
 ck(not Kits.project(bad,raw_k).pass,"reject appended starter mutation")
 ck(not Kits.project(g.starting_loadouts,raw_k+" ").pass,"reject starter raw identity change")
 ck(g.catalog==original_c and g.starting_loadouts==original_k,"all projection negatives are read-only")
 var receipt:Dictionary=Legacy.install(g)
 ck(receipt.pass,"historical installer accepted exact current data")
 ck(g.catalog.weapons.size()==8 and g.catalog.items.size()==30 and g.catalog.mechanism_synergies.size()==12 and g.catalog.affinity_links.size()==12,"exact historical catalog sizes")
 ck(g.starting_loadouts.loadouts.map(func(x):return x.id)==["rivet","scatter","rail"],"exact historical starter order")
 g.catalog["__test_integrity_marker__"]=73
 ck(g.combat_frame.catalog.get("__test_integrity_marker__",-99)==73 and g.weapon_combat.catalog.get("__test_integrity_marker__",-99)==73,"all real Dictionary consumers share mutation")
 g.catalog.erase("__test_integrity_marker__")
 ck(g.combat_frame.catalog==g.catalog and g.weapon_combat.catalog==g.catalog,"marker removed from every real consumer")
 ck(g.effects.fracture_weapons==["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","bankshot_driver"] and g.effects.recoil_definition.is_empty(),"Effects historical cached definitions")
 ck(g.new_weapon_runtime.weapons.is_empty() and g.new_weapon_runtime.memory.is_empty() and g.new_weapon_runtime.collar.is_empty(),"new runtime does not retain current definitions")
 g._start_run(39)
 ck(g.build.weapons==["rivet_gun"] and g.build.coins==35 and g.state=="playing","historical default actual start")
 var next=load("res://scenes/main.tscn").instantiate();root.add_child(next);next.set_process(false)
 ck(next.catalog==original_c and next.starting_loadouts==original_k,"fresh actual main unaffected by historical instance")
 ck(FileAccess.get_file_as_string("res://data/catalog.json")==raw_c and FileAccess.get_file_as_string("res://data/starting_loadouts.json")==raw_k,"historical fixture never changes production source bytes")
 var helper=preload("res://tests/support/audio_teardown.gd").new();helper.prepare([g,next]);g.queue_free();next.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"author test-only historical installer integrity; not current gameplay acceptance"}))
 quit(0 if failures.is_empty() else 1)
