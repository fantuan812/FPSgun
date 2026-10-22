extends RefCounted
## Pure event-to-command engine. Never applies commands recursively.
var epoch := 0
var last_sequence := -1
var active: Dictionary = {}
var cooldowns: Dictionary = {}
var shield := 0
var shield_spent := false
var echo_hits := 0
var phase_charge := 0
var medic_damage := 0.0
var chain_charges := 0

func reset(items: Dictionary, recharge: bool = true) -> void:
	epoch += 1
	last_sequence = -1
	cooldowns.clear()
	chain_charges = 0
	echo_hits = 0
	phase_charge = 0
	medic_damage = 0.0
	if recharge: shield_spent = false
	sync(items)

func invalidate() -> void:
	# Context boundary invalidates queued events only; physical effects and charges freeze.
	epoch += 1
	last_sequence = -1

func sync(items: Dictionary) -> void:
	active = items.duplicate(true)
	if not active.has("echo_chamber"): echo_hits = 0
	if not active.has("phase_capacitor"): phase_charge = 0
	if not active.has("medic_seed"): medic_damage = 0.0
	shield = 1 if active.has("mirror_shell") and not shield_spent else 0
	if not pair("arc_relay","kill_cell"): chain_charges = 0
	for id in cooldowns.keys():
		if not active.has(id): cooldowns.erase(id)

func pair(a: String,b: String) -> bool:
	return active.has(a) and active.has(b)

func ready(id: String, time: float, interval: float) -> bool:
	if not active.has(id) or time < float(cooldowns.get(id,0)): return false
	cooldowns[id] = time + interval
	return true

func process(event: Dictionary, context: Dictionary) -> Array:
	var result: Array = []
	if event.get("epoch",-1) != epoch or int(event.get("sequence",-1)) <= last_sequence: return result
	last_sequence = int(event.sequence)
	if int(event.get("depth",0)) > 1: return result
	var kind: String = event.kind
	var source: String = event.get("source","normal" if kind == "pickup" else "primary")
	var time: float = context.time
	match kind:
		"hit":
			if source != "primary" or event.get("depth",0) != 0: return result
			if active.has("echo_chamber"):
				echo_hits += 1
				if echo_hits >= 5:
					echo_hits = 0
					result.append({"kind":"echo","target":event.target})
			if phase_charge > 0 and active.has("phase_capacitor"):
				phase_charge = 0
				result.append({"kind":"phase","pos":event.pos})
			if event.get("weapon","") == "return_disc" and event.get("returning",false) and ready("return_spool",time,.6): result.append({"kind":"heal","amount":1.0,"source_item":"return_spool"})
			if ready("arc_relay",time,.6):
				var candidates: Array = context.enemies.filter(func(e): return e.hp > 0 and e.id != event.target and e.pos.distance_to(event.pos) <= 220)
				candidates.sort_custom(func(a,b):
					var da: float = a.pos.distance_squared_to(event.pos)
					var db: float = b.pos.distance_squared_to(event.pos)
					return a.id < b.id if is_equal_approx(da,db) else da < db)
				var count := 4 if chain_charges > 0 and pair("arc_relay","kill_cell") else 2
				var ids: Array = []
				for e in candidates:
					if not ids.has(e.id): ids.append(e.id)
					if ids.size() >= count: break
				if not ids.is_empty():
					if chain_charges > 0: chain_charges -= 1
					result.append({"kind":"chain","targets":ids,"pos":event.pos,"damage":context.damage * .4,"source":"chain","depth":1})
			if context.hp < context.max_hp * .4 and ready("blood_valve",time,1): result.append({"kind":"heal","amount":3.0,"source_item":"blood_valve"})
		"kill":
			if source == "primary" and event.get("depth",0) == 0 and active.has("kill_cell"):
				result.append({"kind":"orb","pos":event.pos})
			if source == "mine" and pair("blood_valve","scrap_mine"): result.append({"kind":"heal","amount":5.0,"source_item":"blood_mines"})
		"pickup":
			if source == "energy":
				if pair("arc_relay","kill_cell"): chain_charges = mini(3,chain_charges + 1)
			elif source == "normal" and ready("scrap_mine",time,1): result.append({"kind":"mine","pos":event.pos,"source":"mine"})
		"mortar":
			if active.has("blast_fuse"): result.append({"kind":"scorch","pos":event.pos})
		"mine_detonate":
			if source == "mine" and active.has("gravity_anchor"): result.append({"kind":"pull","pos":event.pos})
		"dash":
			if active.has("phase_capacitor"): phase_charge = 1
			if active.has("dash_resin"): result.append({"kind":"trail","pos":event.pos,"slow":pair("dash_resin","pulse_boots")})
			if active.has("pulse_boots"): result.append({"kind":"push","pos":event.pos,"radius":150.0,"distance":90.0})
		"before_hurt":
			if shield > 0:
				shield = 0
				shield_spent = true
				result.append({"kind":"block"})
				if pair("mirror_shell","thorn_crown") and ready("thorn_crown",time,1): result.append({"kind":"thorns","pos":context.pos,"damage":18.0})
		"hurt":
			if active.has("medic_seed"):
				medic_damage += maxf(0,event.get("amount",0.0))
				while medic_damage >= 30:
					medic_damage -= 30
					result.append({"kind":"medical","pos":context.pos + Vector2(35,0)})
			if ready("thorn_crown",time,1): result.append({"kind":"thorns","pos":context.pos,"damage":18.0})
	return result
