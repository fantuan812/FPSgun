extends SceneTree
## Offline stock planning only, never ordinary acquisition evidence.
const Rules=preload("res://scripts/rules.gd")
const Kits=preload("res://scripts/gameplay/starting_loadouts.gd")
func _initialize()->void:
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/starting_loadouts.json"))
 var rows:Array=[]
 for kit in ["rivet","scatter","rail"]:
  var build:Dictionary=Kits.make_build(data,catalog,kit)
  var id:String=build.weapons[0]
  for seed in [128,86,433,1,2,3,4,5,6,7,8,9,10]:
   var rng:=RandomNumberGenerator.new();rng.seed=seed^92137
   var offers:Array=Rules.draw_shop(build,catalog,rng)
   var ids:Array=[]
   for e in offers:ids.append(e.id)
   rows.append({"kit":kit,"seed":seed,"starter":id,"starting_scrap":build.coins,"offers":ids,"duplicate_in_first_stock":id in ids})
 var result:Dictionary={"scope":"Offline shop seed planning, no combat/acquisition claim. Normal upgrade levels do not add ownership tags. Actual run must earn scrap and buy through UI.","rows":rows}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit()
