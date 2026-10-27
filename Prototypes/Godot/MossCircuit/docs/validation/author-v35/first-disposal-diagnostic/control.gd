extends SceneTree
const Audio = preload("res://scripts/feedback_audio.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var args:=OS.get_cmdline_user_args();var drain:bool=not args.is_empty() and args[0]=="drain"
	var capture:=AudioEffectCapture.new();capture.buffer_length=1.0
	var effect_index:int=AudioServer.get_bus_effect_count(0);AudioServer.add_bus_effect(0,capture)
	var audio=Audio.new();root.add_child(audio)
	var hurt:WeakRef=weakref(audio.players.player_damage.stream)
	var block:WeakRef=weakref(audio.players.shield_block.stream)
	var report:Dictionary={"mode":"drain" if drain else "immediate","driver":AudioServer.get_driver_name(),"helper":"unchanged held R1","requested":audio.request("player_damage")}
	audio.queue_free();await process_frame
	report.hurt_alive_one_frame=hurt.get_ref()!=null
	report.block_alive_one_frame=block.get_ref()!=null
	report.node_freed=not is_instance_valid(audio)
	report.frames=0;report.peak=0.0;report.pushed_before=capture.get_pushed_frames()
	if drain:
		var until:int=Time.get_ticks_usec()+250000
		while Time.get_ticks_usec()<until:
			await create_timer(.01).timeout
			var available:int=capture.get_frames_available()
			if available>0:
				var frames:PackedVector2Array=capture.get_buffer(available);report.frames+=frames.size()
				for frame in frames:report.peak=maxf(report.peak,maxf(absf(frame.x),absf(frame.y)))
		await process_frame
	report.hurt_alive_after=hurt.get_ref()!=null;report.block_alive_after=block.get_ref()!=null
	report.pushed_after=capture.get_pushed_frames();report.discarded=capture.get_discarded_frames()
	AudioServer.remove_bus_effect(0,effect_index)
	if args.size()>1:FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print(JSON.stringify(report));quit(0)
