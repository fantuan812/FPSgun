extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func setup(g,mode_id:String,phase2:bool)->Dictionary:
	g._title();g._select_mode(mode_id);g._start_run(918273)
	g.spawn_clock=999;g.weapon_clocks=[999.0]
	g.stats.hp=1000;g.stats.max_hp=1000
	var e:Dictionary=g._spawn_kind("boss_warden",g.player_pos+Vector2(300,0))
	e.hp=e.max_hp*(.4 if phase2 else .9);e.anim_hp=e.hp
	e.cooldown_left=100;e.aim=Vector2.RIGHT;e.target=g.player_pos
	return e
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var a=g.actor_anim
	for action in ["hurt","death"]:
		var key:String="boss_warden_"+action
		check(a.assets.has(key),"authored asset "+key)
		if a.assets.has(key):check(a.assets[key].frames.get_frame_count("action")== (9 if action=="hurt" else 16),"count "+key)
	for mode_id in ["arena","rooms"]:
		for phase2 in [false,true]:
			for phase in ["charge_warning","blast_warning","charging","charge_recovery","blast_recovery"]:
				var e:Dictionary=setup(g,mode_id,phase2)
				var id:int=e.id
				if phase.ends_with("warning"):
					e.ai_state="warning";e.warning_left=.12;e.attack="charge" if phase.begins_with("charge") else "blast"
				elif phase=="charging":e.ai_state="charging";e.charge_left=.12;e.attack="charge"
				else:e.ai_state="recover";e.recover_left=.12;e.attack="charge" if phase.begins_with("charge") else "blast"
				var label:String="%s/phase2=%s/%s"%[mode_id,phase2,phase]
				var locked_aim:Vector2=e.aim
				var locked_target:Vector2=e.target
				var start_pos:Vector2=e.pos
				e.hp-=1 # Real combat damage detection, not a direct director trigger.
				g._process(.01)
				check(a.state_of(id)=="hurt",label+" real HP loss starts hurt")
				check(e.phase==(2 if phase2 else 1),label+" health phase")
				var first_age:float=a.actors[id].age
				check(not a.trigger(id,"hurt") and a.actors[id].age==first_age,label+" repeated hurt nonrestart")
				var damage_ticks:=0
				var previous_hp:float=g.stats.hp
				var states:Array=[e.ai_state]
				for i in range(28):
					g._process(.01)
					if g.stats.hp<previous_hp:damage_ticks+=1
					previous_hp=g.stats.hp
					states.append(e.ai_state)
					check(e.aim==locked_aim and e.target==locked_target,label+" aim/target authority unchanged")
				check(a.actors[id].reaction=="",label+" hurt ends without replay")
				check(a.state_of(id)==("attack" if e.ai_state=="charging" else e.ai_state),label+" current phase revealed")
				if phase=="blast_warning":
					check(states.has("recover") and damage_ticks==1,label+" one real blast occurs under hurt")
					check(e.recover_left>0 and e.recover_left<.7,label+" .7 recovery advances while hurt")
				elif phase=="charge_warning":
					check(states.has("charging") and e.charge_left<.6 and e.pos.x>start_pos.x,label+" actual charge runs while hurt")
				elif phase=="charging":
					check(states.has("recover") and e.recover_left>0 and e.recover_left<.8,label+" charge .8 recovery advances")
					check(absf(e.pos.x-start_pos.x-310*.12)<.01,label+" movement capped to remaining charge time")
				else:check(e.ai_state=="move",label+" finished recovery not replayed")
				# Lethal interruption in the same authority phase: zero later attacks/rewards.
				e=setup(g,mode_id,phase2);id=e.id
				if phase.ends_with("warning"):
					e.ai_state="warning";e.warning_left=.001;e.attack="charge" if phase.begins_with("charge") else "blast"
				elif phase=="charging":e.ai_state="charging";e.charge_left=.001;e.attack="charge"
				else:e.ai_state="recover";e.recover_left=.001;e.attack="charge" if phase.begins_with("charge") else "blast"
				e.hp=0;g._process(.01)
				check(not g.enemies.has(e) and a.corpses.has(id),label+" lethal tick removes combat retains tail")
				check(g.kills==1 and g.run.boss_rewards.has("boss_warden"),label+" single boss reward")
				var coins:int=g.build.coins
				var hp:float=g.stats.hp
				for i in range(10):g._process(.01)
				check(g.kills==1 and g.build.coins==coins and g.stats.hp==hp,label+" no postmortem blast/reward")
				check(a.state_of(id)=="death" and not a.trigger(id,"hurt"),label+" death terminal")
				var age:float=a.actors[id].age
				g._on_intent("pause",{});g._process(.05)
				check(a.actors[id].age==age,label+" paused death clock")
				g._resume();a.advance(.72-age-.00001)
				check(a.actors.has(id) and e.sprite.frame==15,label+" final death frame visible")
				a.advance(.00002);check(not a.actors.has(id),label+" tail recycles")
	# Source geometry and all unique runtime frame slots in both facing directions.
	for action in ["hurt","death"]:
		var key:String="boss_warden_"+action
		if not a.assets.has(key):continue
		var asset:Dictionary=a.assets[key]
		for flipped in [false,true]:
			var e:Dictionary=setup(g,"arena",false);var id:int=e.id
			e.sprite.flip_h=flipped
			if action=="death":a.die(id)
			else:a.trigger(id,"hurt")
			var n:int=9 if action=="hurt" else 16
			check(is_equal_approx(a.actors[id].duration,.27 if action=="hurt" else .72),"runtime duration "+action)
			for i in range(n):
				a.actors[id].age=a.actors[id].duration*(float(i)+.5)/n;a._present(a.actors[id])
				check(e.sprite.frame==i,"frame "+key+str(i))
				var t:Texture2D=e.sprite.sprite_frames.get_frame_texture("action",i)
				var foot:Vector2=(t.get_size()*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+e.sprite.offset)*e.sprite.scale
				check(foot.distance_to(a.actors[id].base_foot)<.001,"fixed logical anchor "+key+str(i))
				if i==0:check(absf(float(asset.records[0].alpha_bbox[3])*e.sprite.scale.y-a.actors[id].height)<.001,"reference height "+key)
			if action=="hurt":
				var f:int=e.sprite.frame;a.reduced_flashes=true;a.refresh_style()
				check(e.sprite.frame==f and e.sprite.modulate==a.actors[id].base_color,"reduced flashes preserves hurt pose")
				a.reduced_flashes=false
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_warden_reactions_passed":passed,"failures":failures,"scope":"headless authority/visual-overlay/lifecycle/anchor checks; no GUI or Windows playtest"}))
	quit(0 if failures.is_empty() else 1)
