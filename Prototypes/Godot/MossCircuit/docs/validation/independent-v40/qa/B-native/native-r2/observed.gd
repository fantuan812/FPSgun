extends "evidence-workspace/moss-v39-ui/B/native-r2/fixture.gd"
## Read-only size observer. Cases, assertions, runtime and inputs unchanged.
var observed_size:String=""
func _initialize()->void:
	process_frame.connect(_observe_dimensions)
	super._initialize()
func _observe_dimensions()->void:
	var value:Dictionary={"logical":str(root.get_visible_rect()),"root_window_size":str(root.size),"content_scale":str(root.content_scale_size),"os_size":str(DisplayServer.window_get_size()),"os_position":str(DisplayServer.window_get_position())}
	var encoded:String=JSON.stringify(value)
	if encoded!=observed_size:observed_size=encoded;print("B_NATIVE_DIMENSIONS "+encoded)

func scroll_group(first:Control,last:Control)->bool:
	var result:bool=await super.scroll_group(first,last)
	var scroll:ScrollContainer=scroll_of(first) if first!=null else null
	var row:Dictionary={"result":result,"budget":128,"first_exists":first!=null,"last_exists":last!=null,"scroll_exists":scroll!=null}
	if first!=null:row.first_text=first.text if first is Label else first.get_class()
	if scroll!=null and first!=null and last!=null:
		row.merged_rect=str(first.get_global_rect().merge(last.get_global_rect()));row.scroll_rect=str(scroll.get_global_rect());row.scroll_vertical=scroll.scroll_vertical;row.bar_max=scroll.get_v_scroll_bar().max_value;row.bar_page=scroll.get_v_scroll_bar().page
	print("B_SCROLL_FINAL "+JSON.stringify(row))
	return result
