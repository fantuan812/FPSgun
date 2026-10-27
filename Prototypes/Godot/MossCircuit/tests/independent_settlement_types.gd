extends SceneTree
## Independently bounded type-totality / atomic invalid-settlement regression.
const Flow=preload("res://scripts/gameplay/run_flow.gd")
class StopAudit extends "res://scripts/feedback_audio.gd":
 var explicit_stop_all_calls:=0
 func stop_all()->void:
  explicit_stop_all_calls+=1
  super.stop_all()
var diagnostic_rows:Array=[]
class Policy extends RefCounted:
 var decision:Variant
 func can_end(_session:RefCounted,_world:RefCounted,_encounters:Dictionary)->bool:return true
 func resolution(_session:RefCounted,_world:RefCounted,_config:Dictionary)->Variant:return decision
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func clean(v:Variant)->Variant:
 match typeof(v):
  TYPE_FLOAT:return v if is_finite(v) else str(v)
  TYPE_VECTOR2:return [v.x,v.y]
  TYPE_COLOR:return [v.r,v.g,v.b,v.a]
  TYPE_ARRAY:
   var out:Array=[]
   for item in v:out.append(clean(item))
   return out
  TYPE_DICTIONARY:
   var out:Dictionary={}
   for key in v:
    if str(key)!="sprite":out[key]=clean(v[key])
   return out
  TYPE_OBJECT:return "<object>"
  TYPE_CALLABLE:return "<callable>"
  _:return v
func props(o:Object)->Dictionary:
 var out:Dictionary={}
 for p in o.get_property_list():
  if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:out[p.name]=o.get(p.name)
 return clean(out)
func snap(g)->Dictionary:
 return {"world":props(g.combat),"session":props(g.run),"effects":props(g.effects),"sequence":g.effect_sequence,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"actor":props(g.actor_anim),"vfx":props(g.vfx),"rig":clean({"slots":g.weapon_rig.slots,"last":g.weapon_rig.last_shot,"clock":g.weapon_rig.visible_clock,"generation":g.weapon_rig.generation}),"generation":[g.choice_generation,g.shop_generation]}
