extends SceneTree
var g
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);root.size=Vector2i(960,540)
 for mode in ["arena","rooms"]:
  g._title();g._select_mode(mode);g._start_run(1);g._update_hud();await process_frame;await process_frame
  var label:Label=g.mode_status.objective
  print(JSON.stringify({"mode":mode,"focused":false,"size":str(label.size),"minimum":str(label.get_minimum_size()),"lines":label.get_line_count(),"height":label.get_line_height(),"text":label.text}))
  var e:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(100,0));g.combat.focus_enemy_id=e.id;g._update_hud();await process_frame;await process_frame
  print(JSON.stringify({"mode":mode,"focused":true,"size":str(label.size),"minimum":str(label.get_minimum_size()),"lines":label.get_line_count(),"height":label.get_line_height(),"text":label.text}))
 g.queue_free();await process_frame;quit()
