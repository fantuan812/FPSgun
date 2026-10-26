extends SceneTree
func _initialize()->void:
 var out:Dictionary={"events":[],"tests":[]}
 for e in InputMap.action_get_events("ui_accept"):
  out.events.append({"class":e.get_class(),"text":e.as_text(),"device":e.device,"button":e.button_index if e is InputEventJoypadButton else -1})
 for index in range(4):
  var e:=InputEventJoypadButton.new();e.button_index=index;e.pressed=true
  out.tests.append({"index":index,"maps":InputMap.event_is_action(e,"ui_accept"),"pressed":e.is_action_pressed("ui_accept")})
 print(JSON.stringify(out));quit()
