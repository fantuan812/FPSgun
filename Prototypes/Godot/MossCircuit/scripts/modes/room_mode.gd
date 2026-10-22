extends RefCounted
## A finite roster, not a timed wave with a new label. Includes summoned living enemies in clear guard.
var id:="rooms"
var name:="ROOM ENCOUNTERS · PROTOTYPE"
var spawn_clock:=0.0
var refresh_field_between_stages:=true
var profile:Dictionary
var planned_index:=0
var planned_count:=0
var clear_elapsed:=0.0
func _init(data:Dictionary)->void:profile=data.duplicate(true)
func reset()->void:
	planned_index=0;planned_count=0;clear_elapsed=0;spawn_clock=0
func begin_stage(stage:int)->void:
	reset()
	planned_count=profile.stages[clampi(stage-1,0,profile.stages.size()-1)].enemies.size()
func field(_base:Dictionary)->Dictionary:return profile.field.duplicate(true)
func count(_config:Dictionary)->int:return profile.stages.size()
func boss_id(_stage:int,_encounters:Dictionary)->String:return ""
func boss_request(_session:RefCounted,_world:RefCounted,_area:Dictionary,_encounters:Dictionary)->Dictionary:return {}
func regular_request(session:RefCounted,_world:RefCounted,config:Dictionary,_encounters:Dictionary,_rng:RandomNumberGenerator)->Dictionary:
	var roster:Array=profile.stages[clampi(session.wave-1,0,profile.stages.size()-1)].enemies
	planned_count=roster.size()
	if planned_index>=planned_count:return {}
	var entry:Dictionary=roster[planned_index]
	return {"kind":entry.kind,"pos":Vector2(entry.at[0]*config.arena.width,entry.at[1]*config.arena.height),"plan_index":planned_index}
func tick_spawn(dt:float,_session:RefCounted,_config:Dictionary)->bool:
	spawn_clock-=dt
	if spawn_clock>0:return false
	spawn_clock=float(profile.spawn_interval)
	return true
func acknowledge(request:Dictionary,spawned:Dictionary)->void:
	if not spawned.is_empty() and request.get("plan_index",-1)==planned_index:planned_index+=1
func advance_clear(dt:float,world:RefCounted)->void:
	if planned_count>0 and planned_index>=planned_count and world.enemies.is_empty():clear_elapsed+=dt
	else:clear_elapsed=0
func can_end(_session:RefCounted,world:RefCounted,_encounters:Dictionary)->bool:
	return planned_count>0 and planned_index>=planned_count and world.enemies.is_empty() and clear_elapsed>=float(profile.clear_delay)
func is_due(session:RefCounted,world:RefCounted,_config:Dictionary)->bool:return can_end(session,world,{})
func objective(session:RefCounted,world:RefCounted,_config:Dictionary)->String:
	if clear_elapsed>0:return "ROOM CLEAR · automatic transition"
	return "%s · clear all enemies (%d alive / %d queued)"%[profile.stages[clampi(session.wave-1,0,profile.stages.size()-1)].name,world.enemies.size(),maxi(0,planned_count-planned_index)]
func progress()->float:return clampf(clear_elapsed/float(profile.clear_delay),0,1)

func wants_clear_pause(world:RefCounted)->bool:
	return planned_count>0 and planned_index>=planned_count and world.enemies.is_empty()

const MAX_FIELD_AXIS=65536.0
const MAX_FIELD_CELLS=4096
static func number(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))
static func validate(data:Dictionary,encounters:Dictionary)->Array:
	var errors:Array=[]
	var area:Dictionary=data.get("field",{}) if data.get("field",{}) is Dictionary else {}
	for key in ["width","height","tile_size"]:
		if not number(area.get(key)):errors.append("field."+key+" must be finite numeric")
		elif float(area[key])<(1 if key=="tile_size" else 48):errors.append("field."+key+" bounds")
		elif float(area[key])>MAX_FIELD_AXIS:errors.append("field."+key+" exceeds prototype axis budget")
	if errors.is_empty():
		var columns:float=ceilf(float(area.width)/float(area.tile_size))
		var rows:float=ceilf(float(area.height)/float(area.tile_size))
		if columns*rows>MAX_FIELD_CELLS:errors.append("field exceeds 4096 cell allocation budget")
	for key in ["spawn_interval","clear_delay"]:
		if not number(data.get(key)):errors.append(key+" must be finite numeric")
		elif float(data[key])<0.001 or float(data[key])>3600:errors.append(key+" bounds")
	var grant:Dictionary=data.get("reward",{}) if data.get("reward",{}) is Dictionary else {}
	for key in ["coins","heal","upgrades"]:
		if not number(grant.get(key)):errors.append("reward."+key+" must be finite numeric")
		elif float(grant[key])<(1 if key=="upgrades" else 0) or float(grant[key])>(100 if key=="upgrades" else 1000000):errors.append("reward."+key+" bounds")
	if number(grant.get("upgrades")) and float(grant.upgrades)!=floorf(float(grant.upgrades)):errors.append("reward.upgrades must be integral")
	if not data.get("stages") is Array or data.get("stages",[]).is_empty():
		errors.append("stages");return errors
	var known:Array=encounters.get("enemies",[]).map(func(entry):return entry.id)
	for stage in data.stages:
		if not stage is Dictionary:errors.append("stage object");continue
		if not stage.get("name") is String or stage.get("name","").strip_edges().is_empty():errors.append("stage.name")
		if not stage.get("enemies") is Array or stage.get("enemies",[]).is_empty():
			errors.append("empty stage");continue
		for enemy in stage.enemies:
			if not enemy is Dictionary:errors.append("enemy");continue
			if enemy.get("kind","") not in known:errors.append("unknown enemy")
			var at=enemy.get("at")
			if not at is Array or at.size()!=2:errors.append("position");continue
			for value in at:
				if not number(value):errors.append("position must be finite numeric")
				elif float(value)<0 or float(value)>1:errors.append("position bounds")
	return errors
func resolution(session:RefCounted,_world:RefCounted,config:Dictionary)->Dictionary:
	var terminal:bool=session.wave>=count(config)
	return {"terminal":terminal,"next_stage":session.wave if terminal else session.wave+1,"shop":not terminal,"upgrades":0 if terminal else int(profile.reward.upgrades),"coins":0 if terminal else profile.reward.coins,"heal":0 if terminal else profile.reward.heal}
