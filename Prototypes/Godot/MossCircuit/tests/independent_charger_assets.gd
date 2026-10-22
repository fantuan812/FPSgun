extends SceneTree
var passed:=0
var failures:Array=[]
func check(v:bool,s:String)->void:
	if v:passed+=1
	else:failures.append(s)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=load("res://scenes/main.tscn").instantiate()
	root.add_child(g);g.set_process(false);g._start_run(943)
	var e:Dictionary=g._spawn_kind("charger",g.player_pos+Vector2(200,0))
	var ad=g.actor_anim
	var a:Dictionary=ad.actors[e.id]
	var base_frame:AtlasTexture=a.base_frames.get_frame_texture("walk",0)
	var baseline_height:float=base_frame.region.size.y*absf(a.base_scale.y)
	var baseline_width:float=base_frame.region.size.x*absf(a.base_scale.x)
	check(is_equal_approx(a.height,baseline_height),"actor reference equals existing visible walk height, not padded canvas")
	for id in ["charger_charge","charger_hurt","charger_death"]:
		check(ad.assets.has(id),"production resource truly loaded "+id)
		if not ad.assets.has(id):continue
		var asset:Dictionary=ad.assets[id]
		check(asset.frames.get_frame_count("action")==9 and asset.records.size()==9,"nine actual frames "+id)
		var scale_value:float=baseline_height/asset.reference_height
		var box:Array=asset.records[0].alpha_bbox
		check(absf(float(box[3])*scale_value-baseline_height)<.1,"neutral frame world height matches walk "+id)
		check(absf(float(box[2])*scale_value-baseline_width)/baseline_width<.15,"neutral body width comparable to old walk "+id)
		if id=="charger_death":
			check(asset.records[0].region[1]==59 and asset.records[1].region[1]==63,"only authored death entry crops carry explicit grounding offsets")
			for grounded in [0,1]:
				var contact:Array=asset.records[grounded].alpha_bbox
				check(contact[1]+contact[3]==300,"death entry effective contact matches fixed anchor "+str(grounded))
		var fixed_size:Vector2=asset.frames.get_frame_texture("action",0).get_size()
		for index in range(9):
			var texture:AtlasTexture=asset.frames.get_frame_texture("action",index)
			var region:Rect2=texture.region
			check(texture.get_size()==fixed_size,"fixed clip canvas "+id+" frame "+str(index))
			check(region.position.x>=0 and region.position.y>=0 and region.end.x<=texture.atlas.get_width() and region.end.y<=texture.atlas.get_height(),"source region in bounds "+id+" frame "+str(index))
			var record:Dictionary=asset.records[index]
			check(record.alpha_bbox[2]>0 and record.alpha_bbox[3]>0 and record.alpha_bbox[0]>=0 and record.alpha_bbox[1]>=0 and record.alpha_bbox[0]+record.alpha_bbox[2]<=region.size.x and record.alpha_bbox[1]+record.alpha_bbox[3]<=region.size.y,"nonempty declared alpha inside cell "+id+" frame "+str(index))
		# Present the complete hurt/death clip; no engine automatic animation may advance it.
		if id!="charger_charge":
			a.reaction="hurt" if id=="charger_hurt" else "death";a.duration=1.0
			for index in range(9):
				a.age=(index+.1)/9.0;ad._present(a)
				check(e.sprite.frame==index and a.source=="authored nine-frame","authored ordered reaction "+id+" frame "+str(index))
				check(is_equal_approx(e.sprite.scale.x,scale_value) and e.sprite.scale==Vector2.ONE*scale_value,"fixed scale preserves actual pose deformation "+id+" frame "+str(index))
				var rendered_anchor:Vector2=(fixed_size*(Vector2(asset.anchor[0],asset.anchor[1])-Vector2(.5,.5))+e.sprite.offset)*e.sprite.scale
				check(rendered_anchor.is_equal_approx(a.base_foot),"fixed anchor matches existing walk foot "+id+" frame "+str(index))
				check(not e.sprite.is_playing(),"no autonomous engine clip timer "+id+" frame "+str(index))
	a.reaction=""
	if ad.assets.has("charger_charge"):
		var asset:Dictionary=ad.assets.charger_charge
		for row in [["warning",0,3],["attack",4,6],["recover",7,8]]:
			for index in range(row[1],row[2]+1):
				var progress:float=(index-row[1]+.1)/(row[2]-row[1]+1)
				ad.set_phase(e.id,row[0],progress)
				check(e.sprite.frame==index,"authoritative segmented frame "+row[0]+" "+str(index))
				check(is_equal_approx(e.sprite.scale.y,baseline_height/asset.reference_height),"charge segment keeps one scale "+str(index))
			for progress in [-10.0,10.0]:
				ad.set_phase(e.id,row[0],progress)
				check(e.sprite.frame>=row[1] and e.sprite.frame<=row[2],"clamped phase cannot cross segment "+row[0])
		ad.set_phase(e.id,"warning",.99);ad.set_phase(e.id,"recover",.9)
		check(e.sprite.frame==8,"skipped low-FPS phases show current recovery, not replay charge")
	g.queue_free();await process_frame
	print("INDEPENDENT CHARGER ASSETS: ",passed," passed; ",failures.size()," failed")
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
