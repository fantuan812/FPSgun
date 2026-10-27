extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/build_items_runtime.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:
	var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	ck(Rules.validate_catalog(base).is_empty(),"real B catalog valid")
	for key in ["weapon_slots","item_slots"]:
		for value in [null,true,"4",0,-1,1.5,NAN,INF,5 if key=="weapon_slots" else 9]:
			var changed:Dictionary=base.duplicate(true);changed[key]=value;var frozen:PackedByteArray=var_to_bytes(changed)
			ck(not Rules.validate_catalog(changed).is_empty(),key+" Rules rejects "+str(value))
			var helper=Runtime.new();ck(not helper.configure(changed).ok,key+" frozen runtime rejects "+str(value))
			ck(var_to_bytes(changed)==frozen,key+" validators detached "+str(value))
	var misplaced:Dictionary=base.duplicate(true);misplaced.weapons.append(misplaced.items.pop_back());var bytes:PackedByteArray=var_to_bytes(misplaced)
	ck(not Rules.validate_catalog(misplaced).is_empty(),"item in weapon registry rejected by Rules")
	var helper=Runtime.new();ck(not helper.configure(misplaced).ok,"item in weapon registry rejected by frozen runtime")
	ck(var_to_bytes(misplaced)==bytes,"registry validation detached")
	var integral:Dictionary=base.duplicate(true);integral.weapon_slots=4.0;integral.item_slots=8.0
	ck(Rules.validate_catalog(integral).is_empty() and Runtime.new().configure(integral).ok,"legal JSON integral slot counts retained")
	var legacy:Dictionary=base.duplicate(true);legacy.items=legacy.items.filter(func(row):return row.id not in ["crossfire_pin","salvage_capacitor","medic_winch"]);legacy.mechanism_synergies=legacy.mechanism_synergies.filter(func(row):return row.get("id","") not in ["crossfire_control","salvage_field","medical_recovery"]);legacy.weapon_slots=5
	ck(Rules.validate_catalog(legacy).is_empty(),"no B rows keeps old generic positive slot validation; not historical raw projection")
	print(JSON.stringify({"B_rules_configuration_checks":checks,"failures":failures,"scope":"literal Rules and frozen helper admission consistency; not gameplay/legacy raw identity"}))
	quit(0 if failures.is_empty() else 1)
