extends SceneTree
## External real mixer capture of shipped resources driven by actual resolved _hurt.
## Test-owned Master capture only; no microphone, hardware-listening or Windows claim.
var g
var capture:AudioEffectCapture
var effect_index:int=-1
var checks:=0
var failures:Array=[]
var windows:Array=[]
var requests:Array=[]
var output_dir:String=""
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func sha(data:PackedByteArray)->String:
 var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(data);return h.finish().hex_encode()
func pcm_bytes(data:PackedVector2Array)->PackedByteArray:
 var bytes:=PackedByteArray();bytes.resize(data.size()*8)
 for i in range(data.size()):bytes.encode_float(i*8,data[i].x);bytes.encode_float(i*8+4,data[i].y)
 return bytes
func sample_window(label:String,seconds:float,save:bool=false)->Dictionary:
 var until:int=Time.get_ticks_usec()+int(seconds*1000000.)
 var pushed_before:int=capture.get_pushed_frames();var discarded_before:int=capture.get_discarded_frames();var all_frames:=PackedVector2Array()
 while Time.get_ticks_usec()<until:
  await create_timer(.008).timeout
  var available:int=capture.get_frames_available()
  if available>0:all_frames.append_array(capture.get_buffer(available))
 var peak:float=0.;var sum_square:float=0.;var sum_value:float=0.;var nonzero:int=0;var bad:int=0;var stereo_delta:float=0.
 for frame in all_frames:
  stereo_delta=maxf(stereo_delta,absf(frame.x-frame.y))
  for value in [frame.x,frame.y]:
   if not is_finite(value):bad+=1;continue
   peak=maxf(peak,absf(value));sum_square+=value*value;sum_value+=value
   if absf(value)>1e-6:nonzero+=1
 var bytes:PackedByteArray=pcm_bytes(all_frames)
 var report:Dictionary={"label":label,"requested_seconds":seconds,"frames":all_frames.size(),"peak":peak,"rms":sqrt(sum_square/maxf(1.,all_frames.size()*2.)),"mean":sum_value/maxf(1.,all_frames.size()*2.),"nonzero_scalars":nonzero,"nonfinite":bad,"stereo_delta":stereo_delta,"pushed_before":pushed_before,"pushed_after":capture.get_pushed_frames(),"discarded_before":discarded_before,"discarded_after":capture.get_discarded_frames(),"pcm_f32le_stereo_sha256":sha(bytes)}
 if save and not output_dir.is_empty():
  var relative:String=label+".f32le";FileAccess.open(output_dir.path_join(relative),FileAccess.WRITE).store_buffer(bytes);report.raw_file=relative
 windows.append(report);ck(report.frames>=2048 and report.pushed_after>report.pushed_before,label+" sufficient newly pushed/read frames")
 ck(bad==0 and report.discarded_after==0,label+" finite/no discarded frames")
 ck(peak<=.30,label+" bounded combined peak")
 return {"report":report,"frames":all_frames}
func silence(result:Dictionary,label:String)->void:ck(result.report.peak<=1e-6,label+" actual fresh post-drain silence")
func signal_shape(result:Dictionary,cue:String)->Dictionary:
 var stream:AudioStreamWAV=g.feedback_audio.players[cue].stream;var values:PackedByteArray=stream.data
 var first_observed:int=-1;var first_expected:int=-1
 for i in range(result.frames.size()):
  if absf(result.frames[i].x)>5e-5:first_observed=i;break
 for i in range(values.size()/2):
  if absf(float(values.decode_s16(i*2))/32768.*.5)>5e-5:first_expected=i;break
 var best:float=-1.;var best_lag:int=0;var fitted_gain:float=0.;var used:int=0
 if first_observed>=0 and first_expected>=0:
  for lag in range(first_observed-first_expected-16,first_observed-first_expected+17):
   var dot:float=0.;var aa:float=0.;var bb:float=0.;var count:int=0
   for i in range(values.size()/2):
    var j:int=i+lag
    if j<0 or j>=result.frames.size():continue
    var x:float=values.decode_s16(i*2)/32768.;var y:float=result.frames[j].x
    dot+=x*y;aa+=x*x;bb+=y*y;count+=1
   var correlation:float=dot/sqrt(aa*bb) if aa>0 and bb>0 else -1.
   if correlation>best:best=correlation;best_lag=lag;fitted_gain=dot/aa;used=count
 var match_result:Dictionary={"cue":cue,"normalized_correlation":best,"source_pcm_fitted_gain":fitted_gain,"lag_frames":best_lag,"compared_frames":used,"first_observed":first_observed,"first_expected":first_expected}
 ck(result.report.peak>.01 and result.report.rms>.005,cue+" real nonzero energy")
 ck(best>.98 and used>=int(values.size()/2)*.95,cue+" output corresponds to full canonical waveform")
 ck(absf(fitted_gain-.5)<.02,cue+" fitted node gain .5")
 ck(result.report.stereo_delta<1e-6,cue+" mono non-positional mirrored stereo capture")
 return match_result
