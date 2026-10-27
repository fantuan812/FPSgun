extends SceneTree
## Independent resolved-event/resource/lifecycle oracle; no physical-output claim.
const Audio=preload("res://scripts/feedback_audio.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const BaseArena=preload("res://scripts/modes/arena_mode.gd")
class NoShopMode extends BaseArena:
 func resolution(session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:
  return {"terminal":false,"next_stage":session.wave+1,"shop":false,"upgrades":0,"coins":0,"heal":0}
class InvalidMode extends BaseArena:
 func resolution(_session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:return {"terminal":false,"next_stage":2,"shop":false,"upgrades":0,"coins":-1,"heal":0}
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func sha(data:PackedByteArray)->String:
 var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(data);return h.finish().hex_encode()
func clean(v:Variant)->Variant:
 match typeof(v):
  TYPE_FLOAT:return v if is_finite(v) else str(v)
  TYPE_VECTOR2:return [clean(v.x),clean(v.y)]
  TYPE_COLOR:return [v.r,v.g,v.b,v.a]
  TYPE_ARRAY:
   var a:Array=[]
   for x in v:a.append(clean(x))
   return a
  TYPE_DICTIONARY:
   var d:Dictionary={}
   for k in v:
    if str(k)!="sprite":d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<object>"
  TYPE_CALLABLE:return "<callable>"
  _:return v
func props(o:Object)->Dictionary:
 var d:Dictionary={}
 for p in o.get_property_list():
  if int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE:d[p.name]=o.get(p.name)
 return clean(d)
func snap(g)->Dictionary:
 return {"world":props(g.combat),"run":props(g.run),"effects":props(g.effects),"sequence":g.effect_sequence,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"choices":g.choices.duplicate(true),"generations":[g.choice_generation,g.shop_generation],"rig":clean({"slots":g.weapon_rig.slots,"clock":g.weapon_rig.visible_clock,"generation":g.weapon_rig.generation,"last":g.weapon_rig.last_shot}),"actor":props(g.actor_anim),"vfx":props(g.vfx)}
func make_game(mode:String,items:Dictionary={}):
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g._select_mode(mode);g._start_run(3501);g.spawn_clock=999;g.elapsed=10;g.weapon_clocks=[999.0];g.player_pos=Vector2(500,500);g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g.combat_frame.area=g.config.arena
 g.build.items=items.duplicate(true);g._recompute();g.effects.reset(g.build.items);g.hurt_clock=0;g.stats.hp=100;g.stats.dash_time=0
 return g
func record(g,events:Array)->void:
 g.feedback_audio.cue_requested.connect(func(cue:String,accepted:bool):events.append({"cue":cue,"accepted":accepted}))
func none_playing(g)->bool:
 for p in g.feedback_audio.players.values():
  if p.playing:return false
 return true
func start_both(g)->void:
 ck(g.feedback_audio.request("player_damage"),"start damage lifecycle fixture")
 ck(g.feedback_audio.request("shield_block"),"start block lifecycle fixture")
func resource_checks(g)->void:
 var audio=g.feedback_audio;ck(audio is Node and audio.players.size()==2 and audio.get_child_count()==2,"exact fixed two players")
 for cue in ["player_damage","shield_block"]:
  var p=audio.players[cue];var stream=p.stream
  ck(p is AudioStreamPlayer and not p is AudioStreamPlayer2D,"non-positional player "+cue)
  ck(not p.autoplay and p.max_polyphony==1 and p.pitch_scale==1 and is_equal_approx(p.volume_linear,.5) and p.bus==&"Master","fixed bounded playback properties "+cue)
  ck(stream is AudioStreamWAV and Audio.stream_error(cue,stream)=="","canonical imported stream valid "+cue)
  var expected:String="a738bbedcd3b01986f6cd4206303886002500b7589e5b27ee33c66deacd30118" if cue=="player_damage" else "7933a54e3ca54b14fc8286c3d8bfae3a8023e6a1351e2c4e9a20c3c57e3611cc"
  ck(sha(stream.data)==expected,"exact decoded imported PCM "+cue)
  for kind in ["missing","type","format","rate","stereo","loop","count"]:
   var bad:Resource=null
   if kind=="type":bad=Resource.new()
   elif kind!="missing":
    bad=stream.duplicate(true)
    match kind:
     "format":bad.format=AudioStreamWAV.FORMAT_8_BITS
     "rate":bad.mix_rate=22050
     "stereo":bad.stereo=true
     "loop":bad.loop_mode=AudioStreamWAV.LOOP_FORWARD
     "count":bad.data=bad.data.slice(0,-2)
   var before:Dictionary=snap(g)
   ck(not Audio.stream_error(cue,bad).is_empty(),"reject stream schema "+cue+kind)
   ck(not audio.install_stream(cue,bad),"invalid unavailable "+cue+kind)
   ck(not audio.request(cue) and not p.playing,"invalid cue silent "+cue+kind)
   var other:String="shield_block" if cue=="player_damage" else "player_damage"
   ck(audio.request(other),"other valid cue unaffected "+cue+kind)
   ck(snap(g)==before,"resource fault has no gameplay effect "+cue+kind)
   audio.stop_all();ck(audio.install_stream(cue,stream),"restore exact valid stream")
  # Runtime validation deliberately has no content hash. Acceptance above still requires canonical PCM.
  var different:AudioStreamWAV=stream.duplicate(true);var bytes:PackedByteArray=different.data;bytes[20]=bytes[20]^1;different.data=bytes
  ck(Audio.stream_error(cue,different)=="" and sha(different.data)!=expected,"runtime shape check distinct from acceptance identity")
 ck(not audio.request("unknown") and not audio.install_stream("unknown",null),"unknown request/install unavailable")
 audio.stop_all();var before:Dictionary=snap(g);var status:Dictionary=audio.status();status.unavailable.append("MUTATED");status.muted=true
 ck(audio.status().unavailable.is_empty() and not audio.status().muted and snap(g)==before,"status detached/read-only")
func _initialize()->void:call_deferred("run")
func run()->void:
 for mode in ["rooms"]:
  for spec in [
   {"name":"loss","hp":100.0,"damage":11.0,"items":{}},
   {"name":"overkill","hp":7.0,"damage":11.0,"items":{}},
   {"name":"zero","hp":100.0,"damage":0.0,"items":{}},
   {"name":"negative","hp":100.0,"damage":-3.0,"items":{}},
   {"name":"infinite incoming finite capped loss","hp":100.0,"damage":INF,"items":{}},
   {"name":"nonfinite returned loss","hp":INF,"damage":INF,"items":{}},
   {"name":"NaN returned loss","hp":NAN,"damage":NAN,"items":{}},
   {"name":"mirror","hp":100.0,"damage":11.0,"items":{"mirror_shell":1}},
   {"name":"mirror zero","hp":100.0,"damage":0.0,"items":{"mirror_shell":1}},
   {"name":"mirror negative","hp":100.0,"damage":-3.0,"items":{"mirror_shell":1}},
   {"name":"mirror thorns","hp":100.0,"damage":11.0,"items":{"mirror_shell":1,"thorn_crown":1}},
   {"name":"medic thorns","hp":100.0,"damage":31.0,"items":{"medic_seed":1,"thorn_crown":1}}]:
   var reference:Dictionary={}
   for audio_mode in ["enabled","muted","missing"]:
    var g=make_game(mode,spec.items);g.stats.hp=spec.hp;var events:Array=[];record(g,events)
    if audio_mode=="muted":g.feedback_audio.set_muted(true)
    if audio_mode=="missing":
     g.feedback_audio.install_stream("player_damage",null);g.feedback_audio.install_stream("shield_block",null)
    var epoch:int=g.effects.epoch;var sequence:int=g.effect_sequence;var shield:bool=spec.items.has("mirror_shell")
    var loss:float=minf(float(spec.hp),float(spec.damage));var expected_request:bool=shield or (is_finite(loss) and loss>0)
    g._hurt(spec.damage)
    ck(events.size()==(1 if expected_request else 0),mode+spec.name+audio_mode+" exact resolved request count")
    if expected_request:ck(events[0]=={"cue":"shield_block" if shield else "player_damage","accepted":audio_mode=="enabled"},"resolved cue identity/acceptance "+spec.name+audio_mode)
    ck(g.effect_sequence-sequence==(1 if shield else 2),"unchanged before_hurt/hurt count "+spec.name)
    ck(g.effects.epoch-epoch==(1 if g.state=="dead" else 0),"only old terminal epoch invalidation "+spec.name)
    ck(is_equal_approx(g.hurt_clock,.25 if shield else .75),"old immunity clock "+spec.name)
    if shield:ck(g.stats.hp==spec.hp and g.effects.shield==0 and g.effects.shield_spent,"actual Mirror consumption unchanged HP")
    elif is_finite(spec.hp) and is_finite(spec.damage):ck(g.stats.hp==maxf(0,spec.hp-spec.damage),"old HP arithmetic "+spec.name)
    var after:Dictionary=snap(g)
    if audio_mode=="enabled":reference=after
    else:ck(after==reference,"complete gameplay snapshot equals enabled "+mode+spec.name+audio_mode)
    observations.append({"mode":mode,"case":spec.name,"audio":audio_mode,"requests":events,"hp":clean(g.stats.hp),"state":g.state})
    g.queue_free();await process_frame
  var g=make_game(mode,{"mirror_shell":1});var events:Array=[];record(g,events)
  g._hurt(11);g.hurt_clock=0;g._hurt(11)
  ck(events==[{"cue":"shield_block","accepted":true},{"cue":"player_damage","accepted":true}] and g.stats.hp==89,"spent Mirror becomes true loss "+mode)
  g.feedback_audio.stop_all();events.clear()
  for state_value in ["title","shop","paused","inventory","upgrade","settings","codex","room_clear","dead","won"]:
   g.state=state_value;g.hurt_clock=0;var before:Dictionary=snap(g);g._hurt(11);ck(events.is_empty() and snap(g)==before,"wrong-state rejected without cue/mutation "+state_value)
  g.state="playing"
  for guard in ["hurt_clock","dash"]:
   g.hurt_clock=.1 if guard=="hurt_clock" else 0.;g.stats.dash_time=.1 if guard=="dash" else 0.;var before:Dictionary=snap(g);g._hurt(11);ck(events.is_empty() and snap(g)==before,"old damage guard no added request "+guard)
  g.hurt_clock=0;g.stats.dash_time=0
  g._vfx("hit_spark",g.player_pos);g._vfx("shield_impact",g.player_pos);g._mechanism_vfx("gravity_anchor","shield_impact",g.player_pos,{});g._effect_event("mine_detonate",{"source":"mine","pos":g.player_pos,"depth":1})
  ck(events.is_empty(),"reused presentation and unrelated effect events never audio")
  g.queue_free();await process_frame
  for route in ["contact","hostile swept projectile","boss blast","brood annulus"]:
   for mirror in [false,true]:
    g=make_game(mode,{"mirror_shell":1} if mirror else {});events=[];record(g,events)
    var e:Dictionary=g._spawn_kind("boss_warden" if route=="boss blast" else ("brood_keeper" if route=="brood annulus" else "crawler"),g.player_pos+Vector2(200,0))
    e.hp=1000.;e.max_hp=1000.;e.anim_hp=1000.;e.speed=0.;e.damage=11.;e.cooldown_left=999.;e.ai_state="recover";e.recover_left=1.
    match route:
     "contact":e.pos=g.player_pos+Vector2(5,0);e.ai_state="move"
     "hostile swept projectile":g.enemy_bullets.append({"pos":g.player_pos-Vector2(30,0),"velocity":Vector2(1000,0),"life":1.,"damage":11.,"owner":e.id})
     "boss blast":e.ai_state="warning";e.warning_left=.01;e.attack="blast";e.target=g.player_pos
     "brood annulus":e.ai_state="warning";e.warning_left=.01;e.attack="annulus";e.pulse_center=g.player_pos-Vector2(100,0)
    Runtime.step(g.combat_frame,.06)
    ck(events==[{"cue":"shield_block" if mirror else "player_damage","accepted":true}],"actual shared runtime route "+mode+route+str(mirror))
    ck(g.stats.hp==(100 if mirror else 89),"actual HP/block route "+route)
    g.queue_free();await process_frame
  # Real Feedback Diode resolves owner damage during dash, while the old dash guard rejects HP loss.
  g=make_game(mode,{"feedback_diode":1});events=[];record(g,events)
  var owner:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(200,0));owner.hp=1000.;owner.max_hp=1000.;owner.anim_hp=1000.;owner.speed=0;owner.cooldown_left=999
  g.stats.dash_time=.1;g._effect_event("dash",{"pos":g.player_pos,"angle":0.})
  g.enemy_bullets.append({"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.,"damage":11.,"owner":owner.id})
  Runtime.step(g.combat_frame,0.)
  ck(owner.hp==976 and not g.effects.feedback_armed and g.stats.hp==100,"real Feedback return/dash authority")
  ck(events.is_empty(),"real secondary Feedback hit never player cue")
  g.queue_free();await process_frame
  g=make_game(mode);events=[];record(g,events);g.stats.hp=70;g.pickups.append({"pos":g.player_pos,"xp":0,"coins":0,"heal":8.,"source":"medical"})
  Runtime.step(g.combat_frame,0.);ck(g.stats.hp==78 and events.is_empty(),"actual medical pickup heals without loss/block cue")
  g.queue_free();await process_frame
  for transition in ["pause","inventory","upgrade","shop","room_clear","title","start","finish_dead","finish_won","focus_out","no_shop_settlement","normal_settlement"]:
   g=make_game(mode);events=[];record(g,events);start_both(g);events.clear()
   match transition:
    "pause":g._on_intent("pause",{})
    "inventory":g._on_intent("inventory",{})
    "upgrade":g.upgrade_pending=1;g._show_upgrades()
    "shop":g._open_shop()
    "room_clear":g._begin_room_clear()
    "title":g._title()
    "start":g._start_run(3502)
    "finish_dead":g._finish(false)
    "finish_won":g._finish(true)
    "focus_out":g._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    "no_shop_settlement":g.mode=NoShopMode.new();g._complete_wave();ck(g.state=="playing" and g.wave==2,"no-modal stage path really selected")
    "normal_settlement":
     if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=g.mode.profile.clear_delay
     g._complete_wave();ck(g.wave==2,"valid ordinary settlement advanced")
   ck(none_playing(g) and events.is_empty(),"stops both without request "+mode+transition)
   if transition=="pause":g._on_intent("resume",{});ck(none_playing(g) and events.is_empty(),"resume no replay")
   g.queue_free();await process_frame
  for invalid in ["invalid_start","invalid_settlement","ignored_settlement","ignored_room_clear"]:
   g=make_game(mode);start_both(g)
   match invalid:
    "invalid_start":ck(not g._start_run(7,"unknown"),"invalid kit rejected")
    "invalid_settlement":g.mode=InvalidMode.new();g._complete_wave()
    "ignored_settlement":g.state="inventory";g._complete_wave()
    "ignored_room_clear":g.state="inventory";g._begin_room_clear()
   ck(g.feedback_audio.players.player_damage.playing and g.feedback_audio.players.shield_block.playing,"invalid boundary does not acquire stop side effect "+invalid)
   g.queue_free();await process_frame
  for tail_stop in ["focus_out","title","retry","mute"]:
   g=make_game(mode);events=[];record(g,events);g.stats.hp=7.;g._hurt(11)
   ck(g.state=="dead" and g.feedback_audio.players.player_damage.playing,"lethal cue starts AFTER finish "+tail_stop)
   var count:int=events.size();g._hurt(11);ck(events.size()==count,"later dead hit cannot request")
   match tail_stop:
    "focus_out":g._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
    "title":g._title()
    "retry":g._on_intent("retry",{})
    "mute":g.feedback_audio.set_muted(true)
   ck(none_playing(g),"lethal tail explicitly cut "+tail_stop)
   g.queue_free();await process_frame
  g=make_game(mode);events=[];record(g,events);ck(not g.settings.mute_feedback_sounds,"fresh session defaults unmuted")
  for key in [null,42,true,"unknown"]:
   g.state="settings";var before:Dictionary=snap(g);var values:Dictionary=g.settings.duplicate(true);g._on_intent("set_setting",{"key":key,"value":true});ck(g.settings==values and snap(g)==before,"strict setting key")
  for value in [null,0,1,0.,"true",[],{}]:
   var values:Dictionary=g.settings.duplicate(true);g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":value});ck(g.settings==values and not g.feedback_audio.muted,"strict actual bool")
  g.state="playing";g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":true});ck(not g.feedback_audio.muted,"settings state guard")
  g.state="settings";start_both(g);events.clear();var before:Dictionary=snap(g);g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":true})
  ck(g.settings.mute_feedback_sounds and g.feedback_audio.muted and none_playing(g),"session mute actual handler stops")
  ck(snap(g)==before and events.is_empty(),"mute no gameplay/requests")
  g._on_intent("set_setting",{"key":"reduced_flashes","value":true});ck(g.feedback_audio.muted and g.settings.reduced_flashes,"flash and mute independent")
  g._title();g._start_run(333);ck(g.settings.mute_feedback_sounds and g.feedback_audio.muted,"mute retained title and new run")
  g._finish(false);g._on_intent("retry",{});ck(g.feedback_audio.muted,"retry retains mute")
  g.state="settings";g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":false});ck(not g.feedback_audio.muted and none_playing(g) and events.is_empty(),"unmute never replays")
  var before_view:Dictionary=snap(g);g._feedback_audio_view();g._view();g.ui.show_settings(g._view());ck(snap(g)==before_view and events.is_empty(),"views/settings presentation read-only")
  var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
  audio_teardown.prepare([g])
  g.queue_free();await process_frame
  await audio_teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"observations":observations,"scope":"Controlled imported PCM identity, resolved authority, actual four hostile routes, disabled-audio gameplay equality, strict setting and explicit lifecycle. No fresh mixer capture/native/hardware claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
