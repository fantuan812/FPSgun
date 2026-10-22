extends RefCounted
const Rules=preload("res://scripts/rules.gd")
## Field lifecycle owns deterministic terrain only; no spawn, reward, UI or projectile-wall policy.
static func make(area:Dictionary,seed_value:int)->Dictionary:
	var grid:=Rules.grid_dimensions(area)
	return {"grid":grid,"cells":Rules.map_cells(seed_value,grid.x,grid.y),"center":Vector2(area.width,area.height)*.5}
static func camera_position(player:Vector2,area:Dictionary)->Vector2:
	return Vector2(clampf(player.x,480,area.width-480) if area.width>=960 else area.width*.5,clampf(player.y,270,area.height-270) if area.height>=540 else area.height*.5)
