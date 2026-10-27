extends RefCounted
const EnemySupport=preload("res://scripts/gameplay/enemy_support.gd")
## Survival policy. Only this module knows timed waves, random ring spawning and mandatory bosses.
var id:="arena"
var name:="ARENA SURVIVAL"
var spawn_clock:=0.0
var refresh_field_between_stages:=false
func reset()->void:spawn_clock=0.0
func begin_stage(_stage:int)->void:pass # Arena retains the existing spawn cadence across its shop boundary.
func field(base:Dictionary)->Dictionary:return base.duplicate(true)
func count(config:Dictionary)->int:return int(config.waves.count)
func boss_id(stage:int,encounters:Dictionary)->String:return encounters.waves[mini(stage-1,encounters.waves.size()-1)].boss
func boss_request(session:RefCounted,world:RefCounted,area:Dictionary,encounters:Dictionary)->Dictionary:
	var kind:=boss_id(session.wave,encounters)
	if kind=="" or session.boss_spawned:return {}
	var pos:Vector2=world.player_pos+Vector2(360,0)
	pos=pos.clamp(Vector2(80,80),Vector2(area.width-80,area.height-80))
	if pos.distance_to(world.player_pos)<220:pos=world.player_pos-Vector2(360,0)
	return {"kind":kind,"pos":pos,"boss":true}
func regular_request(session:RefCounted,world:RefCounted,config:Dictionary,encounters:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	if world.enemies.size()>=int(config.waves.max_enemies):return {}
	var pos:Vector2=world.player_pos+Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(330,440)
	pos=pos.clamp(Vector2(20,20),Vector2(config.arena.width-20,config.arena.height-20))
	if pos.distance_to(world.player_pos)<180:return {}
	var pool:Array=encounters.waves[mini(session.wave-1,encounters.waves.size()-1)].pool
	var support_rows:Dictionary={}
	for entry in encounters.get("enemies",[]):
		if entry is Dictionary and entry.get("behavior")=="support_repair":support_rows[entry.get("id","")]=entry
	if pool.any(func(kind):return support_rows.has(kind)):
		var known:Array=encounters.enemies.map(func(entry):return entry.id)
		for kind in pool:
			if not kind is String or kind not in known:return {}
		var eligible:Array=[]
		for kind in pool:
			if not support_rows.has(kind):eligible.append(kind);continue
			var row:Dictionary=support_rows[kind]
			if not EnemySupport.validate_entry(row).is_empty():return {}
			var living:int=world.enemies.filter(func(e):return e.get("kind")==kind and e.get("hp",0)>0).size()
			if living<int(row.support_max_alive):eligible.append(kind)
		if eligible.is_empty():return {}
		pool=eligible
	if pool.is_empty():return {}
	return {"kind":pool[rng.randi_range(0,pool.size()-1)],"pos":pos}
func tick_spawn(dt:float,session:RefCounted,config:Dictionary)->bool:
	spawn_clock-=dt
	if spawn_clock>0:return false
	spawn_clock=maxf(.13,float(config.waves.spawn_interval)/(1.0+session.wave*.3))
	return true
func acknowledge(_request:Dictionary,_spawned:Dictionary)->void:pass
func advance_clear(_dt:float,_world:RefCounted)->void:pass
func can_end(session:RefCounted,_world:RefCounted,encounters:Dictionary)->bool:
	return boss_id(session.wave,encounters)=="" or session.boss_defeated
func is_due(session:RefCounted,_world:RefCounted,config:Dictionary)->bool:return session.wave_time>=float(config.waves.duration)
func objective(session:RefCounted,_world:RefCounted,config:Dictionary)->String:
	return "SURVIVE %.0fs · mandatory bosses must fall"%maxf(0,float(config.waves.duration)-session.wave_time)
func progress()->float:return -1.0

func wants_clear_pause(_world:RefCounted)->bool:return false

func resolution(session:RefCounted,world:RefCounted,config:Dictionary)->Dictionary:
	var terminal:bool=session.wave>=count(config)
	var next_stage:int=session.wave if terminal else session.wave+1
	return {"terminal":terminal,"next_stage":next_stage,"shop":not terminal,"upgrades":0 if terminal else 1,"coins":0 if terminal else 15+next_stage*3,"heal":0 if terminal else world.stats.wave_heal}
