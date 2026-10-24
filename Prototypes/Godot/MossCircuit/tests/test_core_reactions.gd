extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func prepare(g,attack:String,second_phase:bool)->Dictionary:
	g._start_run(1515);g.spawn_clock=999;g.weapon_clocks=[999.0]
	var e:Dictionary=g._spawn_kind("boss_core",g.player_pos+Vector2(220,0))
	e.ai_state="warning";e.warning_left=.85;e.attack=attack;e.aim=Vector2.RIGHT;e.target=g.player_pos;e.cooldown_left=999
	if second_phase:e.hp=e.max_hp*.5;e.anim_hp=e.hp
	return e
func children(g,e)->Array:
	return g.enemies.filter(func(child):return child.parent_id==e.id and child.hp>0)
func run_checks()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var e:Dictionary=prepare(g,"ring",false)
	var a=g.actor_anim
	for action in ["hurt","death"]:
		var id:String="boss_core_"+action
		check(a.assets.has(id),"new authored resource "+id)
		if not a.assets.has(id):continue
		var asset:Dictionary=a.assets[id]
		check(asset.frames.get_frame_count("action")== (9 if action=="hurt" else 16),"exact frame count "+id)
		check(not asset.frames.get_animation_loop("action"),"one shot "+id)
	# Close the bounded seven-enemy reaction coverage milestone, not all attack art.
	for kind in ["crawler","charger","spitter","flanker","brood_keeper","boss_warden","boss_core"]:
		for action in ["hurt","death"]:
			var id:String=kind+"_"+action
			check(a.config.profiles.get(kind,{}).get(action,"")==id and a.assets.has(id),"reaction profile resolves authored resource "+id)
	check(a.config.profiles.boss_core.attack=="boss_core_attack","existing attack mapping retained")
	check(not a.config.profiles.boss_core.get("phase_driven_attack",false),"existing contact presentation policy retained")
	for second_phase in [false,true]:
		e=prepare(g,"ring",second_phase);e.warning_left=.01;e.hp-=1
		g._simulate(.02)
		var expected:int=12 if second_phase else 8
		check(g.enemy_bullets.size()==expected,"true ring count unaffected by same-tick hurt "+str(second_phase))
		check(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7),"original ring recovery")
		check(a.state_of(e.id)=="hurt" and is_equal_approx(a.actors[e.id].duration,.27),"real damage starts .27 hurt")
		var age:float=a.actors[e.id].age
		check(not a.trigger(e.id,"hurt") and a.actors[e.id].age==age,"repeat hurt does not restart")
		g._simulate(.1);a.advance(.28)
		check(g.enemy_bullets.size()==expected and is_equal_approx(e.recover_left,.6),"hurt expiration cannot emit ring again")
		check(a.state_of(e.id)=="recover","hurt reveals current recover")
	# Phase2 summon count is bounded by the existing per-parent cap, not animation length.
	for existing in [0,2,3]:
		e=prepare(g,"summon",true)
		for i in range(existing):g._spawn_kind("crawler",e.pos+Vector2(0,40+i*20),e.id)
		e.warning_left=.01;e.hp-=1;g._simulate(.02)
		check(children(g,e).size()==mini(3,existing+2),"real two-child attempt respects cap "+str(existing))
		check(a.state_of(e.id)=="hurt" and e.ai_state=="recover","hurt masks summon body but not spawn")
		g._simulate(.1);a.advance(.28)
		check(children(g,e).size()==mini(3,existing+2),"no replayed child on hurt end")
	# A dead parent clears its projectiles, not already-alive children while play continues.
	e=prepare(g,"summon",true);g.wave=6;g.boss_spawned=true;g.wave_time=1
	var child:Dictionary=g._spawn_kind("crawler",e.pos+Vector2(0,60),e.id)
	g.enemy_bullets.append({"pos":e.pos,"velocity":Vector2.RIGHT,"life":4.0,"damage":15,"owner":e.id})
	e.warning_left=.001;a.trigger(e.id,"hurt");e.hp=0
	var kills:int=g.kills;var coins:int=g.build.coins;var next_id:int=g.next_enemy_id
	g._simulate(.01)
	check(g.kills==kills+1 and not g.enemies.has(e),"Core immediately removed from combat once")
	check(g.enemy_bullets.is_empty() and g.next_enemy_id==next_id,"death cannot leave owned bullets or complete pending summon")
	check(g.enemies.has(child) and child.hp>0,"parent death does not directly kill existing crawler")
	check(g.boss_defeated and not g.build.get("boss_protocol",false) and g.build.coins==coins+100,"original Core crown/100 coins, no Warden protocol")
	check(g.state=="playing" and g.wave==6,"early final boss kill still waits wave timer")
	check(a.state_of(e.id)=="death" and is_equal_approx(a.actors[e.id].duration,.72),"death overrides hurt with .72 tail")
	check(not a.trigger(e.id,"hurt") and not a.trigger(e.id,"attack"),"death terminal")
	var rewarded:int=g.build.coins;g._simulate(.01)
	check(g.kills==kills+1 and g.build.coins==rewarded and g.next_enemy_id==next_id,"tail does not duplicate reward/summon")
	a.advance(.719)
	check(a.actors.has(e.id),"corpse persists before end")
	if a.assets.has("boss_core_death"):check(e.sprite.frame==15,"last authored frame visible")
	a.advance(.002);check(not a.actors.has(e.id),"corpse recycled at duration")
	g.wave_time=g.config.waves.duration-.001;g._simulate(.01)
	check(g.state=="won" and g.enemies.is_empty(),"original terminal settlement clears surviving child at timer")
	g._title();check(a.corpses.is_empty(),"title clears remaining tails")
	g.queue_free();await process_frame
	print(JSON.stringify({"core_reactions_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
