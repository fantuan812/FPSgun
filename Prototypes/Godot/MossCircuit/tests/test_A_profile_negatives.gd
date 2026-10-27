extends SceneTree
## Frozen author contract negatives, run unchanged against pre-fix and minimal-fix candidates.
const Profiles=preload("res://scripts/gameplay/new_weapon_profiles.gd")
const Rules=preload("res://scripts/rules.gd")
var checks:int=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 ck(Rules.validate_catalog(c).is_empty(),"valid actual A catalog")
 var invalid:Array=[true,false,null,"1",0.5,NAN,INF,-INF]
 for id in ["tether_emitter","seismic_drum"]:
  var original:Dictionary=Rules.catalog_entry(c,id)
  ck(not Profiles.weapon(original).is_empty(),"valid weapon "+id)
  var fields:Array=["projectiles","spread","pierce","pulse_count" if id=="tether_emitter" else "max_live_per_slot"]
  for field in fields:
   for i in range(invalid.size()):
    var bad:Dictionary=original.duplicate(true);bad[field]=invalid[i]
    var definition=Profiles.weapon(bad)
    ck(definition is Dictionary and definition.is_empty(),id+" pure rejects "+field+" case "+str(i))
    var edited:Dictionary=c.duplicate(true);Rules.catalog_entry(edited,id)[field]=invalid[i]
    var errors=Rules.validate_catalog(edited)
    ck(errors is Array and not errors.is_empty(),id+" Rules rejects "+field+" case "+str(i))
 for id in ["lock_memory","return_collar"]:
  var original:Dictionary=Rules.catalog_entry(c,id)
  ck(not Profiles.module(original).is_empty(),"valid module "+id)
  for i in range(invalid.size()):
   var bad:Dictionary=original.duplicate(true);bad.max_stack=invalid[i]
   var definition=Profiles.module(bad)
   ck(definition is Dictionary and definition.is_empty(),id+" pure rejects max_stack case "+str(i))
   var edited:Dictionary=c.duplicate(true);Rules.catalog_entry(edited,id).max_stack=invalid[i]
   var errors=Rules.validate_catalog(edited)
   ck(errors is Array and not errors.is_empty(),id+" Rules rejects max_stack case "+str(i))
 print(JSON.stringify({"checks":checks,"failures":failures,"pass":failures.is_empty(),"scope":"165 pure/Rules malformed A count/profile validations; strict raw script errors independently fail gate; no gameplay/native claim"}))
 quit(0 if failures.is_empty() else 1)
