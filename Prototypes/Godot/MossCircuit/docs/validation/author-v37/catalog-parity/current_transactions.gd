extends SceneTree
## Independent controlled old-path projection. No temper action or new API call.
const Rules=preload("res://scripts/rules.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
var g
var cases:Array=[]
var failures:Array=[]
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
func snap()->Dictionary:
 if g.build.has("weapon_temper"):failures.append("unused path inserted metadata")
 return clean({"state":g.state,"build":g.build,"stats":g.stats,"clocks":g.weapon_clocks,"generation":g.shop_generation,"offers":g.shop_offers,"held":g.reserved_offer,"message":g.shop_message,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"origin":g.run.starting_loadout_id,"rig":{"slots":g.weapon_rig.slots,"generation":g.weapon_rig.generation,"clock":g.weapon_rig.visible_clock,"last_shot":g.weapon_rig.last_shot},"effects":{"active":g.effects.active,"epoch":g.effects.epoch,"sequence":g.effects.last_sequence,"cooldowns":g.effects.cooldowns,"echo":g.effects.echo_hits,"phase":g.effects.phase_charge,"shield":g.effects.shield,"feedback":g.effects.feedback_armed}})
func offer(id:String,replace:int=-1)->void:
 var entry:Dictionary=Rules.catalog_entry(g.catalog,id).duplicate(true)
 entry.sold=false;g.shop_offers=[entry]
 if not g._buy(0,g.shop_generation,replace):failures.append("controlled offer failed "+id)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)

 for mode in ["arena","rooms"]:
  for kit in ["rivet","scatter","rail"]:
   g._title();g._select_mode(mode);g._start_run(128,kit)
   var starter:String=g.build.weapons[0]
   var steps:Array=[{"label":"factory","state":snap()}]
   g.build.coins=999;g.build.coin_fraction=.3;g._open_shop()
   g._reserve_offer(0,g.shop_generation);steps.append({"label":"reserved","state":snap()})
   g._release_offer(g.reserved_offer.token,g.shop_generation)
   offer(starter);g.weapon_clocks=[.31,-.2];g._sync_weapon_rig()
   for i in range(2):
    g.weapon_rig.slots[i].age=.07+float(i)*.12;g.weapon_rig.slots[i].aim=Vector2.from_angle(.3+float(i)*.4)
   g._move_weapon(1,-1,g.shop_generation,starter);steps.append({"label":"same-id-copy-move","state":snap()})
   offer("shock_mortar");offer("return_disc")
   for i in range(IDS.size()):
    offer(IDS[i],i%4);steps.append({"label":"replace-"+str(i),"state":snap()})
   g._sell_weapon(1,g.shop_generation);steps.append({"label":"sell","state":snap()})
   offer("power_coil");g._refresh_shop(g.shop_generation);steps.append({"label":"item-and-refresh","state":snap()})
   g._leave_shop(g.shop_generation);steps.append({"label":"deploy","state":snap()})
   g._start_run(128,g.run.starting_loadout_id);steps.append({"label":"same-origin-reset","state":snap()})
   cases.append({"mode":mode,"kit":kit,"steps":steps})
   await process_frame
 var audio_teardown=preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"scope":"Controlled no-temper old authority projection; six kit/mode routes, actual reserve/release/buy/replace/sell/order/item/refresh/deploy/reset. Offers are deliberately supplied from catalog; not ordinary acquisitions. Presentation object IDs and UI metadata excluded; live build dictionary is complete and must have no weapon_temper key.","cases":cases,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"cases":cases.size(),"failures":failures,"case_sha256":JSON.stringify(cases).sha256_text()}))
 quit(0 if failures.is_empty() else 1)
