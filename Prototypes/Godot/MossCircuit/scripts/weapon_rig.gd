extends Node2D
## Dedicated world art and deterministic shared launch geometry; no gameplay RNG.
var assets:Dictionary={}
var geometry:Dictionary={}
var slots:Array=[]
var disc_sprites:Array=[]
var mortar_marks:Array=[]
var generation:=0
var last_shot:Dictionary={}
var visible_clock:=0.0
const OFFSETS=[Vector2.ZERO,Vector2(-12,-18),Vector2(-15,-3),Vector2(4,16)]
static func muzzle_pose(mount:Vector2,target:Vector2,g:Dictionary,fallback:Vector2=Vector2.RIGHT)->Dictionary:
	var rect:Array=g.get("region",[0,0,32,16])
	var size:=Vector2(rect[2],rect[3])
	var scale_value:float=float(g.get("visible_length",28))/maxf(1,float(g.get("reference_width",rect[2])))
	var grip:Array=g.get("grip",[.2,.5])
	var tip:Array=g.get("muzzle",[.95,.5])
	var offset:Vector2=(Vector2(tip[0],tip[1])-Vector2(grip[0],grip[1]))*size*scale_value
	var delta:Vector2=target-mount
	var direction:Vector2=delta.normalized() if delta.length_squared()>.000001 else (fallback.normalized() if fallback.length_squared()>.000001 else Vector2.RIGHT)
	var flip:bool=direction.x<0
	if flip:offset.y=-offset.y
	var angle:float=direction.angle()
	if delta.length()>.000001:angle-=asin(clampf(offset.y/delta.length(),-1,1))
	direction=Vector2.from_angle(angle)
	return {"mount":mount,"muzzle":mount+offset.rotated(angle),"direction":direction,"angle":angle,"scale":Vector2(scale_value,-scale_value if flip else scale_value),"flip_v":flip}
static func range_distance(center:Vector2,muzzle:Vector2,direction:Vector2,reach:float)->float:
	if reach<=0 or direction.length_squared()<.000001:return 0.0
	var delta:Vector2=muzzle-center
	var d:=direction.normalized()
	var projection:float=delta.dot(d)
	var discriminant:float=reach*reach-delta.length_squared()+projection*projection
	if discriminant<0:return 0.0
	# Origins outside the range circle are not granted an inward extra flight.
	if delta.length_squared()>reach*reach+.00001:return 0.0
	return maxf(0,-projection+sqrt(maxf(0,discriminant)))
func load_default()->void:
	var path:="res://assets/weapon_mounts/world_weapon_manifest.json"
	if not FileAccess.file_exists(path):return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	geometry=data.get("weapons",{})
	for id in geometry:
		var g:Dictionary=geometry[id]
		if not ResourceLoader.exists(g.path):continue
		var texture:=AtlasTexture.new();texture.atlas=load(g.path)
		texture.region=Rect2(g.region[0],g.region[1],g.region[2],g.region[3]);texture.filter_clip=true
		assets[id]=texture
func sync_loadout(ids:Array)->void:
	if slots.map(func(s):return s.id)==ids:return
	clear()
	for i in range(ids.size()):
		var sprite:=Sprite2D.new();sprite.texture=assets.get(ids[i]);sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(sprite)
		slots.append({"id":ids[i],"slot":i,"sprite":sprite,"age":10.0,"pose":{},"target":Vector2.RIGHT,"aim":Vector2.RIGHT,"hidden":false})
func swap_copies(first:int,second:int)->void:
	# Shop controller has already rejected outstanding flight state. Keep copy-local aim/age.
	if first<0 or second<0 or first>=slots.size() or second>=slots.size() or first==second:return
	var moved:Dictionary=slots[first]
	slots[first]=slots[second]
	slots[second]=moved
	for index in [first,second]:
		slots[index].slot=index
		slots[index].pose={}
	# last_shot remains an honest historical launch, not a new shot in the moved slot.
	queue_redraw()
func clear()->void:
	for slot in slots:
		if is_instance_valid(slot.sprite):slot.sprite.queue_free()
	slots.clear()
	for sprite in disc_sprites:
		if is_instance_valid(sprite):sprite.queue_free()
	disc_sprites.clear();mortar_marks.clear();last_shot.clear();visible_clock=0;generation+=1;queue_redraw()
