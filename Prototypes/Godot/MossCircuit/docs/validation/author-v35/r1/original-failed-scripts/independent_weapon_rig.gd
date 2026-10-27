extends SceneTree
const Rig=preload("res://scripts/weapon_rig.gd")
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func reset(g,ids:Array=["rivet_gun"])->void:
	g._start_run(83);g.build.weapons=ids.duplicate();g._recompute();g.spawn_clock=999;g.weapon_clocks=[]
	for id in ids:g.weapon_clocks.append(999.0)
func foe(g,pos:Vector2)->Dictionary:
	var e:Dictionary=g._spawn_kind("crawler",pos);e.hp=1000;e.max_hp=1000;e.speed=0
	return e
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	reset(g)
	for id in g.weapon_rig.geometry:
		var geo:Dictionary=g.weapon_rig.geometry[id]
		for delta in [Vector2(200,70),Vector2(-200,70),Vector2(200,-70),Vector2(-200,-70),Vector2.ZERO]:
			var mount:=Vector2(80,50)
			var pose:Dictionary=Rig.muzzle_pose(mount,mount+delta,geo,Vector2.ZERO)
			var size:=Vector2(geo.region[2],geo.region[3])
			var grip:=Vector2(geo.grip[0],geo.grip[1])*size
			var muzzle:=Vector2(geo.muzzle[0],geo.muzzle[1])*size
			var transformed:Vector2=mount+((muzzle-grip)*pose.scale).rotated(pose.angle)
			check(transformed.distance_to(pose.muzzle)<.001,"2D grip/muzzle transform "+id+str(delta))
			check(pose.direction.is_finite() and pose.muzzle.is_finite() and absf(pose.direction.length()-1)<.001,"finite normalized pose "+id+str(delta))
			if delta.length()>100:
				check(absf((mount+delta-pose.muzzle).cross(pose.direction))<.001,"barrel ray aims at target "+id+str(delta))
	for origin in [Vector2.ZERO,Vector2(20,0),Vector2(-20,0),Vector2(0,30)]:
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(1,1).normalized()]:
			var distance:float=Rig.range_distance(Vector2.ZERO,origin,direction,100)
			check(absf((origin+direction*distance).length()-100)<.001 and distance>=0,"positive circle exit")
	check(Rig.range_distance(Vector2.ZERO,Vector2(101,0),Vector2.LEFT,100)==0,"outside origin gets no extra range")
	check(Rig.range_distance(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,100)==0,"zero direction safe")
	reset(g,["rivet_gun","scrap_shotgun","rail_lance","shock_mortar"])
	var e:Dictionary=foe(g,g.player_pos+Vector2(150,0))
	for slot in range(4):
		var id:String=g.build.weapons[slot]
		g._fire_weapon(id,slot)
		var shot:Dictionary=g.weapon_rig.last_shot
		check(shot.slot==slot and shot.id==id,"independent slot fire identity")
		var effect:Dictionary=g.vfx.active.back()
		check(effect.id=="muzzle_flash" and effect.pos.distance_to(shot.pose.muzzle.round())<.001,"actual flash common muzzle")
		if id=="shock_mortar":check(g.pending_blasts.back().visual_origin==shot.pose.muzzle,"mortar visual starts at muzzle")
		else:
			var batch:Array=g.bullets.filter(func(b):return b.slot==slot)
			check(not batch.is_empty() and batch.all(func(b):return b.pos==shot.pose.muzzle),"projectile starts at common muzzle")
	reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
	e=foe(g,g.player_pos+Vector2(200,0));var mounts:Array=[]
	for slot in range(4):g._fire_weapon("rivet_gun",slot);mounts.append(g.weapon_rig.last_shot.pose.mount)
	check(g.weapon_rig.slots.size()==4 and g.bullets.size()==4,"duplicate weapon slots remain separate")
	check(mounts[0]!=mounts[1] and mounts[1]!=mounts[2] and mounts[2]!=mounts[3],"distinct four mount positions")
	for distance in [0.0,1.0,8.0,16.0,25.0]:
		for slot in range(4):
			reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
			e=foe(g,g.player_pos+Vector2(distance,0));g._fire_weapon("rivet_gun",slot)
			var b:Dictionary=g.bullets.back();g._advance_bullet(b,.15)
			check(e.hp<1000,"near target not skipped d"+str(distance)+" slot"+str(slot))
			var hp:float=e.hp;g._advance_bullet(b,.1)
			check(e.hp==hp,"launch and flight hit deduplicated")
	reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
	e=foe(g,g.player_pos+Vector2(-150,-20))
	for slot in range(4):
		g._fire_weapon("rivet_gun",slot)
		var entry:Dictionary=g.weapon_rig.slots[slot]
		var geo:Dictionary=g.weapon_rig.geometry.rivet_gun
		var size:=Vector2(geo.region[2],geo.region[3])
		var tip:=Vector2(geo.muzzle[0],geo.muzzle[1])*size
		var grip:=Vector2(geo.grip[0],geo.grip[1])*size
		check(entry.sprite.to_global(tip+entry.sprite.offset).distance_to(entry.pose.muzzle)<.001,"real mirrored sprite muzzle same as emission")
		check(entry.sprite.to_global(grip+entry.sprite.offset).distance_to(entry.pose.mount)<.001,"real mirrored sprite grip stays mounted")
		var bullet:Dictionary=g.bullets.back()
		var endpoint:Vector2=bullet.pos+bullet.velocity*bullet.life
		var reach:float=load("res://scripts/rules.gd").catalog_entry(g.catalog,"rivet_gun").range*(1+g.stats.range_bonus)
		check(absf(endpoint.distance_to(g.player_pos)-reach)<.01,"actual projectile budget exits player range circle")
	var logical_before:Dictionary=g._launch_pose("rivet_gun",0,e.pos)
	g.weapon_rig.advance(.06);g._sync_weapon_rig()
	var logical_after:Dictionary=g._launch_pose("rivet_gun",0,e.pos)
	check(logical_before==logical_after,"recoil never drives logical pose")
	for delta in [Vector2(150,60),Vector2(-150,60),Vector2(150,-60),Vector2(-150,-60)]:
		reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
		e=foe(g,g.player_pos+delta)
		for slot in range(4):
			g._fire_weapon("rivet_gun",slot)
			var bullet:Dictionary=g.bullets.back()
			var ray:Vector2=bullet.velocity.normalized()
			check(absf((e.pos-bullet.pos).cross(ray))<.001 and (e.pos-bullet.pos).dot(ray)>0,"four slots actual ray forward to target "+str(slot)+str(delta))
			check(ray.distance_to(Vector2.from_angle(g.weapon_rig.slots[slot].sprite.rotation))<.001,"barrel local x matches actual ray")
	reset(g,["scrap_shotgun"])
	e=foe(g,g.player_pos+Vector2(200,0));g._fire_weapon("scrap_shotgun",0)
	check(g.bullets.size()>1 and g.bullets[0].velocity!=g.bullets[-1].velocity and g.bullets.all(func(b):return b.pos==g.bullets[0].pos),"spread common origin distinct fan directions")
	reset(g)
	g.player_pos=Vector2(24,24);e=foe(g,Vector2(-100,24));g._fire_weapon("rivet_gun",0)
	var border_bullet:Dictionary=g.bullets.back();g._advance_bullet(border_bullet,.3)
	check(border_bullet.pos.x<0,"arena border is not an implicit projectile wall")
	reset(g,["return_disc","return_disc"])
	e=foe(g,g.player_pos+Vector2(250,0));g._fire_weapon("return_disc",0);g._sync_weapon_rig()
	check(g.weapon_rig.slots[0].hidden and not g.weapon_rig.slots[1].hidden,"disc hide only owning slot")
	g.bullets[0].life=-1;g._sync_weapon_rig()
	check(not g.weapon_rig.slots[0].hidden,"disc terminal cleanup restores held view")
	var age:float=g.weapon_rig.slots[0].age
	g._on_intent("pause",{});g._process(.05)
	check(g.weapon_rig.slots[0].age==age,"pause freezes recoil")
	reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
	g.build.coins=999;g._open_shop();g.shop_offers=[{"id":"orbit_saw","sold":false}]
	check(g._buy(0,g.shop_generation,0),"shop replace weapon succeeds")
	g._sync_weapon_rig()
	check(g.weapon_rig.slots[0].id=="orbit_saw" and g.weapon_rig.slots.size()==4,"replacement updates actual world slot")
	check(g._sell_weapon(1,g.shop_generation),"shop sell succeeds")
	g._sync_weapon_rig()
	check(g.weapon_rig.slots.size()==3 and g.weapon_rig.slots[2].slot==2,"sale compacts world slots without stale fourth")
	reset(g)
	var near:Dictionary=foe(g,g.player_pos+Vector2(50,0));near.scale=1.0
	var far:Dictionary=foe(g,g.player_pos+Vector2(100,0));far.scale=5.0
	var synthetic:Dictionary={"life":1.0,"damage":10.0,"hit":[],"pierce":0,"weapon":"rivet_gun"}
	g._hit_segment(synthetic,g.player_pos,g.player_pos+Vector2(200,0))
	check(far.hp==990 and near.hp==1000 and synthetic.hit==[far.id],"penetration orders first circle entry not enemy center")
	reset(g,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"])
	g.build.coins=999;g._open_shop();g.shop_offers=[{"id":"rivet_gun","sold":false}]
	g.weapon_rig.fire(0,g._launch_pose("rivet_gun",0,g.player_pos+Vector2(100,0)))
	var before_generation:int=g.weapon_rig.generation
	check(g._buy(0,g.shop_generation,0),"same-ID replacement succeeds")
	check(g.weapon_rig.generation>before_generation and g.weapon_rig.last_shot.is_empty(),"same-ID replacement clears stale recoil despite identical ID list")
	reset(g,["rivet_gun","rivet_gun"])
	e=foe(g,g.player_pos+Vector2(150,0));g._fire_weapon("rivet_gun",1)
	check(g.actor_anim.state_of(0)!="attack","auxiliary fire does not fake main-hand body action")
	g._fire_weapon("rivet_gun",0)
	var body_frame:AtlasTexture=g.hero.sprite_frames.get_frame_texture("action",g.hero.frame)
	check(body_frame.atlas.resource_path=="res://assets/weapon_mounts/clean_hero_attack.png","runtime body attack uses unarmed replacement not baked pistol")
	reset(g);g._hurt(9999);g._sync_weapon_rig()
	check(g.weapon_rig.slots.is_empty(),"death removes equipment presentation")
	reset(g);check(g.weapon_rig.last_shot.is_empty(),"restart clears old recoil identity")
	g.queue_free();await process_frame
	print(JSON.stringify({"independent_weapon_rig_passed":passed,"failures":failures,"scope":"headless geometry and state; no GUI"}))
	quit(0 if failures.is_empty() else 1)
