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
	for id in manifest.get("actions",{}):
		var asset: Dictionary=manifest.actions[id]
		if not ResourceLoader.exists(asset.path) or asset.frames.size()!=9: continue
		var source:Texture2D=load(asset.path)
		var frames:=SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("action")
		frames.set_animation_loop("action",false)
		for record in asset.frames:
			var atlas:=AtlasTexture.new()
			atlas.atlas=source
			atlas.region=Rect2(record.region[0],record.region[1],record.region[2],record.region[3])
			atlas.filter_clip=true
			frames.add_frame("action",atlas)
		var box:Array=asset.frames[0].alpha_bbox
		assets[id]={"records":asset.frames,"frames":frames,"anchor":asset.get("anchor",[.5,.8]),"reference_height":asset.get("reference_height",box[3]),"release_frame":clampi(int(asset.get("release_frame",4)),1,8)}
func register_actor(key:int,sprite:AnimatedSprite2D,profile:String,height:float) -> void:
	var first:AtlasTexture=sprite.sprite_frames.get_frame_texture("walk",0) as AtlasTexture
	var foot:=Vector2(0,height*.5)
	if first!=null:
		height=first.region.size.y*absf(sprite.scale.y)
		foot=(first.margin.position+Vector2(first.region.size.x*.5,first.region.size.y)-first.get_size()*.5+sprite.offset)*sprite.scale
	actors[key]={"sprite":sprite,"profile":profile,"height":height,"base_foot":foot,"base_frames":sprite.sprite_frames,"base_scale":sprite.scale,"base_offset":sprite.offset,"base_color":sprite.modulate,"base_flip":sprite.flip_h,"state":"idle","reaction":"","age":0.0,"duration":0.0,"phase":"idle","phase_progress":0.0,"walk_time":0.0,"corpse":false,"generation":generation,"source":"reused walk/idle"}
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
		var index:int=mini(8,floori(progress*9+.0000001))
		if state=="warning":index=mini(asset.release_frame-1,floori(progress*asset.release_frame+.0000001))
		elif state=="attack":index=asset.release_frame+mini(8-asset.release_frame,floori(progress*(9-asset.release_frame)+.0000001))
		elif state=="recover":index=8
		sprite.frame=index
		var texture:Texture2D=asset.frames.get_frame_texture("action",0)
		var scale_value:float=actor.height/maxf(1,asset.reference_height)
		sprite.scale=Vector2.ONE*scale_value
		sprite.offset=texture.get_size()*(Vector2(.5,.5)-Vector2(asset.anchor[0],asset.anchor[1]))+actor.base_foot/scale_value
		actor.source="authored nine-frame"
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
