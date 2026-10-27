extends RefCounted
## Pure optional catalog profile and return-sweep eligibility. Never awards rewards.
static func _number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func definition(entry:Dictionary)->Dictionary:
	if entry.get("id")!="scavenger_reel" or entry.get("kind")!="item":return {}
	var radius:Variant=entry.get("return_pickup_radius")
	var limit:Variant=entry.get("return_pickup_limit")
	var maximum:Variant=entry.get("max_stack")
	if not _number(radius) or float(radius)<=0 or float(radius)>64:return {}
	if not _number(limit) or float(limit)<1 or float(limit)>8 or floorf(float(limit))!=float(limit):return {}
	if not _number(maximum) or float(maximum)!=1:return {}
	var sources:Variant=entry.get("pickup_sources")
	if not sources is Array or sources.size()!=2:return {}
	if not sources.all(func(s):return s is String and s in ["normal","energy"]):return {}
	if sources[0]==sources[1]:return {}
	if not entry.get("effects") is Dictionary or not entry.effects.is_empty():return {}
	return {"radius":float(radius),"maximum":int(limit),"sources":sources.duplicate()}

static func profile(build:Dictionary,catalog:Dictionary)->Dictionary:
	var items:Variant=build.get("items")
	if not items is Dictionary:return {}
	var owned:Variant=items.get("scavenger_reel",0)
	if not _number(owned) or float(owned)<=0:return {}
	var entries:Variant=catalog.get("items",[])
	if not entries is Array:return {}
	for entry in entries:
		if entry is Dictionary and entry.get("id")=="scavenger_reel":return definition(entry)
	return {}

static func snapshot(build:Dictionary,catalog:Dictionary)->Dictionary:
	var result:=profile(build,catalog)
	if not result.is_empty():result.remaining=result.maximum
	return result

static func valid_snapshot(value:Variant)->bool:
	if not value is Dictionary:return false
	var maximum:Variant=value.get("maximum")
	var remaining:Variant=value.get("remaining")
	var radius:Variant=value.get("radius")
	if not maximum is int or maximum<1 or maximum>8:return false
	if not remaining is int or remaining<0 or remaining>maximum:return false
	if not _number(radius) or float(radius)<=0 or float(radius)>64:return false
	var sources:Variant=value.get("sources")
	return sources is Array and sources.size()==2 and sources.all(func(s):return s is String and s in ["normal","energy"]) and sources[0]!=sources[1]

static func eligible(sweep:Dictionary,pickup:Dictionary)->bool:
	var disc:Variant=sweep.get("disc")
	if not disc is Dictionary or not valid_snapshot(disc.get("scavenger")):return false
	var quota:Dictionary=disc.scavenger
	if quota.remaining<=0:return false
	var start:Variant=sweep.get("start")
	var end:Variant=sweep.get("end")
	var pos:Variant=pickup.get("pos")
	if not start is Vector2 or not end is Vector2 or not pos is Vector2:return false
	if not start.is_finite() or not end.is_finite() or not pos.is_finite() or start==end:return false
	var source:Variant=pickup.get("source","normal")
	if not source is String or not source in quota.sources:return false
	return Geometry2D.get_closest_point_to_segment(pos,start,end).distance_to(pos)<quota.radius

static func describe(entry:Dictionary)->String:
	var data:=definition(entry)
	if data.is_empty():return "Scavenger Reel unavailable: invalid collection profile."
	return "Return Disc required. RETURN LEG ONLY: immediately collects up to %d normal/energy pickups per launched disc within %.1f px of its path. Medicine excluded. No damage or reward multiplier." % [data.maximum,data.radius]
