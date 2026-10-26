extends SceneTree
## Prepared while execution lane is held. Controlled authority oracle, not ordinary acquisition.
const Rules=preload("res://scripts/rules.gd")
class SkipShop:
 extends "res://scripts/modes/arena_mode.gd"
 func resolution(session:RefCounted,world:RefCounted,config:Dictionary)->Dictionary:
  var d:Dictionary=super.resolution(session,world,config);d.shop=false;d.upgrades=1;return d
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func snap()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"state":g.state,"pending":g.upgrade_pending,"shop_pending":g.shop_pending,"choices":g.choices.duplicate(true),"generation":g.choice_generation,"shop_generation":g.shop_generation,"offers":g.shop_offers.duplicate(true),"held":g.reserved_offer.duplicate(true),"xp":g.xp,"level":g.level,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks.duplicate(),"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.active.duplicate(true),g.effects.cooldowns.duplicate(true),g.effects.feedback_armed,g.effects.shield,g.effects.echo_hits,g.effects.phase_charge],"bullets":g.bullets.duplicate(true),"pending_blasts":g.pending_blasts.duplicate(true)}
func setup(mode:String,pending:int=1,shop:bool=false)->void:
 g._title();g._select_mode(mode);g._start_run(29001)
 g.build.coins=32;g.build.coin_fraction=.3;g.build.revision=7
 g.stats.hp=41.0;g.stats.dash_time=.04;g.stats.dash_cooldown=1.7;g.stats.coin_bonus=4.0
 g.weapon_clocks.fill(.23);g.xp=3;g.level=4
 g.upgrade_pending=pending;g.shop_pending=shop;g._show_upgrades()
