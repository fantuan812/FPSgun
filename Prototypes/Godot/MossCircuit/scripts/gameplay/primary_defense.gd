extends RefCounted
## A pure, opt-in primary-contact modifier. It never discovers hits or mutates actors/shots.
const SPATIAL_EPS := 0.0001
const DIRECTION_EPS := 0.000001
const DOT_EPS := 0.000001

static func _number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func _vector(value:Variant)->bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y)

static func validate_entry(entry:Dictionary)->Array:
	var has_degrees:bool=entry.has("brace_degrees")
	var has_multiplier:bool=entry.has("brace_multiplier")
	if not has_degrees and not has_multiplier:return []
	var errors:Array=[]
	if not has_degrees or not has_multiplier:
		errors.append("Brace fields must be paired")
	if not entry.get("id") is String or entry.get("id")!="charger" or not entry.get("behavior") is String or entry.get("behavior")!="charge" or not entry.get("boss") is bool or entry.get("boss"):
		errors.append("Only ordinary Amber Ram may opt into brace")
	var degrees:Variant=entry.get("brace_degrees")
	var multiplier:Variant=entry.get("brace_multiplier")
	if not _number(degrees) or float(degrees)<=0 or float(degrees)>=180:
		errors.append("Brace degrees must be finite and between zero and180")
	if not _number(multiplier) or float(multiplier)<=0 or float(multiplier)>=1:
		errors.append("Brace multiplier must be finite and between zero and one")
	return errors

static func brace(enemy:Dictionary)->Dictionary:
	# Runtime identity differs from data-entry identity: id is the numeric actor ID.
	if not enemy.get("kind") is String or enemy.get("kind")!="charger":return {}
	if not enemy.get("behavior") is String or enemy.get("behavior")!="charge":return {}
	if not enemy.get("boss") is bool or enemy.get("boss"):return {}
	if not enemy.get("ai_state") is String or enemy.get("ai_state")!="warning":return {}
	if not enemy.get("attack") is String or enemy.get("attack")!="charge":return {}
	if not _number(enemy.get("hp")) or float(enemy.hp)<=0:return {}
	var degrees:Variant=enemy.get("brace_degrees")
	var multiplier:Variant=enemy.get("brace_multiplier")
	if not _number(degrees) or float(degrees)<=0 or float(degrees)>=180:return {}
	if not _number(multiplier) or float(multiplier)<=0 or float(multiplier)>=1:return {}
	if not _number(enemy.get("scale")) or float(enemy.scale)<=0:return {}
	if not _vector(enemy.get("pos")) or not _vector(enemy.get("aim")):return {}
	var direction:Vector2=enemy.aim
	if not is_finite(direction.length()) or direction.length()<=DIRECTION_EPS:return {}
	return {"direction":direction.normalized(),"half_angle":deg_to_rad(float(degrees)*.5),"multiplier":float(multiplier),"collision_radius":16.0*float(enemy.scale),"visual_radius":32.0*float(enemy.scale)}

static func resolve(enemy:Dictionary,nominal_damage:float,source_point:Vector2,toward_source:Vector2)->float:
	var current:Dictionary=brace(enemy)
	if current.is_empty():return nominal_damage
	if not _vector(source_point) or not _vector(toward_source):return nominal_damage
	# Exact boundary remains directional; only the strict interior is exempt.
	var distance:float=source_point.distance_to(enemy.pos)
	if not is_finite(distance):return nominal_damage
	if distance<float(current.collision_radius)-SPATIAL_EPS:return nominal_damage
	if not is_finite(toward_source.length()) or toward_source.length()<=DIRECTION_EPS:return nominal_damage
	if current.direction.dot(toward_source.normalized())>=cos(float(current.half_angle))-DOT_EPS:
		return nominal_damage*float(current.multiplier)
	return nominal_damage
