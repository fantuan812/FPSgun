extends SceneTree
const EncounterHistory=preload("res://tests/support/v38_encounter_projection.gd")
const CatalogHistory=preload("res://tests/support/v36_catalog_projection.gd")
const Rules=preload("res://scripts/rules.gd")
const Held=preload("res://scripts/gameplay/shop_reservation.gd")
const ITEM_IDS=["power_coil","cooling_fan","iron_plate","moss_patch","running_boots","salvage_magnet","lucky_chip","lens","capacitor","gear","pellet_pouch","recycler","arc_relay","kill_cell","dash_resin","mirror_shell","thorn_crown","blood_valve","scrap_mine","pulse_boots","return_spool","blast_fuse","echo_chamber","gravity_anchor","medic_seed","phase_capacitor","fracture_coil","bounce_guide","feedback_diode"]
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func projection_negatives(c:Dictionary,raw:String)->void:
 var original:Dictionary=c.duplicate(true)
 for which in range(9):
  var bad:Dictionary=c.duplicate(true)
  match which:
   0:bad.items[-1].price=29
   1:bad.items[0].price+=1
   2:bad.items[-1].return_pickup_limit=4
   3:bad.items.append(bad.items[-1].duplicate(true))
   4:bad.mechanism_synergies[-1].description="unreviewed extra reward"
   5:bad.affinity_links[-1]=["rail_lance","scavenger_reel"]
   6:bad.items.reverse()
   7:bad.mechanism_synergies.append(bad.mechanism_synergies[-1].duplicate(true))
   8:bad.affinity_links.append(bad.affinity_links[-1].duplicate())
  ck(not CatalogHistory.project(bad,raw).get("pass",false),"history projector rejects unrelated/undeclared mutation "+str(which))
 ck(not CatalogHistory.project(c,raw+" ").get("pass",false),"history projector rejects altered original raw bytes")
 ck(not CatalogHistory.project(c,raw.replace('"return_pickup_limit": 3','"return_pickup_limit": 4')).get("pass",false),"history projector rejects nonmatching new raw insertion")
 ck(c==original,"history projection is input read-only")
