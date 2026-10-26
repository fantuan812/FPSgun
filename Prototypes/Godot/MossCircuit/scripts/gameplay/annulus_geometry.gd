extends RefCounted
## Shared fixed-band geometry. No clocks, modes, damage or rendering authority.
const SPATIAL_EPSILON := 0.0001
const DISPLAY_SEGMENTS := 96

static func valid(inner: float, outer: float) -> bool:
	return is_finite(inner) and is_finite(outer) and inner > 0 and outer > inner

static func contains(point: Vector2, center: Vector2, inner: float, outer: float) -> bool:
	if not valid(inner, outer) or not point.is_finite() or not center.is_finite(): return false
	var distance := point.distance_to(center)
	return distance >= inner - SPATIAL_EPSILON and distance <= outer + SPATIAL_EPSILON

static func band_quads(center: Vector2, inner: float, outer: float) -> Array:
	var quads: Array = []
	if not valid(inner, outer) or not center.is_finite(): return quads
	for index in range(DISPLAY_SEGMENTS):
		var a := Vector2.from_angle(TAU * index / DISPLAY_SEGMENTS)
		var b := Vector2.from_angle(TAU * (index + 1) / DISPLAY_SEGMENTS)
		quads.append(PackedVector2Array([center + a * inner, center + a * outer, center + b * outer, center + b * inner]))
	return quads
