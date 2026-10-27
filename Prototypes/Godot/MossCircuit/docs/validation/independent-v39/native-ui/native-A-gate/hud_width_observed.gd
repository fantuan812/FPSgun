extends "<WORKSPACE>/moss-v39-ui/tests/test_expansion_hud_width.gd"
## Read-only dimensions observer. Parent author fixture remains exact frozen bytes.
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_size)
	super._initialize()
func _observe_size()->void:
	var values:Dictionary={"logical_visible_rect":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale_size":str(root.content_scale_size),"os_window_size":str(DisplayServer.window_get_size())}
	var encoded:String=JSON.stringify(values)
	if encoded!=observed_size:
		observed_size=encoded;print("UI_NATIVE_DIMENSIONS "+encoded)
