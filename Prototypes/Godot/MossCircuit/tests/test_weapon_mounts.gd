extends SceneTree
const Rig=preload("res://scripts/weapon_rig.gd")
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game._start_run(808)
	var rig=game.weapon_rig
	check(rig.assets.keys().size()==8 and rig.geometry.keys().size()==8 and rig.assets.has("cryo_sprayer") and rig.assets.has("bankshot_driver"),"eight world assets including Cryo and Bankshot, not inventory icons")
	check(game.actor_anim.assets.hero_attack.frames.get_frame_texture("action",0).atlas.resource_path.contains("weapon_mounts"),"unarmed attack replaces baked gun")
	for id in rig.geometry:
		var g:Dictionary=rig.geometry[id]
		var size:=Vector2(g.region[2],g.region[3]);var muzzle:Array=g.muzzle;var grip:Array=g.grip
		for target in [Vector2(200,0),Vector2(-200,0),Vector2(200,100),Vector2(-100,-200),Vector2.ZERO]:
			var pose:Dictionary=Rig.muzzle_pose(Vector2.ZERO,target,g)
			var transform:=Transform2D(pose.angle,pose.scale,0,pose.mount)
			var actual:Vector2=transform*((Vector2(muzzle[0],muzzle[1])-Vector2(grip[0],grip[1]))*size)
			check(actual.distance_to(pose.muzzle)<.0001,"shared matrix "+id)
			check(is_finite(pose.muzzle.x) and is_finite(pose.direction.y),"finite aim "+id)
			check(absf(pose.direction.length()-1)<.0001,"unit aim "+id)
	for angle in range(36):
		var direction:=Vector2.from_angle(angle*TAU/36)
		var start:=Vector2(14,-7)
		var distance:float=Rig.range_distance(Vector2.ZERO,start,direction,100)
		check(absf((start+direction*distance).length()-100)<.001,"range circle exit")
	check(Rig.range_distance(Vector2.ZERO,Vector2(101,0),Vector2.LEFT,100)==0,"outside origin cannot gain inward travel")
	check(Rig.range_distance(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,100)==0,"zero direction no NaN travel")
	game.build.weapons=["rivet_gun","scrap_shotgun","rail_lance","shock_mortar"];game._recompute()
	var enemy:Dictionary=game._spawn_kind("crawler",game.player_pos+Vector2(180,50));enemy.hp=10000
	var rng_state:int=game.rng.state
	for i in range(4):
		game._fire_weapon(game.build.weapons[i],i)
		var pose:Dictionary=rig.last_shot.pose
		var g:Dictionary=rig.geometry[game.build.weapons[i]]
		var point:=Vector2(g.muzzle[0]*g.region[2],g.muzzle[1]*g.region[3])
		check(rig.slots[i].sprite.to_global(point+rig.slots[i].sprite.offset).distance_to(pose.muzzle)<.001,"world muzzle exact at emission")
		check(game.vfx.last_emission.pos.distance_to(pose.muzzle.round())<.001,"pixel snapped flash from same emission pose")
		if i<3:
			var b:Dictionary=game.bullets[-1]
			check(b.pos.distance_to(pose.muzzle)<.001,"projectile exact at emission")
			check(b.life>0 and is_finite(b.life),"finite positive flight")
	check(game.pending_blasts[0].visual_origin==rig.last_shot.pose.muzzle,"mortar visual launch same cannon")
	check(game.rng.state==rng_state,"rig and pose use no gameplay RNG")
	var spread:Array=game.bullets.filter(func(b):return b.weapon=="scrap_shotgun")
	check(spread.size()>=3 and spread.all(func(b):return b.pos==spread[0].pos),"spread shares one barrel origin")
	check(spread[0].velocity!=spread[-1].velocity,"spread retains fan directions")
	game._start_run(808)
	game.build.weapons=["rivet_gun","rivet_gun","rivet_gun","rivet_gun"];game._recompute()
	check(rig.slots.size()==4,"duplicate weapons have four independent nodes")
	var ids:Array=rig.slots.map(func(slot):return slot.sprite.get_instance_id())
	check(ids[0]!=ids[1] and ids[2]!=ids[3],"slot identity not weapon ID cache")
	game._spawn_kind("crawler",game.player_pos+Vector2(200,0));game._sync_weapon_rig()
	var positions:Array=rig.slots.map(func(slot):return slot.pose.mount)
	check(positions[0]!=positions[1] and positions[2]!=positions[3],"distinct hardpoints")
	game._start_run(808)
	var near:Dictionary=game._spawn_kind("crawler",game.player_pos+Vector2(5,0));near.hp=1000
	game._fire_weapon("rivet_gun",0)
	var bullet:Dictionary=game.bullets[-1]
	var hp:float=near.hp
	game._advance_bullet(bullet,0)
	check(near.hp==hp-bullet.damage and bullet.hit.has(near.id),"point blank launch segment hits once")
	game._advance_bullet(bullet,.01)
	check(near.hp==hp-bullet.damage,"no extra collision hit after launch segment")
	game._start_run(808)
	game.build.weapons=["return_disc","return_disc"];game._recompute()
	game._spawn_kind("crawler",game.player_pos+Vector2(200,0));game._fire_weapon("return_disc",1);game._sync_weapon_rig()
	check(not rig.slots[0].hidden and rig.slots[1].hidden,"disc hand hide is slot-specific")
	check(rig.disc_sprites[0].position==game.bullets[0].pos,"disc image on authoritative trajectory")
	game.bullets.clear();game._sync_weapon_rig()
	check(not rig.slots[1].hidden,"disc returns to rack when no live projectiles")
	var clock:float=rig.visible_clock
	game.state="paused";game._process(.5)
	check(rig.visible_clock==clock,"pause freezes weapon clock")
	game._finish(false)
	check(rig.slots.is_empty() and rig.disc_sprites.is_empty(),"death clears weapon nodes")
	game._start_run(808);game._sync_weapon_rig()
	check(rig.slots.size()==1 and not rig.slots[0].hidden and rig.last_shot.is_empty(),"restart no stale loadout / hidden disc")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v8 deterministic modular loadout and deliberate launch geometry"}));quit(0 if failures.is_empty() else 1)
