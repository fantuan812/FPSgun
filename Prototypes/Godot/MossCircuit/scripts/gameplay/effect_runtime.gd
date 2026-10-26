extends RefCounted
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
const RunSession=preload("res://scripts/gameplay/run_session.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
var world:CombatState
var session:RunSession
var engine:RefCounted
var actor:RefCounted
var play_vfx:Callable
var mechanism_vfx:Callable
var sequence:=0
func _init(w:CombatState,r:RunSession,e:RefCounted,a:RefCounted,v:Callable,m:Callable)->void:
	world=w;session=r;engine=e;actor=a;play_vfx=v;mechanism_vfx=m

func emit_event(kind: String, data: Dictionary) -> bool:
	if session.state != "playing": return false
	if kind == "hit": play_vfx.call("hit_spark",data.pos)
	elif kind == "dash":
		actor.trigger(0,"dash",float(world.stats.dash_time) if world.stats.dash_time>0 else .16)
		play_vfx.call("dash_trail",data.pos,{"angle":data.get("angle",0.0)})
	sequence += 1
	var event := data.duplicate(true)
	event.kind = kind
	event.epoch = engine.epoch
	event.sequence = sequence
	var context := {"time":session.elapsed,"enemies":world.enemies,"damage":event.get("damage",world.stats.damage),"hp":world.stats.hp,"max_hp":world.stats.max_hp,"pos":world.player_pos}
	var commands: Array = engine.process(event,context)
	var blocked := false
	for command in commands:
		match command.kind:
			"fracture":
				for enemy in world.enemies:
					if enemy.id==command.target and Status.can_fracture(enemy,session.elapsed,command.weapon):
						Status.consume_chill(enemy)
						enemy.hp-=command.damage
						enemy.last_source="fracture"
						mechanism_vfx.call("fracture_coil","hit_spark",enemy.pos,{"tint":Color("9be9ef")})
						var existing:Array=world.effect_visuals.filter(func(v):return v.kind=="fracture")
						if existing.size()>=8:world.effect_visuals.erase(existing[0])
						world.effect_visuals.append({"kind":"fracture","pos":enemy.pos,"radius":18,"life":.2})
			"block":
				play_vfx.call("shield_impact",world.player_pos,{"source_item":"mirror_shell"})
				blocked = true
				world.effect_visuals.append({"kind":"block","pos":world.player_pos,"radius":30,"life":.3})
			"heal":
				world.stats.hp = minf(world.stats.max_hp,world.stats.hp + command.amount)
				mechanism_vfx.call(command.get("source_item","healing"),"shield_impact",world.player_pos,{"size":Vector2(32,32),"tint":Color("83e8a5")})
			"medical":
				mechanism_vfx.call("medic_seed","hit_spark",command.pos,{"tint":Color("f69eb5")})
				var medical: Array = world.pickups.filter(func(p): return p.get("source","") == "medical")
				if medical.size() >= 8: world.pickups.erase(medical[0])
				world.pickups.append({"pos":command.pos,"xp":0,"coins":0,"heal":8.0,"source":"medical"})
			"orb":
				world.pickups.append({"pos":command.pos,"xp":2,"coins":1,"source":"energy"})
				mechanism_vfx.call("kill_cell","hit_spark",command.pos,{"tint":Color("f8d569")})
			"chain":
				for id in command.targets:
					for enemy in world.enemies:
						if enemy.id == id and enemy.hp > 0:
							enemy.hp -= command.damage
							enemy.last_source = "chain"
							play_vfx.call("chain_arc",command.pos,{"end":enemy.pos,"source_item":"arc_relay"})
							play_vfx.call("hit_spark",enemy.pos)
							world.effect_visuals.append({"kind":"chain","pos":command.pos,"end":enemy.pos,"life":.2})
			"echo":
				for enemy in world.enemies:
					if enemy.id == command.target and enemy.hp > 0:
						enemy.hp -= 12
						enemy.last_source = "echo"
						mechanism_vfx.call("echo_chamber","hit_spark",enemy.pos,{"tint":Color("c5a4f6")})
						world.effect_visuals.append({"kind":"echo","pos":enemy.pos,"radius":18,"life":.25})
			"phase":
				for enemy in world.enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 95:
						enemy.hp -= 12
						enemy.last_source = "phase"
				mechanism_vfx.call("phase_capacitor","explosion",command.pos,{"radius":95,"tint":Color("94c5ff")})
				world.effect_visuals.append({"kind":"phase","pos":command.pos,"radius":95,"life":.25})
			"pull":
				mechanism_vfx.call("gravity_anchor","shield_impact",command.pos,{"radius":100,"tint":Color("cb92e8")})
				for enemy in world.enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 150:
						enemy.pos = enemy.pos.move_toward(command.pos,60)
				world.effect_visuals.append({"kind":"pull","pos":command.pos,"radius":150,"life":.3})
			"scorch":
				mechanism_vfx.call("blast_fuse","hit_spark",command.pos,{"tint":Color("f7a95c")})
				var same: Array = world.hazards.filter(func(h): return h.kind == "scorch")
				if same.size() >= 3: world.hazards.erase(same[0])
				world.hazards.append({"kind":"scorch","pos":command.pos,"life":1.4,"age":0.0,"tick":0.0,"radius":60.0,"slow":false})
			"thorns":
				mechanism_vfx.call("thorn_crown","shield_impact",command.pos,{"radius":130,"tint":Color("ff947d")})
				for enemy in world.enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= 130:
						enemy.hp -= command.damage
						enemy.last_source = "thorns"
				world.effect_visuals.append({"kind":"thorns","pos":command.pos,"radius":130,"life":.25})
			"push":
				mechanism_vfx.call("pulse_boots","dash_trail",command.pos,{"tint":Color("7fe9cb")})
				for enemy in world.enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(command.pos) <= command.radius:
						var away: Vector2 = (enemy.pos-command.pos).normalized()
						if away == Vector2.ZERO: away = Vector2.RIGHT
						enemy.pos += away * command.distance
				world.effect_visuals.append({"kind":"push","pos":command.pos,"radius":150,"life":.25})
			"mine", "trail":
				mechanism_vfx.call("scrap_mine" if command.kind=="mine" else "dash_resin","hit_spark",command.pos,{"tint":Color("f3cd62")})
				var maximum := 4 if command.kind == "mine" else 3
				var same: Array = world.hazards.filter(func(h): return h.kind == command.kind)
				if same.size() >= maximum: world.hazards.erase(same[0])
				world.hazards.append({"kind":command.kind,"pos":command.pos,"life":5.0 if command.kind == "mine" else 2.4,"age":0.0,"tick":0.0,"radius":70.0,"slow":command.get("slow",false)})
	return blocked

func advance_hazards(dt: float) -> void:
	for i in range(world.effect_visuals.size()-1,-1,-1):
		world.effect_visuals[i].life -= dt
		if world.effect_visuals[i].life <= 0: world.effect_visuals.remove_at(i)
	for i in range(world.hazards.size()-1,-1,-1):
		var hazard: Dictionary = world.hazards[i]
		hazard.age += dt
		hazard.life -= dt
		hazard.tick -= dt
		if hazard.life <= 0:
			world.hazards.remove_at(i)
			continue
		var targets: Array = world.enemies.filter(func(e): return e.hp > 0 and e.pos.distance_to(hazard.pos) <= hazard.radius)
		if hazard.kind == "mine":
			if hazard.age >= .3 and not targets.is_empty():
				for enemy in targets:
					enemy.hp -= 24
					enemy.last_source = "mine"
				play_vfx.call("explosion",hazard.pos,{"radius":70,"source_item":"scrap_mine"})
				emit_event("mine_detonate",{"pos":hazard.pos,"source":"mine","depth":1})
				world.effect_visuals.append({"kind":"mine","pos":hazard.pos,"radius":70,"life":.25})
				world.hazards.remove_at(i)
		elif hazard.tick <= 0:
			hazard.tick = .35
			for enemy in targets:
				enemy.hp -= 6 if hazard.kind == "scorch" else 8
				enemy.last_source = "scorch" if hazard.kind == "scorch" else "trail"
				if hazard.slow: enemy.slow_until = session.elapsed + .6

func advance_mortars(dt: float) -> void:
	for i in range(world.pending_blasts.size()-1,-1,-1):
		var blast: Dictionary = world.pending_blasts[i]
		blast.delay -= dt
		if blast.delay > 0: continue
		for enemy in world.enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(blast.pos) <= blast.radius:
				enemy.hp -= blast.damage
				enemy.last_source = "primary"
				emit_event("hit",{"target":enemy.id,"pos":enemy.pos,"damage":blast.damage,"weapon":blast.weapon})
		play_vfx.call("explosion",blast.pos,{"radius":blast.radius})
		emit_event("mortar",{"pos":blast.pos})
		world.effect_visuals.append({"kind":"mortar","pos":blast.pos,"radius":blast.radius,"life":.25})
		world.pending_blasts.remove_at(i)
