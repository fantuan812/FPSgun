extends RefCounted
## B-only bounded state/control helper. No scene, RNG, damage, collection or event emission.
const MOTION_EPSILON:=0.00001
const B_IDS:=["crossfire_pin","salvage_capacitor","medic_winch"]
var configuration_open:=true
var registry:Dictionary={}
var slot_caps:Dictionary={}
var definitions:Dictionary={"crossfire_pin":{},"salvage_capacitor":{},"medic_winch":{}}
var owned_items:Dictionary={}
var weapon_counts:Dictionary={}
var equipped_types:Array=[]
var mark:Variant=null
var pin_ready_at:Variant=null
var charges:=0
var fields:Array=[]
var next_field_sequence:=0
var winch_count:=0
var pending:Variant=null
var winch_requested_this_batch:=false
var bound_epoch:=-1
var last_sequence:=0
var last_now:=0.0
var last_step_serial:=-1
var batch_serial:=-1
var batch_time:=0.0
var batch_open:=false

static func _number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))
static func _positive(value:Variant)->bool:
	return _number(value) and float(value)>0.0
static func _whole(value:Variant,minimum:int=0)->bool:
	if value is int:return value>=minimum
	return value is float and is_finite(value) and value>=float(minimum) and value<=9223372036854774784.0 and floorf(value)==value
static func _integer(value:Variant,minimum:int=0)->bool:
	return value is int and value>=minimum
static func _vector(value:Variant)->bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y)
static func _area(area:Variant)->bool:
	if not area is Dictionary:return false
	for key in ["width","height"]:
		if not _positive(area.get(key)) or float(area[key])<=40.0:return false
	return _vector(Vector2(float(area.width)-20.0,float(area.height)-20.0))
func _time(now:Variant)->bool:
	return _number(now) and float(now)>=0.0 and float(now)>=last_now
static func _future(now:float,duration:float)->Variant:
	var result:float=now+duration
	return result if is_finite(result) and result>now else null

func configure(catalog:Variant)->Dictionary:
	var errors:Array=[]
	if not configuration_open:return {"ok":false,"errors":["configuration window closed"]}
	if not catalog is Dictionary:return {"ok":false,"errors":["catalog must be dictionary"]}
	if not catalog.get("weapons") is Array or not catalog.get("items") is Array:return {"ok":false,"errors":["catalog lists required"]}
	if not _whole(catalog.get("weapon_slots"),1) or not _whole(catalog.get("item_slots"),1):return {"ok":false,"errors":["invalid slot counts"]}
	if int(catalog.weapon_slots)!=4 or int(catalog.item_slots)!=8:return {"ok":false,"errors":["B preserves four weapon/eight item slots"]}
	var next_registry:Dictionary={}
	var next_definitions:Dictionary={"crossfire_pin":{},"salvage_capacitor":{},"medic_winch":{}}
	var seen:Dictionary={}
	for list_key in ["weapons","items"]:
		var expected_kind:String="weapon" if list_key=="weapons" else "item"
		for value in catalog[list_key]:
			if not value is Dictionary:errors.append("entry must be dictionary");continue
			var entry:Dictionary=value
			if not entry.get("id") is String or str(entry.id).is_empty():errors.append("invalid ID");continue
			var id:String=entry.id
			if seen.has(id):errors.append("duplicate ID "+id);continue
			seen[id]=true
			if not entry.get("kind") is String or str(entry.kind)!=expected_kind:errors.append("wrong registry kind "+id);continue
			if not _whole(entry.get("max_stack"),1):errors.append("invalid max stack "+id);continue
			next_registry[id]={"kind":expected_kind,"max_stack":int(entry.max_stack)}
			if id in B_IDS:
				var definition:Dictionary=_definition(entry)
				if definition.is_empty():errors.append("invalid B definition "+id)
				else:next_definitions[id]=definition
	if not errors.is_empty():return {"ok":false,"errors":errors}
	registry=next_registry;definitions=next_definitions;slot_caps={"weapons":4,"items":8}
	configuration_open=false
	return {"ok":true,"errors":[]}

