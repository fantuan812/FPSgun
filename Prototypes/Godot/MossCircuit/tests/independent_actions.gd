extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func reset(g)->void:
	g._start_run(71);g.spawn_clock=999;g.weapon_clocks=[999.0]
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);reset(g)
	var a=g.actor_anim
	for id in ["hero_attack","hero_hurt","hero_death","hero_dash","boss_warden_attack","boss_core_attack"]:
		check(a.assets.has(id),"authored nine-frame resource "+id)
	var base_texture:AtlasTexture=g.hero.sprite_frames.get_frame_texture(g.hero.animation,0)
	var base_height:float=base_texture.region.size.y*g.hero.scale.y
	var base_foot:float=(base_texture.margin.position.y+base_texture.region.size.y-base_texture.get_height()*.5+g.hero.offset.y)*g.hero.scale.y
	check(a.trigger(0,"attack"),"attack starts")
	if a.assets.has("hero_attack"):
		var aa:Dictionary=a.assets.hero_attack
		var tt:Texture2D=g.hero.sprite_frames.get_frame_texture("action",0)
		var action_foot:float=(tt.get_height()*(float(aa.anchor[1])-.5)+g.hero.offset.y)*g.hero.scale.y
		check(absf(g.hero.scale.y*float(aa.reference_height)-base_height)<.01,"walk to attack preserves reference body height")
		check(absf(action_foot-base_foot)<.01,"walk to attack preserves foot anchor")
	a.set_phase(0,"move")
	check(a.state_of(0)=="attack","movement cannot override release")
	check(a.trigger(0,"dash"),"dash overrides attack")
	check(not a.trigger(0,"attack"),"attack cannot override dash")
	check(a.trigger(0,"hurt"),"hurt overrides dash")
	check(not a.trigger(0,"dash"),"dash cannot override hurt")
	a.die(0)
	check(not a.trigger(0,"hurt") and a.state_of(0)=="death","death terminal priority")
	a.advance(.64)
	check(g.hero.frame==8,"death reaches frame8 before completion")
	a.advance(.08)
	check(g.hero.frame==8 and a.actors.has(0),"hero death tail holds final frame")
	reset(g)
	check(a.state_of(0)=="idle" and not a.actors[0].corpse,"reset cancels death")
	a.trigger(0,"hurt");a.advance(.1)
	var age:float=a.actors[0].age
	var frame:int=g.hero.frame
	g._on_intent("pause",{});g._process(.05)
	check(a.actors[0].age==age and g.hero.frame==frame,"pause freezes actor reaction")
	reset(g)
	g._hurt(9999)
	check(g.state=="dead" and g.result_pending and a.state_of(0)=="death","lethal damage commits result and death tail")
	var generation:int=a.generation
	reset(g)
	check(not g.result_pending and a.generation>generation,"restart cancels pending result")
	for i in range(25):g._process(.05)
	check(g.state=="playing" and not g.result_pending,"old death timer cannot reopen result")
	reset(g)
	var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(300,0))
	var id:int=e.id
	e.hp=0
	g._simulate(.001)
	check(not g.enemies.has(e) and a.corpses.has(id) and g.kills==1,"dead enemy leaves combat but retains visual tail")
	g._simulate(.001)
	check(g.kills==1,"corpse cannot award kill twice")
	a.advance(.8)
	check(not a.actors.has(id) and not a.corpses.has(id),"corpse tail recycles")
	reset(g)
	for i in range(50):
		e=g._spawn_kind("crawler",g.player_pos+Vector2(300,0));e.hp=0
	g._simulate(.001)
	check(a.corpses.size()<=int(a.config.corpse_cap),"bounded corpse visuals")
	reset(g)
	check(a.corpses.is_empty() and a.actors.size()==1,"reset clears all corpse registrations")
	g._spawn_kind("crawler",g.player_pos+Vector2(300,0))
	g._title();await process_frame
	reset(g)
	check(g.state=="playing" and a.actors.size()==1,"title with living enemies then restart safe")
	reset(g)
	e=g._spawn_kind("crawler",g.player_pos+Vector2(150,0));e.hp=1000;e.max_hp=1000;e.speed=0
	g._fire_weapon("rivet_gun",0)
	check(a.state_of(0)=="attack" and g.hero.frame==int(a.assets.hero_attack.release_frame) and g.bullets.size()==1,"real fire begins release authored release frame without delaying projectile")
	a.set_phase(0,"warning",.7)
	check(g.hero.frame==int(a.assets.hero_attack.release_frame) and a.state_of(0)=="attack","other-slot preparation cannot override live release")
	a.advance(.1);g._fire_weapon("rivet_gun",0)
	check(g.hero.frame==int(a.assets.hero_attack.release_frame) and g.bullets.size()==2,"later actual fire restarts release")
	reset(g)
	e=g._spawn_kind("boss_core",g.player_pos+Vector2(300,0));e.cooldown_left=0;e.speed=0
	g._simulate(.001)
	check(e.ai_state=="warning" and a.state_of(e.id)=="warning" and e.sprite.frame<int(a.assets.boss_core_attack.release_frame) and g.enemy_bullets.is_empty(),"boss warning has prep frames and no release")
	e.warning_left=.001
	g._simulate(.002)
	check(e.ai_state=="recover" and a.state_of(e.id)=="attack" and e.sprite.frame==int(a.assets.boss_core_attack.release_frame) and g.enemy_bullets.size()>0,"boss attack authored release frame coincides actual projectile release")
	reset(g)
	var saved:Dictionary=a.assets.duplicate(true)
	var outcomes:Array=[]
	for disabled in [false,true]:
		reset(g);a.assets={} if disabled else saved
		e=g._spawn_kind("crawler",g.player_pos+Vector2(100,0));e.hp=1000;e.max_hp=1000;e.speed=0
		g._fire_weapon("rivet_gun",0)
		for i in range(20):a.advance(.016);g._simulate(.016)
		outcomes.append([e.hp,g.stats.hp,g.rng.state,g.loot_rng.state,g.shop_rng.state,g.kills,g.bullets.size()])
	check(outcomes[0]==outcomes[1],"authored actions versus fallback preserve damage and RNG")
	a.assets=saved
	check(g.telegraphs.z_index>g.vfx.z_index,"danger geometry remains above decoration")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_actions_passed":passed,"failures":failures,"scope":"headless state clocks and resources, no GUI playtest"}))
	quit(0 if failures.is_empty() else 1)
