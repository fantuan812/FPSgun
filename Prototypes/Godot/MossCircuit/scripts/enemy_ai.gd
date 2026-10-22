extends RefCounted
## Data-driven timer/state transitions. Events consumed by the combat controller.
static func tick(enemy: Dictionary, player: Vector2, dt: float, time: float) -> Array:
	var events: Array = []
	if enemy.hp <= 0: return events
	enemy.cooldown_left -= dt
	enemy.phase = 2 if enemy.boss and enemy.hp <= enemy.max_hp * enemy.phase_threshold else 1
	var speed: float = enemy.speed * (enemy.phase_speed if enemy.phase == 2 else 1.0)
	var toward: Vector2 = (player - enemy.pos).normalized()
	var distance: float = enemy.pos.distance_to(player)
	if enemy.ai_state == "warning":
		enemy.warning_left -= dt
		if enemy.warning_left <= 0:
			enemy.ai_state = "recover"
			enemy.recover_left = .7
			match enemy.attack:
				"charge":
					enemy.ai_state = "charging"
					enemy.charge_left = enemy.charge_duration
				"shot": events.append({"kind":"shot","direction":enemy.aim,"count":3 if enemy.phase == 2 else 1})
				"ring": events.append({"kind":"ring","count":12 if enemy.phase == 2 else 8})
				"blast": events.append({"kind":"blast","pos":enemy.target,"radius":105.0,"damage":enemy.damage})
				"summon": events.append({"kind":"summon","count":2 if enemy.phase == 2 else 1})
		return events
	if enemy.ai_state == "charging":
		enemy.pos += enemy.aim * enemy.charge_speed * minf(dt,maxf(0,enemy.charge_left))
		enemy.charge_left -= dt
		if enemy.charge_left <= 0:
			enemy.ai_state = "recover"
			enemy.recover_left = .8
		return events
	if enemy.ai_state == "recover":
		enemy.recover_left -= dt
		if enemy.recover_left <= 0: enemy.ai_state = "move"
		return events
	match enemy.behavior:
		"chase": enemy.pos += toward * speed * dt
		"charge", "warden": enemy.pos += toward * speed * dt
		"ranged", "core":
			if distance < enemy.desired_distance - 30: enemy.pos -= toward * speed * dt
			elif distance > enemy.desired_distance + 30: enemy.pos += toward * speed * dt
		"flank": enemy.pos += (toward * .45 + toward.orthogonal() * sin(time * 1.1 + enemy.id) * .9).normalized() * speed * dt
		"summon":
			if distance < 170: enemy.pos -= toward * speed * dt
	if enemy.cooldown_left <= 0:
		var attack := ""
		match enemy.behavior:
			"charge": attack = "charge"
			"ranged": attack = "shot"
			"summon": attack = "summon"
			"warden": attack = "blast" if enemy.attack_index % 2 == 1 else "charge"
			"core": attack = "summon" if enemy.phase == 2 and enemy.attack_index % 3 == 2 else "ring"
		if attack != "":
			enemy.ai_state = "warning"
			enemy.attack = attack
			enemy.attack_index += 1
			enemy.warning_left = enemy.warning
			enemy.aim = toward
			enemy.target = player
			enemy.cooldown_left = enemy.cooldown / (1.2 if enemy.phase == 2 else 1.0)
	return events

static func validate(config: Dictionary) -> Array:
	if not config.get("enemies") is Array or not config.get("waves") is Array: return ["Enemy/wave arrays required"]
	var errors: Array = []
	var kinds := {}
	for entry in config.enemies:
		if not entry is Dictionary: errors.append("Enemy must be object"); continue
		var valid := true
		for key in ["id","name","behavior","boss","hp","speed","damage","xp","scale","color","cooldown","warning","projectile_speed","charge_speed","charge_duration","desired_distance","summon_limit","phase_threshold","phase_speed"]:
			if not entry.has(key): valid = false
		if not valid: errors.append("Missing enemy field"); continue
		if not entry.id is String or not entry.name is String or not entry.boss is bool: errors.append("Invalid enemy identity"); continue
		if kinds.has(entry.id): errors.append("Duplicate enemy ID")
		kinds[entry.id] = entry.boss
		if not entry.behavior in ["chase","charge","ranged","flank","summon","warden","core"]: errors.append("Unknown behavior")
		for key in ["hp","speed","damage","xp","scale","cooldown","warning","projectile_speed","charge_speed","charge_duration","desired_distance","summon_limit","phase_threshold","phase_speed"]:
			if not (entry[key] is int or entry[key] is float): errors.append("Nonnumeric enemy field"); continue
			if not is_finite(float(entry[key])) or entry[key] <= 0: errors.append("Invalid enemy number")
		if (entry.phase_threshold is int or entry.phase_threshold is float) and entry.phase_threshold >= 1: errors.append("Invalid phase threshold")
	for wave in config.waves:
		if not wave is Dictionary or not wave.get("pool") is Array or not wave.get("boss") is String: errors.append("Invalid wave"); continue
		if wave.pool.is_empty(): errors.append("Empty wave pool")
		for id in wave.pool:
			if not kinds.has(id) or kinds.get(id,false): errors.append("Invalid ordinary spawn")
		if wave.boss != "" and not kinds.get(wave.boss,false): errors.append("Invalid wave boss")
	return errors