static func _definition(entry:Dictionary)->Dictionary:
	if not entry.get("kind") is String or str(entry.kind)!="item":return {}
	if not _whole(entry.get("max_stack"),1) or int(entry.max_stack)!=1:return {}
	if not _whole(entry.get("price"),0):return {}
	if not entry.get("effects") is Dictionary or not entry.effects.is_empty():return {}
	var id:String=entry.id
	var result:Dictionary={}
	var positive_keys:Array=[]
	match id:
		"crossfire_pin":
			if not _whole(entry.get("requires_distinct_weapon_types"),1) or int(entry.requires_distinct_weapon_types)!=2:return {}
			result.requires_distinct_weapon_types=2
			positive_keys=["mark_seconds","pull_distance","cooldown"]
		"salvage_capacitor":
			if not _whole(entry.get("charge_limit"),1) or int(entry.charge_limit)!=3:return {}
			if not _whole(entry.get("field_limit"),1) or int(entry.field_limit)!=2:return {}
			result.charge_limit=3;result.field_limit=2
			positive_keys=["field_radius","field_seconds","field_speed_factor"]
			if not _positive(entry.get("field_speed_factor")) or float(entry.field_speed_factor)>1.0:return {}
		"medic_winch":
			if not _whole(entry.get("pickup_count"),1) or int(entry.pickup_count)!=5:return {}
			if not _whole(entry.get("max_pulls_per_step"),1) or int(entry.max_pulls_per_step)!=1:return {}
			result.pickup_count=5;result.max_pulls_per_step=1
			positive_keys=["medical_range","pull_distance"]
		_:return {}
	for key in positive_keys:
		if not _positive(entry.get(key)):return {}
		result[key]=float(entry[key])
	if id!="crossfire_pin":
		if not entry.get("pickup_sources") is Array or entry.pickup_sources.size()!=1:return {}
		if not entry.pickup_sources[0] is String or str(entry.pickup_sources[0])!="normal":return {}
		result.pickup_sources=["normal"]
	return result

func clear_run(authoritative_epoch:Variant)->bool:
	if not _integer(authoritative_epoch):return false
	configuration_open=true;owned_items={};weapon_counts={};equipped_types=[]
	mark=null;pin_ready_at=null;charges=0;fields=[];next_field_sequence=0;winch_count=0;pending=null
	winch_requested_this_batch=false;bound_epoch=authoritative_epoch;last_sequence=0;last_now=0.0
	last_step_serial=-1;batch_serial=-1;batch_time=0.0;batch_open=false
	return true
func bind_epoch(authoritative_epoch:Variant,now:Variant)->bool:
	if not _integer(authoritative_epoch) or int(authoritative_epoch)<bound_epoch or not _time(now):return false
	if int(authoritative_epoch)>bound_epoch:cancel_pending()
	bound_epoch=int(authoritative_epoch);last_now=float(now)
	return true

static func distinct_weapon_types(weapons:Variant,known:Dictionary)->Dictionary:
	var invalid:Dictionary={"valid":false,"ids":[]}
	if not weapons is Array or weapons.size()>4:return invalid
	var counts:Dictionary={}
	for id in weapons:
		if not id is String or str(id).is_empty() or not known.has(id):return invalid
		var entry:Variant=known[id]
		if not entry is Dictionary or not entry.get("kind") is String or str(entry.kind)!="weapon":return invalid
		if not _integer(entry.get("max_stack"),1):return invalid
		counts[id]=int(counts.get(id,0))+1
		if counts[id]>entry.max_stack:return invalid
	var ids:Array=counts.keys();ids.sort()
	return {"valid":true,"ids":ids}

