extends RefCounted
## Pure run rules; configuration owns balance, presentation owns no damage logic.
# These are the three existing rules, not an open-ended catalog effect engine.
# One definition supplies authority, activation and the read-only progress view.
const TAG_SYNERGY_RULES := [
	{"id":"arc_grid", "name":"ARC GRID", "tag":"electric", "threshold":3, "effect":"electric_bonus", "amount":0.2,
	 "qualifier":"Applies once. Additive matching-weapon damage bonus, not a final-damage multiplier. Fixed module damage is not scaled."},
	{"id":"saw_rig", "name":"SAW RIG", "tag":"melee", "threshold":3, "effect":"melee_bonus", "amount":0.2,
	 "qualifier":"Applies once. Additive matching-weapon damage bonus, not a final-damage multiplier. Fixed module damage is not scaled."},
	{"id":"scatter_rig", "name":"SCATTER RIG", "tag":"spread", "threshold":3, "effect":"extra_pellets", "amount":1,
	 "qualifier":"Applies once to spread attacks only. Adds to Pellet Pouch; not extra projectiles for every weapon."}
]

static func xp_threshold(level: int) -> int:
	return 12 + (level - 1) * 9

static func apply_upgrade(stats: Dictionary, upgrade: Dictionary) -> void:
	match str(upgrade.id):
		"damage": stats.damage *= float(upgrade.value)
		"speed": stats.speed = minf(stats.speed * float(upgrade.value), 300.0)
		"haste": stats.fire_interval = maxf(0.09, stats.fire_interval * float(upgrade.value))
		"health":
			stats.max_hp += float(upgrade.value)
			stats.hp = minf(stats.max_hp, stats.hp + 30.0)
		"magnet": stats.pickup_radius += float(upgrade.value)
		"pierce": stats.pierce = mini(5, int(stats.pierce) + 1)

