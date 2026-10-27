extends SceneTree
## Controlled black-box transaction/authority checks; optional output path after --.
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func clean(v:Variant)->Variant:
 if v is Object:return {"instance_id":v.get_instance_id()} if is_instance_valid(v) else {"freed":true}
 if v is Array:
  var a:Array=[]
  for x in v:a.append(clean(x))
  return a
 if v is Dictionary:
  var d:Dictionary={}
  for key in v:d[key]=clean(v[key])
  return d
 return v
func props(obj:Object)->Dictionary:
 var d:Dictionary={}
 for p in obj.get_script().get_script_property_list():d[p.name]=clean(obj.get(p.name))
 return d
func snap()->Dictionary:
 return {"run":props(g.run),"combat":props(g.combat),"effects":props(g.effects),"effect_sequence":g.effect_runtime.sequence,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"rig":{"slots":clean(g.weapon_rig.slots),"generation":g.weapon_rig.generation,"visible_clock":g.weapon_rig.visible_clock,"last_shot":g.weapon_rig.last_shot.duplicate(true),"disc_sprites":clean(g.weapon_rig.disc_sprites),"mortar_marks":g.weapon_rig.mortar_marks.duplicate(true)}}
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func setup(mode:String,ids:Array=["rivet_gun","rail_lance"],clocks:Array=[.13,.71])->void:
 g._title();g._select_mode(mode);g._start_run(30001)
 g.build.weapons=ids.duplicate();g.build.items={"power_coil":1,"fracture_coil":1,"pulse_boots":1,"feedback_diode":1,"mirror_shell":1};g._recompute()
 g.weapon_clocks=clocks.duplicate();g.build.coins=137;g.build.coin_fraction=.3;g.build.revision=7
 g._open_shop();g._sync_weapon_rig()
 g.stats.hp=41.0;g.stats.dash_time=.04;g.stats.dash_cooldown=1.7
 g.effects.cooldowns={"arc_relay":12.7};g.effects.echo_hits=3;g.effects.phase_charge=1;g.effects.chain_charges=2;g.effects.feedback_armed=true
 for i in range(g.weapon_rig.slots.size()):
  g.weapon_rig.slots[i].age=.01+float(i)*.07
  g.weapon_rig.slots[i].aim=Vector2.from_angle(float(i)*.2)
 g.weapon_rig.visible_clock=3.7;g.weapon_rig.last_shot={"slot":0,"id":ids[0],"generation":g.weapon_rig.generation,"historical":true}
func rejected(slot:Variant,step:Variant,gen:Variant,id:Variant,label:String)->void:
 var before:=snap()
 ck(not g._move_weapon(slot,step,gen,id),label+" false")
 ck(same(snap(),before),label+" all guarded state exact")