func sync_build(items:Variant,weapons:Variant,now:Variant)->bool:
	if configuration_open or not _time(now) or not items is Dictionary or items.size()>8:return false
	var normalized_items:Dictionary={}
	for id in items:
		if not id is String or str(id).is_empty() or not registry.has(id):return false
		if str(registry[id].kind)!="item" or not _whole(items[id],1):return false
		if int(items[id])>int(registry[id].max_stack):return false
		normalized_items[id]=int(items[id])
	var types:Dictionary=distinct_weapon_types(weapons,registry)
	if not types.valid:return false
	var counts:Dictionary={}
	for id in weapons:counts[id]=int(counts.get(id,0))+1
	owned_items=normalized_items;weapon_counts=counts;equipped_types=types.ids;last_now=float(now)
	if mark!=null and (not _pin_enabled() or not equipped_types.has(mark.weapon)):_consume_mark(last_now)
	if not owned_items.has("salvage_capacitor"):charges=0;fields=[]
	if not owned_items.has("medic_winch"):winch_count=0;pending=null
	return true
func _pin_enabled()->bool:
	return owned_items.has("crossfire_pin") and not definitions.crossfire_pin.is_empty() and equipped_types.size()>=int(definitions.crossfire_pin.requires_distinct_weapon_types)

func cancel_pending()->void:
	batch_open=false;pending=null;winch_requested_this_batch=false
func reset_encounter(now:Variant)->bool:
	if not _time(now):return false
	last_now=float(now);mark=null;charges=0;fields=[];winch_count=0
	cancel_pending()
	return true
func begin_step(now:Variant,serial:Variant,enemies:Variant,area:Variant)->bool:
	if configuration_open or bound_epoch<0 or not _time(now) or not _integer(serial) or int(serial)<=last_step_serial:return false
	if not enemies is Array or not area is Dictionary:return false
	last_now=float(now);last_step_serial=int(serial);batch_serial=int(serial);batch_time=last_now
	batch_open=true;pending=null;winch_requested_this_batch=false
	var alive_fields:Array=[]
	for field in fields:
		if _number(field.get("expires")) and float(field.expires)>last_now and _vector(field.get("pos")):alive_fields.append(field)
	fields=alive_fields
	_housekeep_pin(last_now,enemies)
	return true

static func _target(id:Variant,enemies:Array)->Dictionary:
	if not _integer(id,1):return {}
	var found:Dictionary={}
	var matches:=0
	for value in enemies:
		if not value is Dictionary:continue
		if not _integer(value.get("id"),1) or int(value.id)!=int(id):continue
		matches+=1;found=value
	if matches!=1:return {}
	if not _positive(found.get("hp")) or not found.get("boss") is bool or bool(found.boss):return {}
	if not _vector(found.get("pos")):return {}
	return found
func _consume_mark(now:float)->bool:
	mark=null
	if definitions.crossfire_pin.is_empty():return false
	var future:Variant=_future(now,float(definitions.crossfire_pin.cooldown))
	if future==null:return false
	pin_ready_at=float(future)
	return true
func _housekeep_pin(now:float,enemies:Array)->bool:
	if mark==null:return false
	if not _pin_enabled() or not equipped_types.has(mark.weapon) or not _number(mark.expires) or now>=float(mark.expires) or _target(mark.target_id,enemies).is_empty():
		_consume_mark(now)
		return true
	return false

func _context(context:Variant,allow_nonplaying:bool=false)->bool:
	if not context is Dictionary:return false
	if not context.get("playing") is bool:return false
	if not allow_nonplaying and not bool(context.playing):return false
	if not _time(context.get("time")) or not _integer(context.get("effect_epoch")) or int(context.effect_epoch)!=bound_epoch:return false
	if not _integer(context.get("step_serial")) or not _vector(context.get("player_pos")):return false
	if not context.get("dash_active") is bool or not context.get("enemies") is Array or not context.get("area") is Dictionary:return false
	return true
func _admitted(event:Variant,context:Variant)->bool:
	if configuration_open or bound_epoch<0 or not _context(context) or not event is Dictionary:return false
	if not event.get("kind") is String or not event.get("source") is String or not event.get("depth") is int:return false
	if not _integer(event.get("epoch")) or int(event.epoch)!=bound_epoch:return false
	if not _integer(event.get("sequence"),1) or int(event.sequence)<=last_sequence:return false
	if str(event.kind)=="hit" and (not event.get("weapon") is String or not event.get("target") is int):return false
	if str(event.kind)=="dash" and not _vector(event.get("pos")):return false
	return true
