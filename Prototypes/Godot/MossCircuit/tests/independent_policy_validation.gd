extends SceneTree
const RoomMode=preload("res://scripts/modes/room_mode.gd")
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:
	var profile:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_encounters.json"))
	var enemies:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	check(RoomMode.validate(profile,enemies).is_empty(),"real room configuration valid")
	var paths:Array=[["field","width"],["field","height"],["field","tile_size"],["spawn_interval"],["clear_delay"],["reward","coins"],["reward","heal"],["reward","upgrades"]]
	for path in paths:
		for value in [NAN,INF,-INF,"invalid",{},[],true,null]:
			var bad:Dictionary=profile.duplicate(true)
			if path.size()==2:bad[path[0]][path[1]]=value
			else:bad[path[0]]=value
			check(not RoomMode.validate(bad,enemies).is_empty(),"reject malformed "+str(path)+"="+str(value))
	for value in [NAN,INF,-INF,"invalid",{},[],true,null,-.01,1.01]:
		var bad:Dictionary=profile.duplicate(true)
		bad.stages[0].enemies[0].at[1]=value
		check(not RoomMode.validate(bad,enemies).is_empty(),"reject malformed position "+str(value))
	for key in ["field","reward","stages"]:
		for value in [null,true,"bad",12]:
			var bad:Dictionary=profile.duplicate(true);bad[key]=value
			check(not RoomMode.validate(bad,enemies).is_empty(),"reject whole section "+key+"="+str(value))
	var no_name:Dictionary=profile.duplicate(true);no_name.stages[0].erase("name")
	check(not RoomMode.validate(no_name,enemies).is_empty(),"missing stage.name rejected")
	for value in [null,{},[],12,true,""]:
		var bad:Dictionary=profile.duplicate(true);bad.stages[0].name=value
		check(not RoomMode.validate(bad,enemies).is_empty(),"invalid stage.name "+str(value))
	for value in [null,true,"bad",12,{},[]]:
		var bad:Dictionary=profile.duplicate(true);bad.stages[0]=value
		check(not RoomMode.validate(bad,enemies).is_empty(),"malformed stage node "+str(value))
	var areas:Array=[
		[{"width":64,"height":64,"tile_size":1},true],
		[{"width":65,"height":64,"tile_size":1},false],
		[{"width":65536,"height":48,"tile_size":1024},true],
		[{"width":65537,"height":48,"tile_size":1024},false],
		[{"width":48,"height":48,"tile_size":.999},false],
		[{"width":48,"height":48,"tile_size":1},true],
		[{"width":1e30,"height":48,"tile_size":80},false],
		[{"width":48,"height":48,"tile_size":1e-30},false],
		[{"width":48,"height":48,"tile_size":65537},false]]
	for entry in areas:
		var candidate:Dictionary=profile.duplicate(true);candidate.field=entry[0]
		check(RoomMode.validate(candidate,enemies).is_empty()==entry[1],"bounded grid validation only "+str(entry[0]))
	print("INDEPENDENT POLICY VALIDATION: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