static func choose_upgrades(pool: Array, rng: RandomNumberGenerator) -> Array:
	var ids: Array = range(pool.size())
	for i in range(ids.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var old: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = old
	var result: Array = []
	for i in range(mini(3, ids.size())):
		result.append(pool[ids[i]].duplicate(true))
	return result

static func map_cells(seed_value: int, columns: int, rows: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cells: Array = []
	for y in range(rows):
		for x in range(columns):
			# All nine tiles are walkable. No random obstacle can disconnect the map.
			cells.append(rng.randi_range(0, 8) if rng.randf() < 0.38 else 8)
	return cells

static func grid_dimensions(arena: Dictionary) -> Vector2i:
	return Vector2i(ceili(float(arena.width) / float(arena.tile_size)), ceili(float(arena.height) / float(arena.tile_size)))

static func catalog_entry(catalog: Dictionary, id: String) -> Dictionary:
	for entry in catalog.weapons + catalog.items:
		if entry.id == id: return entry
	return {}

# Shared authority/readout calculations. Keep operation order identical to combat.
static func weapon_damage(weapon: Dictionary, stats: Dictionary) -> float:
	var damage: float = weapon.damage * (1.0 + stats.damage_bonus)
	if "electric" in weapon.tags: damage *= 1.0 + stats.electric_bonus
	if "melee" in weapon.tags: damage *= 1.0 + stats.melee_bonus
	return damage

static func weapon_interval(weapon: Dictionary, stats: Dictionary) -> float:
	return maxf(.09, weapon.interval / (1.0 + stats.haste))

static func weapon_reach(weapon: Dictionary, stats: Dictionary) -> float:
	return float(weapon.range) if weapon.behavior == "orbit" else weapon.range * (1.0 + stats.range_bonus)

static func weapon_projectiles(weapon: Dictionary, stats: Dictionary) -> int:
	return weapon.projectiles + (int(stats.extra_pellets) if weapon.behavior == "spread" else 0)

static func owned_tag_counts(build: Dictionary, catalog: Dictionary) -> Dictionary:
	var tags := {}
	for id in build.weapons:
		for tag in catalog_entry(catalog, id).tags: tags[tag] = tags.get(tag, 0) + 1
	for id in build.items:
		for tag in catalog_entry(catalog, id).tags: tags[tag] = tags.get(tag, 0) + int(build.items[id])
	return tags

static func tag_synergy_status(build: Dictionary, catalog: Dictionary) -> Array:
	var tags := owned_tag_counts(build, catalog)
	var result: Array = []
	for rule in TAG_SYNERGY_RULES:
		var row: Dictionary = rule.duplicate(true)
		row.count = int(tags.get(rule.tag, 0))
		row.active = row.count >= rule.threshold
		row.description = ""
		for definition in catalog.get("synergies", []):
			if definition.id == rule.id: row.description = definition.description; break
		row.matching_weapons = []
		for id in build.weapons:
			var entry := catalog_entry(catalog, id)
			if rule.tag in entry.tags: row.matching_weapons.append(entry.name)
		result.append(row)
	return result

static func _positive_number(value: Variant, allow_zero: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and (float(value) >= 0 if allow_zero else float(value) > 0)

static func validate_catalog(catalog: Dictionary) -> Array:
	var errors: Array = []
	for key in ["weapons", "items", "weapon_slots", "item_slots", "starting_coins", "refresh_price", "synergies"]:
		if not catalog.has(key): errors.append("Missing " + key)
	if not errors.is_empty(): return errors
	if not catalog.weapons is Array or not catalog.items is Array: return ["Invalid lists"]
	var tag_rules: Variant = catalog.synergies
	if not tag_rules is Array or tag_rules.size() != TAG_SYNERGY_RULES.size():
		errors.append("Expected the three fixed tag synergies")
	else:
		for i in range(TAG_SYNERGY_RULES.size()):
			var definition: Variant = tag_rules[i]
			var rule: Dictionary = TAG_SYNERGY_RULES[i]
			if not definition is Dictionary: errors.append("Invalid tag synergy"); continue
			if definition.get("id") != rule.id or definition.get("tag") != rule.tag:
				errors.append("Tag synergy ID/tag/order differs from fixed rules")
			if not _positive_number(definition.get("threshold")) or definition.get("threshold") != rule.threshold:
				errors.append("Tag synergy threshold differs from fixed rules")
			if not definition.get("description") is String or definition.get("description", "").is_empty():
				errors.append("Invalid tag synergy description")
	for key in ["weapon_slots","item_slots","starting_coins","refresh_price"]:
		if not _positive_number(catalog[key],key in ["starting_coins","refresh_price"]): errors.append("Invalid " + key)
		elif floorf(float(catalog[key])) != float(catalog[key]): errors.append("Noninteger " + key)
	var seen := {}
	var effect_keys := ["damage_bonus","haste","max_hp","wave_heal","speed_bonus","pickup_radius","coin_bonus","range_bonus","electric_bonus","melee_bonus","extra_pellets","sell_bonus"]
	for entry in catalog.weapons + catalog.items:
		if not entry is Dictionary: errors.append("Invalid entry"); continue
		var valid := true
		for key in ["id", "name", "kind", "price", "max_stack", "tags", "rarity", "description"]:
			if not entry.has(key): valid = false
		if not valid: errors.append("Incomplete entry"); continue
		for key in ["id","name","kind","rarity","description"]:
			if not entry[key] is String or entry[key].is_empty(): valid = false
		if not valid: errors.append("Invalid text"); continue
		if not entry.tags is Array or not entry.tags.all(func(t): return t is String): errors.append("Invalid tags")
		if seen.has(entry.id): errors.append("Duplicate ID")
		seen[entry.id] = true
		for key in ["price","max_stack"]:
			if not _positive_number(entry[key],key == "price"): errors.append("Invalid " + key)
			elif floorf(float(entry[key])) != float(entry[key]): errors.append("Noninteger " + key)
		if entry.kind == "weapon":
			for key in ["behavior", "damage", "interval", "projectiles", "spread", "pierce", "range"]:
				if not entry.has(key): valid = false
			if not valid: errors.append("Incomplete weapon"); continue
			for key in ["damage","interval","projectiles","range","spread","pierce"]:
				if not _positive_number(entry[key],key in ["spread","pierce"]): errors.append("Invalid weapon " + key)
			if not entry.behavior in ["single", "spread", "pierce", "orbit", "return", "mortar", "cone_chill", "field_bankshot"]: errors.append("Invalid behavior")
			if entry.behavior=="field_bankshot":
				if not _positive_number(entry.projectiles) or not _positive_number(entry.spread,true): errors.append("Invalid Bankshot launch fields")
				elif entry.projectiles!=1 or entry.spread!=0: errors.append("Bankshot requires one straight launch")
				if not _positive_number(entry.pierce,true) or floorf(float(entry.pierce))!=float(entry.pierce): errors.append("Invalid Bankshot quota")
			if entry.behavior=="cone_chill":
				for key in ["cone_degrees","chill_duration","chill_speed"]:
					if not _positive_number(entry.get(key)): errors.append("Invalid chill weapon " + key)
				if _positive_number(entry.get("cone_degrees")) and entry.cone_degrees>180: errors.append("Cone exceeds half-plane")
				if _positive_number(entry.get("chill_duration")) and entry.chill_duration>10: errors.append("Chill exceeds duration budget")
				if _positive_number(entry.get("chill_speed")) and entry.chill_speed>1: errors.append("Chill cannot accelerate")
		elif entry.kind == "item":
			if entry.id=="feedback_diode":
				if not _positive_number(entry.get("feedback_damage")): errors.append("Invalid feedback damage")
				elif entry.feedback_damage>1000: errors.append("Feedback exceeds damage budget")
				if not _positive_number(entry.max_stack) or entry.max_stack!=1: errors.append("Feedback Diode must remain unique")
			if entry.id=="bounce_guide" and (not _positive_number(entry.max_stack) or entry.max_stack!=1): errors.append("Bounce Guide must remain unique")
			if entry.id=="fracture_coil":
				if not _positive_number(entry.get("fracture_damage")): errors.append("Invalid fracture damage")
				elif entry.fracture_damage>1000: errors.append("Fracture exceeds damage budget")
				if entry.max_stack!=1: errors.append("Fracture must remain unique")
			if not entry.get("effects", null) is Dictionary: errors.append("Invalid effects")
			else:
				for key in entry.effects:
					if not key in effect_keys or not _positive_number(entry.effects[key],true): errors.append("Invalid effect")
		else: errors.append("Invalid kind")
	if not seen.has("rivet_gun"): errors.append("Missing starter")
	var weighting: Variant = catalog.get("shop_weighting",null)
	if not weighting is Dictionary:
		errors.append("Missing shop weighting")
	else:
		for key in ["base","shared_tag_step","tag_bonus_cap","missing_partner_bonus","duplicate_weapon_bonus","total_cap"]:
			if not _positive_number(weighting.get(key),key not in ["base","total_cap"]): errors.append("Invalid shop weighting " + key)
		if _positive_number(weighting.get("base")) and _positive_number(weighting.get("total_cap")) and weighting.total_cap < weighting.base: errors.append("Shop cap below positive exploration base")
	var links: Variant = catalog.get("affinity_links",null)
	if not links is Array: errors.append("Invalid affinity links")
	else:
		for link in links:
			if not link is Array or link.size()!=2: errors.append("Invalid affinity pair")
			elif not seen.has(link[0]) or not seen.has(link[1]) or link[0]==link[1]: errors.append("Unknown/self affinity pair")
	for pair_data in catalog.get("mechanism_synergies",[]):
		if pair_data is Dictionary and pair_data.has("requires_other_weapon_than"):
			var excluded:Variant=pair_data.requires_other_weapon_than
			if not excluded is String or not seen.has(excluded):errors.append("Invalid companion weapon prerequisite")
			elif catalog_entry(catalog,excluded).kind!="weapon":errors.append("Companion prerequisite must name a weapon")
	return errors

static func new_build(catalog: Dictionary) -> Dictionary:
	return {"coins":int(catalog.starting_coins), "coin_fraction":0.0, "weapons":["rivet_gun"], "items":{}, "levels":{}, "revision":0}

static func derive(base: Dictionary, build: Dictionary, catalog: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	out.max_hp = base.hp
	out.pierce = 0
	out.damage_bonus = 0.0
	out.haste = 0.0
	out.speed_bonus = 0.0
	out.wave_heal = 15.0
	out.coin_bonus = 0.0
	out.range_bonus = 0.0
	out.electric_bonus = 0.0
	out.melee_bonus = 0.0
	out.extra_pellets = 0
	out.sell_bonus = 0.0
	for id in build.items:
		var entry := catalog_entry(catalog, id)
		for effect in entry.effects: out[effect] = out.get(effect, 0.0) + entry.effects[effect] * build.items[id]
	out.synergies = []
	for status in tag_synergy_status(build, catalog):
		if status.active:
			out[status.effect] += status.amount
			out.synergies.append(status.name)
	for id in build.levels:
		var n: int = build.levels[id]
		match id:
			"damage": out.damage_bonus += n * .25
			"speed": out.speed_bonus += n * .12
			"haste": out.haste += n * .15
			"health": out.max_hp += n * 20
			"magnet": out.pickup_radius += n * 35
			"pierce": out.pierce = mini(5, n)
	if build.get("boss_protocol",false):
		out.max_hp += 25
		out.damage_bonus += .1
	out.damage = base.damage * (1 + out.damage_bonus)
	out.speed = minf(300, base.speed * (1 + out.speed_bonus))
	out.fire_interval = maxf(.09, base.fire_interval / (1 + out.haste))
	out.resale = minf(.8, .5 + out.sell_bonus)
	return out

static func transaction(build: Dictionary, catalog: Dictionary, id: String, replace_slot: int = -1) -> String:
	var entry := catalog_entry(catalog, id)
	if entry.is_empty(): return "Unknown item"
	if build.coins < entry.price: return "Not enough scrap"
	if entry.kind == "weapon":
		var count: int = build.weapons.count(id) - (1 if replace_slot >= 0 and replace_slot < build.weapons.size() and build.weapons[replace_slot] == id else 0)
		if count >= int(entry.max_stack): return "Weapon stack limit reached"
		if replace_slot >= 0:
			if replace_slot >= build.weapons.size(): return "Invalid replacement slot"
		elif build.weapons.size() >= int(catalog.weapon_slots): return "Weapon slots full: select replacement"
	else:
		if build.items.get(id, 0) >= entry.max_stack: return "Stack limit reached"
		if not build.items.has(id) and build.items.size() >= int(catalog.item_slots): return "Item slots full: sell an item"
	build.coins -= int(entry.price)
	if entry.kind == "weapon":
		if replace_slot >= 0: build.weapons[replace_slot] = id
		else: build.weapons.append(id)
	else: build.items[id] = build.items.get(id, 0) + 1
	build.revision += 1
	return ""

static func credit(build: Dictionary, amount: float) -> void:
	build.coin_fraction += maxf(0, amount)
	var whole := floori(build.coin_fraction)
	build.coins += whole
	build.coin_fraction -= whole

static func owned_ids(build: Dictionary) -> Dictionary:
	var result: Dictionary = build.items.duplicate(true)
	for id in build.weapons: result[id] = result.get(id,0) + 1
	return result

static func shop_affinity(build: Dictionary,catalog: Dictionary) -> Dictionary:
	var owned := owned_ids(build)
	var tags := {}
	var sources: Array = []
	var missing: Array = []
	for id in owned:
		var entry := catalog_entry(catalog,id)
		if entry.is_empty(): continue
		sources.append("%s x%d" % [entry.name,owned[id]])
		for tag in entry.tags: tags[tag] = tags.get(tag,0) + int(owned[id])
	for link in catalog.get("affinity_links",[]):
		if owned.has(link[0]) and not owned.has(link[1]) and not missing.has(link[1]): missing.append(link[1])
		if owned.has(link[1]) and not owned.has(link[0]) and not missing.has(link[0]): missing.append(link[0])
	return {"tags":tags,"missing_ids":missing,"sources":sources}

static func weighted_pool(build: Dictionary,catalog: Dictionary) -> Array:
	var affinity := shop_affinity(build,catalog)
	var settings: Dictionary = catalog.shop_weighting
	var result: Array = []
	for entry in catalog.weapons + catalog.items:
		var count: int = build.weapons.count(entry.id) if entry.kind == "weapon" else build.items.get(entry.id,0)
		if count >= int(entry.max_stack): continue
		var tag_score := 0.0
		var reasons: Array = []
		for tag in entry.tags:
			if affinity.tags.has(tag):
				tag_score += float(affinity.tags[tag]) * settings.shared_tag_step
				reasons.append("Shared tag: " + str(tag))
		var weight: float = settings.base + minf(settings.tag_bonus_cap,tag_score)
		if entry.id in affinity.missing_ids:
			weight += settings.missing_partner_bonus
			reasons.append("Missing synergy partner")
		if entry.kind == "weapon" and count > 0:
			weight += settings.duplicate_weapon_bonus
			reasons.append("Duplicate weapon fits current loadout")
		weight = minf(settings.total_cap,weight)
		result.append({"id":entry.id,"weight_multiplier":weight / settings.base,"weight":weight,"bias_reasons":reasons})
	return result

static func draw_shop(build: Dictionary,catalog: Dictionary,rng: RandomNumberGenerator,count: int = 4,excluded_ids:Array = []) -> Array:
	var pool := weighted_pool(build,catalog)
	if not excluded_ids.is_empty(): pool=pool.filter(func(entry):return not entry.id in excluded_ids)
	var selected: Array = []
	for _slot in range(mini(count,pool.size())):
		var total := 0.0
		for entry in pool: total += entry.weight
		var cursor := rng.randf() * total
		var chosen := pool.size() - 1
		for i in range(pool.size()):
			cursor -= pool[i].weight
			if cursor < 0:
				chosen = i
				break
		var offer: Dictionary = pool[chosen].duplicate(true)
		offer.sold = false
		selected.append(offer)
		pool.remove_at(chosen)
	return selected
