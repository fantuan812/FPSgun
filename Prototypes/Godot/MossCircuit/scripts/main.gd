extends Node2D
const WeaponRig = preload("res://scripts/weapon_rig.gd")
var weapon_rig:Node2D
const ActorDirector = preload("res://scripts/actor_director.gd")
var actor_anim = ActorDirector.new()
var settings := {"reduced_flashes":false}
var settings_return := "title"
var visual_cooldowns:Dictionary={}
var result_pending := false
var result_wait := 0.0
const Rules = preload("res://scripts/rules.gd")
const Effects = preload("res://scripts/effects.gd")
const EnemyAI = preload("res://scripts/enemy_ai.gd")
const MossUI = preload("res://ui/moss_ui.gd")
const Telegraphs = preload("res://scripts/telegraph_layer.gd")
var telegraphs: Node2D
const VFX = preload("res://scripts/vfx_layer.gd")
var vfx: Node2D
const Art = preload("res://scripts/art.gd")
var effects = Effects.new()
var effect_sequence := 0
var pending_blasts: Array = []
var hazards: Array = []
var effect_visuals: Array = []
var encounters: Dictionary
var enemy_bullets: Array = []
var boss_spawned := false
var boss_defeated := false
var boss_rewards: Dictionary = {}
var rewards: Array = []
var codex_return := "title"
var catalog: Dictionary
var build: Dictionary
var shop_rng := RandomNumberGenerator.new()
var shop_offers: Array = []
var shop_generation := 0
var shop_pending := false
var weapon_clocks: Array = []
var shop_message := ""
var inventory_return := "paused"
var config: Dictionary
var stats: Dictionary
var run_seed := 240102
var rng := RandomNumberGenerator.new()
var loot_rng := RandomNumberGenerator.new()
var map_data: Array = []
var grid_size := Vector2i.ZERO
var ground: Texture2D
var hero: AnimatedSprite2D
var camera: Camera2D
var enemies: Array = []
var bullets: Array = []
var pickups: Array = []
var flashes: Array = []
var player_pos := Vector2.ZERO
var wave := 1
var wave_time := 0.0
var elapsed := 0.0
var spawn_clock := 0.0
var shot_clock := 0.0
var hurt_clock := 0.0
var level := 1
var xp := 0
var kills := 0
var state := "title"
var resume_state := "playing"
var next_enemy_id := 0
var ui: CanvasLayer
var choices: Array = []
var upgrade_pending := 0
var choice_generation := 0
var automation := false

