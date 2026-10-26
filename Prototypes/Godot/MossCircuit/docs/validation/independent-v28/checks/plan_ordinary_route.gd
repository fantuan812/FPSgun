extends SceneTree
const Rules=preload("res://scripts/rules.gd")
func _initialize()->void:
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
 var b:Dictionary=Rules.new_build(catalog)
 var found:Array=[]
 for seed_value in range(1,10001):
  var r:=RandomNumberGenerator.new();r.seed=seed_value^92137
  var offers:Array=Rules.draw_shop(b,catalog,r,4)
  var ids:Array=offers.map(func(e):return e.id)
  if "rail_lance" in ids and "power_coil" in ids:
   found.append({"seed":seed_value,"offers":offers,"rail_slot":ids.find("rail_lance"),"power_slot":ids.find("power_coil"),"shop_rng_after":r.state})
  if found.size()>=3:break
 var result:Dictionary={"scope":"Offline seed planning only; no game state injection or ordinary acquisition claim. Starter Rivet plus level upgrades leaves affinity tags unchanged. Intended ordinary route: reserve Rail, buy Power if earned scrap permits, pay one refresh, deploy and observe next natural shop before purchasing or explicitly unlocking.","routes":found}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if found.size()==3 else 1)
