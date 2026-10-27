extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Forecast=preload("res://scripts/gameplay/build_forecast.gd")
var checks:int=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var raw:String=FileAccess.get_file_as_string("res://data/catalog.json")
 var c:Dictionary=JSON.parse_string(raw)
 var b_input:Dictionary=preload("res://tests/support/v39_B_catalog_projection.gd").project(c,raw)
 if not b_input.pass:
  push_error("historical A fixture strict B input rejected");quit(1);return
 c=b_input.catalog;raw=b_input.bytes
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json")).player
 ck(Rules.validate_catalog(c).is_empty(),"actual current catalog schema")
 ck(c.weapons.size()==10 and c.items.size()==33 and c.mechanism_synergies.size()==14 and c.affinity_links.size()==14,"exact actual10/33/14/14")
 ck(preload("res://tests/support/v39_catalog_projection.gd").project(c,raw).pass,"all appended A definitions and untouched historical raw")
 for row in [["tether_emitter","lock_memory","electric",12,"remembered_lock"],["seismic_drum","return_collar","melee",13,"returning_resonance"]]:
  var b:Dictionary=Rules.new_build(c);b.weapons=[row[0]];b.coins=100
  var before:Dictionary=b.duplicate(true);var stats:Dictionary=Rules.derive(base,b,c)
  ck(Rules.catalog_entry(c,row[0]).tags==[row[2]] and Rules.shop_affinity(b,c).tags.get(row[2],0)==1,"new weapon explicit tag contribution "+row[0])
  ck(Rules.shop_affinity(b,c).missing_ids==[row[1]],"exact actual missing counterpart "+row[0])
  var status:Array=Forecast.mechanism_status(b,c)
  ck(status.size()==14 and not status[row[3]].active and c.mechanism_synergies[row[3]].id==row[4] and c.mechanism_synergies[row[3]].requires==[row[0],row[1]],"actual new pair incomplete "+row[0])
  var prediction:Dictionary=Forecast.project(base,b,c,row[1])
  ck(prediction.available and prediction.mechanisms.size()==1 and prediction.mechanisms[0].index==row[3] and prediction.mechanisms[0].change=="enables" and prediction.mechanisms[0].after.active,"actual forecast enables only intended pair "+row[0])
  ck(b==before,"new pair forecast is pure "+row[0])
  var error:String=Rules.transaction(b,c,row[1])
  ck(error.is_empty() and Forecast.mechanism_status(b,c)[row[3]].active and Rules.shop_affinity(b,c).missing_ids.is_empty(),"actual purchase completes pair and clears missing bias "+row[0])
  ck(Rules.derive(base,b,c)==stats,"mechanic module gives no hidden stat multiplier "+row[0])
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"17 original A catalog/tag/pair/affinity/forecast assertions under explicit strict B-only inverse, not combat or ordinaryplay"}))
 quit(0 if failures.is_empty() else 1)
