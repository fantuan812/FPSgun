extends RefCounted
## Enemy-only repair authority. No RNG, Nodes, callbacks, player settlement or damage changes.
const KIND := "stitch_drone"
const BEHAVIOR := "support_repair"
const LIMITS := {"support_radius":[1.0,1000.0],"support_channel":[.05,60.0],"support_cooldown":[.05,60.0],"support_retry":[.05,60.0],"support_heal":[0.0,1000.0],"support_max_alive":[1.0,4.0]}

static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func point(value:Variant)->bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y)

static func validate_entry(entry:Dictionary)->Array:
	if entry.get("behavior") != BEHAVIOR:return []
	var errors:Array=[]
	if not entry.get("boss") is bool or entry.boss:errors.append("Support must be ordinary")
	for key in LIMITS:
		var value:Variant=entry.get(key)
		if not number(value):errors.append("Invalid support number " + key);continue
		if value < LIMITS[key][0] or value > LIMITS[key][1] or (key=="support_heal" and value<=0):errors.append("Support bounds " + key)
		if key=="support_max_alive" and float(value)!=floorf(float(value)):errors.append("Support cap must be integral")
	return errors

static func _identity(actor:Dictionary)->bool:
	return actor.get("id") is int and actor.id>0

static func _identities(enemies:Array)->bool:
	var seen:Dictionary={}
	for value in enemies:
		if not value is Dictionary or not _identity(value) or seen.has(value.id):return false
		seen[value.id]=true
	return true

static func _base(actor:Dictionary)->bool:
	return _identity(actor) and actor.get("kind") is String and actor.get("behavior") is String and actor.get("boss") is bool and actor.get("parent_id") is int and point(actor.get("pos")) and number(actor.get("hp")) and number(actor.get("max_hp")) and actor.max_hp>0

static func _source_kind(actor:Dictionary)->bool:
	return actor.get("kind")==KIND and actor.get("behavior")==BEHAVIOR

static func _source(actor:Dictionary)->bool:
	if not _base(actor) or not _source_kind(actor) or actor.boss or actor.parent_id!=-1 or actor.hp<=0:return false
	if not validate_entry(actor).is_empty():return false
	if not actor.get("ai_state") in ["move","warning","recover"]:return false
	for key in ["cooldown_left","warning_left","recover_left","support_start_hp"]:
		if not number(actor.get(key)):return false
	return actor.get("support_target_id") is int and actor.get("support_due") is bool and actor.get("support_cancel_pending") is Dictionary and point(actor.get("support_target_pos")) and (actor.get("support_channel_token")==null or actor.get("support_channel_token") is RefCounted)

static func _recipient(source:Dictionary,target:Dictionary)->bool:
	return _base(target) and target.id!=source.id and not target.boss and target.parent_id==-1 and target.kind!=KIND and target.behavior!=BEHAVIOR and target.hp>0 and target.hp<target.max_hp and number(target.get("anim_hp")) and source.pos.distance_squared_to(target.pos)<=float(source.support_radius)*float(source.support_radius)

static func _find(enemies:Array,id:int)->Dictionary:
	for value in enemies:
		if value is Dictionary and value.get("id")==id:return value
	return {}

static func _sources(enemies:Array)->Array:
	var result:Array=[]
	for value in enemies:
		if value is Dictionary and _source_kind(value):result.append(value)
	result.sort_custom(func(a,b):return int(a.get("id",0))<int(b.get("id",0)))
	return result

static func select_target(source:Dictionary,enemies:Array)->int:
	if not _identities(enemies) or not _source(source):return -1
	if _find(enemies,source.id).is_empty():return -1
	var chosen:Dictionary={}
	for target in enemies:
		if not _recipient(source,target):continue
		if chosen.is_empty():chosen=target;continue
		var ratio:float=float(target.hp)/float(target.max_hp)
		var old_ratio:float=float(chosen.hp)/float(chosen.max_hp)
		var distance:float=source.pos.distance_squared_to(target.pos)
		var old_distance:float=source.pos.distance_squared_to(chosen.pos)
		if ratio<old_ratio or (ratio==old_ratio and (distance<old_distance or (distance==old_distance and target.id<chosen.id))):chosen=target
	return -1 if chosen.is_empty() else int(chosen.id)

static func can_repair(source:Dictionary,target:Dictionary)->bool:
	return _source(source) and source.ai_state=="warning" and source.support_target_id>0 and source.support_start_hp>0 and source.support_channel_token is RefCounted and _recipient(source,target) and target.id==source.support_target_id and source.hp>=source.support_start_hp

