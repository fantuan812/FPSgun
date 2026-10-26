extends RefCounted
## Shared target status and cone geometry. No mode, UI, RNG or timer ownership.
# Sub-pixel tolerance covers Vector2 roundoff at the shipped field coordinates.
const DISTANCE_EPSILON:=0.0001
const ANGLE_EPSILON:=0.000001
static func chilled(enemy:Dictionary,time:float)->bool:
	return enemy.hp>0 and float(enemy.get("chill_until",0.0))>time and not str(enemy.get("chill_weapon","")).is_empty()

static func apply_chill(enemy:Dictionary,time:float,weapon:Dictionary)->void:
	if enemy.hp<=0:return
	enemy.chill_until=time+float(weapon.chill_duration)
	enemy.chill_weapon=str(weapon.id)
	enemy.chill_speed=float(weapon.chill_speed)

static func can_fracture(enemy:Dictionary,time:float,weapon_id:String)->bool:
	return not weapon_id.is_empty() and chilled(enemy,time) and weapon_id!=str(enemy.chill_weapon)

static func consume_chill(enemy:Dictionary)->void:
	enemy.erase("chill_until")
	enemy.erase("chill_weapon")
	enemy.erase("chill_speed")

static func movement_factor(enemy:Dictionary,time:float)->float:
	var factor:float=.55 if float(enemy.get("slow_until",0.0))>time else 1.0
	if not enemy.get("boss",false) and chilled(enemy,time):factor=minf(factor,float(enemy.get("chill_speed",1.0)))
	return factor

static func in_cone(point:Vector2,origin:Vector2,direction:Vector2,reach:float,half_angle:float)->bool:
	var offset:Vector2=point-origin
	var distance:float=offset.length()
	if distance>reach+DISTANCE_EPSILON:return false
	if distance<=0.000001:return true
	return offset.dot(direction.normalized())/distance>=cos(half_angle)-ANGLE_EPSILON

static func ordered_living(enemies:Array,origin:Vector2,reach:float)->Array:
	var targets:Array=enemies.filter(func(e):return e.hp>0 and e.pos.distance_to(origin)<=reach+DISTANCE_EPSILON)
	targets.sort_custom(func(a,b):
		var da:float=a.pos.distance_squared_to(origin)
		var db:float=b.pos.distance_squared_to(origin)
		return a.id<b.id if da==db else da<db)
	return targets
