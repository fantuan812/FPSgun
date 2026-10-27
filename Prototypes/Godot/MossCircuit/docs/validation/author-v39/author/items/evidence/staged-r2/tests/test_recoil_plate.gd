extends SceneTree
const Effects=preload("res://scripts/effects.gd")
const Runtime=preload("res://scripts/gameplay/effect_runtime.gd")
const World=preload("res://scripts/gameplay/combat_state.gd")
const Session=preload("res://scripts/gameplay/run_session.gd")
const Recoil=preload("res://scripts/gameplay/recoil_plate.gd")
var checks:=0
var failures:Array=[]
var sequence:=0
func ck(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label)
func row()->Dictionary:
	return {"id":"recoil_plate","max_stack":1,"radius":100.0,"distance":55.0,"cooldown":2.0}
func ctx(time:float=0.0)->Dictionary:
	return {"time":time,"playing":true,"hp":30.0,"max_hp":100.0,"pos":Vector2(100,100),"enemies":[],"damage":10.0}
func hurt()->Dictionary:
	return {"kind":"hurt","source":"player_hp_loss","depth":0,"amount":5.0}
func send(fx:RefCounted,event:Dictionary,context:Dictionary)->Array:
	sequence+=1
	var e:Dictionary=event.duplicate(true)
	e.epoch=fx.epoch;e.sequence=sequence
	return fx.process(e,context)
func fresh()->RefCounted:
	var fx=Effects.new()
	fx.configure({"weapons":[],"items":[row()]})
	fx.reset({"recoil_plate":1})
	return fx