func options_after(state_value:int)->Dictionary:
 var r:=RandomNumberGenerator.new();r.state=state_value
 var ids:Array=range(g.config.upgrades.size())
 for i in range(ids.size()-1,0,-1):
  var j:int=r.randi_range(0,i);var old:Variant=ids[i];ids[i]=ids[j];ids[j]=old
 var options:Array=[]
 for i in range(3):options.append(g.config.upgrades[ids[i]].duplicate(true))
 return {"options":options,"state":r.state}
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for fraction in [0.0,.1,.3,.9999999999999999]:
   setup(mode);g.build.coin_fraction=fraction
   var before:=snap();var generation:int=g.choice_generation
   ck(g._salvage_upgrade(generation,"salvage_upgrade"),"valid fixed resolution "+mode)
   var after:=snap()
   ck(g.build.coins==42 and g.build.coin_fraction==fraction,"exact whole10/fraction preserved")
   ck(g.build.revision==7 and g.build.levels==before.build.levels,"no equipment revision or stat count")
   ck(g.stats==before.stats and g.weapon_clocks==before.clocks,"no stat/heal/dash/clock reset")
   ck(g.xp==3 and g.level==4,"earned XP/level retained")
   ck(g.upgrade_pending==0 and g.choices.is_empty() and g.state=="playing","one choice consumed normal resume")
   ck(after.rng==before.rng and after.effects==before.effects,"grant/resume draws no RNG or proc event")
   ck(after.bullets==before.bullets and after.pending_blasts==before.pending_blasts,"no projectile cleanup")
   ck(not g._salvage_upgrade(generation,"salvage_upgrade") and snap()==after,"duplicate resolution rejected")
  setup(mode)
  var before:=snap();var gen:int=g.choice_generation
  for invalid in [null,true,false,0.5,str(gen),{},[],StringName("salvage_upgrade")]:
   ck(not g._salvage_upgrade(invalid,"salvage_upgrade") and snap()==before,"invalid generation inert")
  for invalid in [null,true,false,1,1.0,{},[],"","SALVAGE_UPGRADE","damage",StringName("salvage_upgrade")]:
   ck(not g._salvage_upgrade(gen,invalid) and snap()==before,"invalid ID inert")
  ck(not g._salvage_upgrade(gen-1,"salvage_upgrade") and snap()==before,"stale generation inert")
  for state_value in ["title","playing","paused","shop","inventory","settings","dead","won","room_clear"]:
   g.state=state_value;var stable:=snap()
   ck(not g._salvage_upgrade(gen,"salvage_upgrade") and snap()==stable,"wrong state inert "+state_value)
  setup(mode);g.upgrade_pending=0;before=snap()
  ck(not g._salvage_upgrade(g.choice_generation,"salvage_upgrade") and snap()==before,"no pending inert")
  setup(mode);g.choices.clear();before=snap()
  ck(not g._salvage_upgrade(g.choice_generation,"salvage_upgrade") and snap()==before,"empty page inert")
  setup(mode);before=snap()
  var view:Dictionary=g._upgrade_salvage_view();view.scrap=999999;view.coins=-1;view.id="damage"
  var definition:Dictionary=Rules.upgrade_salvage_definition();definition.scrap=999999;definition.id="damage"
  ck(snap()==before and Rules.upgrade_salvage_definition().scrap==10,"view/definition detached")
  g._on_intent("salvage_upgrade",{"generation":g.choice_generation,"id":"salvage_upgrade","amount":999999,"scrap":999999})
  ck(g.build.coins==42,"surplus caller amount ignored")
  setup(mode,3,false)
  var old_gen:int=g.choice_generation
  for page in range(3):
   gen=g.choice_generation;before=snap();var oracle:=options_after(g.loot_rng.state)
   ck(g._salvage_upgrade(gen,"salvage_upgrade"),"queued salvage")
   ck(g.build.coins==32+10*(page+1) and g.upgrade_pending==2-page,"queue exact rewards/count")
   ck(g.stats==before.stats and g.build.levels==before.build.levels,"queue grant no stats")
   if page<2:
    ck(g.state=="upgrade" and g.choice_generation==gen+1,"next earned page only")
    ck(g.choices==oracle.options and g.loot_rng.state==oracle.state,"independent normal next-page RNG oracle")
   else:ck(g.state=="playing" and g.loot_rng.state==before.rng[1],"final resume no extra draw")
   var stable:=snap();ck(not g._salvage_upgrade(gen,"salvage_upgrade") and snap()==stable,"old page cannot pay next")
  g._title();before=snap();ck(not g._salvage_upgrade(old_gen,"salvage_upgrade") and snap()==before,"title stale payout rejected")
  g._start_run(29002);before=snap();ck(not g._salvage_upgrade(old_gen,"salvage_upgrade") and snap()==before,"new run stale payout rejected")
  # Non-vacuous actual weapons generate ordinary, boundary and pending-mortar state.
  setup(mode);g.state="playing";g.build.weapons=["rivet_gun","bankshot_driver","shock_mortar"]
  g.build.items={"pulse_boots":1,"feedback_diode":1,"mirror_shell":1};g._recompute()
  g._spawn_kind("crawler",g.player_pos+Vector2(120,0))
  for slot in range(3):g._fire_weapon(g.build.weapons[slot],slot)
  ck(g.bullets.size()>=2 and not g.pending_blasts.is_empty(),"actual in-flight/pending state populated")
  ck(g.bullets.any(func(b):return b.get("behavior","")=="field_bankshot"),"actual Bankshot present")
  g.upgrade_pending=1;g.shop_pending=false;g._show_upgrades();before=snap()
  ck(g._salvage_upgrade(g.choice_generation,"salvage_upgrade"),"in-flight salvage")
  var after:=snap()
  ck(after.bullets==before.bullets and after.pending_blasts==before.pending_blasts,"real projectiles and mortar unchanged")
  ck(after.stats==before.stats and after.clocks==before.clocks and after.effects==before.effects,"real combat/effect state unchanged")
  # A held offer becomes affordable solely from the fixed grant (no settlement credit).
  setup(mode);g._open_shop()
  var held_entry:Dictionary=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id=="rail_lance")[0].duplicate(true)
  held_entry.sold=false;g.shop_offers=[held_entry]
  ck(g._reserve_offer(0,g.shop_generation),"controlled held Rail setup")
  var held:Dictionary=g.reserved_offer.duplicate(true)
  g._leave_shop(g.shop_generation);g.build.coins=32;g.upgrade_pending=1;g.shop_pending=true;g._show_upgrades()
  ck(not (g.build.coins>=42) and not "rail_lance" in g.build.weapons,"unaffordable and unowned before grant")
  ck(g._salvage_upgrade(g.choice_generation,"salvage_upgrade"),"salvage into already pending shop")
  ck(g.state=="shop" and g.build.coins==42 and g.reserved_offer==held,"exact affordability/held identity")
  ck(g.shop_offers[0]==held.offer and not "rail_lance" in g.build.weapons,"no automatic purchase/new held metadata")
  ck(g._buy(0,g.shop_generation) and g.build.coins==0,"normal guarded held BUY charges42")
  ck(g.build.weapons.has("rail_lance") and g.shop_offers[0].sold and g.reserved_offer.is_empty(),"one equipment gain/SOLD/clear")
  # Shared natural settlement queues floor-XP plus policy choice; both can be forfeited once.
  g._title();g._select_mode(mode);g._start_run(29003);g.xp=11
  g.pickups=[{"pos":Vector2(40,40),"xp":2,"coins":3}]
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g._begin_room_clear();g.mode.clear_elapsed=g.mode.profile.clear_delay
  g._complete_wave();ck(g.state=="upgrade" and g.upgrade_pending==2 and g.level==2 and g.xp==1,"actual settlement queues earned and policy choices")
  var coins:int=g.build.coins;var revision:int=g.build.revision;var levels:Dictionary=g.build.levels.duplicate(true)
  ck(g._salvage_upgrade(g.choice_generation,"salvage_upgrade"),"settlement first salvage")
  ck(g.upgrade_pending==1 and g.state=="upgrade" and g.build.coins==coins+10,"one queued choice remains")
  ck(g._salvage_upgrade(g.choice_generation,"salvage_upgrade"),"settlement second salvage")
  ck(g.state=="shop" and g.wave==2 and g.build.coins==coins+20 and g.build.revision==revision and g.build.levels==levels,"normal nextshop and only20 fixed grant")
  # Actual terminal resolution creates neither a spendable page nor salvage payout.
  g._leave_shop(g.shop_generation);g.wave=g.mode.count(g.config);g.boss_defeated=true
  if mode=="rooms":g.mode.begin_stage(g.wave);g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=g.mode.profile.clear_delay
  g._complete_wave();before=snap()
  ck(g.state=="won" and g.upgrade_pending==0,"actual terminal skips inaccessible choices")
  ck(not g._salvage_upgrade(g.choice_generation,"salvage_upgrade") and snap()==before,"terminal payout rejected")
  await process_frame
 # Future mode policy supplies a choice but no shop; salvage must resume, not create a shop.
 setup("arena");g.state="playing";g.upgrade_pending=0;g.mode=SkipShop.new();g._complete_wave()
 ck(g.state=="upgrade" and g.upgrade_pending==1 and not g.shop_pending,"controlled no-shop policy choice")
 var coins:int=g.build.coins
 ck(g._salvage_upgrade(g.choice_generation,"salvage_upgrade") and g.state=="playing" and g.build.coins==coins+10,"no-shop policy remains no shop")
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled actual main salvage guards/fixed currency/fraction/read-only metadata/queue continuation; no ordinary acquisition or balance claim. Includes actual weapon in-flight state, settlement/terminal paths and held affordability/purchase. UI/native and old-path parity gates remain separate."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
