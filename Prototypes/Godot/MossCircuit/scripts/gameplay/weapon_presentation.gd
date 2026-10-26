extends RefCounted
const CombatState=preload("res://scripts/gameplay/combat_state.gd")
const RunSession=preload("res://scripts/gameplay/run_session.gd")
const WeaponRig=preload("res://scripts/weapon_rig.gd")
var world:CombatState
var session:RunSession
var director:RefCounted
var rig:Node2D
var hero:AnimatedSprite2D
func _init(w:CombatState,s:RunSession,a:RefCounted,r:Node2D,h:AnimatedSprite2D)->void:
	world=w;session=s;director=a;rig=r;hero=h
## Shared authoritative static socket pose, not a recoil-dependent visual interpolation.
func pose(id:String,slot:int,target:Vector2)->Dictionary:
	hero.position=world.player_pos.round()
	rig.sync_loadout(session.build.weapons)
	var hand:Vector2=director.socket_world(0,"grip")
	var body:Vector2=director.socket_world(0,"body")
	var offset:Vector2=WeaponRig.OFFSETS[clampi(slot,0,3)]
	if hero.flip_h:offset.x=-offset.x
	var mount:Vector2=hand if slot==0 else body+offset
	var fallback:Vector2=rig.slots[slot].aim if slot>=0 and slot<rig.slots.size() else Vector2.RIGHT
	return WeaponRig.muzzle_pose(mount,target,rig.geometry.get(id,{}),fallback)
func fire(id:String,slot:int,target:Vector2,melee:bool=false)->Dictionary:
	if not melee:
		if slot==0:director.trigger(0,"attack")
		if absf(target.x-world.player_pos.x)>.01:hero.flip_h=target.x<world.player_pos.x
	var result:=pose(id,slot,target)
	rig.fire(slot,result)
	return result

## Explicit direction fallback for a coincident target; normal target-solving paths are unchanged.
func fire_fixed_direction(id:String,slot:int,direction:Vector2)->Dictionary:
	var aim:Vector2=direction.normalized() if direction.is_finite() and direction.length_squared()>.000001 else Vector2.RIGHT
	if slot==0:director.trigger(0,"attack")
	if absf(aim.x)>.01:hero.flip_h=aim.x<0
	var reference:Dictionary=pose(id,slot,world.player_pos+aim)
	# A coincident mount/target invokes the existing solver's exact direction fallback,
	# preserving measured grip/muzzle offset without aiming toward a fabricated distant target.
	var result:Dictionary=WeaponRig.muzzle_pose(reference.mount,reference.mount,rig.geometry.get(id,{}),aim)
	rig.fire(slot,result)
	return result
