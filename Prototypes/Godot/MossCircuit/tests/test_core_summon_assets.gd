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
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/actions/boss_core/attack_manifest.json"))
	check(manifest is Dictionary and manifest.get("actions",{}).has("boss_core_summon"), "Summon manifest missing")
	if failures:
		quit(1);return
	var asset:Dictionary = manifest.actions.boss_core_summon
	var texture = load(asset.path)
	check(texture is Texture2D, "Summon source texture imports")
	if not texture is Texture2D:
		quit(1);return
	check(texture.get_size() == Vector2(1312,1199), "Original source dimensions retained")
	check(Director.valid_records(asset.frames,texture.get_size()), "All records are safe")
	check(asset.frames.size() == 16, "Actual 16-frame clip; not forced to nine")
	check(asset.release_frame == 7, "Summon release pose is 7")
	check(asset.anchor == [0.5,0.8], "Fixed centered anchor preserves mirrored geometry")
	check(asset.reference_height == 246, "Fixed neutral height retained")
	var expected_segments:Dictionary = {"warning":[0,6],"attack":[7,7],"recover":[7,15]}
	for state in expected_segments:
		var segment:Array = asset.phase_frames[state]
		check(segment.size() == 2 and int(segment[0]) == expected_segments[state][0] and int(segment[1]) == expected_segments[state][1], "Authored segment " + state)
		check(Director.valid_segment(asset.phase_frames[state],16), "Valid segment " + state)
	for i in range(asset.frames.size()):
		var record:Dictionary = asset.frames[i]
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(record.region[0],record.region[1],record.region[2],record.region[3])
		atlas.margin = Rect2(record.margin[0],record.margin[1],record.margin[2],record.margin[3])
		atlas.filter_clip = true
		check(atlas.get_size() == Vector2(512,400), "Unified logical canvas %d" % i)
		check(record.source_pose_index == i, "Source chronological order %d" % i)
		var top:float = record.alpha_bbox[1]
		check(top >= 72 and top <= 75, "Upper-body hover registration without following roots %d" % i)
		check(atlas.get_image() != null, "Actual atlas resolves %d" % i)
	print("CORE SUMMON ART: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
