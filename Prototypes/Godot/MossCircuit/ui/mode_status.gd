extends CanvasLayer
## Procedural pixel HUD fallback. Rejected PNG drafts never enter this runtime class.
var phase:=0
var clear_progress:=0.0
var badge:Node2D
var objective:Label
var visible_rooms:=false
func _ready()->void:
	layer=19
	badge=Node2D.new();add_child(badge);badge.position=Vector2(26,104)
	badge.draw.connect(_draw_badge)
	objective=Label.new();add_child(objective)
	objective.position=Vector2(82,110);objective.size=Vector2(760,42)
	objective.add_theme_font_size_override("font_size",16)
	objective.add_theme_color_override("font_color",Color("b4dfb0"))
	objective.mouse_filter=Control.MOUSE_FILTER_IGNORE
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
func place_below(hud_rect:Rect2)->void:
	# Container minimum sizes and font metrics can exceed authored HUD offsets.
	# Use its measured rectangle instead of a fixed overlapping screen position.
	badge.position=Vector2(hud_rect.position.x+10,hud_rect.end.y+8)
	var text_offset:float=66 if visible_rooms else 10
	objective.position=Vector2(hud_rect.position.x+text_offset,hud_rect.end.y+8)
	objective.size=Vector2(maxf(1,hud_rect.size.x-text_offset-10),42)
func present(mode_id:String,state:String,text:String,progress:float,focus_text:String="")->void:
	visible_rooms=mode_id=="rooms"
	visible=state in ["playing","room_clear"]
	clear_progress=maxf(0,progress)
	phase=clampi(int(floor(clear_progress*8+.000001)),0,8)
	objective.text=text if focus_text.is_empty() else text+"\n"+focus_text
	badge.visible=visible_rooms
	badge.queue_redraw()

func blocks_focus_at(viewport_point:Vector2)->bool:
	if not visible:return false
	if objective.is_visible_in_tree() and Rect2(Vector2.ZERO,objective.size).has_point(objective.make_canvas_position_local(viewport_point)):return true
	return badge.is_visible_in_tree() and Rect2(0,0,48,40).has_point(badge.make_canvas_position_local(viewport_point))
func _draw_badge()->void:
	var ink:=Color("142c32")
	var color:=Color("e7b969") if phase==0 else Color("91e8bc")
	badge.draw_rect(Rect2(0,0,48,40),ink)
	badge.draw_rect(Rect2(2,2,44,36),color,false,2)
	# Unlock has a changing opening and a distinct check, not only a colour swap.
	var gap:=phase*2
	badge.draw_rect(Rect2(10,17,14-gap*.5,6),color)
	badge.draw_rect(Rect2(24+gap*.5,17,14-gap*.5,6),color)
	if phase>=6:
		badge.draw_line(Vector2(17,24),Vector2(22,29),color,3)
		badge.draw_line(Vector2(22,29),Vector2(33,14),color,3)
