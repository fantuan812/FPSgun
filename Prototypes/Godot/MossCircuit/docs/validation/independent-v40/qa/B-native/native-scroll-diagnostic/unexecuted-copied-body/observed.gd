extends "evidence-workspace/moss-v39-ui/B/native/observed.gd"
## Only telemetry. Same24 wheel ticks, same waits, same input order/predicates.
var scroll_failure_index:int=0
func trace_scroll(phase:String,index:int,first:Control,last:Control,scroll:ScrollContainer)->void:
	var row:Dictionary={"phase":phase,"iteration":index,"first_exists":first!=null,"last_exists":last!=null,"scroll_exists":scroll!=null}
	if first!=null:
		row.first_path=str(first.get_path());row.first_rect=str(first.get_global_rect());row.first_minimum=str(first.get_combined_minimum_size());row.first_text=first.text if first is Label else first.get_class()
	if last!=null:
		row.last_path=str(last.get_path());row.last_rect=str(last.get_global_rect());row.last_minimum=str(last.get_combined_minimum_size());row.last_text=last.text if last is Label else last.get_class()
	if scroll!=null:
		row.scroll_rect=str(scroll.get_global_rect());row.scroll_vertical=scroll.scroll_vertical;row.bar_max=scroll.get_v_scroll_bar().max_value;row.bar_page=scroll.get_v_scroll_bar().page
		row.content_minimum=str(scroll.get_child(0).get_combined_minimum_size())
		if first!=null and last!=null:
			var rect:Rect2=first.get_global_rect().merge(last.get_global_rect());row.merged_rect=str(rect);row.enclosed=fit_rect(scroll,rect)
	print("B_SCROLL_DIAGNOSTIC "+JSON.stringify(row))
func scroll_group(first:Control,last:Control)->bool:
	if first==null or last==null:
		trace_scroll("missing_target",-1,first,last,null);return false
	var scroll:ScrollContainer=scroll_of(first)
	if scroll==null:
		trace_scroll("missing_scroll",-1,first,last,null);return false
	for _step in range(24):
		trace_scroll("before",_step,first,last,scroll)
		var rect:Rect2=first.get_global_rect().merge(last.get_global_rect())
		if fit_rect(scroll,rect):
			trace_scroll("success",_step,first,last,scroll);return true
		var which:int=MOUSE_BUTTON_WHEEL_DOWN if rect.end.y>scroll.get_global_rect().end.y else MOUSE_BUTTON_WHEEL_UP
		pointer(scroll.get_global_rect().get_center(),which,true);pointer(scroll.get_global_rect().get_center(),which,false);await frames()
		trace_scroll("after",_step,first,last,scroll)
	var result:bool=fit_rect(scroll,first.get_global_rect().merge(last.get_global_rect()))
	trace_scroll("budget_end",24,first,last,scroll)
	if not result:
		scroll_failure_index+=1
		var name:String="scroll_fail_%d.png" % scroll_failure_index
		var saved:int=root.get_texture().get_image().save_png(OS.get_environment("MOSS_B_UI_IMAGES").path_join(name))
		print("B_SCROLL_DIAGNOSTIC "+JSON.stringify({"phase":"pre_return_failure_image","name":name,"save_error":saved}))
	return result
