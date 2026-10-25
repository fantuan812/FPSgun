extends SceneTree
const Director = preload("res://scripts/actor_director.gd")
var checks := 0
var failures := 0
func check(value:bool, message:String)->void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize()->void:
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/actions/boss_warden/attack_manifest.json"))
	check(manifest is Dictionary and manifest.get("actions",{}).has("boss_warden_charge"), "Charge manifest missing")
	if failures:
		quit(1);return
	var asset:Dictionary = manifest.actions.boss_warden_charge
	var texture = load(asset.path)
	check(texture is Texture2D, "Charge source texture imports")
	if not texture is Texture2D:
		quit(1);return
	check(texture.get_size() == Vector2(1254,1254), "Original source dimensions retained")
	check(Director.valid_records(asset.frames,texture.get_size()), "All records are safe")
	check(asset.frames.size() == 16, "Actual 16-frame clip; not forced to nine")
	check(asset.release_frame == 6, "Charge release pose is 6")
	check(asset.anchor == [0.5,0.8], "Fixed centered anchor preserves mirrored geometry")
	check(asset.reference_height == 207, "Fixed neutral height retained")
	var expected_segments:Dictionary = {"warning":[0,5],"attack":[6,11],"recover":[12,15]}
	for state in expected_segments:
		var segment:Array = asset.phase_frames[state]
		check(segment.size() == 2 and int(segment[0]) == expected_segments[state][0] and int(segment[1]) == expected_segments[state][1], "Authored segment " + state)
		check(Director.valid_segment(asset.phase_frames[state],16), "Valid segment " + state)
	for pose in {"12":0,"13":10,"14":20,"15":31}:
		check(int(asset.authored_recovery_x_corrections[pose]) == {"12":0,"13":10,"14":20,"15":31}[pose], "Explicit semantic recovery correction " + pose)
	var first_box:Array = asset.frames[0].alpha_bbox
	var last_box:Array = asset.frames[15].alpha_bbox
	check(absf((first_box[0]+first_box[2]*.5)-(last_box[0]+last_box[2]*.5)) <= 4, "Neutral terminal horizontal handoff within four source pixels")
	for i in range(asset.frames.size()):
		var record:Dictionary = asset.frames[i]
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(record.region[0],record.region[1],record.region[2],record.region[3])
		atlas.margin = Rect2(record.margin[0],record.margin[1],record.margin[2],record.margin[3])
		atlas.filter_clip = true
		check(atlas.get_size() == Vector2(512,400), "Unified logical canvas %d" % i)
		check(record.source_pose_index == i, "Source chronological order %d" % i)
		var bottom:float = record.alpha_bbox[1] + record.alpha_bbox[3]
		check(bottom >= 317 and bottom <= 322, "Natural foot lift without row jump %d" % i)
		check(atlas.get_image() != null, "Actual atlas resolves %d" % i)
	print("WARDEN CHARGE ART: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
