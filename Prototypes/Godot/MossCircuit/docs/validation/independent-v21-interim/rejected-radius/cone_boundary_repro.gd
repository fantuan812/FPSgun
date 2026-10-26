extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode_id in ["arena","rooms"]:
		g._title();g._select_mode(mode_id);g._start_run(874205);g.build.weapons=["cryo_sprayer"];g._recompute()
		var dir:Vector2=Vector2.from_angle(PI*1.75)
		var anchor:Dictionary=g._spawn_kind("crawler",g.player_pos+dir*40.0);anchor.hp=500
		var edge:Dictionary=g._spawn_kind("crawler",g.player_pos+dir*190.0);edge.hp=500
		g._fire_weapon("cryo_sprayer",0)
		print(JSON.stringify({"mode":mode_id,"origin":str(g.player_pos),"point":str(edge.pos),"angle":315,"radius":190,"computed_distance":edge.pos.distance_to(g.player_pos),"distance_error":edge.pos.distance_to(g.player_pos)-190,"hp":edge.hp,"chilled":edge.has("chill_until")}))
	g.queue_free();await process_frame;quit()
