extends Node2D
## Exact gameplay geometry rendered above decorative VFX. Never applies damage.
var markers: Array = []
func show_markers(value: Array) -> void:
	markers = value
	z_index = 20
	queue_redraw()
func _draw() -> void:
	for marker in markers:
		if marker.kind == "line":
			draw_line(marker.pos,marker.end,Color(0.06,.08,.1,.85),marker.width+4)
			draw_line(marker.pos,marker.end,marker.color,marker.width)
		else:
			draw_circle(marker.pos,marker.radius,Color(0.06,.08,.1,.95),false,5)
			draw_circle(marker.pos,marker.radius,marker.color,false,2)
