extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false);game._start_run(770)
	var director=game.actor_anim
	var expected_ids:Array=["hero_attack","hero_hurt","hero_death","hero_dash","boss_warden_attack","boss_core_attack","charger_charge","charger_hurt","charger_death","spitter_shoot","spitter_hurt","spitter_death","brood_keeper_summon","brood_keeper_hurt","brood_keeper_death","crawler_hurt","crawler_death","flanker_hurt","flanker_death","boss_warden_hurt","boss_warden_death","boss_core_hurt","boss_core_death","boss_warden_charge"]
	var actual_ids:Array=director.assets.keys();expected_ids.sort();actual_ids.sort()
	check(actual_ids==expected_ids,"exact approved authored action ID set")
	for id in director.assets:
		var count:int=16 if id in ["brood_keeper_summon","brood_keeper_death","crawler_death","flanker_death","boss_warden_death","boss_core_death","boss_warden_charge"] else 9
		check(director.assets[id].frames.get_frame_count("action")==count,"exact authored clip length "+id)
		check(director.assets[id].frames.get_animation_loop("action")==false,"one shot "+id)
		var size:Vector2=director.assets[id].frames.get_frame_texture("action",0).get_size()
		for i in range(count):check(director.assets[id].frames.get_frame_texture("action",i).get_size()==size,"fixed canvas "+id)
	director.set_phase(0,"warning",.9)
	check(game.hero.frame<director.assets.hero_attack.release_frame,"windup excludes release")
	director.trigger(0,"attack")
	check(game.hero.frame==director.assets.hero_attack.release_frame,"actual shot starts source release frame")
	director.set_phase(0,"move")
	check(director.state_of(0)=="attack","locomotion cannot overwrite release")
	director.trigger(0,"hurt")
	check(not director.trigger(0,"attack") and director.state_of(0)=="hurt","hurt outranks auto shooting")
	director.clear()
	for action in ["hurt","dash"]:
		director.trigger(0,action)
		var period:float=director.config.durations[action]/9.0
		check(game.hero.frame==0,"action first frame")
		for i in range(1,9):
			director.advance(period)
			check(game.hero.frame==i,"action nine chronological frames "+action)
		director.advance(period+.000001)
		check(director.actors[0].reaction=="","one-shot releases arbitration")
	director.clear()
	game._spawn_kind("crawler",game.player_pos+Vector2(180,0))
	var enemy:Dictionary=game.enemies[0]
	director.set_phase(enemy.id,"warning",.5)
	check(director.actors[enemy.id].source=="shared procedural" and enemy.sprite.animation=="idle","ordinary windup is procedural not walk")
	director.trigger(enemy.id,"hurt")
	check(director.state_of(enemy.id)=="hurt","ordinary actual hurt presentation")
	enemy.hp=0
	game.weapon_clocks=[100.0]
	game._simulate(.001)
	check(not game.enemies.any(func(e):return e.id==enemy.id) and director.corpses.has(enemy.id),"corpse detached immediately from combat")
	check(enemy.sprite.position==enemy.pos,"corpse captures latest combat position")
	check(game.kills==1 and game.pickups.size()==1,"kill rewards once before tail")
	director.advance(.3)
	check(is_instance_valid(enemy.sprite),"corpse visible during tail")
	director.advance(1)
	await process_frame
	check(not is_instance_valid(enemy.sprite) and not director.actors.has(enemy.id),"corpse freed after tail")
	game._start_run(770)
	for kind in ["boss_warden","boss_core"]:
		var boss:Dictionary=game._spawn_kind(kind,game.player_pos+Vector2(250,0))
		director.set_phase(boss.id,"warning",.9)
		check(boss.sprite.frame<director.assets[kind+"_attack"].release_frame,"boss windup before authored release")
		director.trigger(boss.id,"attack")
		check(boss.sprite.frame==director.assets[kind+"_attack"].release_frame,"boss exact configured release")
	game._start_run(770)
	game._vfx("hit_spark",game.player_pos)
	director.trigger(0,"hurt")
	var normal_color:Color=game.hero.modulate
	game.state="paused";game._on_intent("settings",{})
	game._on_intent("set_setting",{"key":"reduced_flashes","value":true})
	check(game.settings.reduced_flashes and game.vfx.active[0].sprite.modulate.a<.5,"setting dims active VFX immediately")
	check(game.hero.modulate.r<normal_color.r,"setting removes actor white flash immediately")
	var age:float=director.actors[0].age
	game._process(.2)
	check(director.actors[0].age==age,"settings freezes action time")
	game._on_intent("close_settings",{})
	check(game.state=="paused","settings returns to prior pause")
	game._start_run(770)
	var rng_state:int=game.rng.state
	var hp:float=game.stats.hp
	var emitted:int=game.vfx.emitted
	game._mechanism_vfx("test_source","hit_spark",game.player_pos)
	game._mechanism_vfx("test_source","hit_spark",game.player_pos)
	check(game.vfx.emitted==emitted+1 and game.vfx.active[-1].options.source_item=="test_source","source-tagged visual-only throttle")
	check(game.rng.state==rng_state and game.stats.hp==hp,"presentation does not mutate RNG or health")
	game._finish(false)
	check(game.state=="dead" and game.result_pending and director.state_of(0)=="death","death ends gameplay immediately")
	check(not director.trigger(0,"attack"),"death cannot be interrupted")
	for i in range(14):game._process(.05)
	check(game.hero.frame==8 and game.result_pending,"death final frame held before result")
	for i in range(3):game._process(.05)
	check(not game.result_pending,"result after complete tail")
	game._start_run(770)
	check(not game.result_pending and director.actors[0].walk_time==0 and game.hero.modulate.a==1,"restart clears old death and phase")
	game._spawn_kind("crawler",Vector2(100,100));game._title()
	await process_frame
	game._start_run(770)
	check(game.enemies.is_empty() and director.actors.size()==1,"title then restart no freed-instance reuse")
	game.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v7 authored and procedural action contracts"}))
	quit(0 if failures.is_empty() else 1)
