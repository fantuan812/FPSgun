extends RefCounted
const Context=preload("res://scripts/gameplay/combat_context.gd")
const RunFlow=preload("res://scripts/gameplay/run_flow.gd")
const Rules=preload("res://scripts/rules.gd")
const EnemyAI=preload("res://scripts/enemy_ai.gd")
## Mode-independent combat step: weapons, AI, projectiles, deaths and pickups.
## No wave timer, spawn schedule, completion policy, UI or shop dependency.
static func step(frame:Context,dt:float)->void:
	for prep_slot in range(frame.session.build.weapons.size()):
		var soon:float=frame.world.weapon_clocks[prep_slot]
		var prep_weapon:Dictionary=Rules.catalog_entry(frame.catalog,frame.session.build.weapons[prep_slot])
		var prep_range:float=prep_weapon.range*(1.0+frame.world.stats.range_bonus)
		if prep_slot==0 and prep_weapon.behavior!="orbit" and soon>0 and soon<.12 and frame.world.enemies.any(func(e):return e.hp>0 and e.pos.distance_to(frame.world.player_pos)<=prep_range):
			frame.actor.set_phase(0,"warning",1-soon/.12)
			break
	for slot in range(frame.session.build.weapons.size()):
		frame.world.weapon_clocks[slot] -= dt
		if frame.world.weapon_clocks[slot] <= 0 and not frame.world.enemies.is_empty():
			frame.weapons.fire(frame.session.build.weapons[slot], slot)
			var weapon := Rules.catalog_entry(frame.catalog, frame.session.build.weapons[slot])
			frame.world.weapon_clocks[slot] = maxf(.09, weapon.interval / (1.0 + frame.world.stats.haste))
	frame.procs.advance_mortars(dt)
	frame.procs.advance_hazards(dt)
	var spawn_requests: Array = []
	for e in frame.world.enemies:
		if e.hp <= 0: continue
		var normal_speed: float = e.speed
		if e.get("slow_until",0.0) > frame.session.elapsed: e.speed *= .55
		var previous_ai:String=e.ai_state
		var events: Array = EnemyAI.tick(e,frame.world.player_pos,dt,frame.session.elapsed)
		e.speed = normal_speed
		e.pos = e.pos.clamp(Vector2(20,20),Vector2(frame.area.width - 20,frame.area.height - 20))
		e.sprite.position = e.pos.round()
		frame.actor.observe_enemy(e,previous_ai,frame.world.player_pos)
		for event in events:
			match event.kind:
				"shot", "ring":
					for index in range(event.count):
						var enemy_direction: Vector2 = Vector2.from_angle(TAU * index / event.count + .13) if event.kind == "ring" else event.direction.rotated((index - (event.count - 1) * .5) * .22)
						frame.world.enemy_bullets.append({"pos":e.pos,"velocity":enemy_direction * e.projectile_speed,"life":4.0,"damage":e.damage,"owner":e.id})
				"blast":
					frame.play_vfx.call("explosion",event.pos,{"radius":event.radius})
					frame.world.flashes.append({"pos":event.pos,"radius":event.radius,"life":.2})
					if frame.world.player_pos.distance_to(event.pos) <= event.radius: frame.hurt.call(event.damage)
				"summon":
					var children := frame.world.enemies.filter(func(child): return child.get("parent_id",-1) == e.id and child.hp > 0).size()
					for index in range(mini(event.count,maxi(0,int(e.summon_limit) - children))):
						spawn_requests.append({"parent_id":e.id,"pos":e.pos + Vector2.from_angle(index * PI + frame.session.elapsed) * 50})
		if frame.session.state != "playing": return
		# Warning/recovery windows are contact-safe; charges damage only while moving.
		if e.ai_state in ["move","charging"] and e.pos.distance_to(frame.world.player_pos) < 16.0 * float(e.scale) + 9.0:
			frame.actor.trigger(e.id,"attack")
			frame.hurt.call(e.damage)
		if frame.session.state != "playing": return
	for request in spawn_requests: frame.spawn_kind.call("crawler",request.pos,request.parent_id)
	var living_owners: Array = frame.world.enemies.filter(func(enemy): return enemy.hp > 0).map(func(enemy): return enemy.id)
	frame.world.enemy_bullets = frame.world.enemy_bullets.filter(func(projectile): return projectile.owner in living_owners)
	for i in range(frame.world.enemy_bullets.size() - 1,-1,-1):
		var projectile: Dictionary = frame.world.enemy_bullets[i]
		if projectile.life <= 0:
			frame.world.enemy_bullets.remove_at(i)
			continue
		var previous: Vector2 = projectile.pos
		projectile.pos += projectile.velocity * minf(dt,projectile.life)
		projectile.life -= dt
		if Geometry2D.get_closest_point_to_segment(frame.world.player_pos,previous,projectile.pos).distance_to(frame.world.player_pos) < 12:
			frame.hurt.call(projectile.damage)
			projectile.life = -1
		if projectile.life <= 0: frame.world.enemy_bullets.remove_at(i)
		if frame.session.state != "playing": return
	for i in range(frame.world.bullets.size() - 1, -1, -1):
		var b: Dictionary = frame.world.bullets[i]
		if b.life <= 0:
			frame.world.bullets.remove_at(i)
			continue
		if b.get("weapon","") == "return_disc":
			frame.weapons.advance_disc(b,dt)
		else:
			frame.weapons.advance_bullet(b,dt)
		if b.life <= 0: frame.world.bullets.remove_at(i)
	for enemy in frame.world.enemies:
		if enemy.hp>0 and enemy.hp<enemy.get("anim_hp",enemy.hp):frame.actor.trigger(enemy.id,"hurt")
		enemy.anim_hp=enemy.hp
	for i in range(frame.world.enemies.size() - 1, -1, -1):
		var e: Dictionary = frame.world.enemies[i]
		if e.hp <= 0:
			if e.boss: frame.boss_killed.call(e)
			var source: String = e.get("last_source","primary")
			frame.procs.emit_event("kill",{"pos":e.pos,"source":source,"depth":0 if source == "primary" else 1})
			frame.world.enemy_bullets = frame.world.enemy_bullets.filter(func(projectile): return projectile.owner != e.id)
			frame.world.pickups.append({"pos": e.pos, "xp": e.xp, "coins":maxi(1, int(e.xp / 2))})
			e.sprite.position=e.pos
			frame.actor.die(e.id)
			frame.world.enemies.remove_at(i)
			frame.session.kills += 1
	for i in range(frame.world.pickups.size() - 1, -1, -1):
		var p: Dictionary = frame.world.pickups[i]
		var distance: float = p.pos.distance_to(frame.world.player_pos)
		if distance < frame.world.stats.pickup_radius: p.pos = p.pos.move_toward(frame.world.player_pos, dt * 260)
		if distance < 14:
			RunFlow.collect_pickup(frame.world,frame.session,p)
			frame.procs.emit_event("pickup",{"pos":p.pos,"source":p.get("source","normal")})
			frame.world.pickups.remove_at(i)
	for i in range(frame.world.flashes.size() - 1, -1, -1):
		frame.world.flashes[i].life -= dt
		if frame.world.flashes[i].life <= 0: frame.world.flashes.remove_at(i)