func process(event:Variant,context:Variant)->Array:
	if not _admitted(event,context):return []
	last_sequence=int(event.sequence);last_now=float(context.time)
	var kind:String=event.kind
	if kind in ["hit","pickup"] and (not batch_open or int(context.step_serial)!=batch_serial or float(context.time)!=batch_time):return []
	var cleared_mark:bool=_housekeep_pin(last_now,context.enemies)
	if int(event.depth)!=0:return []
	match kind:
		"hit":
			if str(event.source)!="primary" or not _pin_enabled() or cleared_mark:return []
			var weapon:String=event.weapon
			if weapon.is_empty() or not equipped_types.has(weapon) or not registry.has(weapon):return []
			var enemy:Dictionary=_target(event.target,context.enemies)
			if enemy.is_empty():return []
			if mark!=null:
				if int(mark.target_id)!=int(event.target) or str(mark.weapon)==weapon:return []
				var anchor:Vector2=mark.position
				if not _consume_mark(last_now):return []
				return [{"kind":"pin_pull","target_id":int(event.target),"anchor":anchor,"distance":float(definitions.crossfire_pin.pull_distance),"source_item":"crossfire_pin"}]
			if pin_ready_at!=null and last_now<float(pin_ready_at):return []
			var expires:Variant=_future(last_now,float(definitions.crossfire_pin.mark_seconds))
			if expires==null:return []
			mark={"target_id":int(event.target),"weapon":weapon,"position":enemy.pos,"expires":float(expires)}
		"pickup":
			if str(event.source)!="normal":return []
			if owned_items.has("salvage_capacitor") and not definitions.salvage_capacitor.is_empty():charges=mini(int(definitions.salvage_capacitor.charge_limit),charges+1)
			if owned_items.has("medic_winch") and not definitions.medic_winch.is_empty():
				winch_count+=1
				if winch_count>=int(definitions.medic_winch.pickup_count):
					winch_count=0
					if not winch_requested_this_batch:
						winch_requested_this_batch=true
						pending={"origin":context.player_pos,"serial":batch_serial,"time":batch_time}
		"dash":
			if str(event.source)!="primary" or not bool(context.dash_active):return []
			if not owned_items.has("salvage_capacitor") or definitions.salvage_capacitor.is_empty():return []
			var profile:Dictionary=definitions.salvage_capacitor
			if charges<int(profile.charge_limit):return []
			charges=0
			if not _area(context.area):return []
			var expires:Variant=_future(last_now,float(profile.field_seconds))
			if expires==null or next_field_sequence==9223372036854775807:return []
			next_field_sequence+=1
			if fields.size()>=int(profile.field_limit):fields.pop_front()
			fields.append({"pos":event.pos,"expires":float(expires),"sequence":next_field_sequence})
			return [{"kind":"salvage_field_created","sequence":next_field_sequence,"pos":event.pos,"radius":float(profile.field_radius),"expires":float(expires),"source_item":"salvage_capacitor"}]
	return []

func movement_factor(enemy:Variant,now:Variant,area:Variant)->float:
	if configuration_open or not _time(now) or not _area(area) or not enemy is Dictionary:return 1.0
	if not owned_items.has("salvage_capacitor") or definitions.salvage_capacitor.is_empty():return 1.0
	if not _positive(enemy.get("hp")) or not enemy.get("boss") is bool or bool(enemy.boss):return 1.0
	if not enemy.get("ai_state") is String or str(enemy.ai_state) not in ["move","warning","recover"] or not _vector(enemy.get("pos")):return 1.0
	var radius:float=definitions.salvage_capacitor.field_radius
	var radius_squared:float=radius*radius
	if not is_finite(radius_squared):return 1.0
	for field in fields:
		if float(now)>=float(field.expires):continue
		var distance_squared:float=enemy.pos.distance_squared_to(field.pos)
		if is_finite(distance_squared) and distance_squared<=radius_squared:return float(definitions.salvage_capacitor.field_speed_factor)
	return 1.0

