extends Node2D
## Exact gameplay geometry rendered above decorative VFX. Never applies damage.
var markers: Array = []
static func line_fill(color:Color)->Color:
	# The warning footprint stays exact, but its interior must not hide the actor.
	return Color(color.r,color.g,color.b,minf(color.a,.16))
static func line_outline(marker:Dictionary)->PackedVector2Array:
	var axis:Vector2=marker.end-marker.pos
	if axis.length_squared()<=.000001:return PackedVector2Array()
	var side:Vector2=axis.normalized().orthogonal()*float(marker.width)*.5
	return PackedVector2Array([marker.pos+side,marker.end+side,marker.end-side,marker.pos-side,marker.pos+side])
func show_markers(value: Array) -> void:
	markers = value
	z_index = 20
	queue_redraw()
func _draw() -> void:
	for marker in markers:
		if marker.kind == "line":
			draw_line(marker.pos,marker.end,line_fill(marker.color),marker.width)
			var outline:=line_outline(marker)
			if not outline.is_empty():
				draw_polyline(outline,Color(0.06,.08,.1,.85),4)
				draw_polyline(outline,marker.color,2)
		else:
			draw_circle(marker.pos,marker.radius,Color(0.06,.08,.1,.95),false,5)
			draw_circle(marker.pos,marker.radius,marker.color,false,2)
