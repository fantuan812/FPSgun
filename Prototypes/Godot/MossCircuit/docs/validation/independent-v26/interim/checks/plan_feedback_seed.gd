extends SceneTree
const Rules=preload("res://scripts/rules.gd")
func _initialize()->void:
 var c:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"));var b:Dictionary=Rules.new_build(c);var result:Array=[]
 for seed_value in range(1000):
  var rng=RandomNumberGenerator.new();rng.seed=seed_value^92137
  var offers:Array=Rules.draw_shop(b,c,rng,4);var ids:Array=offers.map(func(o):return o.id)
  if "feedback_diode" in ids and "pulse_boots" in ids:result.append({"seed":seed_value,"ids":ids})
  if result.size()==5:break
 print(JSON.stringify({"scope":"offline deterministic first-shop offer planning only; not ordinary acquisition proof","routes":result}));quit()
