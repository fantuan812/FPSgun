extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,message:String)->void:
	if value:passed+=1
	else:failures.append(message)
func _initialize()->void:call_deferred("run")
func reset(g)->void:
	g._start_run(71);g.spawn_clock=999;g.weapon_clocks=[999.0]
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var a=g.actor_anim
	for mode_id in ["arena","rooms"]:
		g._title();g._select_mode(mode_id)
		for kind in ["crawler","flanker"]:
			reset(g)
			var e:Dictionary=g._spawn_kind(kind,g.player_pos+Vector2(60,0))
			var id:int=e.id
			for distance in [0.0,20.0,84.9,85.0,150.0]:
				e.pos=g.player_pos+Vector2(distance,0)
				a.observe_enemy(e,"move",g.player_pos)
				check(a.state_of(id)=="move","%s/%s move at distance %s has no fake warning"%[mode_id,kind,distance])
			for action in ["hurt","death"]:
				var asset_id:String=kind+"_"+action
				check(a.assets.has(asset_id),"asset present "+asset_id)
				if not a.assets.has(asset_id):continue
				var n:int=9 if action=="hurt" else 16
				var duration:float=.27 if action=="hurt" else .72
				var asset:Dictionary=a.assets[asset_id]
				check(asset.frames.get_frame_count("action")==n,"frame count "+asset_id)
				for flipped in [false,true]:
					reset(g);e=g._spawn_kind(kind,g.player_pos+Vector2(100,0));id=e.id
					e.sprite.flip_h=flipped
					var base_foot:Vector2=a.actors[id].base_foot
					if action=="death":a.die(id)
					else:a.trigger(id,action)
					check(is_equal_approx(a.actors[id].duration,duration),"duration "+asset_id)
					for frame in range(n):
						a.actors[id].age=(float(frame)+.5)/n*duration
						a._present(a.actors[id])
						check(e.sprite.frame==frame,"frame progression %s/%s"%[asset_id,frame])
						var texture:Texture2D=e.sprite.sprite_frames.get_frame_texture("action",frame)
						var contact:Vector2=(texture.get_size()*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+e.sprite.offset)*e.sprite.scale
						check(contact.distance_to(base_foot)<.001,"foot anchor %s/%s flip=%s"%[asset_id,frame,flipped])
						check(e.sprite.rotation==0,"authored not rotated "+asset_id)
						if frame==0:
							check(absf(float(asset.records[0].alpha_bbox[3])*e.sprite.scale.y-a.actors[id].height)<.001,"first pose body height continuity "+asset_id)
					if action=="hurt":
						var age:float=a.actors[id].age
						check(not a.trigger(id,"hurt") and a.actors[id].age==age,"repeat hurt does not restart")
						a.advance(duration-age+.00001)
						check(a.state_of(id)=="idle" and e.sprite.sprite_frames==a.actors[id].base_frames,"hurt returns to base pose")
					else:
						check(not a.trigger(id,"hurt") and not a.trigger(id,"attack"),"death terminal")
						a.advance(duration-a.actors[id].age-.00001)
						check(a.actors.has(id) and e.sprite.frame==15,"death last frame persists until end")
						a.advance(.00002)
						check(not a.actors.has(id) and not a.corpses.has(id),"death recycled at duration")
			reset(g);e=g._spawn_kind(kind,g.player_pos+Vector2(200,0));id=e.id
			a.trigger(id,"hurt");a.advance(.1)
			var saved_frame:int=e.sprite.frame
			a.reduced_flashes=true;a.refresh_style()
			check(e.sprite.frame==saved_frame and e.sprite.modulate==a.actors[id].base_color,"reduced flashes retains reaction frame without tint "+kind)
			a.reduced_flashes=false;a.refresh_style()
			var age:float=a.actors[id].age
			g._on_intent("pause",{});g._process(.05)
			check(a.actors[id].age==age,"pause freezes "+kind)
			reset(g);e=g._spawn_kind(kind,g.player_pos+Vector2(200,0));id=e.id
			a.trigger(id,"hurt");a.advance(.13);a.die(id)
			check(a.state_of(id)=="death" and e.sprite.frame==0 and a.actors[id].age==0,"lethal interruption restarts death at frame zero "+kind)
			a.set_phase(id,"move");check(a.state_of(id)=="death","movement cannot interrupt corpse "+kind)
			reset(g);e=g._spawn_kind(kind,g.player_pos+Vector2(200,0));id=e.id
			e.hp=0;g._simulate(.001)
			check(g.kills==1 and not g.enemies.has(e) and a.corpses.has(id),"dead actor removed from combat exactly once "+kind)
			g._simulate(.001);check(g.kills==1,"no duplicate reward "+kind)
			var generation:int=a.generation
			reset(g);check(a.generation>generation and a.corpses.is_empty() and a.actors.size()==1,"reset clears tails "+kind)
	g.queue_free();await process_frame
	print(JSON.stringify({"independent_crawler_flanker_passed":passed,"failures":failures,"scope":"headless lifecycle and geometric anchors; image appearance requires separate pixel inspection"}))
	quit(0 if failures.is_empty() else 1)
