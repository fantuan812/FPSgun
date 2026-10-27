extends SceneTree
## Local finite disposal boundary, not a universal backend cleanup deadline.
const Audio = preload("res://scripts/feedback_audio.gd")
var checks := 0
var failures: Array = []
var capture: AudioEffectCapture
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func sample(seconds:float, first_signal:bool=false)->Dictionary:
	var until:int=Time.get_ticks_usec()+int(seconds*1000000)
	var row:Dictionary={"frames":0,"peak":0.0,"pushed_before":capture.get_pushed_frames()}
	while Time.get_ticks_usec()<until:
		await create_timer(.01).timeout
		var n:int=capture.get_frames_available()
		if n>0:
			var frames:PackedVector2Array=capture.get_buffer(n);row.frames+=frames.size()
			for frame in frames:row.peak=maxf(row.peak,maxf(absf(frame.x),absf(frame.y)))
			if first_signal and row.peak>.01:break
	row.pushed_after=capture.get_pushed_frames();row.discarded=capture.get_discarded_frames()
	return row
func run()->void:
	var old_effect_count:int=AudioServer.get_bus_effect_count(0)
	capture=AudioEffectCapture.new();capture.buffer_length=1.0;AudioServer.add_bus_effect(0,capture)
	var audio=Audio.new();root.add_child(audio)
	await sample(.12)
	var references:Dictionary={}
	for cue in Audio.CUES:
		ck(audio.request(cue),"valid voice requested "+cue)
		references[cue]={"stream":weakref(audio.players[cue].stream),"playback":weakref(audio.players[cue].get_stream_playback())}
	# Observe real mixed signal before disposal, without retaining playback owners.
	var hot:Dictionary=await sample(1.0,true)
	ck(hot.frames>1000 and hot.peak>.01 and hot.discarded==0,"hot mixer frames before disposal")
	ck(audio.players.player_damage.playing and audio.players.shield_block.playing,"both voices still active at disposal")
	audio.queue_free();await process_frame
	ck(not is_instance_valid(audio),"presentation owner actually freed")
	var drain:Dictionary=await sample(.25)
	ck(drain.frames>1000 and drain.pushed_after>drain.pushed_before and drain.discarded==0,"bounded fresh drain frames")
	for cue in references:
		ck(references[cue].stream.get_ref()==null,"stream reference released "+cue)
		ck(references[cue].playback.get_ref()==null,"playback reference released "+cue)
	var silence:Dictionary=await sample(.15)
	ck(silence.frames>1000 and silence.pushed_after>silence.pushed_before,"silence contains fresh frames")
	ck(silence.peak<=.000001 and silence.discarded==0,"post-disposal silence without overflow")
	AudioServer.remove_bus_effect(0,old_effect_count)
	ck(AudioServer.get_bus_effect_count(0)==old_effect_count,"test-only capture removed")
	var report:Dictionary={"checks":checks,"failures":failures,"driver":AudioServer.get_driver_name(),"mix_rate":AudioServer.get_mix_rate(),"hot":hot,"drain":drain,"silence":silence,"scope":"Actual resource/playback weakref release after owner disposal and finite local mixer settling; no physical listening or all-backend timing guarantee."}
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