static func initialize(source:Dictionary)->void:
	source.support_target_id=-1
	source.support_start_hp=0.0
	source.support_due=false
	source.support_cancel_pending={}
	source.support_target_pos=source.pos
	source.support_channel_token=null
	source.support_max_alive=int(source.support_max_alive)

static func _clear(source:Dictionary)->void:
	source.support_target_id=-1
	source.support_start_hp=0.0
	source.support_due=false
	source.support_channel_token=null

static func _discard(source:Dictionary)->void:
	_clear(source)
	source.support_cancel_pending={}
	if source.get("ai_state")=="warning":source.ai_state="move"

static func _finish(source:Dictionary)->void:
	_clear(source)
	source.ai_state="recover"
	source.recover_left=.7
	source.cooldown_left=float(source.support_cooldown)

static func _cancel(source:Dictionary,target:Dictionary)->void:
	var endpoint:Variant=target.get("pos",source.get("support_target_pos"))
	if not point(endpoint):endpoint=source.get("support_target_pos")
	var record:Dictionary={}
	if number(source.get("hp")) and source.hp>0 and point(source.get("pos")) and point(endpoint):
		record={"source_id":source.id,"target_id":source.support_target_id,"kind":"cancel","amount":0.0,"source_pos":source.pos,"target_pos":endpoint}
	_finish(source)
	source.support_cancel_pending=record

static func advance(enemies:Array,dt:float,playing:bool)->Array:
	var due:Array=[]
	if not is_finite(dt) or dt<0:return due
	if not _identities(enemies):return due
	for source in _sources(enemies):
		if not playing or not _source(source):_discard(source);continue
		if source.ai_state=="warning":
			var target:Dictionary=_find(enemies,source.support_target_id)
			if not can_repair(source,target):_cancel(source,target);continue
			source.support_target_pos=target.pos
			source.warning_left-=dt
			if source.warning_left<=0:
				source.support_due=true
				due.append({"source_id":source.id,"channel_token":source.support_channel_token})
			continue
		source.cooldown_left-=dt
		if source.ai_state=="recover":
			source.recover_left-=dt
			if source.recover_left<=0:source.ai_state="move"
			continue
		if source.cooldown_left>0:continue
		var selected:int=select_target(source,enemies)
		if selected<0:source.cooldown_left=float(source.support_retry);continue
		var target:Dictionary=_find(enemies,selected)
		source.ai_state="warning"
		source.support_target_id=selected
		source.support_target_pos=target.pos
		source.support_start_hp=float(source.hp)
		source.support_channel_token=RefCounted.new()
		source.support_due=false
		source.support_cancel_pending={}
		source.warning_left=float(source.support_channel)
	return due

static func _drain(source:Dictionary,records:Array,playing:bool)->void:
	var pending:Variant=source.get("support_cancel_pending",{})
	if pending is Dictionary and not pending.is_empty() and playing and number(source.get("hp")) and source.hp>0:
		records.append(pending.duplicate(true))
	source.support_cancel_pending={}

static func settle(enemies:Array,due_tickets:Array,playing:bool)->Array:
	var records:Array=[]
	if not _identities(enemies):return records
	for source in _sources(enemies):
		if not playing or not _source(source):_discard(source);continue
		_drain(source,records,playing)
		if source.ai_state!="warning":continue
		var target:Dictionary=_find(enemies,source.support_target_id)
		if not can_repair(source,target):
			_cancel(source,target)
			_drain(source,records,playing)
			continue
		source.support_target_pos=target.pos
		if not source.support_due or source.warning_left>0:continue
		var authentic:=false
		for ticket in due_tickets:
			if ticket is Dictionary and ticket.get("source_id") is int and ticket.source_id==source.id and ticket.get("channel_token") is RefCounted and ticket.channel_token==source.support_channel_token:authentic=true;break
		if not authentic:continue
		var before:float=target.hp
		target.hp=minf(float(target.max_hp),float(target.hp)+float(source.support_heal))
		target.anim_hp=target.hp # Preserve current animation; reset only next damage baseline.
		var record:Dictionary={"source_id":source.id,"target_id":target.id,"kind":"complete","amount":target.hp-before,"source_pos":source.pos,"target_pos":target.pos}
		_finish(source)
		records.append(record)
	return records
