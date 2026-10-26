extends SceneTree
const Rules=preload("res://scripts/rules.gd")
func _initialize()->void:
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"));var build:Dictionary=Rules.new_build(catalog)
 for seed_value in range(1,10000):
  var rng:=RandomNumberGenerator.new();rng.seed=seed_value^92137
  var offers:Array=Rules.draw_shop(build,catalog,rng,4);var ids:Array=offers.map(func(e):return e.id)
  if "rail_lance" in ids and "power_coil" in ids:
   var result={"seed":seed_value,"offers":offers,"build":build,"scope":"Offline first-shop selection only; native acquisition still requires ordinary controls and earned scrap. No exported runtime state injection."}
   print(JSON.stringify(result));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
   quit();return
 quit(1)
