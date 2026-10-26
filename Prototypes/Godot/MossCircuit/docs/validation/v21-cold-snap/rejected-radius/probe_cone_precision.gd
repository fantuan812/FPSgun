extends SceneTree
const S=preload("res://scripts/gameplay/target_status.gd")
func _initialize()->void:
	for origin in [Vector2(720,480),Vector2(480,320)]:
		for i in range(8):
			var direction:=Vector2.from_angle(i*TAU/8)
			for side in [-1,0,1]:
				var point:Vector2=origin+direction.rotated(side*PI/6)*190
				if not S.in_cone(point,origin,direction,190,PI/6):print("EDGE_MISS ",origin," ",i," ",side," radius=",(point-origin).length())
	quit()
