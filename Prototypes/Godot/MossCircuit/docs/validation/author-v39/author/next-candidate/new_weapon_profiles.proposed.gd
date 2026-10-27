extends RefCounted
## Pure definitions shared by catalog validation and the two opt-in new weapon paths.
static func number(value:Variant,zero:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and (value>=0.0 if zero else value>0.0)
static func weapon(entry:Dictionary)->Dictionary:
	var behavior:String=str(entry.get("behavior",""))
	if behavior not in ["tether_pulse","expanding_ring"]:return {}
	for key in ["damage","interval","range"]:
		if not number(entry.get(key)):return {}
	for key in ["projectiles","spread","pierce"]:
		if not number(entry.get(key),true):return {}
	if float(entry.projectiles)!=1.0 or float(entry.spread)!=0.0 or float(entry.pierce)!=0.0:return {}
	if behavior=="tether_pulse":
		if not entry.get("id") is String or entry.id!="tether_emitter":return {}
		if not number(entry.get("pulse_count")) or float(entry.pulse_count)!=4.0:return {}
	else:
		if not entry.get("id") is String or entry.id!="seismic_drum":return {}
		if not number(entry.get("max_live_per_slot")) or float(entry.max_live_per_slot)!=3.0:return {}
		for key in ["inner_start_radius","band_half_width","outward_seconds"]:
			if not number(entry.get(key)):return {}
		if entry.range<=entry.inner_start_radius:return {}
	return entry.duplicate(true)
static func module(entry:Dictionary)->Dictionary:
	if not entry.get("kind") is String or entry.kind!="item":return {}
	if not number(entry.get("max_stack")) or float(entry.max_stack)!=1.0:return {}
	match str(entry.get("id","")):
		"lock_memory":
			if not number(entry.get("grace_seconds")) or entry.grace_seconds>0.2:return {}
		"return_collar":
			if not number(entry.get("inward_seconds")) or not number(entry.get("inward_damage_scale")) or entry.inward_damage_scale>1.0:return {}
		_:return {}
	return entry.duplicate(true)
