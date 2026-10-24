extends RefCounted
## Pure presentation: authoritative AI/weapon events supply phase, never the reverse.
var actors: Dictionary = {}
var assets: Dictionary = {}
var config: Dictionary = {}
var corpses: Array = []
var reduced_flashes := false
var generation := 0
var socket_data:Dictionary={}
func load_default() -> void:
	assets.clear()
	socket_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/hero_sockets.json"))
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/actor_actions.json"))
	if not FileAccess.file_exists(config.manifest): return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.manifest))
	var modular_path:String=config.get("hero_modular_manifest","")
	manifest.actions.erase("hero_attack") # Never fall back to a baked weapon, even with an empty override.
	if FileAccess.file_exists(modular_path):
		var modular:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(modular_path))
		manifest.actions.merge(modular.get("actions",{}),true)
	for extra_path in config.get("additional_manifests",[]):
		if FileAccess.file_exists(extra_path):
			var extra=JSON.parse_string(FileAccess.get_file_as_string(extra_path))
			if extra is Dictionary and extra.get("actions") is Dictionary:
				for id in extra.actions:
					if not manifest.actions.has(id):manifest.actions[id]=extra.actions[id]
	for id in manifest.get("actions",{}):
		var asset=manifest.actions[id]
		if not asset is Dictionary or not asset.get("path") is String:continue
		if not ResourceLoader.exists(asset.path):continue
		var source=load(asset.path)
		if not source is Texture2D or not valid_records(asset.get("frames"),source.get_size()):continue
		var count:int=asset.frames.size()
		var frames:=SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("action")
		frames.set_animation_loop("action",false)
		for record in asset.frames:
			var atlas:=AtlasTexture.new()
			atlas.atlas=source
			atlas.region=Rect2(record.region[0],record.region[1],record.region[2],record.region[3])
			var padding:Array=record.get("margin",[0,0,0,0])
			atlas.margin=Rect2(padding[0],padding[1],padding[2],padding[3])
			atlas.filter_clip=true
			frames.add_frame("action",atlas)
		var box:Array=asset.frames[0].get("alpha_bbox",[0,0,asset.frames[0].region[2],asset.frames[0].region[3]])
		assets[id]={"records":asset.frames,"frames":frames,"anchor":asset.get("anchor",[.5,.8]),"reference_height":asset.get("reference_height",box[3]),"release_frame":clampi(int(asset.get("release_frame",4)),1,count-1)}
func register_actor(key:int,sprite:AnimatedSprite2D,profile:String,height:float) -> void:
	var first:AtlasTexture=sprite.sprite_frames.get_frame_texture("walk",0) as AtlasTexture
	var foot:=Vector2(0,height*.5)
	if first!=null:
		height=first.region.size.y*absf(sprite.scale.y)
		foot=(first.margin.position+Vector2(first.region.size.x*.5,first.region.size.y)-first.get_size()*.5+sprite.offset)*sprite.scale
	actors[key]={"sprite":sprite,"profile":profile,"height":height,"base_foot":foot,"base_frames":sprite.sprite_frames,"base_scale":sprite.scale,"base_offset":sprite.offset,"base_color":sprite.modulate,"base_flip":sprite.flip_h,"state":"idle","reaction":"","age":0.0,"duration":0.0,"phase":"idle","phase_progress":0.0,"recover_span":0.0,"walk_time":0.0,"corpse":false,"generation":generation,"source":"reused walk/idle"}
	sprite.stop()
	_present(actors[key])
func set_phase(key:int,phase:String,progress:float=0) -> void:
	if not actors.has(key) or actors[key].corpse:return
	actors[key].phase=phase
	actors[key].phase_progress=clampf(progress,0,1)
	_present(actors[key])
func trigger(key:int,action:String,duration:float=-1) -> bool:
	if not actors.has(key):return false
	var actor:Dictionary=actors[key]
	if actor.reaction=="death":return false
	if action=="attack" and config.profiles.get(actor.profile,{}).get("phase_driven_attack",false):return false
	var priority:Dictionary={"":0,"attack":1,"dash":2,"hurt":3,"death":4}
	if not priority.has(action):return false
	if priority.get(actor.reaction,0)>priority[action]:return false
	if actor.reaction==action and (action=="hurt" or (action=="attack" and actor.age<.08)):return false
	actor.reaction=action;actor.age=0.0
	actor.duration=float(config.durations.get(action,.3)) if duration<0 else maxf(.001,duration)
	_present(actor)
	return true
func die(key:int) -> void:
	if not actors.has(key) or actors[key].corpse:return
	trigger(key,"death")
	actors[key].corpse=true
	if key!=0:
		corpses.append(key)
		while corpses.size()>int(config.corpse_cap):forget(corpses[0],true)
