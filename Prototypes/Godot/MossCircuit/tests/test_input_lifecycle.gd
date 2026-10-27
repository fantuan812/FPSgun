extends SceneTree
var passed := 0
var failures: Array = []
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func seed_field(node:Node)->LineEdit:
	if node is LineEdit:return node
	for child in node.get_children():
		var found:=seed_field(child)
		if found:return found
	return null
func escape(game)->void:
	var event:=InputEventKey.new()
	event.keycode=KEY_ESCAPE;event.pressed=true
	game._input(event)
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	for modal in ["settings","codex"]:
		game._title()
		var input:=seed_field(game.ui.modal)
		input.text="874205"
		input.text_changed.emit(input.text)
		game._on_intent(modal,{})
		game._on_intent("close_"+modal,{})
		check(game.state=="title" and seed_field(game.ui.modal).text=="874205","title seed survives "+modal)
	game._on_intent("settings",{})
	escape(game)
	check(game.state=="title" and game.ui.current_screen=="title","Escape closes title settings")
	game._start_run(42)
	game._on_intent("pause",{})
	game._on_intent("settings",{})
	escape(game)
	check(game.state=="paused" and game.ui.current_screen=="pause","Escape from pause settings stays paused")
	game._on_intent("resume",{})
	var before_time:float=game.elapsed
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state=="paused" and game.resume_state=="playing","focus loss pauses live combat")
	game._process(.05)
	check(game.elapsed==before_time,"focus-lost combat clock frozen")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.state=="paused","focus gain never auto-resumes")
	game._on_intent("resume",{})
	check(game.state=="playing","explicit resume works after focus loss")
	game._title();game._select_mode("rooms");game._start_run(43)
	game._begin_room_clear()
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state=="paused" and game.resume_state=="room_clear","focus loss preserves clear transition state")
	var progress:float=game.mode.progress()
	game._process(.05)
	check(game.mode.progress()==progress,"focus-lost clear transition frozen")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.resume_state=="room_clear","repeated focus loss does not overwrite resume target")
	game._on_intent("resume",{})
	check(game.state=="room_clear","explicit resume returns to room clear")
	for state_name in ["title","upgrade","shop","inventory","codex","settings","dead","won"]:
		game.state=state_name
		game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(game.state==state_name,"focus loss leaves existing "+state_name+" unchanged")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"input_lifecycle_passed":passed,"failures":failures,"scope":"headless input/notification dispatch; not OS focus or GUI acceptance"}))
	quit(0 if failures.is_empty() else 1)
