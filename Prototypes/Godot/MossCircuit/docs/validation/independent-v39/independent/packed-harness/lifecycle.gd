extends SceneTree
# Expected lifecycle policy originates in pretarget/POLICY_HAND_CASES.json, not target output.
const Combat=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:int=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(39039,"tether");g.set_process(false)
 g.build.weapons=["tether_emitter","seismic_drum"];g.build.weapon_temper=[0,0];g.build.items=items.duplicate(true);g.build.coins=200
 g.weapon_clocks=[0.0,0.0];g._recompute();g.combat_frame.area=g.config.arena
 g.player_pos=Vector2(400,300);g.elapsed=10.0
 var e:Dictionary=g._spawn_kind("crawler",Vector2(500,300));e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0.0;e.damage=0.0
 Combat.step(g.combat_frame,.01)
 ck(g.combat.pulse_beams.size()==1 and g.combat.seismic_waves.size()==1,mode+" real beam and wave armed")
func snap()->Dictionary:
 return {"beams":g.combat.pulse_beams.duplicate(true),"waves":g.combat.seismic_waves.duplicate(true),"epoch":g.combat.new_weapon_epoch,"elapsed":g.elapsed,"clocks":g.weapon_clocks.duplicate(),"build":g.build.duplicate(true),"generation":g.shop_generation}
func cleared(before:Dictionary,label:String)->void:
 ck(g.combat.pulse_beams.is_empty() and g.combat.seismic_waves.is_empty(),label+" no retained/new attacks")
 ck(g.combat.new_weapon_epoch>before.epoch,label+" invalidates old epoch")
 observations.append({"case":label,"epoch_before":before.epoch,"epoch_after":g.combat.new_weapon_epoch})
func shop(id:String)->void:
 g.state="shop";g.shop_offers=[{"id":id,"sold":false}];g.reserved_offer={}
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode);shop("lock_memory");var before:=snap()
  ck(not g._buy(0,g.shop_generation-1) and snap()==before,mode+" rejected buy atomic")
  ck(g._buy(0,g.shop_generation),mode+" real item buy accepted");cleared(before,mode+" item_buy")
  setup(mode,{"lock_memory":1});shop("lock_memory");before=snap()
  ck(g._sell_item("lock_memory",g.shop_generation),mode+" real item sale accepted");cleared(before,mode+" item_sell")
  setup(mode);shop("tether_emitter");before=snap()
  ck(g._buy(0,g.shop_generation,0),mode+" real same-ID replacement accepted");cleared(before,mode+" same_id_replace")
  ck(g.build.weapons==["tether_emitter","seismic_drum"] and g.build.weapon_temper==[0,0],mode+" same IDs do not preserve old flight identity")
  setup(mode);shop("tether_emitter");before=snap()
  ck(not g._move_weapon(0,1,g.shop_generation,"tether_emitter") and snap()==before,mode+" real in-flight move atomic reject")
  g.combat.pulse_beams.clear();g.combat.seismic_waves.clear();before=snap()
  ck(g._move_weapon(0,1,g.shop_generation,"tether_emitter"),mode+" real empty move accepted");cleared(before,mode+" successful_empty_move")
  ck(g.build.weapons==["seismic_drum","tether_emitter"] and g.weapon_clocks==[before.clocks[1],before.clocks[0]],mode+" move retains each copy cooldown")
  setup(mode);g.build.weapons=["tether_emitter","tether_emitter"];g.build.weapon_temper=[0,0];shop("tether_emitter");before=snap()
  ck(not g._temper_weapon(0,1,g.shop_generation,"tether_emitter","tether_emitter") and snap()==before,mode+" real in-flight temper atomic reject")
  g.combat.pulse_beams.clear();g.combat.seismic_waves.clear();before=snap()
  ck(g._temper_weapon(0,1,g.shop_generation,"tether_emitter","tether_emitter"),mode+" real empty temper accepted");cleared(before,mode+" successful_empty_temper")
  ck(g.build.weapons==["tether_emitter"] and g.build.weapon_temper==[1] and g.weapon_clocks==[before.clocks[0]],mode+" temper retained cooldown and tier")
  setup(mode);before=snap();g._recompute();cleared(before,mode+" recompute_same_arrays")
  ck(g.weapon_clocks==before.clocks,mode+" recompute does not recharge clocks")
  setup(mode);g.state="upgrade";g.choices=[{"id":"health"}];g.upgrade_pending=1;before=snap();g._take_upgrade(0,g.choice_generation);cleared(before,mode+" upgrade")
  ck(g.build.levels.get("health",0)==1,mode+" actual upgrade granted")
  setup(mode);before=snap();g._boss_killed({"boss":true,"hp":0.0,"kind":"boss_warden"});cleared(before,mode+" boss_stat_award")
  ck(g.build.get("boss_protocol",false) and g.build.coins==250,mode+" real Warden reward granted once")
  setup(mode);before=snap();g._on_intent("pause",{});g._simulate(.25)
  ck(g.state=="paused" and snap()==before,mode+" actual pause freezes entities epoch clocks time")
  g._on_intent("resume",{});ck(g.state=="playing" and snap()==before,mode+" resume alone no advancement")
  setup(mode);before=snap();g._on_intent("inventory",{});g._simulate(.25)
  ck(g.state=="inventory" and snap()==before,mode+" actual build overlay freezes entities epoch clocks time")
  g._on_intent("close_inventory",{});ck(g.state=="playing" and snap()==before,mode+" close overlay alone no advancement")
  setup(mode);before=snap();g._title();cleared(before,mode+" title")
  setup(mode);before=snap();g._finish(false);cleared(before,mode+" finish")
  before=snap();g._on_intent("retry",{});cleared(before,mode+" retry")
  ck(g.state=="playing" and g.run.starting_loadout_id=="tether" and g.elapsed==0.0,mode+" retry actual selected starting loadout and new clock")
  setup(mode);before=snap();ck(g._start_run(39040,"seismic"),mode+" real new run accepted");cleared(before,mode+" new_run")
  ck(g.build.weapons==["seismic_drum"] and g.elapsed==0.0,mode+" new run owns fresh starting build")
  setup(mode)
  # Controlled completion eligibility, actual main wrapper and actual mode resolution.
  for enemy in g.enemies:
   if is_instance_valid(enemy.sprite):enemy.sprite.queue_free()
  g.enemies.clear()
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=float(g.mode.profile.clear_delay)
  before=snap();g._complete_wave();cleared(before,mode+" room_boundary")
  ck(g.wave==2 and g.elapsed==before.elapsed,mode+" actual stage2 settlement preserves run clock")
 g._title()
 var helper=load("<WORKSPACE>/moss-v39-qa/packed-harness/audio_teardown.gd").new();helper.prepare([g]);g.queue_free();await process_frame;await helper.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Independent pretarget lifecycle expectations through actual main transaction/intent/settlement seams; controlled loadouts and completion eligibility, not ordinary play or natural acquisition"}))
 quit(0 if failures.is_empty() else 1)
