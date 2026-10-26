extends SceneTree
func nodes(n:Node)->Array:
 var a:Array=[n]
 for c in n.get_children():a.append_array(nodes(c))
 return a
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var b:Array=nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with("SWITCH TO"))
 var old:Callable=b[0].get_signal_connection_list("pressed")[0].callable
 g._select_starting_loadout("scatter",g.title_generation)
 await process_frame;await process_frame;await process_frame
 var before:Dictionary={"mode":g.mode.id,"seed":g.run_seed,"generation":g.title_generation,"selected":g.selected_loadout_id}
 old.call()
 var after:Dictionary={"mode":g.mode.id,"seed":g.run_seed,"generation":g.title_generation,"selected":g.selected_loadout_id}
 print(JSON.stringify({"retained_mode_callback":true,"authority_unchanged":before==after}))
 g.queue_free();await process_frame;quit()
