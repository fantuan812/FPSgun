extends SceneTree
var passed:=0
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run_checks")
func prepare(g)->Dictionary:
	g._start_run(1212);g.spawn_clock=999;g.weapon_clocks=[999.0]
	var e:Dictionary=g._spawn_kind("brood_keeper",g.player_pos+Vector2(220,0))
	e.ai_state="warning";e.warning_left=.65;e.attack="summon";e.aim=Vector2.LEFT;e.cooldown_left=999
	return e
func children(g,e)->Array:
	return g.enemies.filter(func(child):return child.parent_id==e.id and child.hp>0)
func run_checks()->void:
	var Director=load("res://scripts/actor_director.gd")
	var record:Dictionary={"region":[0,0,16,16],"alpha_bbox":[2,2,12,12]}
	check(Director.valid_records([record,record],Vector2(32,32)),"two-frame clip supported")
	for count in [0,1,257]:
		var records:Array=[];records.resize(count);records.fill(record)
		check(not Director.valid_records(records,Vector2(32,32)),"bounded clip count "+str(count))
	for n in [NAN,INF,-1.0,0.5,"16",true,null,{}]:
		var bad:Dictionary=record.duplicate(true);bad.region[2]=n
		check(not Director.valid_records([record,bad],Vector2(32,32)),"reject malformed region "+str(n))
	for region in [[20,0,16,16],[0,0,17,16],[0,0,0,16]]:
		check(not Director.valid_records([record,{"region":region}],Vector2(32,32)),"region containment and fixed canvas")
	check(not Director.valid_records([record,{"region":[0,0,16,16],"path":"res://other.png"}],Vector2(32,32)),"unsupported per-frame image cannot silently load wrong source")
	check(not Director.valid_records([record,record],Vector2(INF,32)),"finite source dimensions")
	check(Director.valid_segment([7,15],16) and not Director.valid_segment([7,16],16),"sixteen-frame segment upper bound")
	check(Director.valid_segment([0,8]) and not Director.valid_segment([0,9]),"legacy nine-frame default remains strict")
	for count in [0,1,257]:check(not Director.valid_segment([0,0],count),"segment count budget")
	var padded:Dictionary={"region":[0,0,16,8],"margin":[0,4,0,8],"alpha_bbox":[2,5,12,6]}
	check(Director.valid_records([record,padded],Vector2(32,32)),"different source rows share padded logical canvas")
	for margin in [[0,-1,0,8],[0,9,0,8],[0,0,1,8],[0,INF,0,8],[0,0,0,5000],[0,0,0,.5],null]:
		var bad:Dictionary=padded.duplicate(true);bad.margin=margin
		check(not Director.valid_records([record,bad],Vector2(32,32)),"reject unsafe/inconsistent padding "+str(margin))
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false)
	var e:Dictionary=prepare(g)
	var a=g.actor_anim
	var loaded:bool=a.assets.has("brood_keeper_summon")
	for id in ["brood_keeper_summon","brood_keeper_hurt","brood_keeper_death"]:
		check(a.assets.has(id),"approved resource loaded "+id)
		if not a.assets.has(id):continue
		var asset:Dictionary=a.assets[id]
		var count:int=9 if id=="brood_keeper_hurt" else 16
		check(asset.frames.get_frame_count("action")==count,"exact contract frame count "+id)
		check(not asset.frames.get_animation_loop("action"),"manual one-shot "+id)
		var canvas:Vector2=asset.frames.get_frame_texture("action",0).get_size()
		var neutral:Array=asset.records[0].alpha_bbox
		check(is_equal_approx(float(neutral[1]+neutral[3]),float(asset.anchor[1])*canvas.y),"neutral frame grounded "+id)
		for i in range(count):
			check(asset.frames.get_frame_texture("action",i).get_size()==canvas,"fixed canvas "+id+str(i))
			var box:Array=asset.records[i].alpha_bbox
			check(box[0]>=0 and box[1]>=0 and box[2]>0 and box[3]>0 and box[0]+box[2]<=canvas.x and box[1]+box[3]<=canvas.y,"visible bounds "+id+str(i))
	for phase in ["warning","attack","recover"]:
		var segment:Array=a.config.profiles.brood_keeper.phase_frames[phase]
		for step in range(11):
			a.set_phase(e.id,phase,float(step)/10)
			if loaded:
				var expected:int=int(segment[0])+mini(int(segment[1]-segment[0]),floori(float(step)/10*(segment[1]-segment[0]+1)+.0000001))
				check(e.sprite.frame==expected,"phase frame "+phase+str(step))
			check(not a.trigger(e.id,"attack"),"contact cannot fake summon release")
	g._simulate(.64)
	check(e.ai_state=="warning" and children(g,e).is_empty(),"late warning still no child")
	if loaded:check(e.sprite.frame==6,"last windup before summon attempt")
	g._simulate(.02)
	check(e.ai_state=="recover" and children(g,e).size()==1,"real attempt spawns one child with room")
	if loaded:check(e.sprite.frame==7,"actual attempt and release frame7 same tick")
	var child:Dictionary=children(g,e)[0]
	check(child.kind=="crawler" and child.parent_id==e.id and child.hp==22 and child.xp==4,"child identity/authority unchanged")
	check(child.pos.is_equal_approx(e.pos+Vector2.from_angle(g.elapsed)*50),"child spawn geometry uses original elapsed angle")
	for step in range(1,9):
		g._simulate(.7/9.0)
		if loaded:check(e.sprite.frame==7+step,"real recovery frame "+str(step))
		check(children(g,e).size()==1,"animation produces no extra child")
	g._simulate(.08);check(e.ai_state=="move" and a.state_of(e.id)=="move","recovery returns to movement")
	# Exactly the original per-parent cap, not a visual guarantee of spawning.
	e=prepare(g)
	for i in range(3):g._spawn_kind("crawler",e.pos+Vector2(50,i*20),e.id)
	e.warning_left=.001;var next_id:int=g.next_enemy_id;g._simulate(.02)
	check(children(g,e).size()==3 and g.next_enemy_id==next_id,"three living children block new spawn")
	if loaded:check(e.sprite.frame==7,"blocked summon still shows the real attempt")
	# Global cap is exercised at the actual configured capacity, not patched balance.
	e=prepare(g)
	for i in range(int(g.config.waves.max_enemies)-1):g._spawn_kind("crawler",e.pos+Vector2(10,i%20))
	e.warning_left=.001;next_id=g.next_enemy_id;g._simulate(.02)
	check(g.enemies.size()==int(g.config.waves.max_enemies) and children(g,e).is_empty() and g.next_enemy_id==next_id,"global cap can yield zero children")
	# Actual HP loss masks a same-tick spawn without delaying or replaying it.
	e=prepare(g);e.warning_left=.001;e.hp-=1;g._simulate(.02)
	check(children(g,e).size()==1 and a.state_of(e.id)=="hurt","hurt masks body while summon resolves once")
	child=children(g,e)[0]
	var age:float=a.actors[e.id].age;var left:float=e.recover_left;var pos:Vector2=child.pos
	g._on_intent("pause",{});g._process(.8)
	check(a.actors[e.id].age==age and e.recover_left==left and child.pos==pos,"pause freezes parent/child/action")
	g._resume()
	for i in range(6):g._process(.05)
	check(children(g,e).size()==1 and a.state_of(e.id)=="recover","hurt completion never repeats a summon")
	if loaded:check(e.sprite.frame==10,"hurt ends at current recovery frame10")
	var flip:bool=e.sprite.flip_h;e.aim=Vector2(.00001,1)
	a.observe_enemy(e,"recover",e.pos+Vector2(400,0));check(e.sprite.flip_h==flip,"near vertical locked aim stable")
	e.hp=0;var kills:int=g.kills;g._simulate(.001)
	check(g.kills==kills+1 and a.state_of(e.id)=="death","parent death grants one reward and starts tail")
	check(children(g,e).size()==1 and child.hp>0 and g.enemies.has(child),"parent death deliberately preserves existing living child")
	check(not a.trigger(e.id,"hurt") and not a.trigger(e.id,"attack"),"death refuses late feedback")
	g._simulate(.01);check(g.kills==kills+1 and children(g,e).size()==1,"corpse never spawns or rewards twice")
	a.advance(.70)
	if a.assets.has("brood_keeper_death"):check(e.sprite.frame==15,"last death frame has display time")
	check(a.actors.has(e.id),"death tail retained")
	a.advance(.021);check(not a.actors.has(e.id),"parent corpse reclaimed independently of child")
	g._title();g._select_mode("rooms");g._start_run(1212)
	check(a.corpses.is_empty() and a.actors.keys()==[0] and g.enemies.is_empty(),"cross-mode restart clears parent/child visual references")
	g.queue_free();await process_frame
	print(JSON.stringify({"passed":passed,"failures":failures,"scope":"v12 variable-length broodkeeper actions; summon attempt does not guarantee child"}))
	quit(0 if failures.is_empty() else 1)
