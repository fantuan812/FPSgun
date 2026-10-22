extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func children(g,parent:int)->Array:return g.enemies.filter(func(e):return e.get("parent_id",-1)==parent and e.hp>0)
func arm(e:Dictionary,left:float=.001)->void:
	e.ai_state="warning";e.attack="summon";e.warning_left=left;e.cooldown_left=999
func run()->void:
	for mode in ["arena","rooms"]:
		var g=load("res://scenes/main.tscn").instantiate()
		root.add_child(g);g.set_process(false);g._select_mode(mode);g._start_run(12911)
		g.spawn_clock=999;g.weapon_clocks=[999.0];g.stats.hp=10000;g.stats.max_hp=10000
		var e:Dictionary=g._spawn_kind("brood_keeper",g.player_pos+Vector2(-240,0))
		var ad=g.actor_anim
		var actor:Dictionary=ad.actors[e.id]
		e.cooldown_left=0;g._simulate(.01)
		check(e.ai_state=="warning" and children(g,e.id).is_empty(),mode+" real cooldown starts warning without premature child")
		e.warning_left=.06;g._simulate(.05)
		check(children(g,e.id).is_empty() and actor.phase_progress>.9,mode+" prethreshold warning has no child")
		g._simulate(.05)
		check(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7) and actor.phase_progress==0 and children(g,e.id).size()==1,mode+" actual attempt creates single child and enters recover0")
		var child:Dictionary=children(g,e.id)[0]
		check(child.kind=="crawler" and child.parent_id==e.id and child.pos.is_equal_approx(e.pos+Vector2.from_angle(g.elapsed)*50),mode+" original crawler ownership and center50 geometry unchanged")
		for repeat in range(5):check(not ad.trigger(e.id,"attack"),mode+" contact cannot counterfeit summon "+str(repeat))
		g._simulate(.05)
		check(children(g,e.id).size()==1 and actor.phase_progress>0,mode+" recovery does not repeat attempt")
		# Reach actual per-parent cap via the real spawn event path, not injected children.
		for cycle in range(2):arm(e);g._simulate(.05)
		check(children(g,e.id).size()==3,mode+" three actual summon attempts reach existing parent cap")
		var next_id:int=g.next_enemy_id
		arm(e);g._simulate(.05)
		check(children(g,e.id).size()==3 and g.next_enemy_id==next_id and actor.phase=="recover" and actor.phase_progress==0,mode+" full parent cap still attempts but produces no fake child")
		children(g,e.id)[0].hp=0;g._simulate(.001)
		check(children(g,e.id).size()==2,mode+" actual child death releases living-child capacity")
		arm(e,.02);ad.observe_enemy(e,"move",g.player_pos);e.hp-=1;g._simulate(.001)
		check(actor.state=="hurt",mode+" real hp loss overlays summon warning")
		g._simulate(.05)
		check(actor.state=="hurt" and children(g,e.id).size()==3,mode+" hurt does not delay replacement child")
		for step in range(6):g._simulate(.05);ad.advance(.05)
		check(actor.state=="recover" and actor.phase_progress>.3 and children(g,e.id).size()==3,mode+" hurt resumes current phase without delayed duplicate child")
		# Empty one parent slot but fill the unmodified real global cap with unrelated crawlers.
		children(g,e.id)[0].hp=0;g._simulate(.001)
		while g.enemies.size()<int(g.config.waves.max_enemies):g._spawn_kind("crawler",Vector2(40,40))
		check(g.enemies.size()==90 and int(g.config.waves.max_enemies)==90,mode+" global-cap fixture uses original90 limit")
		next_id=g.next_enemy_id;arm(e);g._simulate(.05)
		check(children(g,e.id).size()==2 and g.enemies.size()==90 and g.next_enemy_id==next_id and actor.phase=="recover",mode+" global cap blocks child despite available parent capacity")
		for other in g.enemies:
			if other.id!=e.id and other.get("parent_id",-1)!=e.id:other.hp=0
		g._simulate(.001)
		for phase in ["warning","recover"]:
			e.ai_state=phase;e.aim=Vector2.RIGHT;ad.observe_enemy(e,phase,e.pos-Vector2(100,0))
			check(e.sprite.flip_h,mode+" locked aim ignores player behind "+phase)
			e.aim=Vector2(.00001,1);ad.observe_enemy(e,phase,e.pos-Vector2(100,0))
			check(e.sprite.flip_h,mode+" near vertical keeps current mirror "+phase)
		var oldpos:Vector2=e.pos
		e.pos=g.player_pos;e.ai_state="warning";e.warning_left=.5;g.hurt_clock=0
		var hp:float=g.stats.hp
		g._simulate(.001);check(g.stats.hp==hp,mode+" warning overlap stays contact safe")
		e.ai_state="move";e.cooldown_left=999;g.hurt_clock=0
		g._simulate(.001);check(g.stats.hp==hp-11,mode+" moving contact retains exact original11 damage")
		e.ai_state="recover";e.recover_left=.7;g.hurt_clock=0;hp=g.stats.hp
		g._simulate(.001);check(g.stats.hp==hp,mode+" recovery overlap stays contact safe")
		e.pos=oldpos
		# Pause preserves both countdown and attempted child count.
		arm(e,.3);ad.observe_enemy(e,"move",g.player_pos)
		g._on_intent("pause",{});g._process(.8)
		check(e.warning_left==.3 and children(g,e.id).size()==2 and actor.phase_progress<.6,mode+" pause freezes warning and child creation")
		g._on_intent("resume",{})
		# A low-FPS tick crosses warning and nominal recovery duration, but preserves
		# the original one-branch-per-tick authority instead of replaying frame events.
		next_id=g.next_enemy_id;g._simulate(.95)
		check(children(g,e.id).size()==3 and g.next_enemy_id==next_id+1 and e.ai_state=="recover" and is_equal_approx(e.recover_left,.7),mode+" large tick attempts exactly once without consuming future recovery")
		g._simulate(.95)
		check(children(g,e.id).size()==3 and g.next_enemy_id==next_id+1 and e.ai_state=="move",mode+" skipped recovery poses do not replay child creation")
		children(g,e.id)[0].hp=0;g._simulate(.001);arm(e)
		var ids:Array=children(g,e.id).map(func(c):return c.id)
		var kills:int=g.kills
		e.warning_left=.001;e.hp=0;g._simulate(.05)
		check(not g.enemies.has(e) and actor.corpse and g.kills==kills+1 and children(g,e.id).map(func(c):return c.id)==ids,mode+" parent dies once while existing living children persist")
		ad.observe_enemy(e,"warning",g.player_pos);ad.trigger(e.id,"attack");g._simulate(.05)
		check(children(g,e.id).size()==2 and g.kills==kills+1 and actor.state=="death",mode+" dead pending summon cannot create or reward again")
		if mode=="rooms":
			for planned in range(g.mode.planned_count):g._spawn_enemy()
			for other in g.enemies:
				if other.get("parent_id",-1)!=e.id:other.hp=0
			g._simulate(.001)
			check(g.state=="playing" and not g.mode.can_end(g.run,g.combat,g.encounters),"living orphan children block finite room completion")
			for other in children(g,e.id):other.hp=0
			g._simulate(.001)
			check(g.state=="room_clear" and g.enemies.is_empty(),"only clearing remaining children permits room clear")
			var coins:int=g.build.coins;g._complete_wave();g._complete_wave()
			check(g.build.coins==coins and g.wave==1,"duplicate early completion cannot pay old parent twice")
			for tick in range(15):g._process(.05)
			coins=g.build.coins;g._complete_wave();g._complete_wave()
			check(g.wave==2 and g.build.coins==coins and g.enemies.is_empty(),"settlement once and no death-tail child spawning")
		g._title();g._select_mode("rooms" if mode=="arena" else "arena");g._start_run(12911)
		check(g.enemies.is_empty() and g.actor_anim.corpses.is_empty() and not g.actor_anim.actors.has(e.id),mode+" cross-mode resets all old parent child and corpse state")
		g.queue_free();await process_frame
	print("INDEPENDENT BROOD EVENTS: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