func assert_move(slot:int,step:int,label:String)->void:
 var before:=snap();var target:int=slot+step
 var expected_ids:Array=g.build.weapons.duplicate();var moved_id:String=expected_ids[slot];expected_ids[slot]=expected_ids[target];expected_ids[target]=moved_id
 var expected_clocks:Array=g.weapon_clocks.duplicate();var moved_clock=expected_clocks[slot];expected_clocks[slot]=expected_clocks[target];expected_clocks[target]=moved_clock
 ck(g._move_weapon(slot,step,g.shop_generation,moved_id),label+" accepted")
 var after:=snap()
 ck(g.build.weapons==expected_ids and same(g.weapon_clocks,expected_clocks),label+" IDs and exact copy clocks")
 ck(g.build.revision==before.run.build.revision+1 and g.shop_generation==before.run.shop_generation+1,label+" one revision/generation")
 ck(g.shop_message.contains("SLOT "+str(target+1)),label+" truthful new slot message")
 var expect_rig:Dictionary=before.rig.duplicate(true);var moved=expect_rig.slots[slot];expect_rig.slots[slot]=expect_rig.slots[target];expect_rig.slots[target]=moved
 for index in [slot,target]:expect_rig.slots[index].slot=index;expect_rig.slots[index].pose={}
 ck(same(after.rig,expect_rig),label+" exact rig copy records/aim/age/pose-only delta")
 after.run.build.weapons=before.run.build.weapons;after.run.build.revision=before.run.build.revision
 after.run.shop_generation=before.run.shop_generation;after.run.shop_message=before.run.shop_message
 after.combat.weapon_clocks=before.combat.weapon_clocks;after.rig=before.rig
 ck(same(after,before),label+" only declared authority/presentation mutations")
 var stable:=snap();ck(not g._move_weapon(slot,step,before.run.shop_generation,moved_id) and same(snap(),stable),label+" stale repeat atomic")
 ck(g._move_weapon(target,-step,g.shop_generation,moved_id),label+" reverse accepted")
 ck(g.build.weapons==before.run.build.weapons and same(g.weapon_clocks,before.combat.weapon_clocks),label+" inverse restores IDs/clocks")
 ck(g.build.revision==before.run.build.revision+2 and g.shop_generation==before.run.shop_generation+2,label+" inverse is not counter rollback")
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 # Explicit original8/30/3 fixture; actual A catalog is separately validated.
 var legacy_input:Dictionary=preload("res://tests/support/v39_legacy_inputs.gd").install(g)
 if not legacy_input.pass:push_error(str(legacy_input.errors));quit(1);return
 var actual_ids:Array=g.catalog.weapons.map(func(w):return w.id);actual_ids.sort();var pinned:Array=IDS.duplicate();pinned.sort();ck(actual_ids==pinned,"exact eight current weapon IDs")
 for mode in ["arena","rooms"]:
  for i in range(IDS.size()):
   setup(mode,[IDS[i],IDS[(i+1)%IDS.size()]],[.13,.71]);assert_move(0,1,mode+" pair"+str(i))
   setup(mode,[IDS[i],IDS[(i+1)%IDS.size()]],[.0,-.125]);assert_move(1,-1,mode+" ready pair"+str(i))
  for ids in [["rivet_gun","rivet_gun"],["cryo_sprayer","orbit_saw","cryo_sprayer"],["return_disc","bankshot_driver","shock_mortar","rivet_gun"]]:
   var clocks:Array=[]
   for i in range(ids.size()):clocks.append([.125,0,-.125,.875][i])
   for source in range(ids.size()-1):
    setup(mode,ids,clocks);assert_move(source,1,mode+" length"+str(ids.size())+" source"+str(source))
  setup(mode,["rivet_gun","rivet_gun"],[.3,.3]);assert_move(0,1,mode+" identical IDs and clocks valid")
  setup(mode)
  var gen:int=g.shop_generation
  for bad in [null,true,false,0.0,"0",{},[],StringName("0")]:
   rejected(bad,1,gen,"rivet_gun","bad slot")
   rejected(0,bad,gen,"rivet_gun","bad step")
   rejected(0,1,bad,"rivet_gun","bad generation")
   rejected(0,1,gen,bad,"bad ID")
  for step in [-99,-2,0,2,99]:rejected(0,step,gen,"rivet_gun","out-of-contract step")
  for source in [-1,2,999,9223372036854775807]:rejected(source,1,gen,"rivet_gun","out-of-range source")
  rejected(0,-1,gen,"rivet_gun","first boundary");rejected(1,1,gen,"rail_lance","last boundary")
  rejected(0,1,gen-1,"rivet_gun","stale generation");rejected(0,1,gen,"rail_lance","wrong current ID")
  for state_value in ["title","playing","paused","inventory","settings","upgrade","room_clear","transition","dead","won"]:
   g.state=state_value;rejected(0,1,gen,"rivet_gun","wrong state "+state_value)
  setup(mode);gen=g.shop_generation
  # Misaligned rig must not lazily synchronize on any rejected action.
  g.weapon_rig.clear();rejected(0,-1,gen,"rivet_gun","rejected unaligned rig")
  ck(g.weapon_rig.slots.is_empty(),"no rejected lazy sync")
  ck(g._move_weapon(0,1,gen,"rivet_gun") and g.weapon_rig.slots.map(func(s):return s.id)==["rail_lance","rivet_gun"],"valid lazy pre-move sync")
  setup(mode);gen=g.shop_generation
  for clocks in [[],[0],[0,0,0],[true,0],["0",0],[null,0],[{},0],[[],0],[INF,0],[-INF,0],[NAN,0]]:
   g.weapon_clocks=clocks.duplicate();rejected(0,1,gen,"rivet_gun","malformed clock state")
  for ids in [[],["rivet_gun"],["rivet_gun","rail_lance","cryo_sprayer","orbit_saw","return_disc"],["rivet_gun","missing"],["rivet_gun","power_coil"],["rivet_gun",true],["rivet_gun",StringName("rail_lance")]]:
   g.build.weapons=ids.duplicate();g.weapon_clocks=[]
   for _id in ids:g.weapon_clocks.append(0.0)
   rejected(0,1,gen,"rivet_gun","malformed loadout state")
  setup(mode);g.catalog.weapon_slots=1;rejected(0,1,g.shop_generation,"rivet_gun","configured lower cap");g.catalog.weapon_slots=4
  # Populate real outstanding attacks, then freeze in shop: never discard/remap them.
  for id in ["rivet_gun","return_disc","bankshot_driver","shock_mortar"]:
   setup(mode,[id,"cryo_sprayer"],[.2,.7]);g.state="playing"
   var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(120,0));e.hp=1000;e.max_hp=1000;e.speed=0
   g._fire_weapon(id,0);g.state="shop"
   ck(not g.bullets.is_empty() if id!="shock_mortar" else not g.pending_blasts.is_empty(),"non-vacuous flight "+id)
   rejected(0,1,g.shop_generation,id,"active real shot "+id)
   ck(not g._weapon_order_view().available and g._weapon_order_view().reason.contains("shots"),"precise active-shot explanation")
  # Actual scheduled attacks retain unequal remaining cooldowns, not just array shape.
  setup(mode,["cryo_sprayer","orbit_saw"],[.11,.6]);g.build.items={"fracture_coil":1};g._recompute()
  ck(g._move_weapon(0,1,g.shop_generation,"cryo_sprayer"),"unequal timing move")
  g._leave_shop(g.shop_generation);g.combat_frame.area=g.config.arena;g.elapsed=10
  var timed:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(90,0));timed.hp=1000;timed.max_hp=1000;timed.speed=0;timed.cooldown_left=999
  Runtime.step(g.combat_frame,.1);ck(timed.hp==1000,"move does not grant immediate free attack")
  g.elapsed+=.02;Runtime.step(g.combat_frame,.02);ck(timed.hp==991 and timed.get("chill_until",0)>g.elapsed,"earlier due Cryo remains same copy now slot1")
  g.elapsed+=.49;Runtime.step(g.combat_frame,.49);ck(timed.hp==955 and timed.get("chill_until",0)<=g.elapsed,"later Saw clock consumes existing mark, not forced alignment")
  # Existing settlement really clears weapon-flight state before the earned shop.
  setup(mode,["rivet_gun","shock_mortar"],[.2,.7]);g.state="playing"
  var retiring:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(120,0));retiring.hp=1000;retiring.max_hp=1000;retiring.speed=0
  g._fire_weapon("rivet_gun",0);g._fire_weapon("shock_mortar",1)
  ck(not g.bullets.is_empty() and not g.pending_blasts.is_empty(),"settlement starts with actual ordinary and mortar attacks")
  if mode=="rooms":
   retiring.sprite.queue_free();g.enemies.clear();g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=float(g.room_profile.clear_delay)
  g._complete_wave()
  while g.state=="upgrade":g._take_upgrade(0,g.choice_generation)
  ck(g.state=="shop" and g.bullets.is_empty() and g.pending_blasts.is_empty(),"normal shared settlement reaches clear-flight shop")
  ck(g._move_weapon(0,1,g.shop_generation,"rivet_gun"),"reorder available after real settlement path")
  # Reservation and future stock draws depend on equipment multiset, not ordering.
  setup(mode,["rivet_gun","cryo_sprayer","orbit_saw"],[.13,.71,-.125])
  ck(g._reserve_offer(0,g.shop_generation),"held setup")
  var held:Dictionary=g.reserved_offer.duplicate(true);var old_build:Dictionary=g.build.duplicate(true);var old_pool:Array=Rules.weighted_pool(g.build,g.catalog)
  var expected_rng:=RandomNumberGenerator.new();expected_rng.state=g.shop_rng.state
  var actual_rng:=RandomNumberGenerator.new();actual_rng.state=g.shop_rng.state
  ck(g._move_weapon(0,1,g.shop_generation,"rivet_gun"),"move with reserved offer")
  ck(g.reserved_offer==held and Rules.weighted_pool(g.build,g.catalog)==old_pool,"held identity and weighted pool preserved")
  ck(Rules.draw_shop(old_build,g.catalog,expected_rng)==Rules.draw_shop(g.build,g.catalog,actual_rng) and expected_rng.state==actual_rng.state,"same future shop draw/RNG after permutation")
  var before:=snap();var view:Dictionary=g._weapon_order_view();view.available=false;view.reason="caller edits"
  ck(same(snap(),before),"detached eligibility view")
  var old_gen:int=g.shop_generation;var old_token:int=g.reserved_offer.token
  g._on_intent("move_weapon",{"slot":1,"step":-1,"generation":old_gen,"id":"rivet_gun","price":-999,"refund":999})
  ck(g.build.coins==before.run.build.coins and g.build.weapons==old_build.weapons,"raw intent ignores surplus reward fields")
  before=snap();g._buy(0,old_gen);g._sell_weapon(0,old_gen);g._sell_item("power_coil",old_gen);g._reserve_offer(1,old_gen);g._release_offer(old_token,old_gen);g._refresh_shop(old_gen);g._leave_shop(old_gen)
  ck(same(snap(),before),"all queued pre-move transaction callbacks rejected")
  ck(g._sell_weapon(0,g.shop_generation) and g.build.weapons==["cryo_sprayer","orbit_saw"],"fresh sale addresses current slot")
  g._leave_shop(g.shop_generation);ck(g.state=="playing" and g.build.weapons==["cryo_sprayer","orbit_saw"],"deployment retains selected order")
  g._title();g._start_run(30002);ck(g.build.weapons==["rivet_gun"] and g.weapon_clocks==[0.0],"new run resets ordering normally")
  setup(mode,["rivet_gun","cryo_sprayer","orbit_saw","bankshot_driver"],[.1,.2,.3,.4])
  var rail:Dictionary=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id=="rail_lance")[0].duplicate(true);rail.sold=false;g.shop_offers=[rail]
  var obsolete:int=g.shop_generation
  ck(g._move_weapon(0,1,obsolete,"rivet_gun"),"full-slot reorder")
  before=snap();ck(not g._buy(0,obsolete,0) and same(snap(),before),"stale replacement selection cannot address new slot")
  ck(g._buy(0,g.shop_generation,0) and g.build.weapons==["rail_lance","rivet_gun","orbit_saw","bankshot_driver"],"fresh replacement replaces visibly current slot")
  await process_frame
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"scope":"Controlled contract-level raw transactions, exact declared authority/rig snapshots, all eight weapon IDs, both modes, strict malformed/stale guards and genuine generated shot states. Not ordinary acquisition/native/balance proof.","checks":checks,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
