extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(960,540)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	for mode_id in ["arena","rooms"]:
		game._title();game._select_mode(mode_id);game._start_run(71)
		for viewport_size in [Vector2i(960,540),Vector2i(1280,720)]:
			root.size=viewport_size
			await process_frame;await process_frame
			game._update_hud()
			await process_frame
			var hud_rect:Rect2=game.ui.hud.get_global_rect()
			var objective_rect:Rect2=game.mode_status.objective.get_global_rect()
			var context:String=mode_id+" "+str(viewport_size)
			check(objective_rect.position.y>=hud_rect.end.y+8,"objective below actual HUD "+context)
			check(objective_rect.end.x<=hud_rect.end.x,"objective within right edge "+context)
			if mode_id=="rooms":
				check(game.mode_status.badge.position.y>=hud_rect.end.y+8,"room badge below HUD "+context)
				check(objective_rect.position.x>=game.mode_status.badge.position.x+48,"room objective does not overlap badge "+context)
	game.queue_free();await process_frame
	print(JSON.stringify({"hud_layout_passed":passed,"failures":failures,"scope":"headless actual control rectangles; rendered-window acceptance separate"}))
	quit(0 if failures.is_empty() else 1)
