extends SceneTree
func _initialize():
 call_deferred("run")
func run():
 var old_scene=load("<WORKSPACE>/moss-v38-svg-author-review/scene-diagnostic/old.scn")
 var new_scene=load("<WORKSPACE>/moss-v38-svg-author-review/scene-diagnostic/new.scn")
 var failures:Array=[]
 if not old_scene is PackedScene or not new_scene is PackedScene:
  failures.append("both actual extracted resources must decode as PackedScene")
  print(JSON.stringify({"pass":false,"failures":failures}));quit(1);return
 var before:Dictionary=old_scene.get("_bundled")
 var after:Dictionary=new_scene.get("_bundled")
 var keys_before=before.keys();var keys_after=after.keys();keys_before.sort();keys_after.sort()
 if keys_before!=keys_after:failures.append("bundled keys changed")
 var different:Array=[]
 for key in keys_before:
  if not after.has(key) or var_to_bytes(before[key])!=var_to_bytes(after[key]):different.append(key)
 if different!=["node_ids"]:failures.append("only node_ids may differ")
 if not before.node_ids is PackedInt32Array or not after.node_ids is PackedInt32Array or before.node_ids.size()!=1 or after.node_ids.size()!=1:failures.append("node_ids exact type/count")
 if before.node_count!=1 or after.node_count!=1 or before.conn_count!=0 or after.conn_count!=0:failures.append("single-node scene topology")
 var report={"pass":failures.is_empty(),"failures":failures,"different_bundled_fields":different,"old_node_ids":Array(before.node_ids),"new_node_ids":Array(after.node_ids),"bundled_keys":keys_before,"node_count":before.node_count,"connection_count":before.conn_count,"old_names":Array(before.names),"new_names":Array(after.names),"scope":"Resource decoding only, no instantiate, no gameplay/native acceptance; original strict byte gate stays rejected"}
 print(JSON.stringify(report))
 before.clear();after.clear();old_scene=null;new_scene=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