func normal()->Dictionary:return {"terminal":false,"next_stage":2,"shop":false,"upgrades":0,"coins":10,"heal":5}
func _initialize()->void:call_deferred("run")
func run()->void:
 var invalid:Array=[]
 for field in ["terminal","shop"]:
  for value in [null,"true","false","",0,1,-1,0.,1.,NAN,INF,[],{},Vector2.ZERO]:
   var row:Dictionary=normal();row[field]=value;invalid.append(row)
   var original:Variant=clean(row);var errors:Array=Flow.validate_resolution(row)
   ck(not errors.is_empty(),"actual boolean field rejects "+field+str(value));ck(clean(row)==original,"validation no mutation "+field)
 # A true terminal combined with malformed shop was the second unsafe comparison.
 for value in [null,"true",0,1,[],{}]:
  var row:Dictionary=normal();row.terminal=true;row.shop=value;row.next_stage=1;invalid.append(row)
  ck(not Flow.validate_resolution(row).is_empty(),"terminal true safely rejects malformed shop "+str(value))
 for terminal in [false,true]:
  for shop in [false,true]:
   for upgrades in [0,1,2]:
    var row:Dictionary=normal();row.terminal=terminal;row.shop=shop;row.upgrades=upgrades
    var expected:bool=not terminal or (not shop and upgrades==0)
    ck(Flow.validate_resolution(row).is_empty()==expected,"old accepted bool/terminal consistency "+str(row))
    if not expected:invalid.append(row)
 for field in ["next_stage","upgrades","coins","heal"]:
  for value in [null,"1",true,false,[],{},NAN,INF,-INF,-1]:
   var row:Dictionary=normal();row[field]=value;invalid.append(row);ck(not Flow.validate_resolution(row).is_empty(),"old numeric rejection "+field+str(value))
 for field in ["next_stage","upgrades"]:
  for value in [0.0,1.0,1.5]:
   var row:Dictionary=normal();row[field]=value;invalid.append(row);ck(not Flow.validate_resolution(row).is_empty(),"actual integral type not coercion "+field)
 for field in ["coins","heal"]:
  for value in [0,0.,1.,1000000,1000000.0]:
   var row:Dictionary=normal();row[field]=value;ck(Flow.validate_resolution(row).is_empty(),"old inclusive numeric accepted "+field+str(value))
  var row:Dictionary=normal();row[field]=1000000.01;invalid.append(row);ck(not Flow.validate_resolution(row).is_empty(),"old numeric upper bound "+field)
 for field in normal():
  var row:Dictionary=normal();row.erase(field);invalid.append(row);ck(not Flow.validate_resolution(row).is_empty(),"missing field safe rejection "+field)
 for row in [{},{"terminal":"invalid"},{"terminal":true,"shop":{}},null,[],true,0,"policy",Vector2.ZERO]:invalid.append(row)
 for mode in ["arena","rooms"]:
  var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);g._select_mode(mode);g._start_run(3517);g.spawn_clock=999;g.weapon_clocks=[-.2];g.stats.hp=73;g.build.coin_fraction=.3;g.upgrade_pending=2;g.shop_pending=true
  g.pickups=[{"pos":g.player_pos,"xp":7,"coins":3}];g.hazards=[{"kind":"mine","pos":g.player_pos,"life":2.,"age":0.,"tick":0.,"radius":70.,"slow":false}]
  # Observer-only replacement preserves actual base FeedbackAudio request/stream/player/stop implementations.
  var original_audio=g.feedback_audio
  var observed_audio:=StopAudit.new();g.add_child(observed_audio);g.feedback_audio=observed_audio
  original_audio.free()
  var policy:=Policy.new();g.mode=policy
  for i in range(invalid.size()):
   policy.decision=invalid[i];var before:Dictionary=snap(g)
   ck(Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)=="invalid","invalid flow returns explicitly before mutation "+mode+str(i))
   ck(snap(g)==before,"world/session/build/effects/RNG unchanged on invalid flow "+mode+str(i))
   var request_started:int=Time.get_ticks_usec()
   g.feedback_audio.request("player_damage");g.feedback_audio.request("shield_block")
   var requested_at:int=Time.get_ticks_usec();var before_calls:int=observed_audio.explicit_stop_all_calls
   var requested_playing:Array=[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing]
   g._complete_wave()
   var call_finished:int=Time.get_ticks_usec();var call_stops:int=observed_audio.explicit_stop_all_calls-before_calls
   var immediately_playing:Array=[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing]
   ck(snap(g)==before,"controller invalid policy remains atomic "+mode+str(i))
   var snap_finished:int=Time.get_ticks_usec()
   diagnostic_rows.append({"mode":mode,"index":i,"requested_playing":requested_playing,"immediately_playing":immediately_playing,"after_snap_playing":[observed_audio.players.player_damage.playing,observed_audio.players.shield_block.playing],"request_elapsed_us":requested_at-request_started,"call_elapsed_us":call_finished-requested_at,"snapshot_elapsed_us":snap_finished-call_finished,"total_after_request_us":snap_finished-requested_at,"explicit_stop_all_calls_during_controller":call_stops,"stop_calls_through_snapshot":observed_audio.explicit_stop_all_calls-before_calls})
   ck(observed_audio.explicit_stop_all_calls==before_calls,"invalid controller settlement does not invoke explicit stop authority "+mode+str(i))
   # Positive control starts the same canonical voices again, then exercises real forwarded stop_all.
   var control_damage:bool=observed_audio.request("player_damage");var control_block:bool=observed_audio.request("shield_block")
   diagnostic_rows[-1]["positive_control_requested"]=[control_damage,control_block]
   g.feedback_audio.stop_all()
   var stopped:bool=not observed_audio.players.player_damage.playing and not observed_audio.players.shield_block.playing
   diagnostic_rows[-1]["positive_control_stop_delta"]=observed_audio.explicit_stop_all_calls-before_calls
   diagnostic_rows[-1]["positive_control_players_stopped"]=stopped
   ck(control_damage and control_block and observed_audio.explicit_stop_all_calls==before_calls+1 and stopped,"explicit stop positive control detected and real players stopped "+mode+str(i))
  g.queue_free();await process_frame;await create_timer(.25).timeout
 # Existing valid direct settlement effects remain unchanged for each boolean policy family.
 for terminal in [false,true]:
  var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);g._start_run(3518);g.stats.hp=80;g.upgrade_pending=0;g.xp=0
  var coins:int=g.build.coins;var epoch:int=g.effects.epoch;var policy:=Policy.new();policy.decision=normal();policy.decision.terminal=terminal
  var result:String=Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)
  ck(result==("won" if terminal else "next"),"valid outcome unchanged")
  ck(g.stats.hp==85 and g.build.coins==coins+10 and g.effects.epoch==epoch+1,"valid heal/credit/reset unchanged")
  ck(g.state=="transition" and g.wave==(1 if terminal else 2) and not g.shop_pending,"valid transition/stage ownership unchanged")
  var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
  audio_teardown.prepare([g])
  g.queue_free();await process_frame
  await audio_teardown.finish(self)
 var report:Dictionary={"checks":checks,"failures":failures,"invalid_decisions":invalid.size(),"scope":"Controlled pure type-totality and exact invalid-settlement atomicity. Original malformed String repro retained separately; no ordinary authored-data failure or broad policy redesign claim."}
 report["audio_observations"]=diagnostic_rows
 report["audio_scope"]="Exact explicit-stop authority: unchanged super implementation, zero calls across each invalid controller boundary, canonical re-request plus real stop positive control. Playing/elapsed remain telemetry, not a requirement that short clips survive arbitrary snapshot wall time. Historical two FAILs and nonreproducing diagnosis retained."
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