func forget(key:int,free_sprite:bool=false) -> void:
	if not actors.has(key):return
	if free_sprite and is_instance_valid(actors[key].sprite):actors[key].sprite.queue_free()
	actors.erase(key);corpses.erase(key)
func clear(keep_hero:bool=true,preserve_corpses:bool=false) -> void:
	for key in actors.keys():
		if preserve_corpses and key in corpses:continue
		if key!=0 or not keep_hero:forget(key,key!=0)
	if not preserve_corpses:corpses.clear()
	generation+=1
	if actors.has(0):
		var actor:Dictionary=actors[0]
		actor.reaction="";actor.corpse=false;actor.age=0.0;actor.duration=0.0;actor.phase="idle";actor.phase_progress=0.0;actor.walk_time=0.0;actor.generation=generation
		actor.recover_span=0.0
		actor.sprite.flip_h=actor.base_flip
		_present(actor)
func advance(dt:float,death_only:bool=false) -> void:
	for key in actors.keys():
		var actor:Dictionary=actors[key]
		if not is_instance_valid(actor.sprite):forget(key);continue
		if death_only and not actor.corpse:continue
		actor.walk_time+=dt
		if actor.reaction!="":
			actor.age+=maxf(0,dt)
			if actor.age>=actor.duration:
				if actor.reaction=="death":
					if key!=0:forget(key,true);continue
					actor.age=actor.duration
				else:actor.reaction=""
		_present(actor)
func state_of(key:int) -> String:
	return actors[key].state if actors.has(key) else "idle"
func _present(actor:Dictionary) -> void:
	var sprite:AnimatedSprite2D=actor.sprite
	var state:String=actor.reaction if actor.reaction!="" else actor.phase
	actor.state=state
	var profile:Dictionary=config.profiles.get(actor.profile,{})
	var action:String="attack" if state in ["warning","recover","attack"] else state
	var id:String=profile.get(action,"")
	actor.asset_id=id if assets.has(id) else ""
	var progress:float=clampf(actor.age/maxf(.001,actor.duration),0,1) if actor.reaction!="" else actor.phase_progress
	sprite.stop();sprite.rotation=0;sprite.modulate=actor.base_color
	if id!="" and assets.has(id):
		var asset:Dictionary=assets[id]
		sprite.sprite_frames=asset.frames;sprite.animation="action"
		var count:int=asset.frames.get_frame_count("action")
		var index:int=mini(count-1,floori(progress*count+.0000001))
		if state=="warning":index=mini(asset.release_frame-1,floori(progress*asset.release_frame+.0000001))
		elif state=="attack":index=asset.release_frame+mini(count-1-asset.release_frame,floori(progress*(count-asset.release_frame)+.0000001))
		elif state=="recover":index=count-1
		var phase_frames=profile.get("phase_frames",{})
		if phase_frames is Dictionary and phase_frames.has(state):
			var segment=phase_frames[state]
			if valid_segment(segment,count):
				index=int(segment[0])+mini(int(segment[1]-segment[0]),floori(progress*(segment[1]-segment[0]+1)+.0000001))
		sprite.frame=index
		var texture:Texture2D=asset.frames.get_frame_texture("action",0)
		var scale_value:float=actor.height/maxf(1,asset.reference_height)
		sprite.scale=Vector2.ONE*scale_value
		sprite.offset=texture.get_size()*(Vector2(.5,.5)-Vector2(asset.anchor[0],asset.anchor[1]))+actor.base_foot/scale_value
		actor.source="authored nine-frame" if count==9 else "authored %d-frame"%count
	else:
		sprite.sprite_frames=actor.base_frames;sprite.animation="walk" if state=="move" else "idle"
		sprite.frame=int(actor.walk_time*9)%9 if state=="move" else 0
		sprite.scale=actor.base_scale;sprite.offset=actor.base_offset
		actor.source="reused walk/idle" if state in ["move","idle"] else "shared procedural"
		match state:
			"warning":sprite.scale*=Vector2(1+progress*.10,1-progress*.12)
			"attack":
				var pulse:float=sin(progress*PI)
				sprite.scale*=Vector2(1+.18*pulse,1-.12*pulse)
				sprite.rotation=(.12 if sprite.flip_h else -.12)*pulse
			"recover":sprite.scale*=Vector2(1.04,.96)
			"hurt":sprite.rotation=sin(progress*TAU)*.13
			"death":
				sprite.rotation=progress*.65
				sprite.scale*=Vector2(1+.2*progress,1-.65*progress)
				sprite.modulate.a=1-progress
	if state=="hurt" and not reduced_flashes:
		sprite.modulate=sprite.modulate.lerp(Color(1.45,1.45,1.45,sprite.modulate.a),.55*(1-progress))

