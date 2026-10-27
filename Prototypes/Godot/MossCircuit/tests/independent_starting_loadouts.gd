extends SceneTree
## Independent controlled registry/start/reset checks; optional output argument only.
const Rules=preload("res://scripts/rules.gd")
const Kits=preload("res://scripts/gameplay/starting_loadouts.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Readout=preload("res://scripts/weapon_readout.gd")
const EXPECT={"rivet":{"weapon":"rivet_gun","coins":35,"damage":15.0,"interval":.4,"range":500.0,"count":1},"scatter":{"weapon":"scrap_shotgun","coins":23,"damage":9.0,"interval":.85,"range":300.0,"count":5},"rail":{"weapon":"rail_lance","coins":17,"damage":30.0,"interval":1.15,"range":650.0,"count":1}}
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func clean(v:Variant)->Variant:
 if v is Object:return {"instance_id":v.get_instance_id()} if is_instance_valid(v) else {"freed":true}
 if v is Array:
  var a:Array=[]
  for x in v:a.append(clean(x))
  return a
 if v is Dictionary:
  var d:Dictionary={}
  for k in v:d[k]=clean(v[k])
  return d
 return v
func props(obj:Object)->Dictionary:
 var d:Dictionary={}
 for p in obj.get_script().get_script_property_list():d[p.name]=clean(obj.get(p.name))
 return d
func rngs()->Array:return [g.rng.state,g.loot_rng.state,g.shop_rng.state]
func snap()->Dictionary:
 return {"run":props(g.run),"combat":props(g.combat),"effects":props(g.effects),"effect_sequence":g.effect_runtime.sequence,"rng":rngs(),"selected":g.selected_loadout_id,"title_generation":g.title_generation,"rig":{"slots":clean(g.weapon_rig.slots),"generation":g.weapon_rig.generation,"clock":g.weapon_rig.visible_clock,"last_shot":g.weapon_rig.last_shot.duplicate(true)}}
func title(mode:String="arena")->void:
 g._title();g._select_mode(mode)
func select(id:String)->void:
 if g.selected_loadout_id!=id:ck(g._select_starting_loadout(id,g.title_generation),"select "+id)
func bad_select(id:Variant,gen:Variant,label:String)->void:
 var before:=snap();ck(not g._select_starting_loadout(id,gen),label+" rejects");ck(same(snap(),before),label+" atomic")
func bad_start(id:Variant,gen:Variant,seed_value:Variant,label:String)->void:
 var before:=snap();ck(not g._start_selected_loadout(id,gen,seed_value),label+" rejects");ck(same(snap(),before),label+" atomic")
func fresh(id:String,seed_value:int,label:String)->void:
 var e:Dictionary=EXPECT[id]
 ck(g.build.weapons==[e.weapon] and g.build.coins==e.coins and g.build.coins is int,label+" exact initial kit/int scrap")
 ck(g.build.items=={} and g.build.levels=={} and g.build.revision==0 and same(g.build.coin_fraction,0.0),label+" no hidden modifiers/fraction/revision")
 ck(g.weapon_clocks==[0.0] and g.level==1 and g.xp==0 and g.kills==0 and g.elapsed==0 and g.wave==1,label+" fresh progression/clocks")
 ck(g.stats.hp==100 and g.stats.max_hp==100 and g.stats.speed==165 and g.stats.damage_bonus==0 and g.stats.haste==0,label+" ordinary base authority")
 ck(g.run.starting_loadout_id==id and g.run_seed==seed_value and g.state=="playing",label+" starter snapshot/seed")
 ck(g.bullets.is_empty() and g.pending_blasts.is_empty() and g.enemies.is_empty() and g.enemy_bullets.is_empty() and g.pickups.is_empty() and g.hazards.is_empty() and g.effect_visuals.is_empty(),label+" transients clear")
 ck(g.reserved_offer.is_empty() and g.shop_offers.is_empty() and not g.shop_pending and g.upgrade_pending==0,label+" no held stock/extra choice/shop")
 ck(not g.effects.feedback_armed and g.effects.active.is_empty() and g.effects.cooldowns.is_empty(),label+" no module allowance/cooldown")
 var expected_rng:Array=[]
 for n in [seed_value,seed_value^58349,seed_value^92137]:
  var r:=RandomNumberGenerator.new();r.seed=n;expected_rng.append(r.state)
 ck(rngs()==expected_rng,label+" no selection/factory random draw")
 var view:Dictionary=g._view();ck(view.starting_loadout.id==id and view.weapons.size()==1 and view.weapons[0].id==e.weapon,label+" origin distinct from current gear")
 var read:Dictionary=view.weapons[0].weapon_readout
 ck(read.damage==e.damage and read.interval==e.interval and read.reach==e.range,label+" shared current numbers")
 var before:=snap();view.starting_loadout.weapon="tampered";view.starting_loadout.starting_scrap=999
 ck(same(snap(),before) and g._view().starting_loadout.weapon==e.weapon,label+" detached origin view")
func schema()->void:
 var original:Dictionary=g.starting_loadouts.duplicate(true);var catalog:Dictionary=g.catalog.duplicate(true)
 ck(original.default_id=="rivet" and original.loadouts.map(func(r):return r.id)==["rivet","scatter","rail"],"exact shipped starter IDs/order")
 ck(Kits.validate(original,catalog).is_empty(),"shipped parsed registry valid")
 for id in EXPECT:
  var row:Dictionary=Kits.entry(original,catalog,id);var e:Dictionary=EXPECT[id]
  ck(row.weapon==e.weapon and row.starting_scrap==e.coins and row.starting_scrap is int,"normalized row "+id)
  var b:Dictionary=Kits.make_build(original,catalog,id);var expect:Dictionary=Rules.new_build(catalog);expect.weapons=[e.weapon];expect.coins=e.coins
  ck(same(b,expect),"factory only changes reviewed weapon/scrap "+id)
  row.weapon="tampered";b.weapons.append("tampered")
  ck(g.starting_loadouts==original and g.catalog==catalog and Kits.entry(original,catalog,id).weapon==e.weapon,"detached row/build "+id)
 ck(same(Kits.make_build(original,catalog,"rivet"),Rules.new_build(catalog)),"default factory exact bytes")
 for bad in [null,true,false,0,0.5,"bad",[],Vector2.ONE]:ck(not Kits.validate(bad,catalog).is_empty(),"wrong registry root")
 for key in ["version","default_id","loadouts"]:
  var d:Dictionary=original.duplicate(true);d.erase(key);ck(not Kits.validate(d,catalog).is_empty(),"missing "+key)
 for bad in [null,true,false,"1",0,2,1.1,INF,NAN,{},[]]:
  var d:Dictionary=original.duplicate(true);d.version=bad;ck(not Kits.validate(d,catalog).is_empty(),"bad registry version")
 for bad in [null,true,0,"scatter","missing",StringName("rivet"),{},[]]:
  var d:Dictionary=original.duplicate(true);d.default_id=bad;ck(not Kits.validate(d,catalog).is_empty(),"bad default")
 for rows in [[],{},true,"rows",[null],[true],[0],[[]]]:
  var d:Dictionary=original.duplicate(true);d.loadouts=rows;ck(not Kits.validate(d,catalog).is_empty(),"bad rows")
 var too_many:Dictionary=original.duplicate(true)
 for i in range(6):
  var row:Dictionary=original.loadouts[1].duplicate(true);row.id="extra"+str(i);too_many.loadouts.append(row)
 ck(not Kits.validate(too_many,catalog).is_empty(),"more than eight rows rejected")
 var missing:Dictionary=original.duplicate(true);missing.loadouts.remove_at(0);ck(not Kits.validate(missing,catalog).is_empty(),"missing default row")
 for key in ["id","name","strength","limitation","weapon","starting_scrap"]:
  var d:Dictionary=original.duplicate(true);d.loadouts[1].erase(key);ck(not Kits.validate(d,catalog).is_empty(),"missing row "+key)
 for key in ["id","name","strength","limitation"]:
  for bad in [null,true,1,"","   ",{},[],StringName("x")]:
   var d:Dictionary=original.duplicate(true);d.loadouts[1][key]=bad;ck(not Kits.validate(d,catalog).is_empty(),"invalid row text "+key)
 for bad in [null,true,1,"missing","power_coil",["rivet_gun"],{},StringName("rivet_gun")]:
  var d:Dictionary=original.duplicate(true);d.loadouts[1].weapon=bad;ck(not Kits.validate(d,catalog).is_empty(),"invalid weapon reference")
 for bad in [null,true,false,"23",-1,23.5,1000001,INF,-INF,NAN,{},[]]:
  var d:Dictionary=original.duplicate(true);d.loadouts[1].starting_scrap=bad;ck(not Kits.validate(d,catalog).is_empty(),"invalid scrap")
 for valid in [0,0.0,23,23.0,1000000,1000000.0]:
  var d:Dictionary=original.duplicate(true);d.loadouts[1].starting_scrap=valid;ck(Kits.validate(d,catalog).is_empty() and Kits.make_build(d,catalog,"scatter").coins==int(valid),"finite integral scrap accepted")
 for field in ["id","weapon","starting_scrap"]:
  var d:Dictionary=original.duplicate(true);d.loadouts[0][field]="not-rivet" if field=="id" else ("rail_lance" if field=="weapon" else 34)
  ck(not Kits.validate(d,catalog).is_empty(),"legacy default mismatch "+field)
 var duplicate:Dictionary=original.duplicate(true);duplicate.loadouts[1].id="rivet";ck(not Kits.validate(duplicate,catalog).is_empty(),"duplicate IDs")
 for bad in [null,true,1,"missing",StringName("rivet"),{},[]]:
  ck(Kits.entry(original,catalog,bad).is_empty() and Kits.make_build(original,catalog,bad).is_empty(),"unknown/wrong lookup no fallback")
 var previews:Array=Kits.previews(original,catalog);ck(previews.size()==3,"three preview rows")
 for row in previews:
  ck(row.weapon_readout==Readout.describe(Rules.catalog_entry(catalog,row.weapon),{},false),"preview shared base readout")
 previews[0].weapon_readout.damage=999;previews[1].weapon="tampered"
 ck(original==g.starting_loadouts and catalog==g.catalog and Kits.previews(original,catalog)[0].weapon_readout.damage==15,"previews detached/no catalog mutation")
func actual_fire(id:String,mode:String)->void:
 g._start_run(31415,id);g.combat_frame.area=g.config.arena
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(120,0));e.hp=1000;e.max_hp=1000;e.speed=0;e.cooldown_left=999
 Runtime.step(g.combat_frame,.001)
 var x:Dictionary=EXPECT[id]
 ck(g.bullets.size()==x.count and g.bullets.all(func(b):return b.weapon==x.weapon and b.damage==x.damage and b.slot==0),mode+id+" actual scheduled projectile identity/count/damage")
 ck(is_equal_approx(g.weapon_clocks[0],x.interval),mode+id+" actual schedule interval")
 ck(g.weapon_rig.slots.size()==1 and g.weapon_rig.slots[0].id==x.weapon,mode+id+" actual starter hand rig")
 for b in g.bullets:g.weapon_combat.advance_bullet(b,.4)
 ck(e.hp<1000 and e.get("last_source","")=="primary",mode+id+" actual existing collision deals primary damage")
 if id=="scatter":ck(e.hp>=955 and fmod(1000-e.hp,9.0)==0,"scatter per-pellet hits not promised all five")
 else:ck(e.hp==1000-x.damage,"single primary exact contact damage "+id)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 schema()
 for mode in ["arena","rooms"]:
  for id in EXPECT:
   title(mode);select(id)
   for seed_value in [0,128,433]:
    g._title();var gen:int=g.title_generation
    ck(g._start_selected_loadout(id,gen,seed_value),mode+id+" visible start accepted")
    fresh(id,seed_value,mode+id+str(seed_value));var current:=snap()
    ck(not g._start_selected_loadout(id,gen,seed_value) and same(snap(),current),"duplicate start cannot reset live run")
   actual_fire(id,mode)
   # Changing current equipment/economy must not redefine retry origin.
   g._open_shop();g.build.coins=200;var other:String="rail_lance" if id=="rivet" else "rivet_gun"
   var offer:Dictionary=Rules.weighted_pool(g.build,g.catalog).filter(func(w):return w.id==other)[0].duplicate(true);offer.sold=false;g.shop_offers=[offer]
   ck(g._buy(0,g.shop_generation),"real purchase before reset "+id)
   g.bullets.clear();g.pending_blasts.clear();ck(g._move_weapon(0,1,g.shop_generation,EXPECT[id].weapon),"real reorder before reset "+id)
   ck(g._sell_weapon(1,g.shop_generation) and g.build.weapons==[other],"sell original starter with another owned "+id)
   ck(g.run.starting_loadout_id==id and g._view().starting_loadout.id==id,"origin survives absent original gear "+id)
   g.build.levels={"damage":2,"health":1};g.build.items={"feedback_diode":1};g._recompute();g.build.coin_fraction=.3
   g._finish(true);g.selected_loadout_id="rail" if id!="rail" else "scatter"
   g._on_intent("retry",{});fresh(id,31415,mode+id+" retry snapshot not draft/currentgear")
   g._finish(false);g._on_intent("new_seed",{});fresh(id,31416,mode+id+" newseed snapshot")
   g._title();select(id);g._on_intent("seed_changed",{"seed":98765});var before:=snap()
   for pair in [["settings","close_settings"],["codex","close_codex"]]:
    g._on_intent(pair[0],{});g._on_intent(pair[1],{});ck(g.selected_loadout_id==id and g.run_seed==98765 and g.state=="title","title submenu preserves draft/seed")
   ck(g.title_generation>before.title_generation,"returning title advances generation")
   g._select_mode("rooms" if mode=="arena" else "arena");ck(g.selected_loadout_id==id and g.run_seed==98765,"mode selection retains draft/seed")
   await process_frame
  title(mode);select("rivet");g._on_intent("seed_changed",{"seed":2468})
  # A title selection must not call cleanup-bearing _title, even in populated controlled state.
  var live:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(120,0));live.hp=999
  g.bullets=[{"life":1.0,"sentinel":"keep"}];g.pending_blasts=[{"delay":.5,"sentinel":"keep"}];g.reserved_offer={"sentinel":"keep"};g.effects.feedback_armed=true
  var before:=snap();ck(g._select_starting_loadout("scatter",g.title_generation),"different draft accepted")
  var after:=snap();after.selected=before.selected;after.title_generation=before.title_generation
  ck(same(after,before),"selection changes only draft/titlegeneration, no cleanup or RNG")
  var gen:int=g.title_generation
  bad_select("scatter",gen,"same selected no-op");bad_select("rail",gen-1,"stale selected");bad_start("rail",gen,2468,"wrong displayed kit");bad_start("scatter",gen-1,2468,"stale start")
  for bad in [null,true,false,0,0.0,"0",{},[],StringName("scatter")]:
   bad_select(bad,gen,"bad selection ID");bad_start(bad,gen,2468,"bad start ID")
  for bad in [null,true,false,0.0,str(gen),{},[],StringName(str(gen))]:
   bad_select("rail",bad,"bad selection generation");bad_start("scatter",bad,2468,"bad start generation")
  for bad in [null,true,false,2468.0,"2468",{},[],Vector2.ZERO]:bad_start("scatter",gen,bad,"bad seed")
  for state_value in ["playing","paused","shop","inventory","upgrade","settings","codex","room_clear","dead","won"]:
   g.state=state_value;bad_select("rail",gen,"wrong state selection "+state_value);bad_start("scatter",gen,2468,"wrong state start "+state_value)
  g.state="title"
  for bad in [null,true,17,"missing",StringName("rivet"),{},[]]:
   before=snap();ck(not g._start_run(999,bad) and same(snap(),before),"explicit invalid direct start before cleanup")
  # Surplus caller fields never create equipment or currency; legacy call stays Rivet.
  g._on_intent("start_loadout",{"id":"scatter","generation":gen,"seed":99,"coins":99999,"weapon":"bankshot_driver","items":{"power_coil":99}});fresh("scatter",99,"caller extras ignored")
  g._title();select("rail");ck(g._start_run(99),"legacy one-argument call succeeds");fresh("rivet",99,"legacy direct remains Rivet regardless draft")
  g._title();g._on_intent("start",{"seed":100});fresh("rivet",100,"legacy intent remains Rivet")
  await process_frame
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"scope":"Controlled registry, strict actual title intents, all three starter initialization and original-kit retry after actual buy/reorder/sale, both modes, shared scheduled fire/collision and read-only origin. Not native or ordinary acquisition/balance evidence.","checks":checks,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
