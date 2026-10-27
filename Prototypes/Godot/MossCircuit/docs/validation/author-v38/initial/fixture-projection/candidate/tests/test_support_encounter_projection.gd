extends SceneTree
const History=preload("res://tests/support/v38_encounter_projection.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var raw:String=FileAccess.get_file_as_string("res://data/encounters.json")
 var rooms:String=FileAccess.get_file_as_string("res://data/room_encounters.json")
 ck(History.project(raw,rooms).get("pass",false),"exact declared append reconstructs old raw")
 var changes:Array=[
  [raw.replace('"hp": 22','"hp": 23'),rooms,"old enemy field"],
  [raw.replace('"pool": [\n        "crawler"\n      ]','"pool": [\n        "flanker"\n      ]'),rooms,"old wave"],
  [raw.replace('"support_heal": 10','"support_heal": 11'),rooms,"new heal numeric"],
  [raw.replace('"color": "86e5ed"','"color": "ffffff"'),rooms,"new declared color"],
  [raw.replace('"name": "Stitch Drone"','"name": "Other Drone"'),rooms,"new declared name"],
  [raw,rooms.replace('[0.5,0.18]','[0.5,0.19]'),"room append position"],
  [raw,rooms.replace('"coins":24','"coins":25'),"old room reward"],
  [raw+" ",rooms,"extra raw text"],
  [raw,rooms+"\n","room raw text"],
  [raw,rooms.replace(',{"kind":"stitch_drone","at":[0.5,0.18]}',''),"missing two room additions"]]
 for change in changes:
  ck(change[0]!=raw or change[1]!=rooms,"negative actually mutates "+change[2])
  ck(not History.project(change[0],change[1]).get("pass",false),"reject "+change[2])
 var c:Dictionary=JSON.parse_string(raw)
 for which in range(5):
  var bad:Dictionary=c.duplicate(true)
  match which:
   0:bad.enemies.append(bad.enemies[-1].duplicate(true))
   1:bad.enemies.reverse()
   2:bad.waves[3].pool.append("crawler")
   3:bad.waves[3].pool.reverse()
   4:bad.waves[3]=17
  ck(not History.project(JSON.stringify(bad,"  ")+"\n",rooms).get("pass",false),"reject extra row or order "+str(which))
 var parsed_rooms:Dictionary=JSON.parse_string(rooms)
 for index in [1,2]:
  for malformed in [null,[]]:
   var bad_rooms:Dictionary=parsed_rooms.duplicate(true);bad_rooms.stages[index]=malformed
   ck(not History.project(raw,JSON.stringify(bad_rooms)).get("pass",false),"malformed room stage cleanly rejected")
 ck(raw==FileAccess.get_file_as_string("res://data/encounters.json") and rooms==FileAccess.get_file_as_string("res://data/room_encounters.json"),"read-only source and input values")
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Strict declared v38 additions and historical raw projection, with changed-value/extra/order/raw negative controls; not runtime gameplay."}))
 quit(0 if failures.is_empty() else 1)
