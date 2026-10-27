extends RefCounted
## Pure per-copy metadata and projection. Missing metadata is the exact legacy path.
## No RNG, economy, scenes, combat events or automatic repair of malformed state.

static func validate_profile(value: Variant) -> Array:
	if not value is Dictionary: return ["Missing weapon tempering profile"]
	var errors: Array = []
	var maximum: Variant = value.get("max_tier")
	if not (maximum is int or maximum is float) or not is_finite(float(maximum)) or maximum != 1:
		errors.append("Weapon tempering has exactly one tier")
	var factor: Variant = value.get("primary_damage_multiplier")
	if not (factor is int or factor is float) or not is_finite(float(factor)) or float(factor) <= 1.0 or float(factor) >= 2.0:
		errors.append("Tempered primary multiplier must be finite and between one and two")
	return errors

static func metadata_error(build: Dictionary) -> String:
	if not build.has("weapon_temper"): return ""
	var tiers: Variant = build.weapon_temper
	var ids: Variant = build.get("weapons")
	if not tiers is Array or not ids is Array: return "Weapon tier data is invalid."
	if tiers.size() != ids.size(): return "Weapon tier data does not match the loadout."
	for tier in tiers:
		if not tier is int or tier not in [0, 1]: return "Weapon tier data is invalid."
	return ""

static func tier_at(build: Dictionary, slot: int, id: String) -> int:
	# Legacy direct fire(id, slot) need not match the owned loadout; it gets no boost.
	if not build.has("weapon_temper") or not metadata_error(build).is_empty(): return 0
	if slot < 0 or slot >= build.weapons.size() or build.weapons[slot] != id: return 0
	return build.weapon_temper[slot]

static func multiplier(build: Dictionary, catalog: Dictionary, slot: int, id: String) -> float:
	if tier_at(build, slot, id) != 1: return 1.0
	var profile: Variant = catalog.get("weapon_tempering")
	if not validate_profile(profile).is_empty(): return 1.0
	return float(profile.primary_damage_multiplier)

static func donor_slot(build: Dictionary, slot: int) -> int:
	if not metadata_error(build).is_empty() or not build.get("weapons") is Array: return -1
	if slot < 0 or slot >= build.weapons.size() or not build.weapons[slot] is String: return -1
	var id: String = build.weapons[slot]
	if tier_at(build, slot, id) != 0: return -1
	for other in range(build.weapons.size()):
		if other != slot and build.weapons[other] == id and tier_at(build, other, id) == 0: return other
	return -1

static func projected_build(build: Dictionary, slot: int, donor: int) -> Dictionary:
	if donor < 0 or donor_slot(build, slot) != donor: return {}
	var result: Dictionary = build.duplicate(true)
	if not result.has("weapon_temper"):
		result.weapon_temper = []
		for _id in result.weapons: result.weapon_temper.append(0)
	result.weapon_temper[slot] = 1
	result.weapons.remove_at(donor)
	result.weapon_temper.remove_at(donor)
	return result