func apply_control(command:Variant,enemies:Variant,area:Variant)->Dictionary:
	var failure:Dictionary={"moved":false,"target_id":-1,"from":Vector2.ZERO,"to":Vector2.ZERO,"reason":"invalid control"}
	if configuration_open or not command is Dictionary or not enemies is Array or not _area(area):return failure
	if not command.get("kind") is String or str(command.kind)!="pin_pull" or not _integer(command.get("target_id"),1):return failure
	if not command.get("source_item") is String or str(command.source_item)!="crossfire_pin":return failure
	if not _vector(command.get("anchor")) or not _positive(command.get("distance")):return failure
	var enemy:Dictionary=_target(command.target_id,enemies)
	if enemy.is_empty():return failure
	var origin:Vector2=enemy.pos
	var anchor:Vector2=command.anchor
	var old_distance:float=origin.distance_to(anchor)
	if not is_finite(old_distance):return failure
	var candidate:Vector2=origin.move_toward(anchor,float(command.distance)).clamp(Vector2(20,20),Vector2(float(area.width)-20,float(area.height)-20))
	if not _vector(candidate):return failure
	var moved_distance:float=origin.distance_to(candidate)
	var new_distance:float=candidate.distance_to(anchor)
	if not is_finite(moved_distance) or not is_finite(new_distance):return failure
	if moved_distance>float(command.distance)+MOTION_EPSILON or new_distance>old_distance+MOTION_EPSILON:return failure
	if moved_distance==0.0 or (old_distance==0.0 and candidate!=origin):return failure
	enemy.pos=candidate
	return {"moved":true,"target_id":int(command.target_id),"from":origin,"to":candidate,"reason":"moved"}

func flush_pickups(context:Variant,pickups:Variant)->Dictionary:
	var result:Dictionary={"accepted":false,"moved_index":-1,"reason":"invalid batch"}
	if configuration_open or not pickups is Array or not _context(context,true) or not batch_open:return result
	if int(context.step_serial)!=batch_serial or float(context.time)!=batch_time:return result
	batch_open=false
	var request:Variant=pending
	pending=null
	result.accepted=true;result.reason="no movement"
	if not bool(context.playing) or request==null or not _area(context.area):return result
	if not owned_items.has("medic_winch") or definitions.medic_winch.is_empty():return result
	var origin:Vector2=request.origin
	var profile:Dictionary=definitions.medic_winch
	var reach_squared:float=float(profile.medical_range)*float(profile.medical_range)
	if not is_finite(reach_squared):return result
	var selected:=-1
	var nearest:=INF
	for i in range(pickups.size()):
		var pickup:Variant=pickups[i]
		if not pickup is Dictionary or not pickup.get("source") is String or str(pickup.source)!="medical" or not _vector(pickup.get("pos")):continue
		var distance_squared:float=pickup.pos.distance_squared_to(origin)
		if not is_finite(distance_squared) or distance_squared>reach_squared:continue
		if distance_squared<nearest:nearest=distance_squared;selected=i
	if selected<0:return result
	var before:Vector2=pickups[selected].pos
	var after:Vector2=before.move_toward(origin,float(profile.pull_distance))
	if not _vector(after) or before==after:return result
	pickups[selected].pos=after
	result.moved_index=selected;result.reason="moved"
	return result

func debug_snapshot()->Dictionary:
	return {"configuration_open":configuration_open,"registry":registry,"slot_caps":slot_caps,"definitions":definitions,"owned_items":owned_items,"weapon_counts":weapon_counts,"equipped_types":equipped_types,"mark":mark,"pin_ready_at":pin_ready_at,"charges":charges,"fields":fields,"next_field_sequence":next_field_sequence,"winch_count":winch_count,"pending":pending,"winch_requested_this_batch":winch_requested_this_batch,"bound_epoch":bound_epoch,"last_sequence":last_sequence,"last_now":last_now,"last_step_serial":last_step_serial,"batch_serial":batch_serial,"batch_time":batch_time,"batch_open":batch_open}.duplicate(true)
