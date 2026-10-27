extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func prepare(game,mode_id:String="arena",phase2:bool=false)->Dictionary:
	game._title();game._select_mode(mode_id);game._start_run(1616)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.stats.hp=10000;game.stats.max_hp=10000
	var enemy:Dictionary=game._spawn_kind("boss_warden",game.player_pos+Vector2(280,0))
	enemy.hp=enemy.max_hp*(.4 if phase2 else .9);enemy.anim_hp=enemy.hp
	enemy.cooldown_left=0
	return enemy
func trace(game,enemy:Dictionary)->Array:
	return [enemy.pos,enemy.hp,enemy.phase,enemy.ai_state,enemy.attack,enemy.attack_index,enemy.aim,enemy.target,enemy.cooldown_left,enemy.warning_left,enemy.charge_left,enemy.recover_left,game.stats.hp,game.hurt_clock,game.elapsed,game.wave_time,game.enemy_bullets.size(),game.flashes.size(),game.kills,game.rng.state,game.loot_rng.state,game.shop_rng.state]
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	var actor=game.actor_anim
	check(actor.assets.has("boss_warden_charge"),"distinct Warden charge resource loaded")
	if not actor.assets.has("boss_warden_charge"):
		game.queue_free();await process_frame
		print(JSON.stringify({"warden_charge_passed":passed,"failures":failures}));quit(1);return
	var asset:Dictionary=actor.assets.boss_warden_charge
	check(asset.frames.get_frame_count("action")==16,"exact sixteen authored charge poses")
	check(not asset.frames.get_animation_loop("action"),"charge clip not free-running")
	var enemy:Dictionary=prepare(game)
	game._simulate(.01)
	check(enemy.attack=="charge" and enemy.ai_state=="warning","true AI selects first charge")
	check(actor.actors[enemy.id].asset_id=="boss_warden_charge" and enemy.sprite.frame==0,"warning selects charge frame zero")
	check(not actor.trigger(enemy.id,"attack"),"contact cannot restart phase-driven charge")
	for flipped in [false,true]:
		enemy.aim=Vector2.RIGHT if flipped else Vector2.LEFT
		for phase in ["warning","charging","recover"]:
			enemy.ai_state=phase
			var first:int=0 if phase=="warning" else (6 if phase=="charging" else 12)
			var count:int=6 if phase!="recover" else 4
			if phase=="recover":actor.actors[enemy.id].recover_span=.8
			for frame in range(count):
				var progress:float=(float(frame)+.5)/count
				enemy.warning_left=enemy.warning*(1-progress)
				enemy.charge_left=enemy.charge_duration*(1-progress)
				enemy.recover_left=.8*(1-progress)
				actor.observe_enemy(enemy,phase,enemy.pos-enemy.aim*100)
				check(enemy.sprite.frame==first+frame,"true "+phase+" selects frame "+str(first+frame))
				check(enemy.sprite.flip_h==flipped,"locked charge aim survives player crossing")
				var texture:Texture2D=enemy.sprite.sprite_frames.get_frame_texture("action",enemy.sprite.frame)
				var foot:Vector2=(texture.get_size()*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+enemy.sprite.offset)*enemy.sprite.scale
				check(foot.distance_to(actor.actors[enemy.id].base_foot)<.001,"fixed logical charge anchor")
	enemy=prepare(game);enemy.ai_state="warning";enemy.attack="charge";enemy.warning_left=.001
	game._simulate(.002)
	check(enemy.ai_state=="charging" and enemy.sprite.frame==6,"same-tick charge release frame matches AI")
	actor.trigger(enemy.id,"hurt");game._simulate(.1);actor.advance(.28)
	check(actor.actors[enemy.id].asset_id=="boss_warden_charge" and enemy.sprite.frame>=6 and enemy.sprite.frame<=11,"hurt reveals current charge, not a restarted attack")
	enemy.ai_state="recover";enemy.recover_left=.8;actor.observe_enemy(enemy,"charging",game.player_pos)
	check(enemy.sprite.frame==12,"recovery begins at frame twelve")
	enemy.recover_left=.001;game._simulate(.002)
	check(enemy.ai_state=="move" and actor.actors[enemy.id].attack_variant=="","finished charge clears active variant")
	check(actor.trigger(enemy.id,"attack"),"normal chase contact presentation retained")
	enemy=prepare(game);enemy.attack_index=1
	game._simulate(.01)
	check(enemy.attack=="blast" and actor.actors[enemy.id].asset_id=="boss_warden_attack","blast retains old slam sheet")
	enemy.warning_left=.001;game._simulate(.002)
	check(enemy.ai_state=="recover" and actor.state_of(enemy.id)=="attack","blast preserves existing event-driven release")
	check(enemy.sprite.frame==actor.assets.boss_warden_attack.release_frame,"blast release frame unchanged")
	# Finite deterministic inputs compare new presentation against the old shared attack mapping.
	var variants:Dictionary=actor.config.profiles.boss_warden.attack_profiles.duplicate(true)
	for mode_id in ["arena","rooms"]:
		for phase2 in [false,true]:
			var baseline:Array=[]
			for enabled in [false,true]:
				actor.config.profiles.boss_warden.attack_profiles=variants if enabled else {}
				enemy=prepare(game,mode_id,phase2)
				for tick in range(600):
					actor.advance(.02);game._simulate(.02)
					if not enabled:baseline.append(trace(game,enemy))
					else:check(trace(game,enemy)==baseline[tick],"authority parity "+mode_id+" phase2="+str(phase2)+" tick="+str(tick))
	actor.config.profiles.boss_warden.attack_profiles=variants
	var owner_refs:Dictionary={}
	var owner_observation:Dictionary={"case":"test_warden_charge.gd","before":{},"after_one_frame":{},"chunks":[],"deadline_ms":1000,"scope":"External disposal-only owner observation; original failed resource identities for non-reproduced cases remain unknown."}
	for cue in game.feedback_audio.players:
		var stream:Resource=game.feedback_audio.players[cue].stream
		owner_refs[cue]=weakref(stream)
		owner_observation.before[cue]={"id":stream.get_instance_id(),"class":stream.get_class(),"path":stream.resource_path,"playing":game.feedback_audio.players[cue].playing}
		stream=null # Never pin the resource through the observer.
	var owner_capture:=AudioEffectCapture.new();owner_capture.buffer_length=2.0
	var owner_effect_index:int=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,owner_capture)
	game.queue_free();await process_frame
	owner_observation.node_freed=not is_instance_valid(game)
	for cue in owner_refs:owner_observation.after_one_frame[cue]=owner_refs[cue].get_ref()!=null
	var owner_queued:int=owner_capture.get_frames_available()
	if owner_queued>0:owner_capture.get_buffer(owner_queued) # Explicit pre-window drain, not fresh-silence evidence.
	owner_observation.pre_window_drained=owner_queued
	var owner_required:int=int(ceil(AudioServer.get_mix_rate()*.15))
	var owner_start:int=Time.get_ticks_usec()
	var owner_pushed_before:int=owner_capture.get_pushed_frames()
	var owner_silent_frames:int=0
	var owner_complete:=false
	var owner_invalid:int=0
	while Time.get_ticks_usec()-owner_start<1000000:
		await create_timer(.01).timeout
		var owner_count:int=owner_capture.get_frames_available()
		var owner_peak:=0.0
		if owner_count>0:
			var owner_pcm:PackedVector2Array=owner_capture.get_buffer(owner_count)
			for frame in owner_pcm:
				if not is_finite(frame.x) or not is_finite(frame.y):owner_invalid+=1
				owner_peak=maxf(owner_peak,maxf(absf(frame.x),absf(frame.y)))
				if absf(frame.x)<=.000001 and absf(frame.y)<=.000001:owner_silent_frames+=1
				else:owner_silent_frames=0
		var owner_released:=true
		for cue in owner_refs:owner_released=owner_released and owner_refs[cue].get_ref()==null
		owner_observation.chunks.append({"frames":owner_count,"peak":owner_peak,"pushed":owner_capture.get_pushed_frames(),"refs_released":owner_released,"elapsed_us":Time.get_ticks_usec()-owner_start})
		if owner_observation.node_freed and owner_invalid==0 and owner_released and owner_silent_frames>=owner_required and owner_capture.get_pushed_frames()-owner_pushed_before>=owner_required and Time.get_ticks_usec()-owner_start>=150000 and owner_capture.get_discarded_frames()==0:
			owner_complete=true;break
	owner_observation.complete=owner_complete
	owner_observation.invalid_samples=owner_invalid
	owner_observation.silent_frames=owner_silent_frames
	owner_observation.discarded=owner_capture.get_discarded_frames()
	owner_observation.new_pushed=owner_capture.get_pushed_frames()-owner_pushed_before
	owner_observation.required_frames=owner_required
	owner_observation.elapsed_us=Time.get_ticks_usec()-owner_start
	AudioServer.remove_bus_effect(0,owner_effect_index)
	owner_observation.capture_removed=AudioServer.get_bus_effect_count(0)==owner_effect_index
	var owner_args:=OS.get_cmdline_user_args()
	if not owner_args.is_empty():FileAccess.open(owner_args[0],FileAccess.WRITE).store_string(JSON.stringify(owner_observation,"  ")+"\n")
	print("OWNER_OBSERVATION ",JSON.stringify(owner_observation))
	if not owner_complete or not owner_observation.capture_removed:push_error("External owner observation reached bounded deadline without complete reference release/fresh silence")
	print(JSON.stringify({"warden_charge_passed":passed,"failures":failures,"scope":"phase selection, anchor, hurt/contact arbitration, finite authority/RNG parity; GUI separate"}))
	quit(0 if failures.is_empty() else 1)