func setup(mode:String="arena",mirror:bool=false)->void:
 g._title();g._select_mode(mode);g._start_run(3511);g.spawn_clock=999;g.weapon_clocks=[999.];g.elapsed=10;g.hurt_clock=0;g.stats.hp=100;g.stats.dash_time=0
 g.build.items={"mirror_shell":1} if mirror else {};g._recompute();g.effects.reset(g.build.items);requests.clear()
func _initialize()->void:call_deferred("run")
func run()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()>1:output_dir=args[1];DirAccess.make_dir_recursive_absolute(output_dir)
 var started:int=Time.get_ticks_usec();var bus_count:int=AudioServer.bus_count;var original_effect_count:int=AudioServer.get_bus_effect_count(0);var original_gain:float=AudioServer.get_bus_volume_db(0)
 ck(AudioServer.get_driver_name()=="Dummy","explicit Dummy backend for reproducible internal capture")
 ck(AudioServer.get_mix_rate()==44100,"contract-rate mixer")
 ck(is_zero_approx(original_gain) and not AudioServer.is_bus_mute(0),"unity unmuted test Master")
 capture=AudioEffectCapture.new();capture.buffer_length=1.;effect_index=original_effect_count;AudioServer.add_bus_effect(0,capture)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.feedback_audio.cue_requested.connect(func(cue:String,accepted:bool):requests.append({"cue":cue,"accepted":accepted}))
 await process_frame
 var report:Dictionary={"scope":"External exact-resource real internal Dummy mix driven by actual resolved damage/block. No physical listening, output device, subjective sound quality or Windows claim.","engine":Engine.get_version_info(),"driver":AudioServer.get_driver_name(),"mix_rate":AudioServer.get_mix_rate(),"master_gain_db":original_gain,"buffer_frames":capture.get_buffer_length_frames(),"node_gains":{},"shapes":[]}
 for cue in ["player_damage","shield_block"]:report.node_gains[cue]=g.feedback_audio.players[cue].volume_linear
 await sample_window("startup_drain",.2);silence(await sample_window("initial_silence",.12),"initial")
 for mode in ["arena","rooms"]:
  for cue in ["player_damage","shield_block"]:
   setup(mode,cue=="shield_block");g._hurt(11)
   ck(requests==[{"cue":cue,"accepted":true}],mode+cue+" actual request")
   ck(g.stats.hp==(100 if cue=="shield_block" else 89),mode+cue+" genuine HP/block result")
   var captured:Dictionary=await sample_window(mode+"_"+cue,.28,true);report.shapes.append(signal_shape(captured,cue))
   ck(not g.feedback_audio.players[cue].playing,mode+cue+" finite natural completion")
   await sample_window(mode+"_"+cue+"_drain",.12);silence(await sample_window(mode+"_"+cue+"_silence",.12),"natural completion")
 # Muted, unavailable and guard paths must produce enough NEW silent frames, not just no request.
 for blocked in ["muted","missing","wrong_state","dash","hurt_clock"]:
  setup();var saved:Resource=g.feedback_audio.players.player_damage.stream
  match blocked:
   "muted":g.feedback_audio.set_muted(true)
   "missing":g.feedback_audio.install_stream("player_damage",null)
   "wrong_state":g.state="paused"
   "dash":g.stats.dash_time=.1
   "hurt_clock":g.hurt_clock=.1
  g._hurt(11);silence(await sample_window("silent_"+blocked,.20),blocked)
  if blocked in ["muted","missing"]:ck(g.stats.hp==89 and requests==[{"cue":"player_damage","accepted":false}],"silent fault preserves real loss "+blocked)
  else:ck(g.stats.hp==100 and requests.is_empty(),"old guards suppress authority "+blocked)
  g.feedback_audio.set_muted(false);g.feedback_audio.install_stream("player_damage",saved);g.state="playing"
  silence(await sample_window("no_replay_"+blocked,.12),"resume/unmute/restore no replay "+blocked)
 # Twenty actual permitted hits in one controlled frame, bypassing only old cooldown between calls.
 setup()
 for i in range(20):g.hurt_clock=0;g._hurt(1)
 ck(requests.size()==20 and g.stats.hp==80,"20 actual resolved hits / fixed voice budget")
 var retrigger:Dictionary=await sample_window("same_cue_retrigger",.28,true)
 ck(retrigger.report.peak>.01 and retrigger.report.peak<=.13,"same cue replacement never adds 20 voices")
 await sample_window("retrigger_drain",.12);silence(await sample_window("retrigger_silence",.12),"retrigger finite/no queued replay")
 setup("arena",true);g._hurt(11);g.hurt_clock=0;g._hurt(11)
 ck(requests==[{"cue":"shield_block","accepted":true},{"cue":"player_damage","accepted":true}] and g.stats.hp==89,"two real distinct cues overlap")
 var overlap:Dictionary=await sample_window("two_cue_overlap",.28,true)
 ck(overlap.report.peak>.13 and overlap.report.peak<=.26,"two fixed voices combined finite bound")
 await sample_window("overlap_drain",.12)
 # A resolved lethal hit starts after _finish stops earlier voices, no blanket nonplaying mute.
 setup();g.stats.hp=7;g._hurt(11);ck(g.state=="dead","actual lethal terminal state")
 g._process(.01)
 var lethal:Dictionary=await sample_window("lethal_tail",.28,true);report.shapes.append(signal_shape(lethal,"player_damage"))
 ck(requests==[{"cue":"player_damage","accepted":true}],"one post-finish lethal cue")
 await sample_window("lethal_drain",.12);silence(await sample_window("lethal_silence",.12),"finite terminal tail")
 var hurt_weak:WeakRef=weakref(g.feedback_audio.players.player_damage.stream)
 var block_weak:WeakRef=weakref(g.feedback_audio.players.shield_block.stream)
 for stop_kind in ["pause","mute","focus_out","title","teardown"]:
  setup();g._hurt(11);await sample_window("pre_stop_"+stop_kind,.04)
  match stop_kind:
   "pause":g._on_intent("pause",{})
   "mute":g.feedback_audio.set_muted(true)
   "focus_out":g._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
   "title":g._title()
   "teardown":g.queue_free();await process_frame
  await sample_window("buffer_drain_after_"+stop_kind,.20)
  silence(await sample_window("fresh_silence_after_"+stop_kind,.12),"stop after measured drain "+stop_kind)
  if stop_kind!="teardown":
   var request_count:int=requests.size();g.feedback_audio.set_muted(false)
   if stop_kind in ["pause","focus_out"]:g._on_intent("resume",{})
   silence(await sample_window("no_replay_after_"+stop_kind,.12),"no resume replay "+stop_kind);ck(requests.size()==request_count,"no deferred request "+stop_kind)
 ck(not is_instance_valid(g) and hurt_weak.get_ref()==null and block_weak.get_ref()==null,"node and both stream references released after actual fresh drained teardown")
 report.windows=windows
 AudioServer.remove_bus_effect(0,effect_index)
 ck(AudioServer.bus_count==bus_count and AudioServer.get_bus_effect_count(0)==original_effect_count and AudioServer.get_bus_volume_db(0)==original_gain,"external capture cleanup preserves bus layout/gain")
 report.seconds_since_ready=float(Time.get_ticks_usec()-started)/1e6;report.checks=checks;report.failures=failures;report.status="PASS" if failures.is_empty() else "FAIL"
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print(JSON.stringify({"checks":checks,"failures":failures,"seconds":report.seconds_since_ready}));quit(0 if failures.is_empty() else 1)
