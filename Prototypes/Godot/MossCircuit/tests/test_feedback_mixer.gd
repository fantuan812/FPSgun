extends SceneTree
## Real internal mixed frames, not a speaker/listening test. Capture is test-only.
var g
var capture: AudioEffectCapture
var passed := 0
var failures: Array = []
var windows: Dictionary = {}
func ck(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func collect(seconds:float)->Dictionary:
	var until:int=Time.get_ticks_usec()+int(seconds*1000000)
	var row:Dictionary={"frames":0,"peak":0.0,"energy":0.0,"nonzero":0,"invalid":0,"pushed_before":capture.get_pushed_frames()}
	while Time.get_ticks_usec()<until:
		await create_timer(.01).timeout
		var available:int=capture.get_frames_available()
		if available>0:
			var pcm:PackedVector2Array=capture.get_buffer(available)
			row.frames+=pcm.size()
			for frame in pcm:
				for value in [frame.x,frame.y]:
					if not is_finite(value):row.invalid+=1;continue
					row.peak=maxf(row.peak,absf(value));row.energy+=value*value
					if absf(value)>.000001:row.nonzero+=1
	row.pushed_after=capture.get_pushed_frames();row.discarded=capture.get_discarded_frames()
	return row
func window_ok(row:Dictionary,label:String,sounding:bool)->void:
	ck(row.frames>1000 and row.pushed_after>row.pushed_before,label+" fresh frames")
	ck(row.discarded==0 and row.invalid==0,label+" finite/no overflow")
	ck(row.peak>.01 and row.peak<=.30 if sounding else row.peak<=.000001,label+" signal/silence")
func setup(mirror:bool=false)->void:
	g._title();g._start_run(3507);g.set_process(false)
	g.build.items={"mirror_shell":1} if mirror else {};g._recompute();g.effects.reset(g.build.items);g.hurt_clock=0;g.stats.dash_time=0
func run()->void:
	var original_bus_count:int=AudioServer.bus_count
	var original_effects:int=AudioServer.get_bus_effect_count(0)
	ck(AudioServer.get_bus_volume_db(0)==0 and not AudioServer.is_bus_mute(0),"test Master unity/not muted")
	capture=AudioEffectCapture.new();capture.buffer_length=2.0
	AudioServer.add_bus_effect(0,capture)
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	await collect(.15)
	for cue in ["player_damage","shield_block"]:
		setup(cue=="shield_block");await collect(.20)
		g._hurt(8)
		windows[cue]=await collect(.35);window_ok(windows[cue],cue,true)
		ck(absf(windows[cue].peak-.125)<.01,cue+" actual fixed half gain")
		ck(not g.feedback_audio.players[cue].playing,cue+" natural completion")
		windows[cue+"_finished"]=await collect(.12);window_ok(windows[cue+"_finished"],cue+" finished",false)
	setup(true);await collect(.20);g._hurt(8);g.hurt_clock=0;g._hurt(8)
	windows.overlap=await collect(.35);window_ok(windows.overlap,"different cues overlap",true)
	ck(g.feedback_audio.get_child_count()==2,"overlap does not allocate voices/nodes")
	setup();await collect(.20)
	for i in range(4):g.hurt_clock=0;g._hurt(1)
	windows.retrigger=await collect(.35);window_ok(windows.retrigger,"same cue replaces",true)
	ck(windows.retrigger.peak<.14,"same cue no fourfold accumulation")
	windows.no_queue=await collect(.15);window_ok(windows.no_queue,"no replay queue",false)
	setup();g._hurt(8);g.feedback_audio.set_muted(true)
	ck(not g.feedback_audio.players.player_damage.playing,"mute stops player immediately")
	windows.mute_drain=await collect(.20)
	g.hurt_clock=0;g._hurt(8);windows.muted=await collect(.20);window_ok(windows.muted,"muted resolved loss",false)
	g.feedback_audio.set_muted(false);windows.unmute=await collect(.15);window_ok(windows.unmute,"unmute no replay",false)
	setup();g.stats.hp=1;g._hurt(8);windows.lethal=await collect(.35);window_ok(windows.lethal,"post-finish lethal tail",true)
	g._hurt(8);windows.dead=await collect(.15);window_ok(windows.dead,"later dead call",false)
	setup();g._hurt(8);g._on_intent("pause",{});windows.pause_drain=await collect(.20)
	windows.paused=await collect(.15);window_ok(windows.paused,"pause after drain",false)
	g._on_intent("resume",{});windows.resumed=await collect(.15);window_ok(windows.resumed,"resume no replay",false)
	g.queue_free();await process_frame
	AudioServer.remove_bus_effect(0,original_effects)
	ck(AudioServer.bus_count==original_bus_count and AudioServer.get_bus_effect_count(0)==original_effects,"test capture cleaned; bus layout unchanged")
	var report:Dictionary={"passed":passed,"failures":failures,"driver":AudioServer.get_driver_name(),"mix_rate":AudioServer.get_mix_rate(),"windows":windows,"scope":"Real internal mixer only. Physical output, human listening and Windows unverified."}
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():var file:=FileAccess.open(args[0],FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n")
	print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
