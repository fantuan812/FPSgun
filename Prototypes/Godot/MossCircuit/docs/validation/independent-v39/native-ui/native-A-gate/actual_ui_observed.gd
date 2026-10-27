extends "<WORKSPACE>/moss-v39-ui/tests/test_expansion_actual_ui.gd"
## Read-only dimensions observer. Parent author fixture remains exact original bytes.
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_size)
	super._initialize()
func _dimensions()->Dictionary:
	return {"logical_visible_rect":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale_size":str(root.content_scale_size),"os_window_size":str(DisplayServer.window_get_size())}
func _observe_size()->void:
	var values:Dictionary=_dimensions();var encoded:String=JSON.stringify(values)
	if encoded!=observed_size:
		observed_size=encoded;print("UI_NATIVE_DIMENSIONS "+encoded)
func screenshot(name:String)->void:
	var values:Dictionary=_dimensions();values.image_name=name+".png"
	print("UI_IMAGE_DIMENSIONS "+JSON.stringify(values))
	super.screenshot(name)
