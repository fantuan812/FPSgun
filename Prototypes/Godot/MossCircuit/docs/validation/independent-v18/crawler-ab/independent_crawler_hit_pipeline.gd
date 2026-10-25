extends SceneTree
var checks:=0
var failures:Array=[]
var trace:Array=[]
func check(v:bool,s:String)->void:
	checks+=1
	if not v:failures.append(s)
func _initialize()->void:call_deferred("run")
func hit(g,e,damage:float)->void:
	var bullet:Dictionary={"hit":[],"damage":damage,"pierce":0,"life":1.0,"weapon":"rivet_gun"}
	g._hit_segment(bullet,e.pos-Vector2(1,0),e.pos+Vector2(1,0))
func sample(g,e,label:String)->void:
	trace.append({"label":label,"mode":g._view().mode_id,"hp":e.hp,"pos":[e.pos.x,e.pos.y],"kills":g.kills,"elapsed":g.elapsed,"rng":g.rng.state,"runstate":g.state,"enemy_count":g.enemies.size(),"hurt_age":g.actor_anim.actors[e.id].age,"reaction":g.actor_anim.state_of(e.id)})
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
	for mode_id in ["arena","rooms"]:
		for side in [-1,1]:
			g._title();g._select_mode(mode_id);g._start_run(1818);g.spawn_clock=999;g.weapon_clocks=[999.0]
			var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(side*200,0));var a=g.actor_anim
			g._process(.01);var start:Vector2=e.pos;var hp:float=e.hp
			hit(g,e,1);g._process(.01)
			check(e.hp==hp-1,"production hit damage "+mode_id)
			check(a.state_of(e.id)=="hurt" and e.sprite.frame==0,"damage observer starts hurt "+mode_id)
			check(is_equal_approx(a.actors[e.id].height,255.0*57.0/414.0),"true visible scale")
			sample(g,e,"first hit")
			for i in range(4):g._process(.03)
			var age:float=a.actors[e.id].age
			hit(g,e,1);g._process(.01)
			check(e.hp==hp-2,"second real hit still damages "+mode_id)
			check(is_equal_approx(a.actors[e.id].age,age+.01),"repeat real hit does not restart reaction")
			check(e.pos!=start,"movement continues during hurt")
			sample(g,e,"repeat hit")
			for i in range(5):g._process(.03)
			check(a.state_of(e.id)=="move","real step expires hurt to current move")
			check(e.sprite.frame==int(a.actors[e.id].walk_time*9)%9,"current walk phase not reset")
			sample(g,e,"expired")
			hit(g,e,1);g._process(.01);check(a.state_of(e.id)=="hurt","later hit starts fresh reaction")
			hit(g,e,100);g._process(.01)
			check(a.state_of(e.id)=="death" and e.sprite.frame==0,"lethal interruption starts death0")
			check(g.kills==1 and not g.enemies.has(e),"authoritative kill exactly once")
			check(not a.trigger(e.id,"hurt"),"dead reaction cannot restart")
			sample(g,e,"lethal interruption")
	g.queue_free();await process_frame
	print(JSON.stringify({"checks":checks,"failures":failures,"trace":trace,"scope":"controlled actual primary hit-segment + simulation damage observer; no GUI or human feel claim"}))
	quit(1 if failures else 0)
