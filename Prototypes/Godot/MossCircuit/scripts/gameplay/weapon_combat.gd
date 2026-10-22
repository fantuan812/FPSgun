extends RefCounted
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
const RunSession=preload("res://scripts/gameplay/run_session.gd")
const WeaponPresentation=preload("res://scripts/gameplay/weapon_presentation.gd")
const WeaponRig=preload("res://scripts/weapon_rig.gd")
const Rules=preload("res://scripts/rules.gd")
## No mode, UI, progression, or input polling. Collision/proc semantics are shared by every mode.
var world:CombatState
var session:RunSession
var catalog:Dictionary
var presentation:WeaponPresentation
var effect_event:Callable
var play_vfx:Callable
func _init(w:CombatState,s:RunSession,c:Dictionary,p:WeaponPresentation,e:Callable,v:Callable)->void:
	world=w;session=s;catalog=c;presentation=p;effect_event=e;play_vfx=v

func fire(id: String, slot: int) -> void:
	if world.enemies.is_empty(): return
	var weapon := Rules.catalog_entry(catalog, id)
	var damage: float = weapon.damage * (1.0 + world.stats.damage_bonus)
	if "electric" in weapon.tags: damage *= 1.0 + world.stats.electric_bonus
	if "melee" in weapon.tags: damage *= 1.0 + world.stats.melee_bonus
	if weapon.behavior == "orbit":
		presentation.fire(id,slot,world.player_pos+Vector2.RIGHT*100,true)
		# A timed rotating radial sweep: damages each nearby target once per attack.
		for enemy in world.enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(world.player_pos) <= weapon.range:
				enemy.hp -= damage
				enemy.last_source = "primary"
				effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":damage,"weapon":id})
		world.flashes.append({"pos":world.player_pos, "life":.25, "radius":weapon.range})
		return
	var living: Array = world.enemies.filter(func(enemy): return enemy.hp > 0)
	if living.is_empty(): return
	var nearest: Dictionary = living[0]
	for enemy in living:
		if world.player_pos.distance_squared_to(enemy.pos) < world.player_pos.distance_squared_to(nearest.pos): nearest = enemy
	var reach: float = weapon.range * (1.0 + world.stats.range_bonus)
	if world.player_pos.distance_to(nearest.pos) > reach: return
	var pose:Dictionary=presentation.fire(id,slot,nearest.pos)
	var aim:Vector2=pose.direction
	if weapon.behavior!="return":play_vfx.call("muzzle_flash",pose.muzzle,{"angle":aim.angle(),"weapon":id,"slot":slot})
	if weapon.behavior == "mortar":
		world.pending_blasts.append({"pos":nearest.pos,"delay":.6,"damage":damage,"radius":85.0,"weapon":id,"visual_origin":pose.muzzle})
		return
	var direction: Vector2 = aim
	var count: int = weapon.projectiles + (int(world.stats.extra_pellets) if weapon.behavior == "spread" else 0)
	for i in range(count):
		var angle: float = (float(i) / maxf(1, count - 1) - .5) * float(weapon.spread) if count > 1 else 0.0
		var vector := direction.rotated(angle)
		var travel:float=WeaponRig.range_distance(world.player_pos,pose.muzzle,vector,reach)
		if travel<=.000001:continue
		world.bullets.append({"pos":pose.muzzle,"launch_start":pose.mount,"launch_end":pose.muzzle, "velocity":vector * world.stats.bullet_speed, "life":2.5 if weapon.behavior == "return" else maxf(.000001,travel / world.stats.bullet_speed), "damage":damage, "pierce":int(weapon.pierce) + int(world.stats.pierce), "hit":[], "weapon":id, "slot":slot, "returning":false,"outbound_left":travel / world.stats.bullet_speed})

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
		enemy.hp-=b.damage;enemy.last_source="primary"
		effect_event.call("hit",{"target":enemy.id,"pos":enemy.pos,"damage":b.damage,"weapon":b.get("weapon",""),"returning":b.get("returning",false)})
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

func advance_disc(b: Dictionary,dt: float) -> void:
	var remaining := minf(dt,maxf(0,b.life))
	if not b.returning:
		if b.has("launch_start"):advance_bullet(b,0)
		if b.life<=0:return
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
			return
		b.velocity = (world.player_pos-b.pos).normalized() * world.stats.bullet_speed
		advance_bullet(b,minf(remaining,distance/world.stats.bullet_speed))
		if b.pos.distance_to(world.player_pos) < 14: b.life = -1
