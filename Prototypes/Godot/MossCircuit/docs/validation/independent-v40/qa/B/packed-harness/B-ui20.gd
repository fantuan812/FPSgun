extends SceneTree
const Readout=preload("res://scripts/gameplay/build_items_readout.gd")
var checks:int=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func _initialize()->void:
	var snapshot:Dictionary={"configuration_open":false,"owned_items":{},"definitions":{"crossfire_pin":{"requires_distinct_weapon_types":2},"salvage_capacitor":{"field_radius":80.0,"field_limit":2,"charge_limit":3,"field_speed_factor":.7},"medic_winch":{"pickup_count":5}},"equipped_types":["a","b"],"mark":null,"pin_ready_at":null,"charges":0,"fields":[],"winch_count":0,"pending":null}
	var enemies:Array=[{"id":7,"hp":10.0,"boss":false,"pos":Vector2(50,60)}]
	check(Readout.describe(snapshot,10,enemies)=={"rows":[],"pin":{},"fields":[]},"unowned empty")
	snapshot.owned_items={"crossfire_pin":1,"salvage_capacitor":1,"medic_winch":1}
	var before:Dictionary=snapshot.duplicate(true)
	var result:Dictionary=Readout.describe(snapshot,10,enemies)
	check(result.rows.size()==3,"owned three only")
	check(result.rows[0].status=="READY / awaiting first eligible contact","pin ready")
	check(result.rows[1].status=="CHARGING / 0/3 / fields 0/2","empty charge")
	check(result.rows[2].status=="PICKUPS 0/5","winch zero")
	check(snapshot==before,"snapshot immutable")
	snapshot.equipped_types=["a"]
	check(Readout.describe(snapshot,10,enemies).rows[0].status=="INACTIVE / needs 2 distinct weapon types","distinct prerequisite")
	snapshot.equipped_types=["a","b"]
	snapshot.pin_ready_at=11.0
	check(Readout.describe(snapshot,10,enemies).rows[0].status=="COOLDOWN / 1.00s","cooldown")
	snapshot.pin_ready_at=10.0
	check(Readout.describe(snapshot,10,enemies).rows[0].status.begins_with("READY"),"cooldown equality ready")
	snapshot.mark={"target_id":7,"weapon":"a","position":Vector2(40,40),"expires":11.5}
	result=Readout.describe(snapshot,10,enemies)
	check(result.pin=={"anchor":Vector2(40,40),"target":Vector2(50,60)},"anchor distinct from live target")
	check(result.rows[0].status=="MARKED / 1.50s left / hit same target with another type","mark time")
	check(Readout.describe(snapshot,11.5,enemies).pin.is_empty(),"expiry equality hidden")
	check(Readout.describe(snapshot,10,[]).rows[0].status=="NO VALID MARK / awaiting simulation update","missing target honest")
	check(Readout.describe(snapshot,10,enemies+enemies).pin.is_empty(),"duplicate target hidden")
	snapshot.charges=3
	snapshot.fields=[{"pos":Vector2(1,2),"expires":10.0,"sequence":1},{"pos":Vector2(3,4),"expires":11.0,"sequence":2}]
	result=Readout.describe(snapshot,10,enemies)
	check(result.fields==[{"pos":Vector2(3,4),"radius":80.0}],"expiry and radius definition")
	check(result.rows[1].status=="READY / next real dash spends charge / 3/3 / fields 1/2","full ready")
	snapshot.winch_count=4;snapshot.pending={"origin":Vector2.ZERO,"serial":1,"time":10.0}
	result=Readout.describe(snapshot,10,enemies)
	check(result.rows[2].status=="PICKUPS 4/5 / pull queued for this batch","pending not healed")
	check("no direct healing" in result.rows[2].detail and "no medicine still spends" in result.rows[2].detail,"medical limitation")
	snapshot.configuration_open=true
	result=Readout.describe(snapshot,10,enemies)
	check(result.pin.is_empty() and result.fields.is_empty() and result.rows[0].status=="INACTIVE / configuration unavailable","failclosed presentation")
	check(Readout.describe(snapshot,NAN,enemies)=={"rows":[],"pin":{},"fields":[]},"bad time hidden")
	print(JSON.stringify({"suite":"B_pure_readout","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