func _initialize()->void:call_deferred("run")
func run()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var expanded_bytes:String=FileAccess.get_file_as_string("res://data/catalog.json")
 var a_history:Dictionary=preload("res://tests/support/v39_B_then_A_catalog_projection.gd").project(c,expanded_bytes)
 if not a_history.pass:push_error(str(a_history.errors));quit(1);return
 var history:Dictionary=CatalogHistory.project(c,expanded_bytes)
 ck(history.get("pass",false),"exact v36 append-only declaration and original v35 byte identity")
 var catalog_bytes:String=history.bytes
 projection_negatives(c,expanded_bytes)
 var declared_profile:String='  "weapon_tempering": {\n    "max_tier": 1,\n    "primary_damage_multiplier": 1.6\n  },\n'
 ck(catalog_bytes.sha256_text()=="317a2d343ba1a005cd44cc1c2ee91e894adf059d77e57c24f7a5ee9439ec56a0","exact reviewed v33 catalog bytes, including only the authored tempering profile")
 ck(catalog_bytes.count(declared_profile)==1 and catalog_bytes.replace(declared_profile,"").sha256_text()=="88002883c5f1141e8d9adf2f95418c81b52b397a44feee46946876bbf8a984d7","exact v27 bytes after removing ONLY the declared v33 profile: all IDs/order/prices/weights/links")
 ck(a_history.catalog.items.map(func(e):return e.id)==ITEM_IDS+["scavenger_reel"],"exact ordered 30 module IDs with old order preserved")
 ck(a_history.catalog.weapons.map(func(e):return e.id)==["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"],"exact ordered eight weapon IDs")
 ck(FileAccess.get_sha256("res://data/balance.json")=="180c521a222f737a93498768acccdb98e6bb93f606de7e6719f88261eb41815c","six existing upgrades and economy unchanged")
 var encounter_history:Dictionary=EncounterHistory.project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))
 ck(encounter_history.get("pass",false),"strict declared v38 row/wave/Rooms append and original raw identity")
 ck(encounter_history.encounter_bytes.sha256_text()=="853bb3699bb05c2ed1eb7d1c8dc3e51844428c233ffa3127ac035a2762a3f356","exact v32 encounter bytes; reviewed Amber Ram brace/copy only")
 ck(encounter_history.room_bytes.sha256_text()=="4a0067faa08241d91042505d72b3a027956ef27571710d74d8559462ac2c5131","Rooms stages/rewards unchanged")
 var b:Dictionary=Rules.new_build(c)
 var offer:Dictionary={"id":"rail_lance","sold":false,"weight":1.0,"weight_multiplier":1.0,"bias_reasons":["original"]}
 var good:Dictionary=Held.create(b,c,offer,3,42)
 ck(good=={"id":"rail_lance","price":42,"slot":3,"token":42,"offer":offer},"frozen record schema and constants")
 ck(Held.invalid_reason(b,c,good).is_empty() and Held.matches(good,"rail_lance") and not Held.matches(good,"power_coil"),"valid association recognizes only held ID")
 var mutations:Dictionary={"id":["unknown",null,true,{},[],4],"offer":[null,true,[],"x",4,{}, {"id":"power_coil","sold":false}],"price":[null,true,{},[],"42",-1,42.5],"slot":[null,true,{},[],"3",-1,4,3.0],"token":[null,true,{},[],"42",0,-1,42.0]}
 for field in mutations:
  for value in mutations[field]:
   var bad:Dictionary=good.duplicate(true);bad[field]=value
   ck(not Held.invalid_reason(b,c,bad).is_empty(),"malformed "+field+" rejects "+str(value))
   ck(Held.matches(bad,"rail_lance"),"original visible card association survives malformed "+field)
   var d:Dictionary=Held.describe(b,c,bad)
   ck(not d.valid and not d.invalid_reason.is_empty(),"malformed describe is safe/non-valid "+field)
 for key in ["price","max_stack"]:
  for value in [null,true,{},[],"1",-1,1.5,INF,NAN]:
   var broken:Dictionary=c.duplicate(true);Rules.catalog_entry(broken,"rail_lance")[key]=value
   ck(Held.create(b,broken,offer,0,1).is_empty(),"invalid catalog "+key+" rejected before comparison "+str(value))
 for value in [null,true,{},[],"false",0,1]:
  var malformed:Dictionary=offer.duplicate(true);malformed.sold=value
  ck(Held.create(b,c,malformed,0,1).is_empty(),"non-boolean sold rejected "+str(value))
 for id in [null,true,{},[],4,"unknown"]:
  var malformed:Dictionary=offer.duplicate(true);malformed.id=id
  ck(Held.create(b,c,malformed,0,1).is_empty(),"invalid original ID rejected "+str(id))
 # The exact actual _buy/_view path must remain atomic and leave RELEASE accessible.
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for field in mutations:
  for value in mutations[field]:
   g._title();g._start_run(28002);g.build.coins=100;g._open_shop();g.shop_offers=[offer.duplicate(true)]
   g._reserve_offer(0,g.shop_generation);g.reserved_offer[field]=value
   var before:Dictionary={"build":g.build.duplicate(true),"held":g.reserved_offer.duplicate(true),"gen":g.shop_generation,"offers":g.shop_offers.duplicate(true),"rng":g.shop_rng.state}
   ck(not g._buy(0,g.shop_generation),"actual malformed "+field+" purchase rejected")
   ck(g.build==before.build and g.reserved_offer==before.held and g.shop_generation==before.gen and g.shop_offers==before.offers and g.shop_rng.state==before.rng,"actual malformed "+field+" full transaction atomic")
   var v:Dictionary=g._view()
   ck(v.offers[0].reserved and not v.offers[0].can_buy and not v.reserved_offer.valid,"malformed current card still marked/releasable, never buyable")
   if field!="token":ck(g._release_offer(g.reserved_offer.token,g.shop_generation),"valid stable token releases malformed "+field+" explicitly")
   await process_frame
 # Catalog deletion is the other unknown-ID form; current visible held metadata is safe.
 g._title();g._start_run(28002);g.build.coins=100;g._open_shop();g.shop_offers=[offer.duplicate(true)];g._reserve_offer(0,g.shop_generation)
 g.catalog=g.catalog.duplicate(true);g.catalog.weapons=g.catalog.weapons.filter(func(e):return e.id!="rail_lance")
 var coins:int=g.build.coins;var gen:int=g.shop_generation
 ck(not g._buy(0,gen) and g.build.coins==coins and g.shop_generation==gen,"removed catalog ID never charges")
 ck(g._view().offers[0].reserved and not g._view().offers[0].can_buy,"removed catalog entry has safe reserved fallback card")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Strict historical v27 catalog-byte preservation after verified exact v36 item/pair/link projection and reviewed v33 profile removal, and reviewed v32 encounter preservation after strict declared v38 enemy/wave/Rooms append reversal plus malformed reservation/catalog type guards and actual held-card association. Corruption is controlled diagnostic input, not an observed ordinary-run occurrence."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
