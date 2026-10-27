extends RefCounted
const ScavengerReel=preload("res://scripts/gameplay/scavenger_reel.gd")
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
const RunSession=preload("res://scripts/gameplay/run_session.gd")
const WeaponPresentation=preload("res://scripts/gameplay/weapon_presentation.gd")
const WeaponRig=preload("res://scripts/weapon_rig.gd")
const Rules=preload("res://scripts/rules.gd")
const BoundaryShot=preload("res://scripts/gameplay/boundary_shot.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
const PrimaryDefense=preload("res://scripts/gameplay/primary_defense.gd")
const WeaponTempering=preload("res://scripts/gameplay/weapon_tempering.gd")
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
## No mode, UI, progression, or input polling. Collision/proc semantics are shared by every mode.
var world:CombatState
var session:RunSession
var catalog:Dictionary
var presentation:WeaponPresentation
var effect_event:Callable
var play_vfx:Callable
func _init(w:CombatState,s:RunSession,c:Dictionary,p:WeaponPresentation,e:Callable,v:Callable)->void:
	world=w;session=s;catalog=c;presentation=p;effect_event=e;play_vfx=v

func fire(id: String, slot: int, area:Dictionary={}) -> void:
	if world.enemies.is_empty(): return
	var weapon := Rules.catalog_entry(catalog, id)
	var damage: float = Rules.weapon_damage(weapon,world.stats,WeaponTempering.multiplier(session.build,catalog,slot,id))
	if weapon.behavior == "field_bankshot":
		fire_bankshot(weapon,slot,damage,area)
		return
	if weapon.behavior == "cone_chill":
		fire_chill(weapon,slot,damage)
		return
	if weapon.behavior == "orbit":
		presentation.fire(id,slot,world.player_pos+Vector2.RIGHT*100,true)
		# A timed rotating radial sweep: damages each nearby target once per attack.
		for enemy in world.enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(world.player_pos) <= Rules.weapon_reach(weapon,world.stats):
				var resolved:float=PrimaryDefense.resolve(enemy,damage,world.player_pos,world.player_pos-enemy.pos)
				enemy.hp -= resolved
				enemy.last_source = "primary"
				effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":resolved,"weapon":id})
		world.flashes.append({"pos":world.player_pos, "life":.25, "radius":Rules.weapon_reach(weapon,world.stats)})
		return
	var living: Array = world.enemies.filter(func(enemy): return enemy.hp > 0)
	if living.is_empty(): return
	var nearest: Dictionary = living[0]
	for enemy in living:
		if world.player_pos.distance_squared_to(enemy.pos) < world.player_pos.distance_squared_to(nearest.pos): nearest = enemy
	var preferred:Dictionary=Focus.eligible(world.enemies,world.focus_enemy_id,world.player_pos,weapon,world.stats)
	if not preferred.is_empty():nearest=preferred
	var reach: float = Rules.weapon_reach(weapon,world.stats)
	if world.player_pos.distance_to(nearest.pos) > reach: return
	var pose:Dictionary=presentation.fire(id,slot,nearest.pos)
	var aim:Vector2=pose.direction
	if weapon.behavior!="return":play_vfx.call("muzzle_flash",pose.muzzle,{"angle":aim.angle(),"weapon":id,"slot":slot})
	if weapon.behavior == "mortar":
		world.pending_blasts.append({"pos":nearest.pos,"delay":.6,"damage":damage,"radius":85.0,"weapon":id,"visual_origin":pose.muzzle})
		return
	var direction: Vector2 = aim
	var count: int = Rules.weapon_projectiles(weapon,world.stats)
	for i in range(count):
		var angle: float = (float(i) / maxf(1, count - 1) - .5) * float(weapon.spread) if count > 1 else 0.0
		var vector := direction.rotated(angle)
		var travel:float=WeaponRig.range_distance(world.player_pos,pose.muzzle,vector,reach)
		if travel<=.000001:continue
		var bullet:Dictionary={"pos":pose.muzzle,"launch_start":pose.mount,"launch_end":pose.muzzle, "velocity":vector * world.stats.bullet_speed, "life":2.5 if weapon.behavior == "return" else maxf(.000001,travel / world.stats.bullet_speed), "damage":damage, "pierce":int(weapon.pierce) + int(world.stats.pierce), "hit":[], "weapon":id, "slot":slot, "returning":false,"outbound_left":travel / world.stats.bullet_speed}
		if id=="return_disc":
			var reel:=ScavengerReel.snapshot(session.build,catalog)
			if not reel.is_empty():bullet.scavenger=reel
		world.bullets.append(bullet)

func fire_chill(weapon:Dictionary,slot:int,damage:float)->void:
	var reach:float=Rules.weapon_reach(weapon,world.stats)
	var targets:Array=Status.ordered_living(world.enemies,world.player_pos,reach)
	if targets.is_empty():return
	var preferred:Dictionary=Focus.find(targets,world.focus_enemy_id)
	var target:Vector2=targets[0].pos if preferred.is_empty() else preferred.pos
	var direction:Vector2=(target-world.player_pos).normalized()
	if direction.length_squared()<.000001:
		direction=Vector2.RIGHT
		target=world.player_pos+direction*reach
	presentation.fire(weapon.id,slot,target)
	var half_angle:float=deg_to_rad(float(weapon.cone_degrees)*.5)
	# Display samples the same origin, radius and angle as authority, never supplies hits.
	var existing:Array=world.effect_visuals.filter(func(v):return v.kind=="cryo_cone")
	if existing.size()>=4:world.effect_visuals.erase(existing[0])
	world.effect_visuals.append({"kind":"cryo_cone","pos":world.player_pos,"direction":direction,"radius":reach,"half_angle":half_angle,"life":.16})
	for enemy in targets:
		if enemy.hp<=0 or not Status.in_cone(enemy.pos,world.player_pos,direction,reach,half_angle):continue
		var resolved:float=PrimaryDefense.resolve(enemy,damage,world.player_pos,world.player_pos-enemy.pos)
		enemy.hp-=resolved
		enemy.last_source="primary"
		if enemy.hp>0:Status.apply_chill(enemy,session.elapsed,weapon)
		effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":resolved,"weapon":weapon.id})

func hit_segment(b:Dictionary,start:Vector2,end:Vector2)->void:
	var candidates:Array=[]
	for enemy in world.enemies:
		if enemy.hp<=0 or b.hit.has(enemy.id):continue
		var closest:Vector2=Geometry2D.get_closest_point_to_segment(enemy.pos,start,end)
		if closest.distance_to(enemy.pos)<16*float(enemy.scale):
			var segment:Vector2=end-start
			var first_contact:float=0.0
			if segment.length_squared()>.000001:
				var projection:float=(enemy.pos-start).dot(segment.normalized())
				var perpendicular_sq:float=maxf(0,enemy.pos.distance_squared_to(start)-projection*projection)
				first_contact=maxf(0,projection-sqrt(maxf(0,pow(16*float(enemy.scale),2)-perpendicular_sq)))
			candidates.append({"enemy":enemy,"distance":first_contact})
	candidates.sort_custom(func(a,c):return a.distance<c.distance or (is_equal_approx(a.distance,c.distance) and a.enemy.id<c.enemy.id))
	for candidate in candidates:
		var enemy:Dictionary=candidate.enemy
		if enemy.hp<=0 or b.hit.has(enemy.id):continue
		var resolved:float=PrimaryDefense.resolve(enemy,b.damage,start,start-end)
		enemy.hp-=resolved;enemy.last_source="primary"
		effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":resolved,"weapon":b.get("weapon",""),"returning":b.get("returning",false)})
		b.hit.append(enemy.id)
		world.flashes.append({"pos":enemy.pos,"life":.14})
		if b.hit.size()>b.get("pierce",world.stats.pierce):b.life=-1;break

func advance_bullet(b: Dictionary,dt: float) -> void:
	if b.life<=0:return
	if b.has("launch_start"):
		hit_segment(b,b.launch_start,b.pos)
		b.erase("launch_start")
		if b.life<=0:return
	var previous: Vector2 = b.pos
	var step := minf(dt,maxf(0,b.life))
	b.pos += b.velocity * step
	b.life -= step
	hit_segment(b,previous,b.pos)

func advance_disc(b: Dictionary,dt: float) -> Array:
	var sweeps:Array=[]
	var remaining := minf(dt,maxf(0,b.life))
	if not b.returning:
		if b.has("launch_start"):advance_bullet(b,0)
		if b.life<=0:return sweeps
		var outbound := minf(remaining,maxf(0,b.outbound_left))
		if outbound > 0: advance_bullet(b,outbound)
		b.outbound_left -= outbound
		remaining -= outbound
		if b.outbound_left <= .000001:
			b.returning = true
			b.hit.clear()
	if b.returning and remaining > 0 and b.life > 0:
		var distance: float = b.pos.distance_to(world.player_pos)
		if distance < 14:
			b.life = -1
			return sweeps
		b.velocity = (world.player_pos-b.pos).normalized() * world.stats.bullet_speed
		var return_start:Vector2=b.pos
		advance_bullet(b,minf(remaining,distance/world.stats.bullet_speed))
		if ScavengerReel.valid_snapshot(b.get("scavenger")) and return_start.is_finite() and b.pos.is_finite() and return_start!=b.pos:
			sweeps.append({"disc":b,"start":return_start,"end":b.pos})
		if b.pos.distance_to(world.player_pos) < 14: b.life = -1
	return sweeps

func fire_bankshot(weapon:Dictionary,slot:int,damage:float,area:Dictionary)->void:
	var reach:float=Rules.weapon_reach(weapon,world.stats)
	var targets:Array=Status.ordered_living(world.enemies,world.player_pos,reach)
	if targets.is_empty():return
	var preferred:Dictionary=Focus.find(targets,world.focus_enemy_id)
	var target:Vector2=targets[0].pos if preferred.is_empty() else preferred.pos
	var coincident:bool=target.distance_squared_to(world.player_pos)<=BoundaryShot.DIR_EPS*BoundaryShot.DIR_EPS
	var pose:Dictionary=presentation.fire_fixed_direction(weapon.id,slot,Vector2.RIGHT) if coincident else presentation.fire(weapon.id,slot,target)
	var shot:Dictionary=BoundaryShot.spawn(pose.muzzle,pose.direction,area,damage,world.stats.bullet_speed,reach,int(weapon.pierce)+int(world.stats.pierce),session.build.items.get("bounce_guide",0)>0,slot)
	if shot.is_empty():return
	world.bullets.append(shot)
	play_vfx.call("muzzle_flash",pose.muzzle,{"angle":pose.direction.angle(),"weapon":weapon.id,"slot":slot})

func advance_bankshot(b:Dictionary,dt:float)->void:
	BoundaryShot.advance(b,dt,world.enemies,_bankshot_hit,_bankshot_contact)

func _bankshot_hit(enemy:Dictionary,b:Dictionary)->void:
	var resolved:float=PrimaryDefense.resolve(enemy,b.damage,b.pos,-Vector2(b.dx,b.dy))
	enemy.hp-=resolved;enemy.last_source="primary"
	effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":resolved,"weapon":b.weapon,"returning":false})
	world.flashes.append({"pos":enemy.pos,"life":.14})

func _bankshot_contact(event:Dictionary)->void:
	var old:Array=world.effect_visuals.filter(func(v):return v.kind=="bankshot_contact")
	if old.size()>=12:world.effect_visuals.erase(old[0])
	world.effect_visuals.append({"kind":"bankshot_contact","pos":event.pos,"direction":event.direction,"guided":event.guided,"reflected":event.reflected,"radius":9.0,"life":.18})
