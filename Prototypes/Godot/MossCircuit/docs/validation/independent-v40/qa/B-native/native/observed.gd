extends "evidence-workspace/moss-v39-ui/B/native/fixture.gd"
## Read-only size observer. Cases, assertions, runtime and inputs unchanged.
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_dimensions)
	super._initialize()
func _observe_dimensions()->void:
	var value:Dictionary={"logical":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale":str(root.content_scale_size),"os_size":str(DisplayServer.window_get_size()),"os_position":str(DisplayServer.window_get_position())}
	var encoded:String=JSON.stringify(value)
	if encoded!=observed_size:observed_size=encoded;print("B_NATIVE_DIMENSIONS "+encoded)
