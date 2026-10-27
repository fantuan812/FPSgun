extends SceneTree
const B=preload("res://tests/support/v39_B_catalog_projection.gd")
const Combined=preload("res://tests/support/v39_B_then_A_catalog_projection.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var raw:String=FileAccess.get_file_as_string("res://data/catalog.json")
 var c:Dictionary=JSON.parse_string(raw);var original:Dictionary=c.duplicate(true)
 var a:Dictionary=B.project(c,raw)
 ck(a.pass and a.catalog.weapons.size()==10 and a.catalog.items.size()==33 and a.catalog.mechanism_synergies.size()==14 and a.catalog.affinity_links.size()==14,"B inverse exact A structure")
 ck(a.pass and a.bytes.sha256_text()=="67eb30bf64c36191f5e7609126da42b0195cb53840e00e60afa15ed55e13cccc","B inverse exact accepted A raw")
 var history:Dictionary=Combined.project(c,raw)
 ck(history.pass and history.catalog.weapons.size()==8 and history.catalog.items.size()==30 and history.catalog.mechanism_synergies.size()==12 and history.catalog.affinity_links.size()==12,"Combined reaches exact original catalog domain")
 ck(c==original and FileAccess.get_file_as_string("res://data/catalog.json")==raw,"positive projections leave original source unchanged")
 for case in range(9):
  var bad:Dictionary=c.duplicate(true);var text:String=raw
  match case:
   0:bad.items[-1].price+=1
   1:bad.weapons[0].damage+=1
   2:bad.mechanism_synergies[-1].requires=["medic_winch"]
   3:bad.items.pop_back()
   4:bad.items.reverse()
   5:bad.affinity_links.pop_back()
   6:text+=" "
   7:text=text.replace('"crossfire_pin"','"wrong_pin"')
   8:text="{}"
  var before:Dictionary=bad.duplicate(true);var failed:Dictionary=B.project(bad,text)
  ck(not failed.pass and failed.catalog.is_empty() and failed.bytes.is_empty() and not failed.errors.is_empty(),"strict inverse rejects mutation atomically "+str(case))
  ck(bad==before and c==original,"strict negative leaves input detached "+str(case))
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"22 author test-only strict B inverse predicates; no production loader change"}))
 quit(0 if failures.is_empty() else 1)
