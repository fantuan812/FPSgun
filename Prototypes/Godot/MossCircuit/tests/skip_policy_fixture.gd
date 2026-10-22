extends "res://scripts/modes/arena_mode.gd"
# Non-user-facing QA policy: retain Arena battle gates but change only progression.
func resolution(session:RefCounted,_world:RefCounted,_config:Dictionary)->Dictionary:
	if session.wave==1:return {"terminal":false,"next_stage":3,"shop":false,"upgrades":0,"coins":7,"heal":3}
	return {"terminal":true,"next_stage":session.wave,"shop":false,"upgrades":0,"coins":0,"heal":0}
