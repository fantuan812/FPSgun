extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(g,mode_id:String,phase2:bool=false)->Dictionary:
	g._title();g._select_mode(mode_id);g._start_run(240102)
	g.spawn_clock=999;g.weapon_clocks=[999.0];g.stats.hp=1000;g.stats.max_hp=1000
	var e:Dictionary=g._spawn_kind("boss_core",g.player_pos+Vector2(300,0))
	e.hp=e.max_hp*(.4 if phase2 else .9);e.anim_hp=e.hp;e.cooldown_left=100
	e.aim=Vector2.LEFT;e.target=g.player_pos
	return e
func children(g,parent:int)->Array:return g.enemies.filter(func(e):return e.get("parent_id",-1)==parent and e.hp>0)
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	var a=g.actor_anim
	for action in ["hurt","death"]:
		var key:String="boss_core_"+action
		check(a.assets.has(key),"authored "+key)
		if a.assets.has(key):check(a.assets[key].frames.get_frame_count("action")== (9 if action=="hurt" else 16),"frame count "+key)
	for mode_id in ["arena","rooms"]:
		# The real scheduling rule is every third phase2 selection, not alternating attacks.
		for phase2 in [false,true]:
			var e:Dictionary=setup(g,mode_id,phase2)
			for index in range(6):
				e.ai_state="move";e.cooldown_left=0
				var events:Array=g.EnemyAI.tick(e,g.player_pos,.001,float(index))
				check(e.attack==("summon" if phase2 and index%3==2 else "ring"),"selection %s/%s/%s"%[mode_id,phase2,index])
				check(events.is_empty() and e.ai_state=="warning" and is_equal_approx(e.warning_left,.85),"selection starts real .85 warning")
				check(is_equal_approx(e.cooldown_left,3.4/(1.2 if phase2 else 1.0)),"phase cooldown")
		for scenario in ["ring_phase1","ring_phase2","summon_phase2","threshold_crossing"]:
			var phase2:bool=scenario in ["ring_phase2","summon_phase2"]
			var e:Dictionary=setup(g,mode_id,phase2);var id:int=e.id
			e.ai_state="warning";e.attack="summon" if scenario=="summon_phase2" else "ring";e.warning_left=.12
			e.hp-=1;g._process(.01)
			check(a.state_of(id)=="hurt",mode_id+scenario+" real damage overlays warning")
			if scenario=="threshold_crossing":e.hp=e.max_hp*.49
			var age:float=a.actors[id].age
			check(not a.trigger(id,"hurt") and a.actors[id].age==age,"repeat hurt not restarted")
			for i in range(12):g._process(.01)
			check(e.ai_state=="recover" and a.state_of(id)=="hurt","release not delayed by hurt "+scenario)
			var expected_count:int=8 if scenario=="ring_phase1" else 12
			if scenario=="summon_phase2":
				check(children(g,id).size()==2 and g.enemy_bullets.is_empty(),"two actual summons, no ring")
			else:
				check(g.enemy_bullets.size()==expected_count and children(g,id).is_empty(),"actual ring count "+scenario)
				for b in g.enemy_bullets:check(b.owner==id and is_equal_approx(b.velocity.length(),145) and b.damage==15,"owned ring authority")
			for i in range(16):g._process(.01)
			check(a.actors[id].reaction=="" and a.state_of(id)=="recover","hurt ends in current recovery")
			check(e.recover_left>0 and e.recover_left<.7,"recovery clock kept running")
			check(children(g,id).size()==2 if scenario=="summon_phase2" else g.enemy_bullets.size()==expected_count,"no duplicate deferred release")
		# Parent-local live-child cap, including a non-child which must not consume the budget.
		for existing in range(5):
			var e:Dictionary=setup(g,mode_id,true);var id:int=e.id
			for i in range(existing):
				var child:Dictionary=g._spawn_kind("crawler",e.pos+Vector2(0,30*i),id);child.speed=0
			var other:Dictionary=g._spawn_kind("crawler",e.pos+Vector2(0,-80),999);other.speed=0
			e.ai_state="warning";e.attack="summon";e.warning_left=.001;a.trigger(id,"hurt")
			g._process(.01)
			check(children(g,id).size()==existing+mini(2,maxi(0,3-existing)),"live child cap "+mode_id+str(existing))
		# Death cancels future emission, but does not kill already-existing children.
		for phase in ["ring_warning","summon_warning","recover","move"]:
			var e:Dictionary=setup(g,mode_id,true);var id:int=e.id
			var child:Dictionary=g._spawn_kind("crawler",e.pos+Vector2(0,50),id);child.speed=0
			var other:Dictionary=g._spawn_kind("spitter",e.pos+Vector2(0,-80));other.speed=0;other.cooldown_left=100
			g.enemy_bullets=[{"pos":e.pos,"velocity":Vector2.RIGHT,"life":4.0,"damage":15,"owner":id},{"pos":other.pos,"velocity":Vector2.RIGHT,"life":4.0,"damage":12,"owner":other.id}]
			e.ai_state="warning" if phase.ends_with("warning") else phase
			e.attack="summon" if phase=="summon_warning" else "ring";e.warning_left=.001;e.recover_left=.001
			g.stats.hp=20
			var coins:int=g.build.coins
			e.hp=0;g._process(.01)
			check(not g.enemies.has(e) and a.corpses.has(id),"Core removed immediately, visual retained")
			check(children(g,id).size()==1 and child.hp>0,"surviving child not tied to parent death")
			check(g.enemy_bullets.size()==1 and g.enemy_bullets[0].owner==other.id,"only dead owner's bullets cleared")
			check(g.build.coins==coins+100 and g.stats.hp==20 and not g.build.get("boss_protocol",false),"Core trophy reward only, no Warden repair")
			check(g.run.boss_rewards.has("boss_core") and g.kills==1,"Core award recorded once")
			g._boss_killed(e);a.die(id)
			check(g.build.coins==coins+100 and a.corpses.count(id)==1,"reentrant award/death idempotent")
			for i in range(10):g._process(.01)
			check(children(g,id).size()==1 and g.kills==1,"no postmortem summon or kill")
			var age:float=a.actors[id].age
			g._on_intent("pause",{});g._process(.05)
			check(a.actors[id].age==age,"pause freezes visual tail")
			g._resume();a.advance(.72-age-.00001)
			check(a.actors.has(id) and e.sprite.frame==15,"last death frame before recycle")
			a.advance(.00002);check(not a.actors.has(id),"tail recycles at .72")
		# Mode-specific end policy must not become corpse-driven or child-death-driven.
		var e:Dictionary=setup(g,mode_id,true);var id:int=e.id
		var child:Dictionary=g._spawn_kind("crawler",e.pos+Vector2(0,50),id);child.speed=0
		if mode_id=="arena":g.wave=6;g.boss_spawned=true;g.wave_time=0
		else:g.mode.planned_index=g.mode.planned_count
		e.hp=0;g._process(.01)
		check(g.state=="playing" and children(g,id).size()==1,"early parent death leaves active battlefield")
		if mode_id=="arena":
			g.wave_time=float(g.config.waves.duration);g._complete_wave()
			check(g.state=="won" and g.enemies.is_empty() and a.corpses.has(id),"timer plus boss defeat settles survivors without awaiting tail")
		else:
			check(not g.mode.can_end(g.run,g.combat,g.encounters),"room children block clear")
			child.hp=0;g._process(.01)
			check(g.state=="room_clear","last child enables normal room clear")
		var generation:int=a.generation
		g._title();g._start_run(71)
		check(a.generation>generation and a.corpses.is_empty() and a.actors.size()==1,"restart removes stale tails")
	for action in ["hurt","death"]:
		var key:String="boss_core_"+action
		if not a.assets.has(key):continue
		var asset:Dictionary=a.assets[key]
		for flipped in [false,true]:
			var e:Dictionary=setup(g,"arena");var id:int=e.id;e.sprite.flip_h=flipped
			if action=="death":a.die(id)
			else:a.trigger(id,"hurt")
			var count:int=9 if action=="hurt" else 16
			check(is_equal_approx(a.actors[id].duration,.27 if action=="hurt" else .72),"Core duration")
			for i in range(count):
				a.actors[id].age=a.actors[id].duration*(float(i)+.5)/count;a._present(a.actors[id])
				check(e.sprite.frame==i,"Core frame index")
				var t:Texture2D=e.sprite.sprite_frames.get_frame_texture("action",i)
				var logical_anchor:Vector2=(t.get_size()*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+e.sprite.offset)*e.sprite.scale
				check(logical_anchor.distance_to(a.actors[id].base_foot)<.001,"logical hover registration, not physical foot")
				if i==0:check(absf(float(asset.records[0].alpha_bbox[3])*e.sprite.scale.y-a.actors[id].height)<.001,"first pose height continuity")
			if action=="hurt":
				var frame:int=e.sprite.frame;a.reduced_flashes=true;a.refresh_style()
				check(e.sprite.frame==frame and e.sprite.modulate==a.actors[id].base_color,"reduced flashes preserves pose")
				a.reduced_flashes=false
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_core_reactions_passed":passed,"failures":failures,"scope":"headless actual events, parent/child lifetime, modes, reaction overlay and logical anchors; no GUI/Windows playtest"}))
	quit(0 if failures.is_empty() else 1)
