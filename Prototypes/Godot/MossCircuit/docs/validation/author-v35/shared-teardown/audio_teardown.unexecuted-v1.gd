extends RefCounted
## Test-only final-owner observation. Never called by production code.
const DEADLINE_US := 1000000
const SILENCE_SECONDS := 0.15
var owner_refs: Array = []
var stream_refs: Array = []
var capture: AudioEffectCapture
var effect_index := -1
var observations: Array = []

func prepare(owners: Array) -> void:
	for owner in owners:
		owner_refs.append(weakref(owner))
		var has_audio := false
		for property in owner.get_property_list():
			if property.name == "feedback_audio": has_audio = true
		if not has_audio: continue
		var audio = owner.get("feedback_audio")
		for player in audio.players.values():
			var stream: Resource = player.stream
			if stream != null: stream_refs.append(weakref(stream))
			stream = null # The observer must not keep the resource alive.
	capture = AudioEffectCapture.new()
	capture.buffer_length = 2.0
	effect_index = AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, capture)

static func complete(state: Dictionary) -> bool:
	return state.owners_released and state.streams_released and state.invalid == 0 and state.discarded == 0 and state.required_frames > 0 and state.new_pushed >= state.required_frames and state.silent_frames >= state.required_frames and state.elapsed_us >= 150000 and state.elapsed_us <= DEADLINE_US

func finish(tree: SceneTree) -> Dictionary:
	# Existing fixture already queued/freed its owners and yielded its original frame.
	var queued := capture.get_frames_available()
	if queued > 0: capture.get_buffer(queued) # Old queue is not fresh-silence evidence.
	var start := Time.get_ticks_usec()
	var pushed_before := capture.get_pushed_frames()
	var silent_frames := 0
	var invalid := 0
	var state: Dictionary = {"owners_released":false,"streams_released":false,"invalid":0,"discarded":0,"required_frames":int(ceil(AudioServer.get_mix_rate() * SILENCE_SECONDS)),"new_pushed":0,"silent_frames":0,"elapsed_us":0}
	var success := false
	while Time.get_ticks_usec() - start < DEADLINE_US:
		await tree.create_timer(0.01).timeout
		var available := capture.get_frames_available()
		if available > 0:
			var frames := capture.get_buffer(available)
			for frame in frames:
				if not is_finite(frame.x) or not is_finite(frame.y): invalid += 1
				if is_finite(frame.x) and is_finite(frame.y) and absf(frame.x) <= 0.000001 and absf(frame.y) <= 0.000001: silent_frames += 1
				else: silent_frames = 0
		state.owners_released = true
		for reference in owner_refs: state.owners_released = state.owners_released and reference.get_ref() == null
		state.streams_released = true
		for reference in stream_refs: state.streams_released = state.streams_released and reference.get_ref() == null
		state.invalid = invalid
		state.discarded = capture.get_discarded_frames()
		state.new_pushed = capture.get_pushed_frames() - pushed_before
		state.silent_frames = silent_frames
		state.elapsed_us = Time.get_ticks_usec() - start
		observations.append(state.duplicate(true))
		if complete(state): success = true; break
	AudioServer.remove_bus_effect(0, effect_index)
	var removed := AudioServer.get_bus_effect_count(0) == effect_index
	capture = null
	var report := {"complete":success and removed,"capture_removed":removed,"pre_window_drained":queued,"observations":observations,"scope":"Test-only bounded final-owner resource release and fresh internal silence; not physical output or a universal timing guarantee."}
	print("TEST_AUDIO_TEARDOWN ", JSON.stringify(report))
	if not report.complete: push_error("Test final-owner audio teardown did not complete within its bounded contract")
	return report