func ignore(_a:Variant=null,_b:Variant=null,_c:Variant=null,_d:Variant=null)->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
	ck(Recoil.definition(row())=={"radius":100.0,"distance":55.0,"cooldown":2.0},"data values not magic")
	for key in ["radius","distance","cooldown","max_stack"]:
		for bad in [null,true,"2",0,-1,NAN,INF]:
			var r:=row();r[key]=bad
			ck(Recoil.definition(r).is_empty(),"definition reject "+key+" "+str(bad))
	var fx=fresh()
	ck(fx.recoil_cooldown.is_empty(),"fresh never-triggered no tombstone")
	var commands=send(fx,hurt(),ctx(10))
	ck(commands.size()==1 and commands[0].kind=="recoil_push","real hurt one command")
	ck(fx.recoil_cooldown=={"ready_at":12.0} and fx.cooldowns.is_empty(),"new-only tombstone")
	fx.sync({});fx.sync({"recoil_plate":1})
	ck(send(fx,hurt(),ctx(11)).is_empty(),"sell rebuy does not refresh")
	fx.reset({"recoil_plate":1})
	ck(send(fx,hurt(),ctx(11.999)).is_empty(),"encounter reset preserves remaining")
	ck(send(fx,hurt(),ctx(12)).size()==1,"exact 2s ready")
	fx.clear_recoil_run();fx.reset({"recoil_plate":1})
	ck(send(fx,hurt(),ctx()).size()==1,"new run at zero clear")
	for field in ["source","depth","amount"]:
		var bad_values:Array=[]
		if field=="source":bad_values=["primary","normal","energy","medical",null]
		elif field=="depth":bad_values=[-1,1,2,true,"0",null,NAN,INF]
		else:bad_values=[0,-1,true,"5",null,NAN,INF]
		for bad in bad_values:
			fx=fresh();var e:=hurt();e[field]=bad
			ck(send(fx,e,ctx()).is_empty(),"event guard "+field+" "+str(bad))
			ck(fx.recoil_cooldown.is_empty(),"invalid event no spend")
	for field in ["hp","time","playing","pos"]:
		var bad_values:Array=[]
		if field=="hp":bad_values=[0,-1,true,"30",NAN,INF,null]
		elif field=="time":bad_values=[-1,true,"0",NAN,INF,null]
		elif field=="playing":bad_values=[false,1,"true",null]
		else:bad_values=[null,Vector2(INF,0),Vector2(0,NAN)]
		for bad in bad_values:
			var context:=ctx();context[field]=bad
			# Guard helper directly: old engine context typed conversion is unchanged.
			ck(not Recoil.eligible(hurt(),context),"context guard "+field+" "+str(bad))
	fx=fresh()
	for kind in ["before_hurt","pickup","dash","kill"]:
		var e:=hurt();e.kind=kind;e.pos=Vector2.ZERO
		ck(send(fx,e,ctx()).is_empty(),"non hurt no recoil "+kind)
	fx=fresh();var duplicate:=hurt();duplicate.epoch=fx.epoch;duplicate.sequence=10000
	ck(fx.process(duplicate,ctx()).size()==1,"first sequence")
	ck(fx.process(duplicate,ctx(3)).is_empty(),"duplicate sequence no trigger")
	fx.invalidate();ck(fx.process(duplicate,ctx(3)).is_empty(),"stale epoch")
	ck(fx.recoil_cooldown=={"ready_at":2.0},"invalidate no cooldown change")
	var command:Dictionary={"kind":"recoil_push","pos":Vector2(100,100),"radius":100.0,"distance":55.0}
	var area:Dictionary={"width":960,"height":540}
	var positions:Array=[Vector2(100,100),Vector2(200,100),Vector2(200.01,100),Vector2(130,140)]
	var expected:Array=[Vector2(155,100),Vector2(255,100),Vector2(200.01,100),Vector2(163,184)]
	for i in range(positions.size()):
		var enemy:Dictionary={"id":i,"hp":10.0,"boss":false,"pos":positions[i],"ai_state":"charging","velocity":Vector2(2,3),"charge_left":.5,"warning_left":.2,"attack_left":.3,"recover_left":.4}
		var before:Dictionary=enemy.duplicate(true)
		Recoil.apply(command,[enemy],area)
		ck(enemy.pos.distance_to(expected[i])<.0001,"geometry hand "+str(i))
		enemy.pos=before.pos
		ck(enemy==before,"all other enemy fields untouched "+str(i))
	for flag in ["boss","dead"]:
		var enemy:Dictionary={"id":1,"hp":0.0 if flag=="dead" else 10.0,"boss":flag=="boss","pos":Vector2(130,140)}
		var before:=enemy.duplicate(true)
		ck(Recoil.apply(command,[enemy],area).is_empty() and enemy==before,"excluded "+flag)
	var edge:Dictionary={"id":1,"hp":10,"boss":false,"pos":Vector2(25,100)}
	command.pos=Vector2(50,100);Recoil.apply(command,[edge],area)
	ck(edge.pos==Vector2(20,100),"left clamp")
	edge.pos=Vector2(930,100);command.pos=Vector2(900,100);Recoil.apply(command,[edge],area)
	ck(edge.pos==Vector2(940,100),"right clamp")
	for bad_area in [{},{"width":40,"height":540},{"width":960,"height":40},{"width":true,"height":540},{"width":INF,"height":540},{"width":960,"height":NAN}]:
		var before:Dictionary=edge.duplicate(true)
		ck(Recoil.apply(command,[edge],bad_area).is_empty() and edge==before,"invalid area failclosed")
	fx=fresh();commands=send(fx,hurt(),ctx(10))
	ck(Recoil.apply(commands[0],[edge],{}).is_empty(),"invalid area no move")
	ck(fx.recoil_cooldown=={"ready_at":12.0} and send(fx,hurt(),ctx(10.1)).is_empty(),"invalid area no refund")
	fx=Effects.new();fx.configure({"weapons":[],"items":[]});fx.reset({})
	send(fx,hurt(),ctx());fx.reset({});fx.sync({})
	ck(fx.recoil_cooldown.is_empty() and fx.cooldowns.is_empty(),"old no item state unaffected")
	var world=World.new();var session=Session.new()
	world.stats={"hp":30.0,"max_hp":100.0,"damage":10.0,"dash_time":0.0}
	world.player_pos=Vector2(100,100)
	world.enemies=[{"id":1,"hp":10.0,"boss":false,"pos":Vector2(100,100)}]
	session.state="playing";session.elapsed=0.0;fx=fresh()
	var runtime=Runtime.new(world,session,fx,RefCounted.new(),ignore,ignore)
	runtime.recoil_area=area
	runtime.emit_event("hurt",{"source":"player_hp_loss","depth":0,"amount":5.0})
	ck(world.enemies[0].pos==Vector2(155,100),"real effect runtime displacement")
	ck(world.enemies[0].hp==10 and world.stats.hp==30,"runtime no damage or heal")
	ck(world.effect_visuals.size()==1 and world.effect_visuals[0].kind=="recoil_push","bounded new visual")
	var previous_pos:Vector2=world.enemies[0].pos
	session.elapsed=3;world.stats.hp=0
	runtime.emit_event("hurt",{"source":"player_hp_loss","depth":0,"amount":30.0})
	ck(world.enemies[0].pos==previous_pos and fx.recoil_cooldown.ready_at==2,"lethal no push or spend")
	world.stats.hp=30;session.state="paused"
	runtime.emit_event("hurt",{"source":"player_hp_loss","depth":0,"amount":5.0})
	ck(world.enemies[0].pos==previous_pos and fx.recoil_cooldown.ready_at==2,"paused runtime gate")
	print(JSON.stringify({"recoil_checks":checks,"failures":failures,"scope":"A author pure engine/helper focused; not independent runtime/native acceptance"}))
	quit(0 if failures.is_empty() else 1)