func refresh_style() -> void:
	for actor in actors.values():_present(actor)

func socket_world(key:int,name:String="grip")->Vector2:
	if not actors.has(key):return Vector2.ZERO
	var actor:Dictionary=actors[key]
	var sprite:AnimatedSprite2D=actor.sprite
	var texture:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var id:String=actor.get("asset_id","")
	var uv:=Vector2(.5,.63)
	if name=="grip":
		var table:Array=socket_data.get(id if id!="" else sprite.animation,[[.68,.65]])
		var point:Array=table[mini(sprite.frame,table.size()-1)]
		if id!="" and assets[id].records[sprite.frame].has("grip"):point=assets[id].records[sprite.frame].grip
		uv=Vector2(point[0],point[1])
	if sprite.flip_h:uv.x=1-uv.x
	return sprite.to_global(texture.get_size()*(uv-Vector2(.5,.5))+sprite.offset)

## Read-only adapter from authoritative enemy state to presentation.
## Recovery span is observed at its actual entry, never written back to EnemyAI.
func observe_enemy(enemy:Dictionary,previous_ai:String,player_position:Vector2)->void:
	if not actors.has(enemy.id) or enemy.hp<=0:return
	var actor:Dictionary=actors[enemy.id]
	if actor.corpse:return
	var profile:Dictionary=config.profiles.get(actor.profile,{})
	var locked_states=profile.get("locked_aim_states",[])
	if locked_states is Array and enemy.ai_state in locked_states:
		if absf(enemy.aim.x)>.001:enemy.sprite.flip_h=enemy.aim.x>0
	else:enemy.sprite.flip_h=player_position.x>enemy.pos.x
	if previous_ai=="warning" and enemy.ai_state not in ["warning","charging"]:trigger(enemy.id,"attack",.35)
	if enemy.ai_state=="warning":set_phase(enemy.id,"warning",1-enemy.warning_left/enemy.warning)
	elif enemy.ai_state=="recover":
		if previous_ai!="recover" or actor.recover_span<=0:actor.recover_span=maxf(.001,enemy.recover_left)
		set_phase(enemy.id,"recover",1-enemy.recover_left/actor.recover_span)
	elif enemy.ai_state=="charging":set_phase(enemy.id,"attack",1-enemy.charge_left/enemy.charge_duration)
	else:set_phase(enemy.id,"move")

static func valid_segment(value:Variant,frame_count:int=9)->bool:
	if frame_count<2 or frame_count>256:return false
	if not value is Array or value.size()!=2:return false
	for index in value:
		if not (index is int or index is float):return false
		if not is_finite(float(index)) or index<0 or index>=frame_count or float(index)!=floorf(float(index)):return false
	return value[0]<=value[1]

## A clip is 2..256 authored frame records from one source image.
## Sheet grid dimensions do not set animation length; metadata windows must be safe.
## Optional AtlasTexture.margin pads row windows to one fixed logical canvas (<=4096²).
## Multi-source clips are intentionally unsupported: do not silently ignore a frame path.
static func valid_records(value:Variant,source_size:Vector2)->bool:
	if not is_finite(source_size.x) or not is_finite(source_size.y) or source_size.x<=0 or source_size.y<=0:return false
	if not value is Array or value.size()<2 or value.size()>256:return false
	var canvas:=Vector2.ZERO
	for record in value:
		if not record is Dictionary or record.has("path"):return false
		var region=record.get("region")
		if not region is Array or region.size()!=4:return false
		for n in region:
			if not (n is int or n is float) or not is_finite(float(n)) or n<0 or float(n)!=floorf(float(n)):return false
		var size:=Vector2(region[2],region[3])
		if size.x<=0 or size.y<=0 or region[0]+size.x>source_size.x or region[1]+size.y>source_size.y:return false
		var margin=record.get("margin",[0,0,0,0])
		if not margin is Array or margin.size()!=4:return false
		for n in margin:
			if not (n is int or n is float) or not is_finite(float(n)) or n<0 or float(n)!=floorf(float(n)):return false
		if margin[0]>margin[2] or margin[1]>margin[3]:return false
		var logical_size:=size+Vector2(margin[2],margin[3])
		if logical_size.x>4096 or logical_size.y>4096:return false
		if canvas!=Vector2.ZERO and logical_size!=canvas:return false
		canvas=logical_size
		if record.has("alpha_bbox"):
			var box=record.alpha_bbox
			if not box is Array or box.size()!=4:return false
			for n in box:
				if not (n is int or n is float) or not is_finite(float(n)) or n<0:return false
			if box[2]<=0 or box[3]<=0 or box[0]<margin[0] or box[1]<margin[1] or box[0]+box[2]>margin[0]+size.x or box[1]+box[3]>margin[1]+size.y:return false
	return true
