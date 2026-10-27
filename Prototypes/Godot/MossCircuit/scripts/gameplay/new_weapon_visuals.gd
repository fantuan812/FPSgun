extends RefCounted
## Original editable code geometry. Presentation cannot select or damage enemies.
const Runtime=preload("res://scripts/gameplay/new_weapon_runtime.gd")
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
static func draw(canvas:CanvasItem,world:RefCounted,reduced:bool)->void:
	var cyan:=Color(0.38,0.86,0.88,0.55 if reduced else 0.8)
	var amber:=Color(0.9,0.7,0.35,0.5 if reduced else 0.75)
	for beam in world.pulse_beams:
		var target:Dictionary=Focus.find(world.enemies,int(beam.target_id))
		if target.is_empty():continue
		var origin:Vector2=world.player_pos
		if not beam.was_outside:
			canvas.draw_line(origin,target.pos,cyan,1.5)
		else:
			var direction:Vector2=(target.pos-origin).normalized()
			canvas.draw_line(origin,origin+direction*18,Color(cyan,0.3),1.0)
		for i in range(4):
			var point:Vector2=origin+Vector2((i-1.5)*5,-22-int(beam.slot_id)*5)
			canvas.draw_rect(Rect2(point,Vector2(3,3)),cyan if i<int(beam.pulse_index) else Color(cyan,0.25))
	for wave in world.seismic_waves:
		var leg:int=1 if wave.outward_done and wave.return_enabled else 0
		var radius:float=Runtime.radius_at(wave,float(wave.age),leg)
		canvas.draw_arc(wave.center,maxf(0.0,radius-wave.half_width),0,TAU,64,Color(amber,0.3),1)
		canvas.draw_arc(wave.center,radius+wave.half_width,0,TAU,64,amber,1.5)
		for index in range(4):
			var direction:Vector2=Vector2.from_angle(index*PI*0.5)
			var point:Vector2=wave.center+direction*radius
			var forward:Vector2=direction*(-1.0 if leg==1 else 1.0)
			var side:=Vector2(-forward.y,forward.x)
			canvas.draw_line(point-forward*4+side*3,point+forward*3,amber,1.5)
			canvas.draw_line(point-forward*4-side*3,point+forward*3,amber,1.5)
	for visual in world.effect_visuals:
		if visual.kind!="tether_break":continue
		canvas.draw_line(visual.pos+Vector2(-5,-8),visual.pos+Vector2(-1,-12),cyan,1)
		canvas.draw_line(visual.pos+Vector2(1,-8),visual.pos+Vector2(5,-12),cyan,1)

static func hud_status(world:RefCounted,owned:Array)->String:
	var parts:Array=[]
	if "tether_emitter" in owned:
		var text:String="LOCK -"
		if not world.pulse_beams.is_empty():
			var first:Dictionary=world.pulse_beams[0]
			text="LOCK %d/%d" % [int(first.pulse_index),int(first.pulse_count)]
			if world.pulse_beams.size()>1:text+="x%d" % world.pulse_beams.size()
		parts.append(text)
	if "seismic_drum" in owned:
		var inward:int=world.seismic_waves.filter(func(w):return w.return_enabled and w.outward_done).size()
		parts.append("RING ↑%d ↓%d" % [world.seismic_waves.size()-inward,inward])
	return " · ".join(parts)
