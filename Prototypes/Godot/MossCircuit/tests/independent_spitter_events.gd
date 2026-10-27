extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func run()->void:
	for mode in ["arena","rooms"]:
		var g=load("res://scenes/main.tscn").instantiate()
		root.add_child(g);g.set_process(false);g._select_mode(mode);g._start_run(81127)
		g.spawn_clock=999;g.weapon_clocks=[999.0]
		var e:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(-200,0))
		var ad=g.actor_anim
		var actor:Dictionary=ad.actors[e.id]
		e.cooldown_left=0
		g._simulate(.01)
		check(e.ai_state=="warning" and g.enemy_bullets.is_empty() and actor.phase=="warning",mode+" cooldown starts warning without premature projectile")
		e.warning_left=.06
		g._simulate(.05)
		check(g.enemy_bullets.is_empty() and actor.phase_progress>.9,mode+" immediately before threshold no projectile")
		g._simulate(.05)
		check(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7) and actor.phase=="recover" and actor.phase_progress==0,mode+" threshold enters real recover at zero progress")
		check(g.enemy_bullets.size()==1,mode+" threshold emits exactly one projectile")
		if not g.enemy_bullets.is_empty():
			var bullet:Dictionary=g.enemy_bullets[0]
			check(bullet.owner==e.id and bullet.damage==8 and bullet.velocity==e.aim*145 and is_equal_approx(bullet.life,3.95),mode+" actual shot ownership damage speed and lifetime unchanged")
		var index:int=e.attack_index
		for repeat in range(5):check(not ad.trigger(e.id,"attack"),mode+" contact cannot counterfeit shot "+str(repeat))
		g._simulate(.05)
		check(e.attack_index==index and g.enemy_bullets.size()==1 and actor.phase_progress>0,mode+" recovery does not duplicate actual shot or reset phase")
		# Real damage notification overlaps the next authoritative release.
		g.enemy_bullets.clear();e.ai_state="warning";e.warning_left=.02;e.cooldown_left=999;e.aim=Vector2.RIGHT
		ad.observe_enemy(e,"move",g.player_pos);e.hp-=1
		g._simulate(.001)
		check(actor.state=="hurt",mode+" actual hp loss triggers hurt overlay")
		g._simulate(.05)
		check(actor.state=="hurt" and actor.phase=="recover" and g.enemy_bullets.size()==1,mode+" hurt cannot postpone real projectile")
		for step in range(5):g._simulate(.05);ad.advance(.05)
		ad.advance(.03)
		check(actor.reaction=="" and actor.state=="recover" and actor.phase_progress>.3 and g.enemy_bullets.size()==1,mode+" hurt resumes current recovery without replay or extra shot")
		var saved_left:float=e.recover_left
		var saved_progress:float=actor.phase_progress
		g._on_intent("pause",{});g._process(.8)
		check(e.recover_left==saved_left and actor.phase_progress==saved_progress,mode+" pause freezes authoritative and presentation recovery")
		g._on_intent("resume",{})
		for phase in ["warning","recover"]:
			e.ai_state=phase;e.aim=Vector2.RIGHT;ad.observe_enemy(e,phase,e.pos-Vector2(100,0))
			check(e.sprite.flip_h,mode+" locked aim beats player behind "+phase)
			e.aim=Vector2(.00001,-1);ad.observe_enemy(e,phase,e.pos-Vector2(100,0))
			check(e.sprite.flip_h,mode+" near vertical preserves previous orientation "+phase)
		# Kill before pending warning resolves. Existing owner bullet must be removed.
		e.ai_state="warning";e.warning_left=.001;e.hp=0
		var kills:int=g.kills
		g._simulate(.05)
		check(g.enemies.is_empty() and g.enemy_bullets.is_empty() and g.kills==kills+1 and actor.corpse,mode+" death cancels warning and removes old owner projectiles immediately")
		check(not ad.trigger(e.id,"hurt") and not ad.trigger(e.id,"attack"),mode+" corpse rejects delayed reactions")
		var flip:bool=e.sprite.flip_h
		ad.observe_enemy(e,"warning",e.pos-Vector2(999,0));g._simulate(.05)
		check(g.kills==kills+1 and g.enemy_bullets.is_empty() and actor.state=="death" and e.sprite.flip_h==flip,mode+" repeated tick cannot reward refire or flip corpse")
		if mode=="rooms":
			for planned in range(g.mode.planned_count):g._spawn_enemy()
			for enemy in g.enemies:enemy.hp=0
			g._simulate(.001)
			for drain in range(20):
				if g.state!="upgrade":break
				g._take_upgrade(0,g.choice_generation)
			if g.state=="playing":g._simulate(.001)
			check(g.state=="room_clear" and g.enemy_bullets.is_empty(),"room clearing after spitter death retains no projectile authority")
			var coins:int=g.build.coins
			g._complete_wave();g._complete_wave();ad.observe_enemy(e,"warning",g.player_pos)
			check(g.wave==1 and g.build.coins==coins and g.enemy_bullets.is_empty(),"late spitter observation and repeated early completion cannot pay or refire")
			for tick in range(15):g._process(.05)
			check(g.wave==2 and g.state=="upgrade" and g.enemy_bullets.is_empty(),"room clear advances once without corpse projectile callbacks")
			coins=g.build.coins;g._complete_wave();g._complete_wave()
			check(g.wave==2 and g.build.coins==coins,"repeated settlement cannot credit old spitter twice")
		g._title();g._select_mode("rooms" if mode=="arena" else "arena");g._start_run(81127)
		check(g.actor_anim.corpses.is_empty() and g.enemy_bullets.is_empty() and not g.actor_anim.actors.has(e.id),mode+" cross-mode new run drops corpse and shot state")
		var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
		audio_teardown.prepare([g])
		g.queue_free();await process_frame
		await audio_teardown.finish(self)
	print("INDEPENDENT SPITTER EVENTS: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
