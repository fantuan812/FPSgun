extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func prepare(g)->Dictionary:
	g._start_run(1111);g.spawn_clock=999;g.weapon_clocks=[999.0]
	var e:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(200,0))
	e.ai_state="warning";e.warning_left=.65;e.attack="shot";e.aim=Vector2.LEFT;e.cooldown_left=999
	return e
func run_checks()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var e:Dictionary=prepare(g)
	var a=g.actor_anim
	var loaded:bool=a.assets.has("spitter_shoot")
	for id in ["spitter_shoot","spitter_hurt","spitter_death"]:
		check(a.assets.has(id),"approved resource loaded "+id)
		if not a.assets.has(id):continue
		var asset:Dictionary=a.assets[id]
		check(asset.frames.get_frame_count("action")==9,"nine frames "+id)
		check(not asset.frames.get_animation_loop("action"),"manual one-shot "+id)
		var canvas:Vector2=asset.frames.get_frame_texture("action",0).get_size()
		var neutral:Array=asset.records[0].alpha_bbox
		check(is_equal_approx(float(neutral[1]+neutral[3]),float(asset.anchor[1])*canvas.y),"neutral frame grounded "+id)
		for i in range(9):
			check(asset.frames.get_frame_texture("action",i).get_size()==canvas,"fixed canvas "+id+str(i))
			var box:Array=asset.records[i].alpha_bbox
			check(box[0]>=0 and box[1]>=0 and box[2]>0 and box[3]>0 and box[0]+box[2]<=canvas.x and box[1]+box[3]<=canvas.y,"visible bounds "+id+str(i))
	for phase in ["warning","attack","recover"]:
		var segment:Array=a.config.profiles.spitter.phase_frames[phase]
		for step in range(11):
			a.set_phase(e.id,phase,float(step)/10)
			if loaded:
				var expected:int=int(segment[0])+mini(int(segment[1]-segment[0]),floori(float(step)/10*(segment[1]-segment[0]+1)+.0000001))
				check(e.sprite.frame==expected,"phase frame "+phase+str(step))
			check(not a.trigger(e.id,"attack"),"contact cannot fake ranged release")
	g._simulate(.64)
	check(e.ai_state=="warning" and g.enemy_bullets.is_empty(),"late windup still emits no projectile")
	if loaded:check(e.sprite.frame==3,"last windup frame before release")
	g._simulate(.02)
	check(e.ai_state=="recover" and g.enemy_bullets.size()==1,"actual shot event creates exactly one bullet")
	if loaded:check(e.sprite.frame==4,"same tick actual shot shows release frame4")
	check(e.sprite.flip_h==false,"release faces locked left aim")
	var bullet:Dictionary=g.enemy_bullets[0]
	check(bullet.velocity==e.aim*145 and bullet.owner==e.id and bullet.damage==8,"unchanged bullet authority")
	check(bullet.pos.is_equal_approx(e.pos+e.aim*145*.02),"unchanged center-origin bullet movement")
	check(is_equal_approx(a.actors[e.id].recover_span,.7),"capture real recovery span")
	for step in range(1,5):
		g._simulate(.14)
		if loaded:check(e.sprite.frame==4+step,"real recovery progresses once "+str(step))
		check(g.enemy_bullets.size()==1,"no animation-frame duplicate projectile")
	g._simulate(.15)
	check(e.ai_state=="move" and a.state_of(e.id)=="move","completion returns to locomotion")
	# A real HP delta and the real shot event happen in the same combat tick.
	e=prepare(g);e.warning_left=.001;e.hp-=1
	g._simulate(.02)
	check(g.enemy_bullets.size()==1 and a.state_of(e.id)=="hurt","hurt masks release without delaying real bullet")
	check(a.actors[e.id].phase=="recover","underlying phase is current recovery, not queued attack")
	var before_age:float=a.actors[e.id].age
	var before_left:float=e.recover_left
	var before_bullet:Dictionary=g.enemy_bullets[0].duplicate(true)
	g._on_intent("pause",{});g._process(.8)
	check(a.actors[e.id].age==before_age and e.recover_left==before_left and g.enemy_bullets[0]==before_bullet,"pause freezes action/AI/projectile together")
	g._resume()
	for i in range(6):g._process(.05)
	check(g.enemy_bullets.size()==1 and a.state_of(e.id)=="recover","hurt completion does not replay shot")
	if loaded:check(e.sprite.frame==6,"hurt completion uses current recovery frame6, not4")
	var flip:bool=e.sprite.flip_h;e.aim=Vector2(.00001,1)
	a.observe_enemy(e,"recover",e.pos+Vector2(400,0))
	check(e.sprite.flip_h==flip,"near-vertical locked aim retains orientation")
	e.hp=0;var kills:int=g.kills;g._simulate(.001)
	check(g.kills==kills+1 and g.enemy_bullets.is_empty() and a.state_of(e.id)=="death","death exits authority and removes its shots immediately")
	check(not a.trigger(e.id,"hurt") and not a.trigger(e.id,"attack"),"late feedback cannot interrupt death")
	g._simulate(.01);check(g.kills==kills+1,"death clip grants no duplicate reward")
	a.advance(.64)
	if a.assets.has("spitter_death"):check(e.sprite.frame==8,"death last frame is visible before reclamation")
	check(a.actors.has(e.id),"death tail retained through final frame")
	a.advance(.081);check(not a.actors.has(e.id),"one-shot corpse reclaimed")
	g._title();g._select_mode("rooms");g._start_run(1111)
	check(a.corpses.is_empty() and a.actors.keys()==[0] and g.enemy_bullets.is_empty(),"cross-mode new run clears all old shot/action references")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v11 data-only spitter actions; no gameplay code change"}))
	quit(0 if failures.is_empty() else 1)
