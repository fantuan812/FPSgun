extends RefCounted
## Read-only eligibility for shop-only adjacent copy moves. No economy, RNG or scene policy.
const Rules = preload("res://scripts/rules.gd")

static func loadout_error(build: Dictionary, catalog: Dictionary, clocks: Array) -> String:
	var ids = build.get("weapons")
	if not ids is Array: return "Weapon loadout is unavailable."
	if ids.size() < 2: return "Own at least two weapons to change their order."
	if ids.size() > 4 or ids.size() > int(catalog.get("weapon_slots", 4)): return "Weapon slot count is invalid."
	if clocks.size() != ids.size(): return "Weapon cooldown state is unavailable."
	for id in ids:
		if not id is String: return "Weapon identity is invalid."
		var entry := Rules.catalog_entry(catalog, id)
		if entry.get("kind", "") != "weapon": return "Weapon identity is invalid."
	for clock in clocks:
		if not (clock is int or clock is float) or not is_finite(float(clock)):
			return "Weapon cooldown state is unavailable."
	return ""
