extends SceneTree
const Audio = preload("res://scripts/feedback_audio.gd")
var g
var passed := 0
var failures: Array = []
var requests: Array = []
func ck(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failures.append(label)
func _initialize() -> void: call_deferred("run")
func setup(mode: String, mirror: bool = false) -> void:
	g._title(); g._select_mode(mode); g._start_run(3501); g.set_process(false)
	g.settings.mute_feedback_sounds=false; g.feedback_audio.set_muted(false)
	g.build.items={"mirror_shell":1,"thorn_crown":1,"medic_seed":1} if mirror else {"thorn_crown":1,"medic_seed":1}
	g._recompute();g.effects.reset(g.build.items);g.hurt_clock=0;g.stats.dash_time=0;requests.clear()
func playing() -> bool:
	return g.feedback_audio.players.player_damage.playing or g.feedback_audio.players.shield_block.playing
func ignite() -> void:
	g.feedback_audio.request("player_damage");g.feedback_audio.request("shield_block")
func state_snapshot() -> Dictionary:
	return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clock":g.hurt_clock,"clocks":g.weapon_clocks.duplicate(),"state":g.state,"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_sequence,g.effects.shield,g.effects.shield_spent,g.effects.medic_damage,g.effects.cooldowns.duplicate(true)],"queues":[g.pending_blasts.duplicate(true),g.hazards.duplicate(true),g.pickups.duplicate(true)],"focus":g.combat.focus_enemy_id}
func run() -> void:
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	g.feedback_audio.cue_requested.connect(func(cue: String,accepted:bool):requests.append([cue,accepted]))
	ck(g.feedback_audio.players.size()==2,"exactly two players")
	var source: Dictionary = {}
	for cue in Audio.CUES:
		var player: AudioStreamPlayer=g.feedback_audio.players[cue]
		var stream:AudioStreamWAV=player.stream
		ck(stream!=null and Audio.stream_error(cue,stream).is_empty(),"valid imported "+cue)
		if stream==null:continue
		source[cue]=stream
		ck(player.max_polyphony==1 and player.volume_linear==.5 and player.pitch_scale==1 and not player.autoplay and player.bus==&"Master","fixed player policy "+cue)
		var provenance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/provenance.json"))
		var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(stream.data)
		ck(hash.finish().hex_encode()==provenance.cues[cue].pcm_sha256,"canonical imported/exported PCM identity "+cue)
		for bad in [null,Resource.new()]:ck(not g.feedback_audio.install_stream(cue,bad),"missing/wrong type isolated")
		for field in ["format","mix_rate","stereo","loop_mode","data"]:
			var invalid:AudioStreamWAV=stream.duplicate()
			match field:
				"format":invalid.format=AudioStreamWAV.FORMAT_8_BITS
				"mix_rate":invalid.mix_rate=22050
				"stereo":invalid.stereo=true
				"loop_mode":invalid.loop_mode=AudioStreamWAV.LOOP_FORWARD
				"data":invalid.data=PackedByteArray([0,0])
			ck(not g.feedback_audio.install_stream(cue,invalid) and not g.feedback_audio.request(cue),"invalid stream silent "+field)
		ck(g.feedback_audio.install_stream(cue,stream),"restore valid stream")
	for mode in ["arena","rooms"]:
		setup(mode)
		var before:Dictionary=state_snapshot();var status:Dictionary=g.feedback_audio.status();g._view()
		ck(before==state_snapshot() and requests.is_empty(),"status/view pure "+mode)
		ck(status.unavailable.is_empty() and status.driver==AudioServer.get_driver_name(),"truthful availability/driver")
		g._hurt(9);ck(requests==[["player_damage",true]] and g.stats.hp==91 and g.hurt_clock==.75,"resolved positive loss once")
		g._hurt(9);ck(requests.size()==1,"hurt cooldown no extra")
		setup(mode,true);g._hurt(9)
		ck(requests==[["shield_block",true]] and g.stats.hp==100 and g.effects.shield==0 and g.hurt_clock==.25,"genuine consumed Mirror block only")
		g.hurt_clock=0;g._hurt(9);ck(requests==[["shield_block",true],["player_damage",true]],"spent shield actual loss")
		for phase in ["paused","inventory","settings","shop","upgrade","room_clear","dead","won","title"]:
			setup(mode);g.state=phase;g._hurt(9);ck(requests.is_empty(),"wrong phase no request "+phase)
		setup(mode);g.stats.dash_time=.1;g._hurt(9);ck(requests.is_empty(),"dash immunity no cue")
		for amount in [0.0,-5.0]:
			setup(mode);g._hurt(amount);ck(requests.is_empty(),"nonpositive returned loss no cue")
		setup(mode);g._vfx("hit_spark",g.player_pos);g._vfx("shield_impact",g.player_pos);g._effect_event("pickup",{"kind":"heal","value":5});ck(requests.is_empty(),"generic VFX/heal no cue")
		setup(mode);g.stats.hp=3;g._hurt(999)
		ck(g.state=="dead" and requests==[["player_damage",true]] and g.feedback_audio.players.player_damage.playing,"lethal cue after finish cleanup")
		g._hurt(9);ck(requests.size()==1,"later dead request rejected")
		g._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);ck(not playing() and g.state=="dead","focus-out stops terminal tail without pause-state rewrite")
		for seam in ["_present_pause","_present_inventory","_show_upgrades","_open_shop","_title","_begin_room_clear"]:
			setup(mode);ignite();g.call(seam);ck(not playing(),"named entry stops "+seam)
		setup(mode);ignite();g._start_run(3502,"not-a-kit");ck(playing(),"invalid start no stop side effect")
		g._start_run(3502);ck(not playing(),"valid new run stops")
		setup(mode);ignite();g._finish(true);ck(not playing(),"victory stops without cue")
		setup(mode);ignite();g._on_intent("pause",{});g._on_intent("settings",{})
		before=state_snapshot();requests.clear()
		for invalid in [{"key":"mute_feedback_sounds","value":1},{"key":1,"value":true},{"key":"unknown","value":true}]:g._on_intent("set_setting",invalid)
		ck(before==state_snapshot() and not g.settings.mute_feedback_sounds and requests.is_empty(),"malformed settings atomic")
		g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":true})
		ck(before==state_snapshot() and g.feedback_audio.muted and requests.is_empty(),"mute no gameplay mutation/request")
		g._on_intent("close_settings",{});g._on_intent("resume",{});g.hurt_clock=0;g._hurt(7)
		ck(requests==[["player_damage",false]] and not playing(),"muted real damage silent")
		g._on_intent("pause",{});g._on_intent("settings",{});requests.clear()
		g._on_intent("set_setting",{"key":"mute_feedback_sounds","value":false});g._on_intent("close_settings",{});g._on_intent("resume",{})
		ck(not playing() and requests.is_empty(),"unmute/resume never replay")
		var traces:Array=[]
		for muted in [false,true]:
			setup(mode,true);g.settings.mute_feedback_sounds=muted;g.feedback_audio.set_muted(muted)
			var origin_epoch:int=g.effects.epoch
			g._hurt(7);g.hurt_clock=0;g._hurt(13)
			var trace:Dictionary=state_snapshot();trace.effects[0]-=origin_epoch;traces.append(trace)
		ck(traces[0]==traces[1],"enabled/muted authority exact parity "+mode)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	source.clear() # Release this fixture's retained PCM references after its last assertion.
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"Author controlled requests, resources, settings and lifecycle; actual mixer and independent authority remain separate."}));quit(0 if failures.is_empty() else 1)
