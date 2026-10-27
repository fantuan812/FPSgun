extends SceneTree
const Teardown = preload("res://tests/support/audio_teardown.gd")
func _initialize()->void:
	var failures:Array=[]
	var good:Dictionary={"owner_count":1,"game_owner_count":1,"prepare_errors":0,"owners_released":true,"streams_released":true,"invalid":0,"discarded":0,"required_frames":6615,"new_pushed":8192,"silent_frames":8192,"elapsed_us":180000}
	if not Teardown.complete(good):failures.append("valid finite observed completion")
	var bad_states:Array=[{"owner_count":0},{"game_owner_count":0},{"prepare_errors":1},{"owners_released":false},{"streams_released":false},{"invalid":1},{"discarded":1},{"required_frames":0},{"new_pushed":0},{"new_pushed":6614},{"silent_frames":0},{"silent_frames":6614},{"elapsed_us":149999},{"elapsed_us":1000001}]
	for change in bad_states:
		var state:=good.duplicate(true);state.merge(change,true)
		if Teardown.complete(state):failures.append("unsafe state accepted "+str(change))
	print(JSON.stringify({"checks":1+bad_states.size(),"failures":failures,"scope":"Deterministic predicate negatives: retained owners/resources, nonfinite/drop, missing or insufficient fresh/silent frames, early/late completion. Real engine ownership checked separately."}))
	quit(0 if failures.is_empty() else 1)
