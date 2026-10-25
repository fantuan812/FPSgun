extends SceneTree
const Director = preload("res://scripts/actor_director.gd")
const Art = preload("res://scripts/art.gd")
var checks := 0
var failures := 0
func check(ok:bool,message:String)->void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize()->void:
	var manifest:Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/actions/crawler/action_manifest.json"))
	var audit:Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/art/crawler_hurt_registration/semantic-audit.json"))
	var asset:Dictionary = manifest.actions.crawler_hurt
	check(asset.frames.size() == 9, "Nine original hurt poses")
	check(asset.reference_height == 260, "Fixed reference height")
	check(is_equal_approx(asset.duration_seconds,.27), "Original hurt duration")
	check(asset.anchor == [.5,.8], "Fixed centered anchor")
	check(Director.valid_records(asset.frames,Vector2(1268,1241)), "Safe source records")
	var sprite:AnimatedSprite2D = Art.actor("res://assets/beetle_walk.png",57.0,9.0)
	var director = Director.new()
	director.load_default()
	director.register_actor(700,sprite,"crawler",57)
	var actual_height:float = director.actors[700].height
	check(is_equal_approx(actual_height,255.0*57.0/414.0), "True existing crawler visible spawn height, not assumed requested57")
	check(actual_height > 35 and actual_height < 36, "True small-scale actor height")
	for flip in [false,true]:
		sprite.flip_h = flip
		director.trigger(700,"hurt")
		for i in range(9):
			var record:Dictionary = asset.frames[i]
			var original:Dictionary = audit.frames[i].before_record
			var correction:int = [-25,-4,26][i%3]
			for j in range(4):check(record.region[j] == original.region[j], "Source region preserved %d/%d" % [i,j])
			check(record.margin[0]-original.margin[0] == correction, "Fixed column correction %d" % i)
			check(record.alpha_bbox[0]-original.alpha_bbox[0] == correction, "Descriptive alpha X follows translation %d" % i)
			for j in range(1,4):
				check(record.margin[j] == original.margin[j], "No Y/size margin change %d/%d" % [i,j])
				check(record.alpha_bbox[j] == original.alpha_bbox[j], "No alpha Y/size change %d/%d" % [i,j])
			director.actors[700].age = .27*(float(i)+.5)/9
			director._present(director.actors[700])
			check(sprite.frame == i, "Original chronological frame %d" % i)
			check(is_equal_approx(sprite.scale.x,actual_height/260), "No per-frame rescale %d" % i)
			var texture:Texture2D = sprite.sprite_frames.get_frame_texture("action",i)
			check(texture.get_size() == Vector2(512,400), "Fixed canvas %d" % i)
			var anchor:Vector2 = (texture.get_size()*Vector2(0,.3)+sprite.offset)*sprite.scale
			check(anchor.distance_to(director.actors[700].base_foot)<.001, "Fixed logical anchor %d" % i)
			check(sprite.flip_h == flip, "Mirroring retained %d" % i)
		director.advance(.3)
		check(director.state_of(700) == "idle", "Real hurt expiry returns to current idle")
	var world_dx:float = audit.after_terminal_eye_delta[0]*actual_height/260
	check(absf(world_dx)<.3, "Corrected terminal neutral eye delta under0.3world px, no claim about full GUI")
	print("CRAWLER REGISTRATION: %d checks, %d failures; actual height %.5f; terminal eye dx %.5f world px" % [checks,failures,actual_height,world_dx])
	sprite.free()
	quit(1 if failures else 0)
