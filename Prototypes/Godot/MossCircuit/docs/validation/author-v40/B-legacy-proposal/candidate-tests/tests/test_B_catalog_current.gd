extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
const Profiles=preload("res://scripts/gameplay/build_items_profiles.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).player
 ck(Rules.validate_catalog(c).is_empty(),"actual B catalog valid")
 ck(c.weapons.size()==10 and c.items.size()==36 and c.mechanism_synergies.size()==17 and c.affinity_links.size()==14,"actual10/36/17/14")
 ck(c.weapon_slots==4 and c.item_slots==8,"actual slot caps4/8")
 ck(Profiles.configuration(c).ok,"detached B registry valid")
 for data in [["crossfire_pin",28,14,"crossfire_control"],["salvage_capacitor",28,15,"salvage_field"],["medic_winch",24,16,"medical_recovery"]]:
  var id:String=data[0];var index:int=data[2];var entry:Dictionary=Rules.catalog_entry(c,id)
  ck(entry.kind=="item" and entry.price==data[1] and entry.max_stack==1 and entry.effects.is_empty(),"B unique price and no stat effects "+id)
  ck(not Profiles.definition(entry).is_empty() and c.mechanism_synergies[index].id==data[3],"exact profile and mechanism index "+id)
  var b:Dictionary=Rules.new_build(c);b.weapons=["rivet_gun","scrap_shotgun"];b.coins=100
  if id=="medic_winch":b.items={"medic_seed":1}
  var before:Dictionary=b.duplicate(true);var stats:Dictionary=Rules.derive(base,b,c);var catalog_before:Dictionary=c.duplicate(true)
  var statuses:Array=Forecast.mechanism_status(b,c)
  ck(statuses.size()==17 and not statuses[index].active,"actual B pair initially incomplete "+id)
  var predicted:Dictionary=Forecast.project(base,b,c,id)
  ck(predicted.available and predicted.mechanisms.size()==1 and predicted.mechanisms[0].index==index and predicted.mechanisms[0].change=="enables" and predicted.mechanisms[0].after.active,"forecast enables intended B mechanism only "+id)
  ck(b==before and c==catalog_before,"actual B forecast leaves build/catalog unchanged "+id)
  var error:String=Rules.transaction(b,c,id)
  ck(error.is_empty() and Forecast.mechanism_status(b,c)[index].active and b.coins==100-data[1],"actual B purchase activates exact mechanism and price "+id)
  ck(Rules.derive(base,b,c)==stats,"B mechanic adds no hidden stat bonus "+id)
 var pin:Dictionary=Rules.new_build(c);pin.items={"crossfire_pin":1};pin.weapons=["rivet_gun","rivet_gun"]
 ck(not Forecast.mechanism_status(pin,c)[14].active,"same type copies cannot satisfy Pin forecast")
 pin.weapons=["rivet_gun","scrap_shotgun"]
 ck(Forecast.mechanism_status(pin,c)[14].active,"two current types satisfy Pin forecast")
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"27 actual B catalog/profile/forecast/economy predicates; no texture or combat claim"}))
 quit(0 if failures.is_empty() else 1)
