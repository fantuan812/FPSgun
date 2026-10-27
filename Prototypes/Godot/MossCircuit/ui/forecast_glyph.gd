extends Control
## Original code-native build connector glyphs; labels carry the meaning independently.
var kind:String="needs"
func _ready()->void:
	custom_minimum_size=Vector2(16,16)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw()->void:
	var tint:Color=Color("a3c98b") if kind=="enables" else Color("e9b660")
	if kind=="enables":
		draw_circle(Vector2(8,8),6,tint,false,1.5,true)
		draw_line(Vector2(4,8),Vector2(12,8),tint,1.5,true)
		draw_line(Vector2(8,4),Vector2(8,12),tint,1.5,true)
	elif kind=="disables":
		draw_line(Vector2(2,8),Vector2(6,8),tint,2,true)
		draw_line(Vector2(10,8),Vector2(14,8),tint,2,true)
		draw_line(Vector2(9,3),Vector2(7,13),tint,1.5,true)
	else:
		draw_circle(Vector2(4,8),2.5,tint,false,1.5,true)
		draw_circle(Vector2(12,8),2.5,tint,false,1.5,true)
		draw_line(Vector2(6.5,8),Vector2(9.5,8),tint,1.5,true)
