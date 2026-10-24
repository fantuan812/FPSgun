extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func prepare(g,attack:String)->Dictionary:
	g._start_run(1414);g.spawn_clock=999;g.weapon_clocks=[999.0]
	var e:Dictionary=g._spawn_kind("boss_warden",g.player_pos+Vector2(220,0))
	e.ai_state="warning";e.warning_left=.85;e.attack=attack;e.aim=Vector2.RIGHT;e.target=g.player_pos;e.cooldown_left=999
	return e
func run_checks()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var e:Dictionary=prepare(g,"charge")
	var a=g.actor_anim
	for action in ["hurt","death"]:
		var id:String="boss_warden_"+action
		check(a.assets.has(id),"new authored resource "+id)
		if not a.assets.has(id):continue
		var asset:Dictionary=a.assets[id]
		check(asset.frames.get_frame_count("action")== (9 if action=="hurt" else 16),"exact frame count "+id)
		check(not asset.frames.get_animation_loop("action"),"one shot "+id)
	check(a.config.profiles.boss_warden.attack=="boss_warden_attack","existing attack mapping retained")
	check(not a.config.profiles.boss_warden.get("phase_driven_attack",false),"existing contact presentation policy retained")
	for attack in ["charge","blast"]:
		e=prepare(g,attack)
		e.warning_left=.01;e.hp-=1
		var hp:float=g.stats.hp
		g._simulate(.02)
		check(a.state_of(e.id)=="hurt","same-tick HP loss masks body, not authority "+attack)
		check(is_equal_approx(a.actors[e.id].duration,.27),"hurt .27s "+attack)
		if attack=="charge":
			check(e.ai_state=="charging" and is_equal_approx(e.charge_left,.6),"charge begins on true release despite hurt")
			var pos:Vector2=e.pos
			g._simulate(.1)
			check(e.pos.distance_to(pos)>30 and is_equal_approx(e.charge_left,.5),"charge movement/timer continue through hurt")
		else:
			check(e.ai_state=="recover" and is_equal_approx(e.recover_left,.7),"blast enters original .7 recovery through hurt")
			check(g.stats.hp<hp and g.flashes.size()==1,"one true blast still damages on release")
			var damaged_hp:float=g.stats.hp
			g._simulate(.1)
			check(g.stats.hp==damaged_hp and is_equal_approx(e.recover_left,.6),"hurt cannot replay blast or pause recovery")
		var age:float=a.actors[e.id].age
		check(not a.trigger(e.id,"hurt") and a.actors[e.id].age==age,"repeat hurt does not restart "+attack)
		a.advance(.28)
		check(a.actors[e.id].reaction=="","hurt expires without replaying attack "+attack)
		check(a.state_of(e.id)==("attack" if attack=="charge" else "recover"),"return to current authoritative phase "+attack)
	# Lethal damage before release must suppress the blast, not defer it to death frames.
	e=prepare(g,"blast");e.warning_left=.001;a.trigger(e.id,"hurt");e.hp=0
	var kills:int=g.kills;var flashes:int=g.flashes.size();var coins:int=g.build.coins
	g._simulate(.01)
	check(g.kills==kills+1 and not g.enemies.has(e),"boss immediately leaves combat once")
	check(g.flashes.size()==flashes,"death before release never creates blast")
	check(g.boss_defeated and g.build.boss_protocol and g.build.coins==coins+50,"original Warden protocol and 50 coins immediate")
	check(a.state_of(e.id)=="death" and a.actors[e.id].corpse,"lethal reaction overrides hurt")
	check(is_equal_approx(a.actors[e.id].duration,.72),"death .72s")
	var reward_coins:int=g.build.coins
	g._simulate(.01)
	check(g.kills==kills+1 and g.build.coins==reward_coins,"death animation cannot duplicate kill reward")
	check(not a.trigger(e.id,"hurt") and not a.trigger(e.id,"attack"),"death terminal against late events")
	a.advance(.719)
	check(a.actors.has(e.id),"corpse remains before .72")
	if a.assets.has("boss_warden_death"):check(e.sprite.frame==15,"last authored frame visible")
	a.advance(.002)
	check(not a.actors.has(e.id),"corpse recycled without gameplay effects")
	check(g.flashes.is_empty(),"visual tail does not release deferred blast")
	# Defeating the mandatory wave3 boss is authoritative, but does not bypass the timer.
	e=prepare(g,"charge");g.wave=3;g.boss_spawned=true;g.wave_time=1;e.hp=0
	g._simulate(.01)
	check(g.wave==3 and g.state=="playing" and g.boss_defeated,"early kill waits existing wave timer")
	g.wave_time=g.config.waves.duration-.001;g._simulate(.01)
	check(g.wave==4 and g.state=="upgrade","original wave completion does not wait for death sheet")
	check(a.corpses.has(e.id),"visual corpse preserved through settlement")
	g._title();check(a.corpses.is_empty(),"title clears Warden tail")
	g.queue_free();await process_frame
	print(JSON.stringify({"warden_reactions_passed":passed,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
