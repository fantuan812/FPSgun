extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func prepare(game,mode_id:String="arena",phase2:bool=false)->Dictionary:
	game._title();game._select_mode(mode_id);game._start_run(1616)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.stats.hp=10000;game.stats.max_hp=10000
	var enemy:Dictionary=game._spawn_kind("boss_warden",game.player_pos+Vector2(280,0))
	enemy.hp=enemy.max_hp*(.4 if phase2 else .9);enemy.anim_hp=enemy.hp
	enemy.cooldown_left=0
	return enemy
func trace(game,enemy:Dictionary)->Array:
	return [enemy.pos,enemy.hp,enemy.phase,enemy.ai_state,enemy.attack,enemy.attack_index,enemy.aim,enemy.target,enemy.cooldown_left,enemy.warning_left,enemy.charge_left,enemy.recover_left,game.stats.hp,game.hurt_clock,game.elapsed,game.wave_time,game.enemy_bullets.size(),game.flashes.size(),game.kills,game.rng.state,game.loot_rng.state,game.shop_rng.state]
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	var actor=game.actor_anim
	check(actor.assets.has("boss_warden_charge"),"distinct Warden charge resource loaded")
	if not actor.assets.has("boss_warden_charge"):
		game.queue_free();await process_frame
		print(JSON.stringify({"warden_charge_passed":passed,"failures":failures}));quit(1);return
	var asset:Dictionary=actor.assets.boss_warden_charge
	check(asset.frames.get_frame_count("action")==16,"exact sixteen authored charge poses")
	check(not asset.frames.get_animation_loop("action"),"charge clip not free-running")
	var enemy:Dictionary=prepare(game)
	game._simulate(.01)
	check(enemy.attack=="charge" and enemy.ai_state=="warning","true AI selects first charge")
	check(actor.actors[enemy.id].asset_id=="boss_warden_charge" and enemy.sprite.frame==0,"warning selects charge frame zero")
	check(not actor.trigger(enemy.id,"attack"),"contact cannot restart phase-driven charge")
	for flipped in [false,true]:
		enemy.aim=Vector2.RIGHT if flipped else Vector2.LEFT
		for phase in ["warning","charging","recover"]:
			enemy.ai_state=phase
			var first:int=0 if phase=="warning" else (6 if phase=="charging" else 12)
			var count:int=6 if phase!="recover" else 4
			if phase=="recover":actor.actors[enemy.id].recover_span=.8
			for frame in range(count):
				var progress:float=(float(frame)+.5)/count
				enemy.warning_left=enemy.warning*(1-progress)
				enemy.charge_left=enemy.charge_duration*(1-progress)
				enemy.recover_left=.8*(1-progress)
				actor.observe_enemy(enemy,phase,enemy.pos-enemy.aim*100)
				check(enemy.sprite.frame==first+frame,"true "+phase+" selects frame "+str(first+frame))
				check(enemy.sprite.flip_h==flipped,"locked charge aim survives player crossing")
				var texture:Texture2D=enemy.sprite.sprite_frames.get_frame_texture("action",enemy.sprite.frame)
				var foot:Vector2=(texture.get_size()*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+enemy.sprite.offset)*enemy.sprite.scale
				check(foot.distance_to(actor.actors[enemy.id].base_foot)<.001,"fixed logical charge anchor")
	enemy=prepare(game);enemy.ai_state="warning";enemy.attack="charge";enemy.warning_left=.001
	game._simulate(.002)
	check(enemy.ai_state=="charging" and enemy.sprite.frame==6,"same-tick charge release frame matches AI")
	actor.trigger(enemy.id,"hurt");game._simulate(.1);actor.advance(.28)
	check(actor.actors[enemy.id].asset_id=="boss_warden_charge" and enemy.sprite.frame>=6 and enemy.sprite.frame<=11,"hurt reveals current charge, not a restarted attack")
	enemy.ai_state="recover";enemy.recover_left=.8;actor.observe_enemy(enemy,"charging",game.player_pos)
	check(enemy.sprite.frame==12,"recovery begins at frame twelve")
	enemy.recover_left=.001;game._simulate(.002)
	check(enemy.ai_state=="move" and actor.actors[enemy.id].attack_variant=="","finished charge clears active variant")
	check(actor.trigger(enemy.id,"attack"),"normal chase contact presentation retained")
	enemy=prepare(game);enemy.attack_index=1
	game._simulate(.01)
	check(enemy.attack=="blast" and actor.actors[enemy.id].asset_id=="boss_warden_attack","blast retains old slam sheet")
	enemy.warning_left=.001;game._simulate(.002)
	check(enemy.ai_state=="recover" and actor.state_of(enemy.id)=="attack","blast preserves existing event-driven release")
	check(enemy.sprite.frame==actor.assets.boss_warden_attack.release_frame,"blast release frame unchanged")
	# Finite deterministic inputs compare new presentation against the old shared attack mapping.
	var variants:Dictionary=actor.config.profiles.boss_warden.attack_profiles.duplicate(true)
	for mode_id in ["arena","rooms"]:
		for phase2 in [false,true]:
			var baseline:Array=[]
			for enabled in [false,true]:
				actor.config.profiles.boss_warden.attack_profiles=variants if enabled else {}
				enemy=prepare(game,mode_id,phase2)
				for tick in range(600):
					actor.advance(.02);game._simulate(.02)
					if not enabled:baseline.append(trace(game,enemy))
					else:check(trace(game,enemy)==baseline[tick],"authority parity "+mode_id+" phase2="+str(phase2)+" tick="+str(tick))
	actor.config.profiles.boss_warden.attack_profiles=variants
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"warden_charge_passed":passed,"failures":failures,"scope":"phase selection, anchor, hurt/contact arbitration, finite authority/RNG parity; GUI separate"}))
	quit(0 if failures.is_empty() else 1)
