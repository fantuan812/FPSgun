extends RefCounted
## Optional future-acquisition preference. No input, mutation, RNG or damage authority.
const Rules=preload("res://scripts/rules.gd")
const Status=preload("res://scripts/gameplay/target_status.gd")
const PICK_PADDING:=8.0
const AIMED_BEHAVIORS=["single","spread","pierce","return","mortar","cone_chill","field_bankshot","tether_pulse"]

static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func pick_radius(enemy:Variant)->float:
	if not enemy is Dictionary or not number(enemy.get("scale")) or enemy.scale<=0:return -1.0
	var radius:float=16.0*float(enemy.scale)+PICK_PADDING
	return radius if is_finite(radius) and radius>0 and is_finite(radius*radius) else -1.0

static func living(enemy:Variant)->bool:
	return enemy is Dictionary and enemy.get("id") is int and enemy.id>0 and number(enemy.get("hp")) and enemy.hp>0 and enemy.get("pos") is Vector2 and enemy.pos.is_finite() and pick_radius(enemy)>0

static func find(enemies:Array,id:Variant)->Dictionary:
	if not id is int or id<=0:return {}
	for enemy in enemies:
		if living(enemy) and enemy.id==id:return enemy
	return {}

## -1 is an invalid point, 0 valid empty ground; neither guesses an entity.
static func pick(enemies:Array,point:Variant)->int:
	if not point is Vector2 or not point.is_finite():return -1
	var selected:int=0
	var best:float=INF
	for enemy in enemies:
		if not living(enemy):continue
		var radius:float=pick_radius(enemy)
		var distance:float=enemy.pos.distance_squared_to(point)
		if not is_finite(distance) or distance>radius*radius:continue
		if distance<best or (distance==best and (selected==0 or enemy.id<selected)):
			best=distance;selected=enemy.id
	return selected

static func directional(weapon:Dictionary)->bool:
	return weapon.get("behavior","") in AIMED_BEHAVIORS

static func eligible(enemies:Array,id:Variant,origin:Vector2,weapon:Dictionary,stats:Dictionary)->Dictionary:
	if not id is int or id<=0 or not origin.is_finite() or not directional(weapon):return {}
	var target:Dictionary=find(enemies,id)
	if target.is_empty() or not number(weapon.get("range")) or not number(stats.get("range_bonus")):return {}
	var reach:float=Rules.weapon_reach(weapon,stats)
	var distance:float=origin.distance_to(target.pos)
	if not is_finite(reach) or reach<0 or not is_finite(distance):return {}
	var tolerance:float=Status.DISTANCE_EPSILON if weapon.behavior in ["cone_chill","field_bankshot"] else 0.0
	return target if distance<=reach+tolerance else {}
