extends SceneTree
const Rules=preload("res://scripts/rules.gd")
func _initialize()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"));var b:Dictionary=Rules.new_build(c)
 for seed_value in range(1,100000):
  var rng:=RandomNumberGenerator.new();rng.seed=seed_value^92137
  var stock:Array=Rules.draw_shop(b,c,rng,4);var ids:Array=stock.map(func(e):return e.id)
  if "bankshot_driver" in ids and "bounce_guide" in ids:
   var record:Dictionary={"seed":seed_value,"build":b,"offers":stock,"shop_rng_seed_xor":92137,"scope":"offline deterministic first-shop selection only; subsequent native acquisition must earn currency and use ordinary controls"}
   FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(record,"\t"));print(JSON.stringify(record));quit();return
 quit(1)
