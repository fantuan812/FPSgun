extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func prepare(game,mode_id:String="arena",phase2:bool=true)->Dictionary:
	game._title();game._select_mode(mode_id);game._start_run(1717)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.stats.hp=10000;game.stats.max_hp=10000
	var enemy:Dictionary=game._spawn_kind("boss_core",game.player_pos+Vector2(270,0))
	enemy.hp=enemy.max_hp*(.4 if phase2 else .9);enemy.anim_hp=enemy.hp
	enemy.attack_index=2;enemy.cooldown_left=0
	return enemy
func trace(game)->Array:
	var entities:Array=[]
	for enemy in game.enemies:
		entities.append([enemy.id,enemy.kind,enemy.parent_id,enemy.pos,enemy.hp,enemy.phase,enemy.ai_state,enemy.attack,enemy.attack_index,enemy.aim,enemy.target,enemy.cooldown_left,enemy.warning_left,enemy.charge_left,enemy.recover_left])
	var projectiles:Array=[]
	for projectile in game.enemy_bullets:projectiles.append([projectile.pos,projectile.velocity,projectile.life,projectile.owner])
	return [entities,projectiles,game.stats.hp,game.hurt_clock,game.elapsed,game.wave_time,game.kills,game.build.coins,game.rng.state,game.loot_rng.state,game.shop_rng.state]
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	var director=game.actor_anim
	check(director.assets.has("boss_core_summon"),"distinct Core summon source loaded")
	if not director.assets.has("boss_core_summon"):
		game.queue_free();await process_frame
		print(JSON.stringify({"core_summon_passed":passed,"failures":failures}));quit(1);return
	var asset:Dictionary=director.assets.boss_core_summon
	check(asset.frames.get_frame_count("action")==16,"exact sixteen summon poses")
	var enemy:Dictionary=prepare(game)
	check(is_equal_approx(director.actors[enemy.id].height,165.3),"actual Core spawn height 57 times 2.9")
	game._simulate(.01)
	check(enemy.phase==2 and enemy.attack=="summon" and enemy.attack_index==3,"actual phase2 third attack selects summon")
	check(enemy.sprite.frame==0 and director.actors[enemy.id].asset_id=="boss_core_summon","true warning chooses new summon pose")
	check(is_equal_approx(enemy.sprite.scale.x,165.3/246.0),"true Boss world scale derives from fixed reference height")
	check(not director.trigger(enemy.id,"attack"),"contact/event reaction cannot restart summon")
	for flipped in [false,true]:
		enemy.aim=Vector2.RIGHT if flipped else Vector2.LEFT
		for phase in ["warning","recover"]:
			enemy.ai_state=phase
			var first:int=0 if phase=="warning" else 7
			var count:int=7 if phase=="warning" else 9
			if phase=="recover":director.actors[enemy.id].recover_span=.7
			for index in range(count):
				var progress:float=(float(index)+.5)/count
				enemy.warning_left=enemy.warning*(1-progress);enemy.recover_left=.7*(1-progress)
				director.observe_enemy(enemy,phase,enemy.pos-enemy.aim*100)
				check(enemy.sprite.frame==first+index,"actual "+phase+" pose "+str(first+index))
				check(enemy.sprite.flip_h==flipped,"summon facing remains locked")
				check(is_equal_approx(enemy.sprite.scale.x,165.3/246.0),"no per-pose scale normalization")
	enemy=prepare(game);game._simulate(.01);enemy.warning_left=.001
	game._simulate(.002)
	check(enemy.ai_state=="recover" and enemy.sprite.frame==7,"real release tick shows summon attempt pose seven")
	check(game.enemies.size()==3 and game.enemies.filter(func(e):return e.parent_id==enemy.id).size()==2,"phase2 release creates original two children")
	director.trigger(enemy.id,"hurt");game._simulate(.3);director.advance(.28)
	check(director.actors[enemy.id].asset_id=="boss_core_summon" and enemy.sprite.frame>7,"hurt reveals current recovery without replay")
	check(game.enemies.size()==3,"hurt cannot duplicate summon")
	# Existing three-child cap can turn the same attempt pose into zero new children.
	enemy=prepare(game);game._simulate(.01)
	for index in range(3):game._spawn_kind("crawler",Vector2(40+index*40,40),enemy.id)
	enemy.warning_left=.001;game._simulate(.002)
	check(game.enemies.size()==4 and enemy.sprite.frame==7,"capped attempt still shows release but creates zero children")
	enemy=prepare(game);enemy.hp=enemy.max_hp*.9;enemy.anim_hp=enemy.hp
	game._simulate(.01)
	check(enemy.phase==1 and enemy.attack=="ring" and director.actors[enemy.id].asset_id=="boss_core_attack","phase1 third attack retains original ring source")
	enemy.warning_left=.001;game._simulate(.002)
	check(game.enemy_bullets.size()==8 and director.state_of(enemy.id)=="attack","original phase1 ring release and count unchanged")
	var variants:Dictionary=director.config.profiles.boss_core.attack_profiles.duplicate(true)
	for mode_id in ["arena","rooms"]:
		for phase2 in [false,true]:
			var baseline:Array=[]
			for enabled in [false,true]:
				director.config.profiles.boss_core.attack_profiles=variants if enabled else {}
				enemy=prepare(game,mode_id,phase2)
				for tick in range(600):
					director.advance(.02);game._simulate(.02)
					if not enabled:baseline.append(trace(game))
					else:check(trace(game)==baseline[tick],"authority parity "+mode_id+" phase2="+str(phase2)+" tick="+str(tick))
	director.config.profiles.boss_core.attack_profiles=variants
	game.queue_free();await process_frame
	print(JSON.stringify({"core_summon_passed":passed,"failures":failures,"scope":"actual Boss scale, true AI attempt/caps, original ring and finite authority/RNG parity; GUI separate"}))
	quit(0 if failures.is_empty() else 1)
