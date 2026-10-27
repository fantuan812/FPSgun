extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(8813)
	g.mode=load(get_script().resource_path.get_base_dir().path_join("skip_policy_fixture.gd")).new()
	g.build.items={"power_coil":2};g._recompute();g.stats.hp=50
	var shared_rules=g.weapon_combat
	var shared_world=g.combat
	var shared_session=g.run
	var coins:int=g.build.coins
	g._complete_wave()
	check(g.wave==3 and g.state=="playing","policy advances 1 to 3 without forced upgrade/shop")
	check(not g.shop_pending and g.upgrade_pending==0 and g.shop_offers.is_empty(),"no-shop no-upgrade leaves no pending UI economy state")
	check(g.build.coins==coins+7 and g.stats.hp==53,"mode grant applied exactly not hardcoded wave reward")
	check(g.build.items.get("power_coil",0)==2 and g.weapon_combat==shared_rules and g.combat==shared_world and g.run==shared_session,"nonadjacent transition reuses combat session and build")
	# Stage three's inherited live-Boss guard rejects duplicate old-stage completion.
	g._complete_wave()
	check(g.wave==3 and g.state=="playing" and g.build.coins==coins+7,"duplicate completion cannot pay again through new stage gate")
	g.boss_defeated=true
	g._complete_wave()
	check(g.state=="won" and g.wave==3 and g.mode.count(g.config)==6,"policy terminal at 3 overrides arena count 6")
	var terminal_coins:int=g.build.coins
	for i in range(4):g._complete_wave()
	check(g.state=="won" and g.build.coins==terminal_coins,"terminal calls are idempotent")
	g._title();g._start_run(8813)
	g.mode=load(get_script().resource_path.get_base_dir().path_join("invalid_policy_fixture.gd")).new()
	var enemy:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(160,0))
	var sprite=enemy.sprite
	var before_build:Dictionary=g.build.duplicate(true)
	g._complete_wave()
	await process_frame
	check(g.state=="playing" and g.wave==1 and g.build==before_build,"invalid decision rejects without economy/stage mutation")
	check(g.enemies.size()==1 and is_instance_valid(sprite) and not sprite.is_queued_for_deletion(),"invalid decision preserves live enemy sprite through frame boundary")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([g])
	g.queue_free();await process_frame
	await audio_teardown.finish(self)
	print("INDEPENDENT RESOLUTION: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
