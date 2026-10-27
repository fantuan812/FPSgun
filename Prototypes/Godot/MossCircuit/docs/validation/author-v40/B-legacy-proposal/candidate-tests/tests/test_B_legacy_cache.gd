extends SceneTree
## Test-only historical-domain reset; not normal-game B acceptance.
const Legacy=preload("res://tests/support/v39_legacy_inputs.gd")
const Profiles=preload("res://scripts/gameplay/build_items_profiles.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var owners:Array=[]
 for prior_run in [false,true]:
  var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);owners.append(g)
  if prior_run:
   g._start_run(39031);g.set_process(false)
   g.build.items={"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1};g.build.weapons=["rivet_gun","scrap_shotgun"];g._recompute()
   g.combat.combat_tick_serial+=1;g.effect_runtime.begin_build_items_step(g.config.arena)
   for i in range(5):g._effect_event("pickup",{"source":"normal","pos":g.player_pos})
  var runtime=g.effect_runtime.build_items
  var before:Dictionary=runtime.debug_snapshot()
  ck(not prior_run or (before.owned_items.size()==3 and before.charges==3 and before.pending!=null),"prior run genuinely owns B and has stocks/pending")
  if prior_run:g._title()
  ck(g.state=="title" and (not prior_run or g.build.items.size()==3),"title retains prior build, cannot use live-build sync for fixture configure")
  var receipt:Dictionary=Legacy.install(g)
  ck(receipt.pass,"historical installation accepted")
  var s:Dictionary=runtime.debug_snapshot();var expected:Dictionary=Profiles.configuration(g.catalog)
  ck(expected.ok and s.registry==expected.registry and s.definitions==expected.definitions and s.slot_caps==expected.slot_caps,"exact projected registry/definitions/caps")
  ck(s.definitions.values().all(func(x):return x.is_empty()) and not s.configuration_open and s.bound_epoch==g.effects.epoch,"no B definitions and configure window closed on current epoch")
  ck(s.owned_items.is_empty() and s.weapon_counts.is_empty() and s.equipped_types.is_empty(),"no prior owned or equipped caches")
  ck(s.mark==null and s.pin_ready_at==null and s.charges==0 and s.fields.is_empty() and s.next_field_sequence==0 and s.winch_count==0 and s.pending==null and not s.winch_requested_this_batch,"all stocks controls and cooldowns reset")
  ck(s.last_sequence==0 and s.last_now==0.0 and s.last_step_serial==-1 and s.batch_serial==-1 and s.batch_time==0.0 and not s.batch_open,"all replay/clock/batch guards reset")
  var rejected:Dictionary=runtime.configure(g.catalog)
  ck(not rejected.ok and runtime.debug_snapshot()==s,"live reconfigure rejected atomically after installer")
  g._start_run(39);g.set_process(false);s=runtime.debug_snapshot()
  ck(g.state=="playing" and g.build.weapons==["rivet_gun"] and g.build.coins==35 and s.equipped_types==["rivet_gun"] and s.owned_items.is_empty() and s.definitions==expected.definitions,"real subsequent historical start syncs fresh build")
 var helper=preload("res://tests/support/audio_teardown.gd").new();helper.prepare(owners)
 for g in owners:g.queue_free()
 await process_frame;await helper.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"20 author test-only fresh/prior-B-title historical cache assertions, not current B gameplay"}))
 quit(0 if failures.is_empty() else 1)
