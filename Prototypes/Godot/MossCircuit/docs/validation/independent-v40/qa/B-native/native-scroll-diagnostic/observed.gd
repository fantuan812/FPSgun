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
var scroll_trace_context:Dictionary={}
var scroll_step_index:int=0
func pointer(at:Vector2,which:int,pressed:bool)->void:
	if not scroll_trace_context.is_empty() and which in [MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_UP] and pressed:
		trace_scroll("before",scroll_step_index,scroll_trace_context.first,scroll_trace_context.last,scroll_trace_context.scroll)
		print("B_SCROLL_DIAGNOSTIC "+JSON.stringify({"phase":"wheel_direction","iteration":scroll_step_index,"direction":which}))
	super.pointer(at,which,pressed)
func frames()->void:
	await super.frames()
	if not scroll_trace_context.is_empty():
		trace_scroll("after",scroll_step_index,scroll_trace_context.first,scroll_trace_context.last,scroll_trace_context.scroll)
		scroll_step_index+=1
func scroll_group(first:Control,last:Control)->bool:
	var scroll:ScrollContainer=scroll_of(first) if first!=null else null
	scroll_trace_context={"first":first,"last":last,"scroll":scroll};scroll_step_index=0
	trace_scroll("start",0,first,last,scroll)
	# Original parent owns all24 bounded wheel inputs, waits and fit predicates.
	var result:bool=await super.scroll_group(first,last)
	trace_scroll("success" if result else "budget_end",scroll_step_index,first,last,scroll)
	scroll_trace_context={}
	if not result:
		scroll_failure_index+=1
		var name:String="scroll_fail_%d.png" % scroll_failure_index
		var saved:int=root.get_texture().get_image().save_png(OS.get_environment("MOSS_B_UI_IMAGES").path_join(name))
		print("B_SCROLL_DIAGNOSTIC "+JSON.stringify({"phase":"pre_return_failure_image","name":name,"save_error":saved}))
	return result
