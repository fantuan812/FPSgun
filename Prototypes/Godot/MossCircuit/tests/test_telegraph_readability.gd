extends SceneTree
const Telegraph=preload("res://scripts/telegraph_layer.gd")
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	for alpha in [0.0,.1,.9,1.0]:
		var original:=Color(.9,.35,.18,alpha)
		var fill:=Telegraph.line_fill(original)
		check(fill.r==original.r and fill.g==original.g and fill.b==original.b,"warning hue preserved")
		check(is_equal_approx(fill.a,minf(alpha,.16)),"interior low opacity without strengthening faint input")
	for index in range(8):
		var axis:=Vector2.from_angle(index*TAU/8)
		var marker:Dictionary={"kind":"line","pos":Vector2(80,90),"end":Vector2(80,90)+axis*186,"width":102.0,"color":Color(1,.35,.18,.9)}
		var original:=marker.duplicate(true)
		var outline:=Telegraph.line_outline(marker)
		check(outline.size()==5 and outline[0]==outline[4],"closed outline "+str(index))
		check(marker==original,"presentation never mutates marker geometry "+str(index))
		for corner in range(4):
			var relative:Vector2=outline[corner]-marker.pos
			var along:float=relative.dot(axis)
			var across:float=relative.dot(axis.orthogonal())
			check(is_equal_approx(along,0) or absf(along-186)<.001,"outline endpoints match original sweep")
			check(absf(absf(across)-51)<.001,"outline sides match original collision halfwidth")
	check(Telegraph.line_outline({"pos":Vector2.ONE,"end":Vector2.ONE,"width":102}).is_empty(),"zero-length line remains empty")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	for mode_id in ["arena","rooms"]:
		game._title();game._select_mode(mode_id);game._start_run(1616)
		var enemy:Dictionary=game._spawn_kind("boss_warden",game.player_pos+Vector2(220,0))
		enemy.ai_state="warning";enemy.attack="charge";enemy.aim=Vector2.LEFT
		game._sync_telegraphs()
		var marker:Dictionary=game.telegraphs.markers[0]
		check(marker.pos==enemy.pos and marker.end==enemy.pos+enemy.aim*enemy.charge_speed*enemy.charge_duration,"true charge endpoints retained "+mode_id)
		check(marker.width==2*(16*enemy.scale+9),"true swept contact width retained "+mode_id)
		check(game.telegraphs.z_index>game.vfx.z_index and game.telegraphs.z_index>enemy.sprite.z_index,"warning outline remains above actor and decorative effects "+mode_id)
		enemy.attack="blast";enemy.target=game.player_pos;game._sync_telegraphs()
		check(game.telegraphs.markers[0].kind=="circle" and game.telegraphs.markers[0].pos==enemy.target and game.telegraphs.markers[0].radius==105,"blast geometry unchanged "+mode_id)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"telegraph_readability_passed":passed,"failures":failures,"scope":"exact marker/outline geometry and style contract; actual GUI contrast separate"}))
	quit(0 if failures.is_empty() else 1)
