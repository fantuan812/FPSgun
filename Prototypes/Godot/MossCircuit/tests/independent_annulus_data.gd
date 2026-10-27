extends SceneTree
const EncounterHistory=preload("res://tests/support/v38_encounter_projection.gd")
# Independent fixed-roster/data oracle. The projection masks exactly seven reviewed
# Broodkeeper fields plus the five explicitly reviewed v32 Amber Ram fields.
# The original semantic golden remains unchanged; no whole entry is masked.
const AI=preload("res://scripts/enemy_ai.gd")
const OLD_ROSTER_SHA="f7a0ebd9273c2627f657a1a66099b2a56028ee5ec5e4acc719730bd7c080d31c"
var count:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 count+=1
 if not ok:failures.append(label)
func keeper(c:Dictionary)->Dictionary:
 for e in c.enemies:
  if e.id=="brood_keeper":return e
 return {}
func _initialize()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
 ck(AI.validate(c).is_empty(),"current encounter config valid")
 var encounter_history:Dictionary=EncounterHistory.project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))
 ck(encounter_history.get("pass",false),"strict v38 additions before original historical roster oracle")
 c=encounter_history.encounters
 ck(c.enemies.map(func(e):return e.id)==["crawler","charger","spitter","flanker","brood_keeper","boss_warden","boss_core"],"exact old seven IDs/order")
 var e:Dictionary=keeper(c)
 ck(e.behavior=="brood_cycle","only keeper opts in")
 ck(e.get("pulse_inner_radius")==70 and e.get("pulse_outer_radius")==180 and e.get("pulse_warning")==1.0,"frozen shipped pulse tuning")
 var masked:Dictionary=c.duplicate(true)
 # Restore exactly the reviewed v32 charger copy/opt-in to the old projection.
 for old in masked.enemies:
  if old.id=="charger":
   old.erase("brace_degrees");old.erase("brace_multiplier")
   old.description="Locks direction, warns, then charges in a straight line."
   old.tell="Orange line marks the locked dash route for 0.65 s."
   old.dodge="Step sideways; warning and recovery are contact-safe."
 for k in ["behavior","description","tell","dodge","pulse_inner_radius","pulse_outer_radius","pulse_warning"]:keeper(masked).erase(k)
 ck(JSON.stringify(masked).sha256_text()==OLD_ROSTER_SHA,"all old roster/waves values/order exact outside seven Brood and five reviewed charger fields")
 for field in ["pulse_inner_radius","pulse_outer_radius","pulse_warning"]:
  for value in [null,true,false,"70",[],{},0,-1,NAN,INF,-INF]:
   var bad:Dictionary=c.duplicate(true);keeper(bad)[field]=value
   ck(not AI.validate(bad).is_empty(),"reject "+field+" type="+str(typeof(value))+" value="+str(value))
  var missing:Dictionary=c.duplicate(true);keeper(missing).erase(field)
  ck(not AI.validate(missing).is_empty(),"reject missing "+field)
 for outer in [1.0,69.99,70.0]:
  var bad:Dictionary=c.duplicate(true);keeper(bad).pulse_outer_radius=outer
  ck(not AI.validate(bad).is_empty(),"reject reversed/empty band "+str(outer))
 var old:Dictionary=c.duplicate(true);keeper(old).behavior="summon"
 for key in ["pulse_inner_radius","pulse_outer_radius","pulse_warning"]:keeper(old).erase(key)
 ck(AI.validate(old).is_empty(),"legacy summon behavior still supported")
 var result:Dictionary={"checks":count,"failures":failures,"scope":"controlled exact historical roster preservation after strict declared v38 enemy/wave/Rooms append reversal and malformed new-field validation; not gameplay/native/balance evidence"}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
