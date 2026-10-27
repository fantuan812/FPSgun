extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func run_checks()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	for kind in ["crawler","flanker"]:
		g._start_run(1313);g.spawn_clock=999;g.weapon_clocks=[999.0]
		var e:Dictionary=g._spawn_kind(kind,g.player_pos+Vector2(60,0))
		var a=g.actor_anim
		for action in ["hurt","death"]:
			var id:String=kind+"_"+action
			check(a.assets.has(id),"loaded "+id)
			if not a.assets.has(id):continue
			var asset:Dictionary=a.assets[id]
			check(asset.frames.get_frame_count("action")== (9 if action=="hurt" else 16),"authored count "+id)
			check(not asset.frames.get_animation_loop("action"),"one shot "+id)
		a.observe_enemy(e,"move",g.player_pos)
		check(a.state_of(e.id)=="move" and e.sprite.animation=="walk","close range retains locomotion "+kind)
		var before:Vector2=e.pos
		g._simulate(.01)
		check(e.pos!=before,"close range still moves "+kind)
		check(a.trigger(e.id,"hurt"),"hurt begins "+kind)
		check(is_equal_approx(a.actors[e.id].duration,.27),"hurt duration "+kind)
		a.advance(.13)
		var age:float=a.actors[e.id].age
		check(not a.trigger(e.id,"hurt") and a.actors[e.id].age==age,"repeat hit does not reset "+kind)
		a.advance(.14)
		check(a.actors[e.id].reaction=="" and a.state_of(e.id)=="move","hurt restores authoritative move "+kind)
		check(a.trigger(e.id,"attack"),"contact visual trigger remains legal "+kind)
		a.die(e.id)
		check(a.actors[e.id].corpse and a.state_of(e.id)=="death","death overrides contact "+kind)
		check(is_equal_approx(a.actors[e.id].duration,.72),"death duration "+kind)
		check(not a.trigger(e.id,"hurt") and not a.trigger(e.id,"attack"),"death is terminal "+kind)
		a.advance(.719)
		check(a.actors.has(e.id),"corpse exists before duration "+kind)
		if a.assets.has(kind+"_death"):check(e.sprite.frame==15,"last frame shown before recycle "+kind)
		a.advance(.002)
		check(not a.actors.has(e.id),"corpse recycled after duration "+kind)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("CONTACT_ENEMY_ACTIONS ",passed," passed; failures=",failures)
	quit(0 if failures.is_empty() else 1)
