extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 ck(Rules.validate_catalog(c).is_empty(),"valid current catalog")
 var expected:Dictionary=Rules.catalog_entry(c,"feedback_diode")
 ck(not expected.is_empty() and expected.max_stack==1 and expected.feedback_damage==24 and expected.price==28,"exact frozen module tuning")
 for value in ["bad",true,false,null,{},[],0,-1,1.5,2,INF,NAN]:
  var bad:Dictionary=c.duplicate(true);Rules.catalog_entry(bad,"feedback_diode").max_stack=value
  ck(not Rules.validate_catalog(bad).is_empty(),"reject max_stack type="+str(typeof(value))+" value="+str(value))
 for value in ["24",true,false,null,{},[],0,-1,1001,INF,NAN]:
  var bad:Dictionary=c.duplicate(true);Rules.catalog_entry(bad,"feedback_diode").feedback_damage=value
  ck(not Rules.validate_catalog(bad).is_empty(),"reject damage type="+str(typeof(value))+" value="+str(value))
 for field in ["max_stack","feedback_damage"]:
  var bad:Dictionary=c.duplicate(true);Rules.catalog_entry(bad,"feedback_diode").erase(field)
  ck(not Rules.validate_catalog(bad).is_empty(),"reject missing "+field)
 for numeric_one in [1,1.0]:
  var good:Dictionary=c.duplicate(true);Rules.catalog_entry(good,"feedback_diode").max_stack=numeric_one
  ck(Rules.validate_catalog(good).is_empty(),"accept numeric integral one")
 var result={"checks":checks,"failures":failures,"scope":"malformed new-entry type/bounds handling, errors must be returned without script exceptions"}
 var args=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
