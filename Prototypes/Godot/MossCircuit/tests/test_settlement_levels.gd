extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func prepare(game,mode_id:String)->void:
	game._title();game._select_mode(mode_id);game._start_run(1717)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.xp=11;game.pickups=[{"pos":Vector2(40,40),"xp":2,"coins":3}]
	if mode_id=="rooms":
		game.mode.planned_index=game.mode.planned_count
		game._begin_room_clear();game.mode.clear_elapsed=game.mode.profile.clear_delay
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	for mode_id in ["arena","rooms"]:
		prepare(game,mode_id)
		var coins:int=game.build.coins
		game._complete_wave()
		check(game.state=="upgrade" and game.level==2 and game.xp==1,"floor XP levels before upgrade/shop "+mode_id)
		check(game.upgrade_pending==2,"earned XP plus stage upgrade both queued "+mode_id)
		check(game.pickups.is_empty(),"floor pickups settled once "+mode_id)
		var settled_coins:int=game.build.coins
		check(settled_coins>coins,"settlement coins retained "+mode_id)
		game._complete_wave()
		check(game.build.coins==settled_coins and game.upgrade_pending==2,"repeated settlement cannot duplicate level reward "+mode_id)
		game._take_upgrade(0,game.choice_generation)
		check(game.state=="upgrade" and game.upgrade_pending==1,"first selection cannot skip second earned choice "+mode_id)
		game._take_upgrade(0,game.choice_generation)
		check(game.state=="shop" and game.upgrade_pending==0,"shop only after all choices "+mode_id)
		game._leave_shop(game.shop_generation);game.spawn_clock=999
		game._simulate(.001)
		check(game.state=="playing" and game.level==2 and game.xp==1,"deploy no deferred-XP surprise "+mode_id)
	# Several earned levels must settle before the policy reward, not only one threshold.
	prepare(game,"arena");game.pickups[0].xp=60
	game._complete_wave()
	check(game.level==4 and game.xp==8 and game.upgrade_pending==4,"multi-threshold collected XP queues all three levels plus stage reward")
	# Ended runs show final earned level, but cannot open a post-victory reward modal.
	prepare(game,"arena");game.wave=6;game.boss_defeated=true;game.boss_spawned=true
	game._complete_wave()
	check(game.state=="won" and game.level==2 and game.xp==1,"terminal result includes collected XP level")
	check(game.upgrade_pending==0 and not game.shop_pending,"terminal settlement queues no inaccessible choice or shop")
	game._process(.01)
	check(game.state=="won","terminal level cannot reopen upgrade")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"settlement_levels_passed":passed,"failures":failures,"scope":"earned XP ordering, reward idempotence and terminal result; UI timing tested separately"}))
	quit(0 if failures.is_empty() else 1)
