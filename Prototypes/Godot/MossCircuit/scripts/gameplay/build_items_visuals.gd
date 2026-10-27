extends RefCounted
## Editable original code geometry; draw in the existing world CanvasItem.
## No CanvasLayer, hit area or input node. HUD/modal layers remain authoritative.
static func draw(canvas:CanvasItem, view:Dictionary, reduced:bool)->void:
	var field_color:=Color(.48,.72,.57,.22 if reduced else .38)
	for field in view.get("fields",[]):
		# Outline only: never cover actors or imply an old damaging hazard.
		canvas.draw_arc(field.pos,float(field.radius),0,TAU,48,field_color,1.5)
		for angle in [0.0,PI*.5,PI,PI*1.5]:
			var point:Vector2=field.pos+Vector2.from_angle(angle)*float(field.radius)
			canvas.draw_line(point-Vector2(2,0),point+Vector2(2,0),field_color,1)
	var pin:Dictionary=view.get("pin",{})
	if pin.is_empty():return
	var tint:=Color(.88,.72,.41,.42 if reduced else .66)
	var anchor:Vector2=pin.anchor
	var target:Vector2=pin.target
	# Small square anchor and four corner ticks, unlike circular priority focus.
	canvas.draw_rect(Rect2(anchor-Vector2(3,3),Vector2(6,6)),tint,false,1)
	for side in [-1.0,1.0]:
		for vertical in [-1.0,1.0]:
			var corner:Vector2=target+Vector2(side*12,vertical*12)
			canvas.draw_line(corner,corner-Vector2(side*4,0),tint,1.5)
			canvas.draw_line(corner,corner-Vector2(0,vertical*4),tint,1.5)
