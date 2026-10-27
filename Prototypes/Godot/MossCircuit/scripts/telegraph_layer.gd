extends Node2D
const Annulus=preload("res://scripts/gameplay/annulus_geometry.gd")
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
static func brace_outline(marker:Dictionary)->PackedVector2Array:
	# Display radius is only an indicator; it never changes collision or applies damage.
	var points:=PackedVector2Array()
	var angle:float=marker.direction.angle()
	for i in range(25):
		var theta:float=angle-float(marker.half_angle)+2.0*float(marker.half_angle)*float(i)/24.0
		points.append(marker.pos+Vector2.from_angle(theta)*float(marker.radius))
	return points

func show_markers(value: Array) -> void:
	markers = value
	z_index = 20
	queue_redraw()
func _draw() -> void:
	for marker in markers:
		if marker.kind == "support_tether":
			var delta:Vector2=marker.end-marker.pos
			var length:float=delta.length()
			if length>.001:
				var axis:Vector2=delta/length
				for offset in range(0,int(length),12):
					var a:Vector2=marker.pos+axis*float(offset)
					var b:Vector2=marker.pos+axis*minf(float(offset)+7.0,length)
					draw_line(a,b,Color(.03,.08,.1,.9),4)
					draw_line(a,b,marker.color,2)
			# Four discrete repair notches and a center needle; never an orange damage disc.
			var center:Vector2=marker.pos+Vector2(0,-30)
			for i in range(4):
				var a:Vector2=center+Vector2(-13+float(i)*7,-5)
				var b:Vector2=a+Vector2(0,10)
				var color:Color=marker.color if marker.progress>=float(i+1)/4.0 else Color(.2,.35,.4,.8)
				draw_line(a,b,Color(.03,.08,.1,.95),5)
				draw_line(a,b,color,3)
		elif marker.kind == "support_complete":
			var center:Vector2=marker.pos+Vector2(0,-24)
			for axis in [Vector2.RIGHT,Vector2.DOWN]:
				draw_line(center-axis*7,center+axis*7,Color(.03,.08,.1,marker.color.a),5)
				draw_line(center-axis*7,center+axis*7,marker.color,3)
		elif marker.kind == "support_cancel":
			var center:Vector2=(marker.pos+marker.end)*.5
			var axis:Vector2=(marker.end-marker.pos).normalized()
			if axis==Vector2.ZERO:axis=Vector2.RIGHT
			var side:Vector2=axis.orthogonal()
			draw_line(center-axis*16,center-axis*5,marker.color,2)
			draw_line(center+axis*5,center+axis*16,marker.color,2)
			draw_line(center-side*5-axis*3,center+side*5+axis*3,marker.color,2)
		elif marker.kind == "line":
			draw_line(marker.pos,marker.end,line_fill(marker.color),marker.width)
			var outline:=line_outline(marker)
			if not outline.is_empty():
				draw_polyline(outline,Color(0.06,.08,.1,.85),4)
				draw_polyline(outline,marker.color,2)
		elif marker.kind == "brace":
			var outline:=brace_outline(marker)
			draw_polyline(outline,Color(0.06,.08,.1,.95),4)
			draw_polyline(outline,marker.color,2)
			for side in [-1.0,1.0]:
				var axis:=Vector2.from_angle(marker.direction.angle()+side*float(marker.half_angle))
				var a:Vector2=marker.pos+axis*(float(marker.radius)-3.0)
				var b:Vector2=marker.pos+axis*(float(marker.radius)+3.0)
				draw_line(a,b,Color(0.06,.08,.1,.95),4)
				draw_line(a,b,marker.color,2)
		elif marker.kind == "annulus":
			var fill: Color = marker.color
			fill.a = float(marker.get("fill_alpha",.08))
			for quad in Annulus.band_quads(marker.pos,marker.inner_radius,marker.outer_radius):
				draw_colored_polygon(quad,fill)
			for radius in [marker.inner_radius,marker.outer_radius]:
				draw_circle(marker.pos,radius,Color(0.06,.08,.1,.95),false,5)
				draw_circle(marker.pos,radius,marker.color,false,2)
		else:
			draw_circle(marker.pos,marker.radius,Color(0.06,.08,.1,.95),false,5)
			draw_circle(marker.pos,marker.radius,marker.color,false,2)