func _ready() -> void:
	var raw_balance = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	var raw_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	if not raw_balance is Dictionary or not raw_catalog is Dictionary:
		push_error("Configuration must be valid JSON objects")
		set_process(false)
		return
	config = raw_balance
	catalog = raw_catalog
	var catalog_errors := Rules.validate_catalog(catalog)
	if not catalog_errors.is_empty():
		push_error("Invalid catalog: " + str(catalog_errors))
		set_process(false)
		return
	var raw_encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	if not raw_encounters is Dictionary:
		push_error("Encounters must be a JSON object")
		set_process(false)
		return
	encounters = raw_encounters
	if not EnemyAI.validate(encounters).is_empty() or encounters.waves.size() != int(config.waves.count):
		push_error("Invalid encounter definitions: " + str(EnemyAI.validate(encounters)))
		set_process(false)
		return
	ground = load("res://assets/ground_atlas.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera = Camera2D.new()
	add_child(camera)
	camera.position = Vector2(config.arena.width, config.arena.height) * 0.5
	camera.zoom = Vector2.ONE
	hero = Art.actor("res://assets/hero_walk.png", 64.0, 11.0)
	add_child(hero)
	actor_anim.load_default()
	actor_anim.register_actor(0,hero,"hero",64.0)
	hero.z_index=2
	weapon_rig=WeaponRig.new()
	add_child(weapon_rig)
	weapon_rig.load_default()
	vfx = VFX.new()
	add_child(vfx)
	vfx.load_default()
	telegraphs = Telegraphs.new()
	add_child(telegraphs)
	_build_ui()
	grid_size = Rules.grid_dimensions(config.arena)
	map_data = Rules.map_cells(run_seed, grid_size.x, grid_size.y)
	player_pos = camera.position
	hero.position = player_pos
	_title()
	if "--smoke" in OS.get_cmdline_user_args():
		automation = true
		_start_run(run_seed)

func _build_ui() -> void:
	ui = MossUI.new()
	add_child(ui)
	ui.intent.connect(_on_intent)


func _title() -> void:
	weapon_rig.clear()
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	pickups.clear()
	flashes.clear()
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	visual_cooldowns.clear()
	result_pending = false
	actor_anim.clear()
	vfx.clear()
	telegraphs.show_markers([])
	state = "title"
	ui.show_title(run_seed)


func _start_run(seed_value: int) -> void:
	weapon_rig.clear()
	visual_cooldowns.clear()
	result_pending = false
	actor_anim.clear()
	vfx.clear()
	telegraphs.show_markers([])
	for e in enemies:
		if is_instance_valid(e.sprite):e.sprite.queue_free()
	enemies.clear()
	bullets.clear()
	pickups.clear()
	flashes.clear()
	run_seed = seed_value
	rng.seed = run_seed
	loot_rng.seed = run_seed ^ 58349
	shop_rng.seed = run_seed ^ 92137
	build = Rules.new_build(catalog)
	effects.reset(build.items)
	effect_sequence = 0
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	pending_blasts.clear()
	shop_generation += 1
	choice_generation += 1
	shop_pending = false
	boss_spawned = false
	boss_defeated = false
	boss_rewards.clear()
	rewards.clear()
	enemy_bullets.clear()
	shop_offers.clear()
	weapon_clocks = [0.0]
	grid_size = Rules.grid_dimensions(config.arena)
	map_data = Rules.map_cells(run_seed, grid_size.x, grid_size.y)
	stats = Rules.derive(config.player, build, catalog)
	stats.max_hp = stats.hp
	stats.pierce = 0
	stats.dash_cooldown = 0.0
	stats.dash_time = 0.0
	player_pos = Vector2(config.arena.width, config.arena.height) * 0.5
	wave = 1
	wave_time = 0.0
	elapsed = 0.0
	spawn_clock = 0.0
	shot_clock = 0.0
	hurt_clock = 0.0
	level = 1
	xp = 0
	kills = 0
	next_enemy_id = 0
	upgrade_pending = 0
	state = "playing"
	_hide_modal()
	_update_hud()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == "playing":
				state = "paused"
				_present_pause()
			elif state == "paused": _resume()
			elif state == "inventory": _on_intent("close_inventory",{})
			elif state == "codex": _on_intent("close_codex",{})
		if event.keycode == KEY_I:
			_on_intent("close_inventory" if state == "inventory" else "inventory",{})
		if state == "upgrade" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			_take_upgrade(int(event.keycode - KEY_1), choice_generation)


func _resume() -> void:
	state = "playing"
	_hide_modal()

func _process(delta: float) -> void:
	if state == "playing":
		weapon_rig.advance(minf(delta,.05))
		actor_anim.advance(minf(delta,.05))
		vfx.advance(minf(delta,0.05))
		_simulate(minf(delta, 0.05))
	elif state in ["dead","won"]:
		actor_anim.advance(minf(delta,.05),true)
		if state=="dead" and result_pending:
			result_wait-=minf(delta,.05)
			if result_wait<=0:
				result_pending=false
				_show_result(false)
	hero.position = player_pos.round()
	_sync_weapon_rig()
	camera.position = Vector2(clampf(player_pos.x, 480, config.arena.width - 480) if config.arena.width >= 960 else config.arena.width * 0.5, clampf(player_pos.y, 270, config.arena.height - 270) if config.arena.height >= 540 else config.arena.height * 0.5)
	_update_hud()
	_sync_telegraphs()
	queue_redraw()

func _simulate(dt: float) -> void:
	elapsed += dt
	wave_time += dt
	hurt_clock = maxf(0, hurt_clock - dt)
	stats.dash_cooldown = maxf(0, stats.dash_cooldown - dt)
	stats.dash_time = maxf(0, stats.dash_time - dt)
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if automation: direction = Vector2(cos(elapsed * 0.7), sin(elapsed * 0.7))
	if Input.is_physical_key_pressed(KEY_SPACE) and stats.dash_cooldown <= 0 and direction != Vector2.ZERO:
		stats.dash_time = 0.16
		stats.dash_cooldown = 2.5
		_effect_event("dash",{"pos":player_pos,"angle":direction.angle()})
	player_pos += direction * stats.speed * dt * (3.0 if stats.dash_time > 0 else 1.0)
	player_pos = player_pos.clamp(Vector2(24, 24), Vector2(config.arena.width - 24, config.arena.height - 24))
	if direction != Vector2.ZERO:
		actor_anim.set_phase(0,"move")
		if direction.x != 0 and actor_anim.state_of(0)!="attack": hero.flip_h = direction.x < 0
	else: actor_anim.set_phase(0,"idle")
	hero.modulate = Color(1, 0.5, 0.45) if hurt_clock > 0.5 else Color.WHITE
	_ensure_boss()
	spawn_clock -= dt
	if spawn_clock <= 0:
		_spawn_enemy()
		spawn_clock = maxf(0.13, float(config.waves.spawn_interval) / (1.0 + wave * 0.3))
	for prep_slot in range(build.weapons.size()):
		var soon:float=weapon_clocks[prep_slot]
		var prep_weapon:Dictionary=Rules.catalog_entry(catalog,build.weapons[prep_slot])
		var prep_range:float=prep_weapon.range*(1.0+stats.range_bonus)
		if prep_slot==0 and prep_weapon.behavior!="orbit" and soon>0 and soon<.12 and enemies.any(func(e):return e.hp>0 and e.pos.distance_to(player_pos)<=prep_range):
			actor_anim.set_phase(0,"warning",1-soon/.12)
			break
	for slot in range(build.weapons.size()):
		weapon_clocks[slot] -= dt
		if weapon_clocks[slot] <= 0 and not enemies.is_empty():
			_fire_weapon(build.weapons[slot], slot)
			var weapon := Rules.catalog_entry(catalog, build.weapons[slot])
			weapon_clocks[slot] = maxf(.09, weapon.interval / (1.0 + stats.haste))
	_update_mortars(dt)
	_update_hazards(dt)
	var spawn_requests: Array = []
	for e in enemies:
		if e.hp <= 0: continue
		var normal_speed: float = e.speed
		if e.get("slow_until",0.0) > elapsed: e.speed *= .55
		var previous_ai:String=e.ai_state
		var events: Array = EnemyAI.tick(e,player_pos,dt,elapsed)
		e.speed = normal_speed
		e.pos = e.pos.clamp(Vector2(20,20),Vector2(config.arena.width - 20,config.arena.height - 20))
		e.sprite.position = e.pos.round()
		e.sprite.flip_h = player_pos.x > e.pos.x
		if previous_ai=="warning" and e.ai_state not in ["warning","charging"]:actor_anim.trigger(e.id,"attack",.35)
		if e.ai_state=="warning":actor_anim.set_phase(e.id,"warning",1-e.warning_left/e.warning)
		elif e.ai_state=="recover":actor_anim.set_phase(e.id,"recover")
		elif e.ai_state=="charging":actor_anim.set_phase(e.id,"attack",1-e.charge_left/e.charge_duration)
		elif e.behavior in ["chase","flank"] and e.pos.distance_to(player_pos)<85:
			actor_anim.set_phase(e.id,"warning",1-e.pos.distance_to(player_pos)/85)
		else:actor_anim.set_phase(e.id,"move")
		for event in events:
			match event.kind:
				"shot", "ring":
					for index in range(event.count):
						var enemy_direction: Vector2 = Vector2.from_angle(TAU * index / event.count + .13) if event.kind == "ring" else event.direction.rotated((index - (event.count - 1) * .5) * .22)
						enemy_bullets.append({"pos":e.pos,"velocity":enemy_direction * e.projectile_speed,"life":4.0,"damage":e.damage,"owner":e.id})
				"blast":
					_vfx("explosion",event.pos,{"radius":event.radius})
					flashes.append({"pos":event.pos,"radius":event.radius,"life":.2})
					if player_pos.distance_to(event.pos) <= event.radius: _hurt(event.damage)
				"summon":
					var children := enemies.filter(func(child): return child.get("parent_id",-1) == e.id and child.hp > 0).size()
					for index in range(mini(event.count,maxi(0,int(e.summon_limit) - children))):
						spawn_requests.append({"parent_id":e.id,"pos":e.pos + Vector2.from_angle(index * PI + elapsed) * 50})
		if state != "playing": return
		# Warning/recovery windows are contact-safe; charges damage only while moving.
		if e.ai_state in ["move","charging"] and e.pos.distance_to(player_pos) < 16.0 * float(e.scale) + 9.0:
			actor_anim.trigger(e.id,"attack")
			_hurt(e.damage)
		if state != "playing": return
	for request in spawn_requests: _spawn_kind("crawler",request.pos,request.parent_id)
	var living_owners: Array = enemies.filter(func(enemy): return enemy.hp > 0).map(func(enemy): return enemy.id)
	enemy_bullets = enemy_bullets.filter(func(projectile): return projectile.owner in living_owners)
	for i in range(enemy_bullets.size() - 1,-1,-1):
		var projectile: Dictionary = enemy_bullets[i]
		if projectile.life <= 0:
			enemy_bullets.remove_at(i)
			continue
		var previous: Vector2 = projectile.pos
		projectile.pos += projectile.velocity * minf(dt,projectile.life)
		projectile.life -= dt
		if Geometry2D.get_closest_point_to_segment(player_pos,previous,projectile.pos).distance_to(player_pos) < 12:
			_hurt(projectile.damage)
			projectile.life = -1
		if projectile.life <= 0: enemy_bullets.remove_at(i)
		if state != "playing": return
	for i in range(bullets.size() - 1, -1, -1):
		var b: Dictionary = bullets[i]
		if b.life <= 0:
			bullets.remove_at(i)
			continue
		if b.get("weapon","") == "return_disc":
			_advance_disc(b,dt)
		else:
			_advance_bullet(b,dt)
		if b.life <= 0: bullets.remove_at(i)
	for enemy in enemies:
		if enemy.hp>0 and enemy.hp<enemy.get("anim_hp",enemy.hp):actor_anim.trigger(enemy.id,"hurt")
		enemy.anim_hp=enemy.hp
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		if e.hp <= 0:
			if e.boss: _boss_killed(e)
			var source: String = e.get("last_source","primary")
			_effect_event("kill",{"pos":e.pos,"source":source,"depth":0 if source == "primary" else 1})
			enemy_bullets = enemy_bullets.filter(func(projectile): return projectile.owner != e.id)
			pickups.append({"pos": e.pos, "xp": e.xp, "coins":maxi(1, int(e.xp / 2))})
			e.sprite.position=e.pos
			actor_anim.die(e.id)
			enemies.remove_at(i)
			kills += 1
	for i in range(pickups.size() - 1, -1, -1):
		var p: Dictionary = pickups[i]
		var distance: float = p.pos.distance_to(player_pos)
		if distance < stats.pickup_radius: p.pos = p.pos.move_toward(player_pos, dt * 260)
		if distance < 14:
			stats.hp = minf(stats.max_hp,stats.hp + p.get("heal",0.0))
			xp += int(p.xp)
			Rules.credit(build, p.get("coins", 1) * (1.0 + stats.coin_bonus))
			_effect_event("pickup",{"pos":p.pos,"source":p.get("source","normal")})
			pickups.remove_at(i)
	for i in range(flashes.size() - 1, -1, -1):
		flashes[i].life -= dt
		if flashes[i].life <= 0: flashes.remove_at(i)
	while xp >= Rules.xp_threshold(level):
		xp -= Rules.xp_threshold(level)
		level += 1
		upgrade_pending += 1
	if upgrade_pending > 0:
		_show_upgrades()
		return
	if wave_time >= float(config.waves.duration): _complete_wave()

func _spawn_enemy() -> void:
	if enemies.size() >= int(config.waves.max_enemies): return
	var pos := player_pos + Vector2.from_angle(rng.randf_range(0,TAU)) * rng.randf_range(330,440)
	pos = pos.clamp(Vector2(20,20),Vector2(config.arena.width - 20,config.arena.height - 20))
	if pos.distance_to(player_pos) < 180: return
	var pool: Array = encounters.waves[mini(wave - 1,encounters.waves.size() - 1)].pool
	_spawn_kind(pool[rng.randi_range(0,pool.size() - 1)],pos)

func _spawn_kind(kind: String, pos: Vector2, parent_id: int = -1) -> Dictionary:
	if enemies.size() >= int(config.waves.max_enemies): return {}
	var data: Dictionary = {}
	for entry in encounters.enemies:
		if entry.id == kind: data = entry.duplicate(true); break
	if data.is_empty(): return {}
	var path := "res://assets/enemies/" + kind + ".png"
	# Until an authored sheet is supplied, the known baseline remains a clearly marked fallback.
	if not ResourceLoader.exists(path): path = "res://assets/beetle_walk.png"
	var sprite := Art.actor(path,57.0 * float(data.scale),9.0)
	sprite.modulate = Color(str(data.color)) if path.ends_with("beetle_walk.png") else Color.WHITE
	add_child(sprite)
	next_enemy_id += 1
	data.kind = kind
	data.id = next_enemy_id
	data.pos = pos
	data.hp *= 1.0 if data.boss else 1.0 + (wave - 1) * .12
	data.max_hp = data.hp
	data.sprite = sprite
	data.anim_hp = data.hp
	actor_anim.register_actor(data.id,sprite,kind,57.0*float(data.scale))
	data.parent_id = parent_id
	data.last_source = "primary"
	data.phase = 1
	data.ai_state = "move"
	data.cooldown_left = .8
	data.warning_left = 0.0
	data.recover_left = 0.0
	data.charge_left = 0.0
	data.attack_index = 0
	data.attack = ""
	data.aim = Vector2.RIGHT
	data.target = pos
	enemies.append(data)
	return data

func _ensure_boss() -> void:
	var boss_id: String = encounters.waves[mini(wave - 1,encounters.waves.size() - 1)].boss
	if boss_id == "" or boss_spawned: return
	var pos := player_pos + Vector2(360,0)
	pos = pos.clamp(Vector2(80,80),Vector2(config.arena.width - 80,config.arena.height - 80))
	if pos.distance_to(player_pos) < 220: pos = player_pos - Vector2(360,0)
	var spawned := _spawn_kind(boss_id,pos)
	if not spawned.is_empty(): boss_spawned = true

func _hurt(damage: float) -> void:
	if state != "playing" or hurt_clock > 0 or stats.dash_time > 0: return
	if _effect_event("before_hurt",{}):
		hurt_clock = .25
		return
	actor_anim.trigger(0,"hurt")
	_vfx("hit_spark",player_pos)
	var actual_loss := minf(stats.hp,damage)
	stats.hp = maxf(0,stats.hp - damage)
	_effect_event("hurt",{"amount":actual_loss})
	hurt_clock = .75
	if stats.hp <= 0: _finish(false)

func _boss_killed(enemy: Dictionary) -> void:
	if not enemy.get("boss",false) or enemy.hp > 0 or boss_rewards.has(enemy.kind) or state != "playing": return
	boss_rewards[enemy.kind] = true
	boss_defeated = true
	if enemy.kind == "boss_warden":
		build.boss_protocol = true
		rewards.append("WARDEN PROTOCOL: +25 max HP, +10% damage")
		_recompute()
		stats.hp = minf(stats.max_hp,stats.hp + 25)
		Rules.credit(build,50)
	else:
		rewards.append("REACTOR CROWN: final trophy")
		Rules.credit(build,100)

func _shoot() -> void:
	_fire_weapon("rivet_gun", 0)

func _fire_weapon(id: String, slot: int) -> void:
	if enemies.is_empty(): return
	var weapon := Rules.catalog_entry(catalog, id)
	var damage: float = weapon.damage * (1.0 + stats.damage_bonus)
	if "electric" in weapon.tags: damage *= 1.0 + stats.electric_bonus
	if "melee" in weapon.tags: damage *= 1.0 + stats.melee_bonus
	if weapon.behavior == "orbit":
		_sync_weapon_rig()
		var rotor_pose:Dictionary=_launch_pose(id,slot,player_pos+Vector2.RIGHT*100)
		weapon_rig.fire(slot,rotor_pose)
		# A timed rotating radial sweep: damages each nearby target once per attack.
		for enemy in enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(player_pos) <= weapon.range:
				enemy.hp -= damage
				enemy.last_source = "primary"
				_effect_event("hit",{"target":enemy.id,"pos":enemy.pos,"damage":damage,"weapon":id})
		flashes.append({"pos":player_pos, "life":.25, "radius":weapon.range})
		return
	var living: Array = enemies.filter(func(enemy): return enemy.hp > 0)
	if living.is_empty(): return
	var nearest: Dictionary = living[0]
	for enemy in living:
		if player_pos.distance_squared_to(enemy.pos) < player_pos.distance_squared_to(nearest.pos): nearest = enemy
	var reach: float = weapon.range * (1.0 + stats.range_bonus)
	if player_pos.distance_to(nearest.pos) > reach: return
	if slot==0:actor_anim.trigger(0,"attack")
	if absf(nearest.pos.x-player_pos.x)>.01:hero.flip_h=nearest.pos.x<player_pos.x
	var pose:Dictionary=_launch_pose(id,slot,nearest.pos)
	weapon_rig.fire(slot,pose)
	var aim:Vector2=pose.direction
	if weapon.behavior!="return":_vfx("muzzle_flash",pose.muzzle,{"angle":aim.angle(),"weapon":id,"slot":slot})
	if weapon.behavior == "mortar":
		pending_blasts.append({"pos":nearest.pos,"delay":.6,"damage":damage,"radius":85.0,"weapon":id,"visual_origin":pose.muzzle})
		return
	var direction: Vector2 = aim
	var count: int = weapon.projectiles + (int(stats.extra_pellets) if weapon.behavior == "spread" else 0)
	for i in range(count):
		var angle: float = (float(i) / maxf(1, count - 1) - .5) * float(weapon.spread) if count > 1 else 0.0
		var vector := direction.rotated(angle)
		var travel:float=WeaponRig.range_distance(player_pos,pose.muzzle,vector,reach)
		if travel<=.000001:continue
		bullets.append({"pos":pose.muzzle,"launch_start":pose.mount,"launch_end":pose.muzzle, "velocity":vector * stats.bullet_speed, "life":2.5 if weapon.behavior == "return" else maxf(.000001,travel / stats.bullet_speed), "damage":damage, "pierce":int(weapon.pierce) + int(stats.pierce), "hit":[], "weapon":id, "slot":slot, "returning":false,"outbound_left":travel / stats.bullet_speed})

func _complete_wave() -> void:
	if state != "playing": return
	var boss_id: String = encounters.waves[mini(wave - 1,encounters.waves.size() - 1)].boss
	if boss_id != "" and not boss_defeated:
		_ensure_boss()
		return
	vfx.clear()
	telegraphs.show_markers([])
	for p in pickups:
		stats.hp = minf(stats.max_hp,stats.hp+p.get("heal",0.0))
		xp += int(p.xp)
		Rules.credit(build, p.get("coins", 1) * (1.0 + stats.coin_bonus))
	pickups.clear()
	actor_anim.clear(true,true)
	for e in enemies: e.sprite.queue_free()
	enemies.clear()
	bullets.clear()
	enemy_bullets.clear()
	hazards.clear()
	pending_blasts.clear()
	effect_visuals.clear()
	effects.reset(build.items)
	if wave >= int(config.waves.count):
		_finish(true)
		return
	wave += 1
	wave_time = 0
	boss_spawned = false
	boss_defeated = false
	enemy_bullets.clear()
	stats.hp = minf(stats.max_hp, stats.hp + stats.wave_heal)
	Rules.credit(build, 15 + wave * 3)
	shop_pending = true
	upgrade_pending += 1
	_show_upgrades()

func _show_upgrades() -> void:
	effects.invalidate()
	state = "upgrade"
	choice_generation += 1
	choices = Rules.choose_upgrades(config.upgrades, loot_rng)
	ui.show_upgrade(choices,choice_generation)
	if automation: call_deferred("_take_upgrade", 0, choice_generation)


func _take_upgrade(index: int, generation: int) -> void:
	if generation != choice_generation or state != "upgrade" or index < 0 or index >= choices.size(): return
	var id: String = choices[index].id
	build.levels[id] = build.levels.get(id, 0) + 1
	_recompute()
	if id == "health": stats.hp = minf(stats.max_hp, stats.hp + 30)
	choices.clear()
	upgrade_pending -= 1
	if upgrade_pending > 0: _show_upgrades()
	elif shop_pending:
		_open_shop()
	else:
		state = "playing"
		_hide_modal()

func _finish(won: bool) -> void:
	weapon_rig.clear()
	_clear_transients()
	state = "won" if won else "dead"
	stats.hp = maxf(0,stats.hp)
	if won:
		_show_result(true)
	else:
		actor_anim.die(0)
		result_pending=true
		result_wait=float(actor_anim.config.durations.death)*10.0/9.0
		ui.hide_modal()

func _show_result(won:bool) -> void:
	var view:=_view()
	view.won=won
	ui.show_result(view)


func _update_hud() -> void:
	if not stats.is_empty(): ui.update_hud(_view())
	if ui.has_method("update_bosses"):
		var bars: Array = []
		for enemy in enemies:
			if enemy.boss and enemy.hp > 0 and not state in ["title","codex","won","dead"]: bars.append({"name":enemy.name,"hp":enemy.hp,"max_hp":enemy.max_hp,"phase":enemy.phase,"hint":enemy.ai_state + ": " + enemy.attack})
		ui.update_bosses(bars)


func _draw() -> void:
	if ground == null: return
	var tile: int = config.arena.tile_size
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var index: int = map_data[y * grid_size.x + x]
			var rect := Rect2(x * tile, y * tile, minf(tile, config.arena.width - x * tile), minf(tile, config.arena.height - y * tile))
			draw_texture_rect_region(ground, rect, Art.region(ground, index), Color(0.65, 0.75, 0.72))
			# Deliberate modular floor joints disguise non-identical generated edges.
			draw_rect(rect, Color(0.03, 0.08, 0.09, 0.28), false, 1.0)
	draw_rect(Rect2(0, 0, config.arena.width, config.arena.height), Color("a0b77c"), false, 4)
	for blast in pending_blasts:
		draw_circle(blast.pos,blast.radius,Color(.65,.8,1,.8),false,2)
	for hazard in hazards:
		draw_circle(hazard.pos,hazard.radius,Color(.95,.5,.12,.22) if hazard.kind in ["trail","scorch"] else Color(.9,.85,.3,.3))
		if hazard.kind == "mine": draw_rect(Rect2(hazard.pos-Vector2(6,6),Vector2(12,12)),Color("f3d66d"))
	for visual in effect_visuals:
		if visual.kind == "chain": draw_line(visual.pos,visual.end,Color("79e8ff"),3)
		else: draw_circle(visual.pos,visual.radius,Color("b0e7cf"),false,3)
	if effects.shield > 0 and not build.is_empty(): draw_circle(player_pos,25,Color("a7e5ff"),false,2)
	for projectile in enemy_bullets:
		draw_circle(projectile.pos,6,Color("f6827c"))
	for p in pickups:
		if p.get("source","") == "medical":
			draw_rect(Rect2(p.pos-Vector2(5,2),Vector2(10,4)),Color("ff8ca1"))
			draw_rect(Rect2(p.pos-Vector2(2,5),Vector2(4,10)),Color("ff8ca1"))
		elif p.get("source","") == "energy":
			draw_circle(p.pos,7,Color("f3d66d"),false,2)
			draw_rect(Rect2(p.pos-Vector2(2,2),Vector2(4,4)),Color("f3d66d"))
		else: draw_rect(Rect2(p.pos - Vector2(3, 3), Vector2(6, 6)), Color("86e6c1"))
	for b in bullets:
		if b.get("weapon","") == "return_disc":
			draw_circle(b.pos,8,Color("98eaf6"),false,2)
			draw_line(b.pos-Vector2(7,0).rotated(elapsed*16),b.pos+Vector2(7,0).rotated(elapsed*16),Color("e0faff"),2)
			continue
		draw_rect(Rect2(b.pos - Vector2(3, 2), Vector2(6, 4)), Color("ffe1a3"))
	for f in flashes:
		draw_circle(f.pos, f.get("radius", 8), Color("f4d692"), false, 2)
	if state == "playing" and stats.dash_time > 0:
		draw_circle(player_pos, 24, Color("b6f2df"), false, 2)

func _recompute() -> void:
	if weapon_rig.slots.map(func(slot):return slot.id)!=build.weapons:
		weapon_rig.sync_loadout(build.weapons)
		bullets.clear()
		pending_blasts.clear()
		vfx.clear()
	var hp: float = stats.get("hp", config.player.hp)
	var dash: float = stats.get("dash_time", 0.0)
	var cooldown: float = stats.get("dash_cooldown", 0.0)
	stats = Rules.derive(config.player, build, catalog)
	stats.hp = minf(hp, stats.max_hp)
	stats.dash_time = dash
	stats.dash_cooldown = cooldown
	while weapon_clocks.size() < build.weapons.size(): weapon_clocks.append(0.0)
	weapon_clocks.resize(build.weapons.size())
	effects.sync(build.items)
	if not build.items.has("medic_seed"): pickups = pickups.filter(func(p): return p.get("source","") != "medical")
	hazards = hazards.filter(func(h): return build.items.has("dash_resin" if h.kind == "trail" else ("blast_fuse" if h.kind == "scorch" else "scrap_mine")))
	if not effects.pair("dash_resin","pulse_boots"):
		for enemy in enemies: enemy.slow_until = 0.0
		for hazard in hazards: hazard.slow = false

func _roll_offers() -> void:
	shop_offers = Rules.draw_shop(build,catalog,shop_rng,4)
	shop_generation += 1

func _open_shop() -> void:
	state = "shop"
	shop_pending = false
	shop_message = "Buy, sell or replace. Replacement discards old weapon without refund."
	_roll_offers()
	_render_shop()
	if automation: call_deferred("_leave_shop", shop_generation)

func _render_shop() -> void:
	ui.show_shop(_view())


func _buy(index: int, generation: int, replace_slot: int = -1) -> bool:
	if state != "shop" or generation != shop_generation or index < 0 or index >= shop_offers.size(): return false
	if shop_offers[index].sold: return false
	var error := Rules.transaction(build, catalog, shop_offers[index].id, replace_slot)
	if error != "":
		shop_message = error
		_render_shop()
		return false
	if replace_slot>=0 and Rules.catalog_entry(catalog,shop_offers[index].id).kind=="weapon":
		weapon_rig.clear()
		bullets.clear()
		pending_blasts.clear()
		vfx.clear()
	shop_offers[index].sold = true
	shop_generation += 1
	_recompute()
	shop_message = "Purchased."
	_render_shop()
	return true

func _refresh_shop(generation: int) -> bool:
	if state != "shop" or generation != shop_generation or build.coins < catalog.refresh_price: return false
	build.coins -= int(catalog.refresh_price)
	build.revision += 1
	_roll_offers()
	shop_message = "New stock."
	_render_shop()
	return true

func _sell_weapon(slot: int, generation: int) -> bool:
	if state != "shop" or generation != shop_generation or slot < 0 or slot >= build.weapons.size(): return false
	if build.weapons.size() <= 1:
		shop_message = "Keep at least one weapon."
		_render_shop()
		return false
	var entry := Rules.catalog_entry(catalog, build.weapons[slot])
	build.coins += floori(entry.price * stats.resale)
	build.weapons.remove_at(slot)
	weapon_clocks.remove_at(slot)
	build.revision += 1
	shop_generation += 1
	_recompute()
	_render_shop()
	return true

func _sell_item(id: String, generation: int) -> bool:
	if state != "shop" or generation != shop_generation or build.items.get(id, 0) <= 0: return false
	var entry := Rules.catalog_entry(catalog, id)
	build.coins += floori(entry.price * stats.resale)
	build.items[id] -= 1
	if build.items[id] == 0: build.items.erase(id)
	build.revision += 1
	shop_generation += 1
	_recompute()
	_render_shop()
	return true

func _leave_shop(generation: int) -> void:
	if state != "shop" or generation != shop_generation: return
	shop_generation += 1
	state = "playing"
	_hide_modal()

func _view() -> Dictionary:
	if build.is_empty(): return {"seed":run_seed,"settings":settings.duplicate(true)}
	var view := {"coins":build.coins,"wave":wave,"level":level,"hp":stats.hp,"max_hp":stats.max_hp,"xp":xp,"xp_max":Rules.xp_threshold(level),"time":elapsed,"kills":kills,"seed":run_seed,"stats":stats,"weapons":[],"items":[],"synergies":stats.synergies,"generation":shop_generation,"refresh_price":catalog.refresh_price,"weapon_slots":catalog.weapon_slots,"item_slots":catalog.item_slots,"message":shop_message,"offers":[],"rewards":rewards,"synergy_status":[],"mechanics":{"shield":effects.shield,"chain_charges":effects.chain_charges,"hazards":hazards.size(),"echo_hits":effects.echo_hits,"phase_charge":effects.phase_charge,"medic_damage":effects.medic_damage,"cooldowns":{}}}
	view.actor_state=actor_anim.state_of(0)
	view.dash_cooldown=stats.get("dash_cooldown",0.0)
	view.settings=settings.duplicate(true)
	var affinity := Rules.shop_affinity(build,catalog)
	var missing_names: Array = []
	for id in affinity.missing_ids: missing_names.append(Rules.catalog_entry(catalog,id).name)
	view.shop_bias = {"preferred_tags":affinity.tags.keys(),"missing_partners":missing_names,"sources":affinity.sources,"summary":"Preference, not a guarantee. Positive exploration remains; selling affects the next refresh."}
	for pair_data in catalog.get("mechanism_synergies",[]):
		var required: Array = []
		var missing: Array = []
		for id in pair_data.requires:
			var name: String = Rules.catalog_entry(catalog,id).name
			required.append(name)
			if not Rules.owned_ids(build).has(id): missing.append(name)
		view.synergy_status.append({"name":pair_data.name,"active":missing.is_empty(),"requires":required,"missing":missing,"description":pair_data.description})
	for id in effects.cooldowns: view.mechanics.cooldowns[id] = maxf(0,effects.cooldowns[id] - elapsed)
	for i in range(build.weapons.size()):
		var entry := Rules.catalog_entry(catalog,build.weapons[i]).duplicate(true)
		entry.slot = i
		entry.sell_price = floori(entry.price * stats.resale)
		view.weapons.append(entry)
	for id in build.items:
		var entry := Rules.catalog_entry(catalog,id).duplicate(true)
		entry.count = build.items[id]
		entry.sell_price = floori(entry.price * stats.resale)
		view.items.append(entry)
	for i in range(shop_offers.size()):
		var offer: Dictionary = shop_offers[i]
		var entry := Rules.catalog_entry(catalog,offer.id).duplicate(true)
		entry.index = i
		entry.sold = offer.sold
		entry.weight_multiplier = offer.get("weight_multiplier",1.0)
		entry.bias_reasons = offer.get("bias_reasons",[])
		entry.can_buy = not offer.sold and build.coins >= entry.price
		if entry.kind == "item":
			entry.can_buy = entry.can_buy and build.items.get(entry.id,0) < entry.max_stack and (build.items.has(entry.id) or build.items.size() < catalog.item_slots)
		view.offers.append(entry)
	return view

func _on_intent(action: String, payload: Dictionary) -> void:
	match action:
		"settings":
			if state in ["title","paused"]:
				settings_return=state
				state="settings"
				ui.show_settings(_view())
		"set_setting":
			if state=="settings" and payload.get("key","")=="reduced_flashes" and payload.get("value") is bool:
				settings.reduced_flashes=payload.value
				vfx.reduced_flashes=payload.value
				actor_anim.reduced_flashes=payload.value
				vfx.refresh_style()
				actor_anim.refresh_style()
				ui.show_settings(_view())
		"close_settings":
			if state=="settings":
				if settings_return=="title":_title()
				else:
					state="paused"
					_present_pause()
		"codex":
			if state in ["title","paused"]:
				codex_return = state
				state = "codex"
				ui.show_codex(encounters.enemies)
		"close_codex":
			if state == "codex":
				if codex_return == "title": _title()
				else:
					state = "paused"
					_present_pause()
		"start":
			if state == "title": _start_run(int(payload.get("seed",run_seed)))
		"pause":
			if state == "playing":
				state = "paused"
				_present_pause()
		"resume":
			if state == "paused": _resume()
		"title": _title()
		"retry":
			if state in ["won","dead"]: _start_run(run_seed)
		"new_seed":
			if state in ["won","dead"]: _start_run(run_seed + 1)
		"buy": _buy(int(payload.get("index",-1)),int(payload.get("generation",-1)),int(payload.get("replace_slot",-1)))
		"sell_weapon": _sell_weapon(int(payload.get("slot",-1)),int(payload.get("generation",-1)))
		"sell_item": _sell_item(str(payload.get("id","")),int(payload.get("generation",-1)))
		"refresh": _refresh_shop(int(payload.get("generation",-1)))
		"continue": _leave_shop(int(payload.get("generation",-1)))
		"upgrade": _take_upgrade(int(payload.get("index",-1)),int(payload.get("generation",-1)))
		"inventory":
			if state in ["playing","paused","shop"]:
				inventory_return = state
				state = "inventory"
				_present_inventory()
		"close_inventory":
			if state == "inventory":
				state = inventory_return
				if state == "shop": _render_shop()
				elif state == "paused": _present_pause()
				else: _hide_modal()

func _present_inventory() -> void:
	effects.invalidate()
	ui.show_inventory(_view())


func _present_pause() -> void:
	effects.invalidate()
	ui.show_pause(_view())


func _hide_modal() -> void:
	ui.hide_modal()


func _clear_transients() -> void:
	visual_cooldowns.clear()
	vfx.clear()
	telegraphs.show_markers([])
	effects.invalidate()
	effects.chain_charges = 0
	effects.echo_hits = 0
	effects.phase_charge = 0
	effects.medic_damage = 0
	pending_blasts.clear()
	hazards.clear()
	effect_visuals.clear()
	for enemy in enemies: enemy.slow_until = 0.0

func _effect_event(kind: String, data: Dictionary) -> bool:
	if state != "playing": return false
	if kind == "hit": _vfx("hit_spark",data.pos)
	elif kind == "dash":
		actor_anim.trigger(0,"dash",float(stats.dash_time) if stats.dash_time>0 else .16)
		_vfx("dash_trail",data.pos,{"angle":data.get("angle",0.0)})
	effect_sequence += 1
	var event := data.duplicate(true)
	event.kind = kind
	event.epoch = effects.epoch
	event.sequence = effect_sequence
	var context := {"time":elapsed,"enemies":enemies,"damage":event.get("damage",stats.damage),"hp":stats.hp,"max_hp":stats.max_hp,"pos":player_pos}
	var commands: Array = effects.process(event,context)
	var blocked := false
	for command in commands:
		match command.kind:
			"block":
				_vfx("shield_impact",player_pos,{"source_item":"mirror_shell"})
				blocked = true
				effect_visuals.append({"kind":"block","pos":player_pos,"radius":30,"life":.3})
			"heal":
				stats.hp = minf(stats.max_hp,stats.hp + command.amount)
				_mechanism_vfx(command.get("source_item","healing"),"shield_impact",player_pos,{"size":Vector2(32,32),"tint":Color("83e8a5")})
			"medical":
				_mechanism_vfx("medic_seed","hit_spark",command.pos,{"tint":Color("f69eb5")})
				var medical: Array = pickups.filter(func(p): return p.get("source","") == "medical")
				if medical.size() >= 8: pickups.erase(medical[0])
				pickups.append({"pos":command.pos,"xp":0,"coins":0,"heal":8.0,"source":"medical"})
			"orb":
				pickups.append({"pos":command.pos,"xp":2,"coins":1,"source":"energy"})
				_mechanism_vfx("kill_cell","hit_spark",command.pos,{"tint":Color("f8d569")})
			"chain":
				for id in command.targets:
					for enemy in enemies:
						if enemy.id == id and enemy.hp > 0:
							enemy.hp -= command.damage
							enemy.last_source = "chain"
							_vfx("chain_arc",command.pos,{"end":enemy.pos,"source_item":"arc_relay"})
							_vfx("hit_spark",enemy.pos)
							effect_visuals.append({"kind":"chain","pos":command.pos,"end":enemy.pos,"life":.2})
			"echo":
				for enemy in enemies:
					if enemy.id == command.target and enemy.hp > 0:
						enemy.hp -= 12
						enemy.last_source = "echo"
						_mechanism_vfx("echo_chamber","hit_spark",enemy.pos,{"tint":Color("c5a4f6")})
						effect_visuals.append({"kind":"echo","pos":enemy.pos,"radius":18,"life":.25})
			"phase":
				for enemy in enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 95:
						enemy.hp -= 12
						enemy.last_source = "phase"
				_mechanism_vfx("phase_capacitor","explosion",command.pos,{"radius":95,"tint":Color("94c5ff")})
				effect_visuals.append({"kind":"phase","pos":command.pos,"radius":95,"life":.25})
			"pull":
				_mechanism_vfx("gravity_anchor","shield_impact",command.pos,{"radius":100,"tint":Color("cb92e8")})
				for enemy in enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 150:
						enemy.pos = enemy.pos.move_toward(command.pos,60)
				effect_visuals.append({"kind":"pull","pos":command.pos,"radius":150,"life":.3})
			"scorch":
				_mechanism_vfx("blast_fuse","hit_spark",command.pos,{"tint":Color("f7a95c")})
				var same: Array = hazards.filter(func(h): return h.kind == "scorch")
				if same.size() >= 3: hazards.erase(same[0])
				hazards.append({"kind":"scorch","pos":command.pos,"life":1.4,"age":0.0,"tick":0.0,"radius":60.0,"slow":false})
			"thorns":
				_mechanism_vfx("thorn_crown","shield_impact",command.pos,{"radius":130,"tint":Color("ff947d")})
				for enemy in enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 130:
						enemy.hp -= command.damage
						enemy.last_source = "thorns"
				effect_visuals.append({"kind":"thorns","pos":command.pos,"radius":130,"life":.25})
			"push":
				_mechanism_vfx("pulse_boots","dash_trail",command.pos,{"tint":Color("7fe9cb")})
				for enemy in enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= command.radius:
						var away: Vector2 = (enemy.pos-command.pos).normalized()
						if away == Vector2.ZERO: away = Vector2.RIGHT
						enemy.pos += away * command.distance
				effect_visuals.append({"kind":"push","pos":command.pos,"radius":150,"life":.25})
			"mine", "trail":
				_mechanism_vfx("scrap_mine" if command.kind=="mine" else "dash_resin","hit_spark",command.pos,{"tint":Color("f3cd62")})
				var maximum := 4 if command.kind == "mine" else 3
				var same: Array = hazards.filter(func(h): return h.kind == command.kind)
				if same.size() >= maximum: hazards.erase(same[0])
				hazards.append({"kind":command.kind,"pos":command.pos,"life":5.0 if command.kind == "mine" else 2.4,"age":0.0,"tick":0.0,"radius":70.0,"slow":command.get("slow",false)})
	return blocked

func _update_hazards(dt: float) -> void:
	for i in range(effect_visuals.size()-1,-1,-1):
		effect_visuals[i].life -= dt
		if effect_visuals[i].life <= 0: effect_visuals.remove_at(i)
	for i in range(hazards.size()-1,-1,-1):
		var hazard: Dictionary = hazards[i]
		hazard.age += dt
		hazard.life -= dt
		hazard.tick -= dt
		if hazard.life <= 0:
			hazards.remove_at(i)
			continue
		var targets: Array = enemies.filter(func(e): return e.hp > 0 and e.pos.distance_to(hazard.pos) <= hazard.radius)
		if hazard.kind == "mine":
			if hazard.age >= .3 and not targets.is_empty():
				for enemy in targets:
					enemy.hp -= 24
					enemy.last_source = "mine"
				_vfx("explosion",hazard.pos,{"radius":70,"source_item":"scrap_mine"})
				_effect_event("mine_detonate",{"pos":hazard.pos,"source":"mine","depth":1})
				effect_visuals.append({"kind":"mine","pos":hazard.pos,"radius":70,"life":.25})
				hazards.remove_at(i)
		elif hazard.tick <= 0:
			hazard.tick = .35
			for enemy in targets:
				enemy.hp -= 6 if hazard.kind == "scorch" else 8
				enemy.last_source = "scorch" if hazard.kind == "scorch" else "trail"
				if hazard.slow: enemy.slow_until = elapsed + .6

func _update_mortars(dt: float) -> void:
	for i in range(pending_blasts.size()-1,-1,-1):
		var blast: Dictionary = pending_blasts[i]
		blast.delay -= dt
		if blast.delay > 0: continue
		for enemy in enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(blast.pos) <= blast.radius:
				enemy.hp -= blast.damage
				enemy.last_source = "primary"
				_effect_event("hit",{"target":enemy.id,"pos":enemy.pos,"damage":blast.damage,"weapon":blast.weapon})
		_vfx("explosion",blast.pos,{"radius":blast.radius})
		_effect_event("mortar",{"pos":blast.pos})
		effect_visuals.append({"kind":"mortar","pos":blast.pos,"radius":blast.radius,"life":.25})
		pending_blasts.remove_at(i)

func _hit_segment(b:Dictionary,start:Vector2,end:Vector2)->void:
	var candidates:Array=[]
	for enemy in enemies:
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
		_effect_event("hit",{"target":enemy.id,"pos":enemy.pos,"damage":b.damage,"weapon":b.get("weapon",""),"returning":b.get("returning",false)})
		b.hit.append(enemy.id)
		flashes.append({"pos":enemy.pos,"life":.14})
		if b.hit.size()>b.get("pierce",stats.pierce):b.life=-1;break

func _advance_bullet(b: Dictionary,dt: float) -> void:
	if b.life<=0:return
	if b.has("launch_start"):
		_hit_segment(b,b.launch_start,b.pos)
		b.erase("launch_start")
		if b.life<=0:return
	var previous: Vector2 = b.pos
	var step := minf(dt,maxf(0,b.life))
	b.pos += b.velocity * step
	b.life -= step
	_hit_segment(b,previous,b.pos)

func _advance_disc(b: Dictionary,dt: float) -> void:
	var remaining := minf(dt,maxf(0,b.life))
	if not b.returning:
		if b.has("launch_start"):_advance_bullet(b,0)
		if b.life<=0:return
		var outbound := minf(remaining,maxf(0,b.outbound_left))
		if outbound > 0: _advance_bullet(b,outbound)
		b.outbound_left -= outbound
		remaining -= outbound
		if b.outbound_left <= .000001:
			b.returning = true
			b.hit.clear()
	if b.returning and remaining > 0 and b.life > 0:
		var distance: float = b.pos.distance_to(player_pos)
		if distance < 14:
			b.life = -1
			return
		b.velocity = (player_pos-b.pos).normalized() * stats.bullet_speed
		_advance_bullet(b,minf(remaining,distance/stats.bullet_speed))
		if b.pos.distance_to(player_pos) < 14: b.life = -1

func _vfx(id: String,pos: Vector2,options: Dictionary = {}) -> void:
	if is_instance_valid(vfx): vfx.play(id,pos,options)

func _sync_telegraphs() -> void:
	var markers: Array = []
	for blast in pending_blasts:
		markers.append({"kind":"circle","pos":blast.pos,"radius":blast.radius,"color":Color("9ddcf6")})
	for enemy in enemies:
		if enemy.hp <= 0 or enemy.ai_state != "warning": continue
		var color := Color(1,.35,.18,.9)
		if enemy.attack == "charge":
			markers.append({"kind":"line","pos":enemy.pos,"end":enemy.pos+enemy.aim*enemy.charge_speed*enemy.charge_duration,"width":2*(16*enemy.scale+9),"color":color})
		else:
			markers.append({"kind":"circle","pos":enemy.target if enemy.attack=="blast" else enemy.pos,"radius":105 if enemy.attack=="blast" else 34*enemy.scale,"color":color})
	for visual in effect_visuals:
		if visual.kind in ["mine","mortar","phase"]:
			markers.append({"kind":"circle","pos":visual.pos,"radius":visual.radius,"color":Color("b0e7cf")})
	for flash in flashes:
		if flash.get("radius",0)>=70:
			markers.append({"kind":"circle","pos":flash.pos,"radius":flash.radius,"color":Color("f4d692")})
	telegraphs.show_markers(markers)

func _mechanism_vfx(source:String,id:String,pos:Vector2,options:Dictionary={}) -> void:
	if elapsed<float(visual_cooldowns.get(source,-1.0)):return
	visual_cooldowns[source]=elapsed+.08
	var decorated:=options.duplicate(true)
	decorated.source_item=source
	_vfx(id,pos,decorated)

func _launch_pose(id:String,slot:int,target:Vector2)->Dictionary:
	hero.position=player_pos.round()
	weapon_rig.sync_loadout(build.weapons)
	var hand:Vector2=actor_anim.socket_world(0,"grip")
	var body:Vector2=actor_anim.socket_world(0,"body")
	var offset:Vector2=WeaponRig.OFFSETS[clampi(slot,0,3)]
	if hero.flip_h:offset.x=-offset.x
	var mount:Vector2=hand if slot==0 else body+offset
	var fallback:Vector2=weapon_rig.slots[slot].aim if slot>=0 and slot<weapon_rig.slots.size() else Vector2.RIGHT
	return WeaponRig.muzzle_pose(mount,target,weapon_rig.geometry.get(id,{}),fallback)

func _sync_weapon_rig()->void:
	if not is_instance_valid(weapon_rig):return
	if state in ["title","dead","won"] or build.is_empty():
		if not weapon_rig.slots.is_empty():weapon_rig.clear()
		return
	weapon_rig.sync_loadout(build.weapons)
	var target:Vector2=player_pos+Vector2(-100 if hero.flip_h else 100,0)
	var living:Array=enemies.filter(func(e):return e.hp>0)
	if not living.is_empty():
		var nearest:Dictionary=living[0]
		for e in living:
			if e.pos.distance_squared_to(player_pos)<nearest.pos.distance_squared_to(player_pos):nearest=e
		target=nearest.pos
	weapon_rig.update_poses(actor_anim.socket_world(0,"grip"),actor_anim.socket_world(0,"body"),target,hero.flip_h,bullets,pending_blasts,true)
