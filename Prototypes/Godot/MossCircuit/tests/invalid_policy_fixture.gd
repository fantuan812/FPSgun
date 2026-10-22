extends "res://scripts/modes/arena_mode.gd"
func resolution(session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:
	return {"terminal":false,"next_stage":session.wave+1,"shop":false,"upgrades":0,"coins":NAN,"heal":0}
