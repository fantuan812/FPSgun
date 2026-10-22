extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func verify_records(ad)->void:
	for count in [2,9,16,256]:
		var records:Array=[]
		for index in range(count):records.append({"region":[index%16,index/16,1,1]})
		check(ad.valid_records(records,Vector2(16,16)),"single-image structural validator accepts legitimate count "+str(count))
	for count in [0,1,257]:
		var records:Array=[]
		for index in range(count):records.append({"region":[0,0,1,1]})
		check(not ad.valid_records(records,Vector2(16,16)),"illegal source count rejected "+str(count))
		check(not ad.valid_segment([0,0],count),"illegal segment count rejected "+str(count))
	var base:Array=[{"region":[0,0,8,8],"alpha_bbox":[0,0,8,8]},{"region":[8,0,8,8]}]
	for bad in [null,"wrong",{},true,12]:check(not ad.valid_records(bad,Vector2(16,8)),"wrong records type rejected "+str(bad))
	for bad in [null,"wrong",[],true,12]:
		var records:Array=base.duplicate(true);records[0]=bad
		check(not ad.valid_records(records,Vector2(16,8)),"wrong record object rejected "+str(bad))
	for region in [[0,0,0,8],[0,0,8,0],[-1,0,8,8],[0,0,17,8],[0,1,8,8],[0,0,7,8],[.5,0,8,8],[NAN,0,8,8],[0,INF,8,8],[0,0,"8",8],[],null]:
		var records:Array=base.duplicate(true);records[0].region=region
		check(not ad.valid_records(records,Vector2(16,8)),"invalid geometry/canvas rejected "+str(region))
	for box in [[0,0,0,8],[-1,0,8,8],[0,0,9,8],[0,NAN,8,8],[0,0,8,INF],[],null,"wrong"]:
		var records:Array=base.duplicate(true);records[0].alpha_bbox=box
		check(not ad.valid_records(records,Vector2(16,8)),"invalid effective alpha box rejected "+str(box))
	var padded:Array=[{"region":[0,0,8,8],"margin":[0,2,0,2],"alpha_bbox":[0,2,8,8]},{"region":[8,0,8,6],"margin":[0,4,0,4],"alpha_bbox":[0,4,8,6]}]
	check(ad.valid_records(padded,Vector2(16,8)),"different safe physical crops with same padded logical canvas accepted")
	for margin in [[-1,0,0,0],[0,-1,0,0],[0,1,0,0],[1,0,0,0],[0,NAN,0,0],[0,0,0,INF],[0,.5,0,1],[0,0,0,"2"],[],null,"wrong"]:
		var bad:Array=base.duplicate(true);bad[0].margin=margin
		check(not ad.valid_records(bad,Vector2(16,8)),"invalid padding safely rejected "+str(margin))
	var bad_canvas:Array=base.duplicate(true);bad_canvas[0].margin=[0,0,0,2]
	check(not ad.valid_records(bad_canvas,Vector2(16,8)),"per-row padding cannot change logical clip canvas")
	for size in [Vector2.ZERO,Vector2(-1,8),Vector2(16,0),Vector2(NAN,8),Vector2(16,INF)]:
		check(not ad.valid_records(base,size),"nonpositive/nonfinite source dimensions rejected "+str(size))
	var boundary:Array=base.duplicate(true)
	for record in boundary:record.margin=[0,0,4088,4088]
	check(ad.valid_records(boundary,Vector2(16,8)),"logical 4096 by 4096 boundary accepted without allocating pixels")
	for padding in [[0,0,4089,4088],[0,0,4088,4089],[0,0,1e300,1e300]]:
		var excessive:Array=base.duplicate(true)
		for record in excessive:record.margin=padding
		check(not ad.valid_records(excessive,Vector2(16,8)),"oversized logical canvas rejected before construction "+str(padding))
	var records:Array=base.duplicate(true);records[0].path="res://assets/enemies/crawler.png"
	check(not ad.valid_records(records,Vector2(16,8)),"unsupported per-record source path explicitly rejected rather than ignored")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(943)
	var e:Dictionary=g._spawn_kind("brood_keeper",g.player_pos+Vector2(200,0))
	var ad=g.actor_anim
	verify_records(ad)
	var a:Dictionary=ad.actors[e.id]
	var base_frame:AtlasTexture=a.base_frames.get_frame_texture("walk",0)
	var baseline_height:float=base_frame.region.size.y*absf(a.base_scale.y)
	var baseline_width:float=base_frame.region.size.x*absf(a.base_scale.x)
	check(is_equal_approx(a.height,baseline_height),"actor reference equals existing visible walk height, not padded canvas")
	for id in ["brood_keeper_summon","brood_keeper_hurt","brood_keeper_death"]:
		check(ad.assets.has(id),"production resource truly loaded "+id)
		if not ad.assets.has(id):continue
		var asset:Dictionary=ad.assets[id]
		var expected:int=9 if id=="brood_keeper_hurt" else 16
		check(asset.frames.get_frame_count("action")==expected and asset.records.size()==expected,"exact contracted real frame count "+id)
		var scale_value:float=baseline_height/asset.reference_height
		var box:Array=asset.records[0].alpha_bbox
		check(absf(float(box[3])*scale_value-baseline_height)<.1,"neutral frame world height matches walk "+id)
		check(absf(float(box[2])*scale_value-baseline_width)/baseline_width<.15,"neutral body width comparable to old walk "+id)
		if id=="brood_keeper_death":
			for pose in range(1,expected):
				check(asset.records[pose].alpha_bbox[3]-asset.records[pose-1].alpha_bbox[3]<=2,"authored dying sequence does not stand back up after collapse "+str(pose))
			for grounded in [0,1]:
				var contact:Array=asset.records[grounded].alpha_bbox
				check(absf(contact[1]+contact[3]-asset.frames.get_frame_texture("action",0).get_size().y*asset.anchor[1])<=1,"death entry effective contact matches fixed anchor "+str(grounded))
		var fixed_size:Vector2=asset.frames.get_frame_texture("action",0).get_size()
		for index in range(expected):
			var texture:AtlasTexture=asset.frames.get_frame_texture("action",index)
			var region:Rect2=texture.region
			check(texture.get_size()==fixed_size,"fixed clip canvas "+id+" frame "+str(index))
			check(region.position.x>=0 and region.position.y>=0 and region.end.x<=texture.atlas.get_width() and region.end.y<=texture.atlas.get_height(),"source region in bounds "+id+" frame "+str(index))
			var record:Dictionary=asset.records[index]
			check(record.alpha_bbox[2]>0 and record.alpha_bbox[3]>0 and record.alpha_bbox[0]>=0 and record.alpha_bbox[1]>=0 and record.alpha_bbox[0]+record.alpha_bbox[2]<=texture.get_size().x and record.alpha_bbox[1]+record.alpha_bbox[3]<=texture.get_size().y,"nonempty declared alpha inside cell "+id+" frame "+str(index))
		# Present the complete hurt/death clip; no engine automatic animation may advance it.
		if id!="brood_keeper_summon":
			a.reaction="hurt" if id=="brood_keeper_hurt" else "death";a.duration=1.0
			for index in range(expected):
				a.age=(index+.1)/float(expected);ad._present(a)
				check(e.sprite.frame==index and a.asset_id==id and a.source==("authored nine-frame" if expected==9 else "authored 16-frame"),"authored ordered reaction "+id+" frame "+str(index))
				check(is_equal_approx(e.sprite.scale.x,scale_value) and e.sprite.scale==Vector2.ONE*scale_value,"fixed scale preserves actual pose deformation "+id+" frame "+str(index))
				var rendered_anchor:Vector2=(fixed_size*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+e.sprite.offset)*e.sprite.scale
				check(rendered_anchor.is_equal_approx(a.base_foot),"fixed anchor matches existing walk foot "+id+" frame "+str(index))
				check(not e.sprite.is_playing(),"no autonomous engine clip timer "+id+" frame "+str(index))
	a.reaction=""
	if ad.assets.has("brood_keeper_summon"):
		var asset:Dictionary=ad.assets.brood_keeper_summon
		for row in [["warning",0,6],["attack",7,7],["recover",7,15]]:
			for index in range(row[1],row[2]+1):
				var progress:float=(index-row[1]+.1)/(row[2]-row[1]+1)
				ad.set_phase(e.id,row[0],progress)
				check(e.sprite.frame==index,"authoritative segmented frame "+row[0]+" "+str(index))
				check(is_equal_approx(e.sprite.scale.y,baseline_height/asset.reference_height),"charge segment keeps one scale "+str(index))
			for progress in [-10.0,10.0]:
				ad.set_phase(e.id,row[0],progress)
				check(e.sprite.frame>=row[1] and e.sprite.frame<=row[2],"clamped phase cannot cross segment "+row[0])
		ad.set_phase(e.id,"warning",.99);ad.set_phase(e.id,"recover",.9)
		check(e.sprite.frame==15,"skipped low-FPS phases show current recovery, not replay charge")
	# Actual event/frame synchronization, not just manually selected presentation phases.
	g.spawn_clock=999;g.weapon_clocks=[999.0]
	e.ai_state="warning";e.warning_left=.06;e.attack="summon";e.cooldown_left=999;e.aim=Vector2.LEFT
	g._simulate(.05)
	check(e.sprite.frame<7 and g.enemies.size()==1,"real pre-release tick cannot show release or child")
	g._simulate(.05)
	check(e.sprite.frame==7 and g.enemies.size()==2,"real summon attempt and source release7 occur in same authoritative tick")
	e.ai_state="warning";e.warning_left=.01
	ad.trigger(e.id,"hurt");g._simulate(.05)
	check(a.state=="hurt" and g.enemies.size()==3,"hurt conceals only body attempt, never child")
	for step in range(6):g._simulate(.05)
	ad.advance(.3)
	check(a.state=="recover" and e.sprite.frame>7 and g.enemies.size()==3,"hurt end displays current recovery frame without replaying attempt7")
	e.ai_state="warning";e.warning_left=.001;g._simulate(.05)
	check(g.enemies.size()==4 and e.sprite.frame==7,"third child genuinely spawned at attempt frame7")
	var next_id:int=g.next_enemy_id
	e.ai_state="warning";e.warning_left=.001;g._simulate(.05)
	check(g.enemies.size()==4 and g.next_enemy_id==next_id and e.sprite.frame==7,"capped attempt frame7 never means guaranteed child appearance")
	check(ad.valid_segment([15,15],16) and ad.valid_segment([0,15],16),"16-frame valid upper boundary accepted")
	check(not ad.valid_segment([16,16],16) and not ad.valid_segment([-1,15],16),"16-frame out-of-bounds segment rejected")
	check(not ad.valid_segment([9,9]) and ad.valid_segment([8,8]),"default segment validator retains old nine-frame boundary")
	for bad in [[NAN,8],[0,INF],[1.5,7],[8,7],"wrong",null]:check(not ad.valid_segment(bad,16),"malformed variable-frame segment safely rejected "+str(bad))
	e.hp=0;g._simulate(.001)
	ad.advance(.70)
	check(ad.actors.has(e.id) and e.sprite.frame==15,"sixteenth death pose accessible before unchanged .72 duration")
	ad.advance(.021)
	check(not ad.actors.has(e.id),"more source poses do not extend original corpse lifetime")
	g.queue_free();await process_frame
	print("INDEPENDENT BROOD ASSETS: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
