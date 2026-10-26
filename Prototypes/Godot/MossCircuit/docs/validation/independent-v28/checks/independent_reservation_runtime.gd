extends SceneTree
## Contract-first black-box shop tests. Controlled state setup is not ordinary acquisition.
const Rules=preload("res://scripts/rules.gd")
class SkipShop:
 extends "res://scripts/modes/arena_mode.gd"
 func resolution(session:RefCounted,world:RefCounted,config:Dictionary)->Dictionary:
  var d:Dictionary=super.resolution(session,world,config)
  d.shop=false;d.upgrades=0
  return d
var g
var original_catalog:Dictionary
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func safe_state()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.active.duplicate(true),g.effects.cooldowns.duplicate(true),g.effects.feedback_armed,g.effects.shield,g.effects.echo_hits,g.effects.phase_charge]}
func snapshot()->Dictionary:
 return {"authority":safe_state(),"state":g.state,"generation":g.shop_generation,"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true)}
func setup(mode:String="arena",slot:int=0,id:String="rail_lance")->void:
 g._title();g.catalog=original_catalog.duplicate(true);g._select_mode(mode);g._start_run(28001)
 g.build.coins=200;g._recompute();g._open_shop()
 var ids:Array=["rail_lance","power_coil","mirror_shell","feedback_diode"]
 ids.erase(id);ids.insert(slot,id)
 var pool:Array=Rules.weighted_pool(g.build,g.catalog)
 g.shop_offers=[]
 for item_id in ids:
  var record:Dictionary=pool.filter(func(e):return e.id==item_id)[0].duplicate(true)
  record.sold=false;g.shop_offers.append(record)
func hold(slot:int=0)->void:
 ck(g._reserve_offer(slot,g.shop_generation),"setup successful hold")
func oracle_draw(count:int,exclude:String)->Dictionary:
 var pool:Array=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id!=exclude)
 var r:=RandomNumberGenerator.new();r.seed=g.shop_rng.seed;r.state=g.shop_rng.state
 var selected:Array=[]
 for _i in range(mini(count,pool.size())):
  var total:=0.0
  for p in pool:total+=float(p.weight)
  var u:float=r.randf()*total
  var cumulative:=0.0
  var index:int=pool.size()-1
  for j in range(pool.size()):
   cumulative+=float(pool[j].weight)
   if u<cumulative:index=j;break
  var entry:Dictionary=pool[index].duplicate(true);entry.sold=false
  selected.append(entry);pool.remove_at(index)
 return {"offers":selected,"rng":r.state}
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 original_catalog=g.catalog.duplicate(true)
 for mode in ["arena","rooms"]:
  for slot in range(4):
   for id in ["rail_lance","feedback_diode"]:
    setup(mode,slot,id);g.build.coins=0
    var before:=safe_state();var offers:Array=g.shop_offers.duplicate(true);var gen:int=g.shop_generation
    ck(g._reserve_offer(slot,gen),mode+" free unfunded reservation "+str(slot)+id)
    ck(g.shop_generation==gen+1 and g.reserved_offer.token==gen+1,"exact generation and initial token")
    ck(safe_state()==before,"no ownership/stat/economy/clock/proc/RNG effects")
    ck(g.reserved_offer.id==id and g.reserved_offer.price==Rules.catalog_entry(g.catalog,id).price and g.reserved_offer.slot==slot,"held identity/price/slot")
    ck(g.reserved_offer.offer==offers[slot],"original metadata preserved")
    var snap:=snapshot()
    ck(not g._reserve_offer(slot,gen) and snapshot()==snap,"stale reserve inert")
    ck(not g._reserve_offer(slot,g.shop_generation) and snapshot()==snap,"not a toggle")
    ck(not g._reserve_offer((slot+1)%4,g.shop_generation) and snapshot()==snap,"no automatic switch")
    ck(not g._release_offer(g.reserved_offer.token,gen) and snapshot()==snap,"old generation cannot unlock")
    ck(not g._release_offer(g.reserved_offer.token+1,g.shop_generation) and snapshot()==snap,"wrong token cannot unlock")
    ck(not g._refresh_shop(g.shop_generation) and snapshot()==snap,"unfunded refresh fully inert")
    ck(not g._buy(slot,g.shop_generation) and snapshot()==snap,"unfunded held buy fully inert")
    var token:int=g.reserved_offer.token
    g.shop_offers[slot].bias_reasons.append("controlled live-offer mutation")
    ck(g.reserved_offer.offer==offers[slot],"held metadata detached from current offer")
    g.shop_offers=offers.duplicate(true)
    var v:Dictionary=g._view();v.reserved_offer.id="tampered";v.reserved_offer.price=0
    ck(g.reserved_offer.id==id and g.reserved_offer.price>0,"view summary detached")
    before=safe_state();gen=g.shop_generation
    ck(g._release_offer(token,gen),"explicit unlock")
    ck(g.reserved_offer.is_empty() and g.shop_offers==offers and g.shop_generation==gen+1,"unlock does not redraw/remove card")
    ck(safe_state()==before,"unlock is free and RNG inert")
    snap=snapshot();ck(not g._release_offer(token,g.shop_generation) and snapshot()==snap,"duplicate unlock inert")
    ck(g._reserve_offer(slot,g.shop_generation) and g.reserved_offer.token!=token,"re-reserve issues new token")
    snap=snapshot();ck(not g._release_offer(token,g.shop_generation) and snapshot()==snap,"old token cannot release replacement hold")
   await process_frame
  # One held ID is removed BEFORE independent weighted sampling; all other weights remain current.
  for slot in range(4):
   for seed_value in [0,17,86,128,433]:
    setup(mode,slot,"rail_lance");hold(slot)
    var held:Dictionary=g.reserved_offer.duplicate(true)
    g.build.items={"power_coil":2,"cooling_fan":1};g.build.weapons=["rivet_gun","return_disc"]
    g.build.revision+=1;g._recompute();g.shop_rng.seed=seed_value
    var expected:=oracle_draw(3,"rail_lance")
    expected.offers.insert(slot,held.offer.duplicate(true))
    var coins:int=g.build.coins;var revision:int=g.build.revision;var gen:int=g.shop_generation
    ck(g._refresh_shop(gen),"paid held refresh")
    ck(g.shop_offers==expected.offers and g.shop_rng.state==expected.rng,"independent held-pool draw/RNG "+mode+str(slot)+str(seed_value))
    ck(g.reserved_offer==held and g.shop_offers[slot]==held.offer,"stable token and original weight/reasons")
    ck(g.build.coins==coins-5 and g.build.revision==revision+1 and g.shop_generation==gen+1,"unchanged refresh price/revision/generation")
    var ids:Array=g.shop_offers.map(func(e):return e.id)
    ck(ids.count("rail_lance")==1 and ids.size()==4,"held ID appears once")
    ck(Rules.owned_ids(g.build).has("rail_lance")==false,"held weapon is not ownership")
    var snap:=snapshot()
    for _repeat in range(3):g._view()
    ck(snapshot()==snap,"repeated views read-only")
    ck(g._release_offer(held.token,g.shop_generation),"original token valid after later generations")
    expected=oracle_draw(4,"");g._refresh_shop(g.shop_generation)
    ck(g.shop_offers==expected.offers and g.shop_rng.state==expected.rng,"unlock resumes ordinary four draws")
   await process_frame
  # Full capacity is not max-stack ownership. Explicit replacement consumes the hold only on success.
  setup(mode,2,"rail_lance");g.build.weapons=["rivet_gun","return_disc","orbit_saw","cryo_sprayer"];g._recompute();hold(2)
  var snap:=snapshot()
  ck(not g._buy(2,g.shop_generation) and snapshot()==snap,"full weapons require explicit replacement")
  ck(not g._buy(2,g.shop_generation,9) and snapshot()==snap,"out-of-range replacement atomic")
  var coins:int=g.build.coins;var rev:int=g.build.revision;var rngs:Array=safe_state().rng
  ck(g._buy(2,g.shop_generation,1),"valid full-slot replacement")
  ck(g.reserved_offer.is_empty() and g.shop_offers[2].sold and g.build.weapons==["rivet_gun","rail_lance","orbit_saw","cryo_sprayer"],"replacement clears matching hold and retains SOLD card")
  ck(g.build.coins==coins-42 and g.build.revision==rev+1 and safe_state().rng==rngs,"catalog replacement price/no refund/no draw")
  setup(mode,1,"feedback_diode")
  g.build.items={"power_coil":1,"cooling_fan":1,"iron_plate":1,"running_boots":1,"moss_patch":1,"lens":1,"capacitor":1,"gear":1};g._recompute();hold(1)
  snap=snapshot();ck(not g._buy(1,g.shop_generation) and snapshot()==snap,"full module slots preserve hold")
  var token:int=g.reserved_offer.token
  ck(g._sell_item("gear",g.shop_generation) and g.reserved_offer.token==token,"selling frees slot without releasing reservation")
  coins=g.build.coins;ck(g._buy(1,g.shop_generation),"buy after freeing module slot")
  ck(g.build.items.feedback_diode==1 and g.build.coins==coins-28 and g.reserved_offer.is_empty() and g.shop_offers[1].sold,"module charges exact catalog price once")
  snap=snapshot();ck(not g._buy(1,g.shop_generation) and snapshot()==snap,"SOLD cannot buy twice")
  setup(mode,0,"rail_lance");hold();token=g.reserved_offer.token
  ck(g._buy(1,g.shop_generation) and g.reserved_offer.token==token,"buying other offer retains hold")
  # New action payloads are fail-closed; no String/bool/fraction coercion into a live index/token.
  setup(mode)
  for value in ["0",true,{},[],.5,null]:
   snap=snapshot();g._on_intent("reserve_offer",{"index":value,"generation":g.shop_generation})
   ck(snapshot()==snap,"malformed index inert "+str(value))
   g._on_intent("reserve_offer",{"index":0,"generation":value})
   ck(snapshot()==snap,"malformed generation inert "+str(value))
  for index in [-1,4,999]:
   snap=snapshot();ck(not g._reserve_offer(index,g.shop_generation) and snapshot()==snap,"invalid reserve index "+str(index))
  g.shop_offers[0].sold=true;snap=snapshot()
  ck(not g._reserve_offer(0,g.shop_generation) and snapshot()==snap,"SOLD is not reservable")
  setup(mode,0,"feedback_diode");g.build.items.feedback_diode=1;g._recompute();snap=snapshot()
  ck(not g._reserve_offer(0,g.shop_generation) and snapshot()==snap,"owned max-stack is not reservable")
  setup(mode);hold()
  for value in [str(g.reserved_offer.token),true,{},[],.5,null]:
   snap=snapshot();g._on_intent("release_offer",{"token":value,"generation":g.shop_generation})
   ck(snapshot()==snap,"malformed release token inert "+str(value))
  for other_state in ["playing","paused","inventory","settings","upgrade","title","won","dead"]:
   g.state=other_state;snap=snapshot()
   ck(not g._reserve_offer(1,g.shop_generation) and not g._release_offer(g.reserved_offer.token,g.shop_generation) and snapshot()==snap,"new actions restricted to shop "+other_state)
  # Invalid held identity/price/max-stack is cleaned only at an affordable successful draw.
  for invalidation in ["unknown","price","max_stack"]:
   setup(mode,1,"feedback_diode");hold(1)
   if invalidation=="unknown":g.reserved_offer.id="not_a_catalog_id"
   elif invalidation=="price":g.reserved_offer.price+=1
   else:g.build.items.feedback_diode=1;g._recompute()
   g.build.coins=0;snap=snapshot()
   ck(not g._refresh_shop(g.shop_generation) and snapshot()==snap,invalidation+" failed draw preserves invalid hold")
   if invalidation in ["unknown","price"]:
    g.build.coins=100;snap=snapshot()
    ck(not g._buy(1,g.shop_generation) and snapshot()==snap,"held "+invalidation+" guard refuses silent alternate charge")
   if invalidation=="max_stack":
    g.build.coins=100;snap=snapshot()
    ck(not g._buy(1,g.shop_generation) and snapshot()==snap,"held ownership cap purchase stays atomic")
   g.build.coins=100;var expected:=oracle_draw(4,"");var gen:int=g.shop_generation
   ck(g._refresh_shop(gen),invalidation+" successful refresh")
   ck(g.reserved_offer.is_empty() and g.shop_offers==expected.offers and g.shop_rng.state==expected.rng,"invalid hold removed before normal four draws")
   ck(g.shop_generation==gen+1 and g.shop_message!="New stock." and not g.shop_message.is_empty(),"invalidation notice retained without extra generation")
  setup(mode,0,"feedback_diode");hold()
  Rules.catalog_entry(g.catalog,"feedback_diode").price=29
  snap=snapshot();ck(not g._buy(0,g.shop_generation) and snapshot()==snap,"changed catalog price cannot silently charge differently")
  g._leave_shop(g.shop_generation);g._open_shop()
  ck(g.reserved_offer.is_empty() and g.shop_message!="Buy, sell or replace. Replacement discards old weapon without refund." and not g.shop_message.is_empty(),"new shop retains precise invalidation notice")
  # Real shared settlement, including floor XP plus the existing policy choice.
  setup(mode,3,"rail_lance");hold(3)
  var held:Dictionary=g.reserved_offer.duplicate(true)
  g._leave_shop(g.shop_generation);g.xp=11;g.pickups=[{"pos":Vector2(40,40),"xp":2,"coins":3}]
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g._begin_room_clear();g.mode.clear_elapsed=g.mode.profile.clear_delay
  g._complete_wave()
  ck(g.state=="upgrade" and g.upgrade_pending==2 and g.reserved_offer==held,"settlement retains hold while both choices queue")
  g._take_upgrade(0,g.choice_generation);ck(g.state=="upgrade" and g.reserved_offer==held,"first choice retains hold")
  g._take_upgrade(0,g.choice_generation)
  ck(g.state=="shop" and g.wave==2 and g.reserved_offer==held and g.shop_offers[3]==held.offer,"later actual shop preserves original slot and record")
  g._on_intent("inventory",{});g._on_intent("close_inventory",{});ck(g.state=="shop" and g.reserved_offer==held,"shop inventory round trip")
  g._leave_shop(g.shop_generation);g._clear_transients();ck(g.reserved_offer==held,"combat transient cleanup is not reservation cleanup")
  g._on_intent("pause",{});g._on_intent("settings",{});g._on_intent("close_settings",{});g._on_intent("codex",{});g._on_intent("close_codex",{});g._on_intent("resume",{})
  ck(g.state=="playing" and g.reserved_offer==held,"paused nested settings/guide retain hold")
  for terminal in ["title","defeat","victory"]:
   setup(mode);hold();var old_gen:int=g.shop_generation;var old_token:int=g.reserved_offer.token
   g._leave_shop(g.shop_generation)
   if terminal=="title":g._title()
   elif terminal=="defeat":g.hurt_clock=0;g.stats.dash_time=0;g._hurt(g.stats.hp+1)
   else:
    g.wave=g.mode.count(g.config);g.boss_defeated=true
    if mode=="rooms":g.mode.begin_stage(g.wave);g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=g.mode.profile.clear_delay
    g._complete_wave()
   ck(g.reserved_offer.is_empty(),terminal+" clears hold "+mode)
   if terminal=="title":g._start_run(28001)
   else:g._on_intent("retry" if terminal=="defeat" else "new_seed",{})
   ck(g.state=="playing" and g.reserved_offer.is_empty(),"new run starts without held stock")
   g._open_shop();snap=snapshot()
   ck(not g._release_offer(old_token,g.shop_generation) and not g._reserve_offer(0,old_gen) and snapshot()==snap,"old-run tokens inert")
  await process_frame
 # Future policy with no shop: reservation survives without forcing a modal or extra reward.
 setup();hold();var held:Dictionary=g.reserved_offer.duplicate(true)
 g._leave_shop(g.shop_generation);g.mode=SkipShop.new();g._complete_wave()
 ck(g.state=="playing" and not g.shop_pending and g.upgrade_pending==0 and g.wave==2 and g.reserved_offer==held,"non-shop policy remains non-shop")
 g._open_shop();ck(g.reserved_offer==held and g.shop_offers[0]==held.offer,"future shop still honors hold")
 # Exhausted synthetic pools: over-cap diagnostic ownership is not a legal-run claim.
 for available in [0,1,2]:
  setup("arena",3,"feedback_diode");hold(3);held=g.reserved_offer.duplicate(true)
  g.build.weapons=[];g.build.items={}
  var allow:Array=["rivet_gun","power_coil"].slice(0,available)
  for entry in g.catalog.weapons+g.catalog.items:
   if entry.id=="feedback_diode" or entry.id in allow:continue
   if entry.kind=="weapon":
    for _i in range(int(entry.max_stack)):g.build.weapons.append(entry.id)
   else:g.build.items[entry.id]=entry.max_stack
  g._roll_offers()
  ck(g.shop_offers.size()==available+1 and g.shop_offers[available]==held.offer and g.reserved_offer.slot==3,"short pool insertion and stable preferred slot "+str(available))
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled actual main transaction/refresh/lifecycle paths plus independent weighted-selection oracle in both modes. No ordinary acquisition, balance or physical-controller certification. Short-pool tests use explicitly over-cap synthetic ownership only to exhaust the pool.","observations":observations}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
