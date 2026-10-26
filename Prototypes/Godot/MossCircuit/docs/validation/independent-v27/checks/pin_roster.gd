extends SceneTree
func _initialize()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
 for e in c.enemies:
  if e.id=="brood_keeper":
   for k in ["behavior","description","tell","dodge","pulse_inner_radius","pulse_outer_radius","pulse_warning"]:e.erase(k)
 print("BASELINE_ROSTER_PROJECTION="+JSON.stringify(c).sha256_text())
 quit()
