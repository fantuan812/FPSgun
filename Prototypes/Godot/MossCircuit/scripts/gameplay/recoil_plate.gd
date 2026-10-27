extends RefCounted
## A-only pure definition/command and bounded position mutation. Never emits events.
static func number(value:Variant, positive:bool=false)->bool:
	return (value is int or value is float) and is_finite(float(value)) and (not positive or float(value)>0.0)

static func definition(entry:Dictionary)->Dictionary:
	if entry.get("id")!="recoil_plate":return {}
	if not number(entry.get("max_stack"),true) or float(entry.max_stack)!=1.0:return {}
	for key in ["radius","distance","cooldown"]:
		if not number(entry.get(key),true):return {}
	return {"radius":float(entry.radius),"distance":float(entry.distance),"cooldown":float(entry.cooldown)}

static func eligible(event:Dictionary,context:Dictionary)->bool:
	if event.get("kind")!="hurt" or event.get("source")!="player_hp_loss":return false
	if not number(event.get("depth")) or float(event.depth)!=0.0:return false
	if not number(event.get("amount"),true):return false
	if not context.get("playing") is bool:return false
	if not bool(context.playing):return false
	if not number(context.get("hp"),true) or not number(context.get("time")):return false
	if float(context.time)<0:return false
	return finite_vector(context.get("pos"))

static func finite_vector(value:Variant)->bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y)

static func valid_area(area:Dictionary)->bool:
	for key in ["width","height"]:
		if not number(area.get(key),true) or float(area[key])<=40:return false
	return finite_vector(Vector2(float(area.width)-20,float(area.height)-20))

static func apply(command:Dictionary,enemies:Array,area:Dictionary)->Array:
	var moved:Array=[]
	if command.get("kind")!="recoil_push" or not valid_area(area):return moved
	if not finite_vector(command.get("pos")):return moved
	for key in ["radius","distance"]:
		if not number(command.get(key),true):return moved
	var origin:Vector2=command.pos
	var minimum:=Vector2(20,20)
	var maximum:=Vector2(float(area.width)-20,float(area.height)-20)
	for value in enemies:
		if not value is Dictionary:continue
		var enemy:Dictionary=value
		if not number(enemy.get("hp"),true) or enemy.get("boss",false):continue
		if not finite_vector(enemy.get("pos")):continue
		var offset:Vector2=enemy.pos-origin
		var distance:float=offset.length()
		if not is_finite(distance) or distance>float(command.radius):continue
		var away:Vector2=Vector2.RIGHT if distance==0.0 else offset/distance
		var destination:Vector2=enemy.pos+away*float(command.distance)
		if not finite_vector(destination):continue
		enemy.pos=destination.clamp(minimum,maximum)
		moved.append(enemy.get("id",-1))
	return moved