func consume_copy(index:int)->void:
	# Shop tempering already rejected flight state. Delete only the disclosed donor.
	if index<0 or index>=slots.size():return
	var donor:Dictionary=slots[index]
	if is_instance_valid(donor.sprite):donor.sprite.queue_free()
	slots.remove_at(index)
	for remaining in range(index,slots.size()):
		slots[remaining].slot=remaining
		slots[remaining].pose={}
	# Keep surviving aim/age, visible clock, generation and historical last_shot.
	queue_redraw()
func advance(dt:float)->void:
	visible_clock+=maxf(0,dt)
	for slot in slots:slot.age+=maxf(0,dt)
func pose_for(slot_index:int,hand:Vector2,body:Vector2,target:Vector2,facing_left:bool)->Dictionary:
	if slot_index<0 or slot_index>=slots.size():return {}
	var slot:Dictionary=slots[slot_index]
	var offset:Vector2=OFFSETS[mini(slot_index,3)]
	if facing_left:offset.x=-offset.x
	var mount:Vector2=hand if slot_index==0 else body+offset
	return muzzle_pose(mount,target,geometry.get(slot.id,{}),slot.aim)
func fire(index:int,pose:Dictionary)->void:
	if index<0 or index>=slots.size() or pose.is_empty():return
	var slot:Dictionary=slots[index];slot.age=0;slot.pose=pose;slot.aim=pose.direction
	last_shot={"slot":index,"id":slot.id,"pose":pose.duplicate(true),"generation":generation}
	_apply(slot)
func update_poses(hand:Vector2,body:Vector2,target:Vector2,facing_left:bool,bullets:Array,blasts:Array,alive:bool,priority_targets:Dictionary={})->void:
	for i in range(slots.size()):
		var slot:Dictionary=slots[i]
		var idle_target:Vector2=priority_targets.get(i,target)
		if slot.age>0 or slot.pose.is_empty():slot.pose=pose_for(i,hand,body,idle_target,facing_left)
		slot.aim=slot.pose.direction
		slot.hidden=not alive or (slot.id=="return_disc" and bullets.any(func(b):return b.get("slot",-1)==i and b.get("weapon","")=="return_disc" and b.life>0))
		_apply(slot)
	var discs:Array=bullets.filter(func(b):return b.get("weapon","")=="return_disc" and b.life>0)
	while disc_sprites.size()<mini(64,discs.size()):
		var sprite:=Sprite2D.new();sprite.texture=assets.get("return_disc");sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.z_index=4;add_child(sprite);disc_sprites.append(sprite)
	for i in range(disc_sprites.size()):
		var sprite:Sprite2D=disc_sprites[i];sprite.visible=i<discs.size() and alive
		if not sprite.visible:continue
		sprite.position=discs[i].pos;sprite.rotation=visible_clock*14
		var g:Dictionary=geometry.get("return_disc",{});sprite.scale=Vector2.ONE*16/maxf(1,float(g.get("reference_width",512)))
		var anchor:Array=g.get("grip",[.5,.5])
		if sprite.texture!=null:sprite.offset=sprite.texture.get_size()*(Vector2(.5,.5)-Vector2(anchor[0],anchor[1]))
	mortar_marks=[]
	if alive:
		for blast in blasts:
			var t:float=clampf(1-float(blast.delay)/.6,0,1)
			var start:Vector2=blast.get("visual_origin",body)
			mortar_marks.append(start.lerp(blast.pos,t)+Vector2(0,-sin(t*PI)*48))
	queue_redraw()
func _apply(slot:Dictionary)->void:
	var sprite:Sprite2D=slot.sprite
	sprite.visible=not slot.hidden
	if slot.pose.is_empty():return
	var g:Dictionary=geometry.get(slot.id,{})
	var size:=Vector2(float(g.get("region",[0,0,32,16])[2]),float(g.get("region",[0,0,32,16])[3]))
	var grip:Array=g.get("grip",[.2,.5])
	var recoil:float=sin(clampf(slot.age/.12,0,1)*PI)*3 if slot.id not in ["orbit_saw","return_disc"] else 0.0
	sprite.position=slot.pose.mount-slot.pose.direction*recoil
	sprite.rotation=slot.pose.angle if slot.id!="orbit_saw" else visible_clock*12
	sprite.scale=slot.pose.scale;sprite.offset=-Vector2(grip[0],grip[1])*size
	sprite.z_index=1 if slot.slot in [1,2] else 3
func _draw()->void:
	for p in mortar_marks:draw_rect(Rect2(p.round()-Vector2(2,2),Vector2(4,4)),Color("b5deef"))
