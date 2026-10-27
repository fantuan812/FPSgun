extends "<WORKSPACE>/moss-v39-ui/equipment16-native-r2/cards.gd"
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_size)
	super._initialize()
func _observe_size()->void:
	var v:Dictionary={"logical_visible_rect":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale_size":str(root.content_scale_size),"os_window_size":str(DisplayServer.window_get_size()),"os_position":str(DisplayServer.window_get_position())}
	var encoded:String=JSON.stringify(v)
	if encoded!=observed_size:observed_size=encoded;print("UI_NATIVE_DIMENSIONS "+encoded)
