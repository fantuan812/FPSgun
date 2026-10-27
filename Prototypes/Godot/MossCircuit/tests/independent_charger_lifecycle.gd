extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(8080)
	g.spawn_clock=999;g.weapon_clocks=[999.0]
	var e:Dictionary=g._spawn_kind("charger",g.player_pos+Vector2(-100,0))
	var ad=g.actor_anim
	var a:Dictionary=ad.actors[e.id]
	e.ai_state="warning";e.warning_left=.65;e.aim=Vector2.RIGHT
	ad.observe_enemy(e,"move",e.pos-Vector2(100,0))
	check(e.sprite.flip_h and a.phase=="warning" and a.phase_progress==0,"warning faces locked right aim not player behind")
	for phase in ["warning","charging","recover"]:
		e.ai_state=phase;e.charge_left=.6;e.recover_left=.8;e.aim=Vector2(.00001,1)
		ad.observe_enemy(e,phase,e.pos-Vector2(100,0))
		check(e.sprite.flip_h,"near vertical keeps right orientation in "+phase)
		e.sprite.flip_h=false;e.aim=Vector2(-.00001,-1)
		ad.observe_enemy(e,phase,e.pos+Vector2(100,0))
		check(not e.sprite.flip_h,"near vertical keeps left orientation in "+phase)
		e.sprite.flip_h=true
	e.ai_state="warning";e.warning_left=.001;e.aim=Vector2.LEFT
	ad.observe_enemy(e,"warning",g.player_pos)
	check(not e.sprite.flip_h and a.phase_progress>.99,"late warning keeps locked left aim")
	check(ad.trigger(e.id,"hurt"),"real hurt accepted")
	e.ai_state="charging";e.charge_left=.4
	var before:Dictionary={"hp":e.hp,"pos":e.pos,"aim":e.aim,"left":e.charge_left}
	ad.observe_enemy(e,"warning",g.player_pos)
	check(a.state=="hurt" and a.phase=="attack" and is_equal_approx(a.phase_progress,1.0/3),"hurt overlays current authoritative charge progress")
	ad.advance(.30)
	check(a.state=="attack" and a.reaction=="" and is_equal_approx(a.phase_progress,1.0/3),"hurt expiry resumes current phase instead of replay warning")
	check(e.hp==before.hp and e.pos==before.pos and e.aim==before.aim and e.charge_left==before.left,"presentation advance cannot change AI state")
	var phase_progress:float=a.phase_progress
	for repeat in range(5):check(not ad.trigger(e.id,"attack"),"contact attack cannot restart charge "+str(repeat))
	check(a.phase_progress==phase_progress and a.reaction=="","repeated contact leaves authoritative visual phase")
	e.ai_state="recover";e.recover_left=.8
	ad.observe_enemy(e,"charging",g.player_pos)
	check(a.recover_span==.8 and a.phase_progress==0,"recover captures actual entry span")
	e.recover_left=.2;ad.observe_enemy(e,"recover",g.player_pos)
	check(is_equal_approx(a.phase_progress,.75) and a.recover_span==.8,"repeated recover observation does not reset span")
	ad.trigger(e.id,"hurt");e.ai_state="move";ad.observe_enemy(e,"recover",g.player_pos);ad.advance(.5)
	check(a.state=="move","low FPS hurt expiry resumes now-current move")
	ad.trigger(e.id,"hurt")
	var age:float=a.age
	g._on_intent("pause",{});g._process(.8)
	check(a.age==age and g.state=="paused","pause does not advance hurt timer")
	g._on_intent("resume",{})
	# Existing combat damage gates, observed through real simulation, not animation frame.
	e.pos=g.player_pos;e.ai_state="warning";e.warning_left=.5;e.cooldown_left=999
	var hp:float=g.stats.hp
	g._simulate(.01);check(g.stats.hp==hp,"warning collision remains contact safe")
	e.pos=g.player_pos;e.ai_state="charging";e.charge_left=.6;e.aim=Vector2.ZERO
	g.hurt_clock=0;g._simulate(.01)
	check(g.stats.hp==hp-15,"charging overlap retains exactly original15 damage")
	e.pos=g.player_pos;e.ai_state="recover";e.recover_left=.8
	g.hurt_clock=0;hp=g.stats.hp;g._simulate(.01)
	check(g.stats.hp==hp,"recover collision remains contact safe")
	ad.trigger(e.id,"hurt");e.hp=0
	var kills:int=g.kills
	g._simulate(.001)
	check(g.enemies.is_empty() and g.kills==kills+1 and a.corpse and a.state=="death","death cancels hurt and immediately exits combat/rewards once")
	check(not ad.trigger(e.id,"hurt") and not ad.trigger(e.id,"attack"),"death cannot be resurrected by late reaction")
	var flip:bool=e.sprite.flip_h
	ad.observe_enemy(e,"charging",g.player_pos+Vector2(1000,0))
	check(e.sprite.flip_h==flip and a.state=="death","late observation cannot flip or replace corpse")
	g._simulate(.05)
	check(g.kills==kills+1,"corpse frame cannot duplicate kill reward")
	g._title();g._select_mode("rooms");g._start_run(8080)
	check(ad.corpses.is_empty() and not ad.actors.has(e.id),"cross-mode restart clears prior corpse entry")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("INDEPENDENT CHARGER LIFECYCLE: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
