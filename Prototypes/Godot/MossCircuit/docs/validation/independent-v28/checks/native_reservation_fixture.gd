extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var g
var mode:="arena"
var index:=1
var keys:Dictionary={}
func _initialize()->void:call_deferred("ready_fixture")
func ready_fixture()->void:
 root.title="MossCircuit v28 CONTROLLED reservation QA"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.ui.intent.connect(observe_intent)
 scene_case(1)
func observe_intent(action:String,payload:Dictionary)->void:
 print(JSON.stringify({"fixture":"controlled shop setup; real UI intents","action":action,"payload":payload,"state":g.state,"coins":g.build.get("coins",0),"generation":g.shop_generation,"reserved":g.reserved_offer}))
func scene_case(number:int)->void:
 index=number
 g._title();g._select_mode(mode);g._start_run(128);g.build.coins=100;g._open_shop()
 var ids:Array=["rail_lance","power_coil","feedback_diode","bounce_guide"]
 if number==4:ids=["feedback_diode","rail_lance","power_coil","bounce_guide"]
 var pool:Array=Rules.weighted_pool(g.build,g.catalog)
 g.shop_offers=[]
 for id in ids:
  var entry:Dictionary=pool.filter(func(e):return e.id==id)[0].duplicate(true)
  entry.sold=false;g.shop_offers.append(entry)
 if number==1:g.build.coins=0
 if number in [2,3,4,5,6,7]:g._reserve_offer(0,g.shop_generation)
 if number==2:
  g._buy(1,g.shop_generation);g._refresh_shop(g.shop_generation)
 if number in [3,4]:
  g.build.weapons=["rivet_gun","return_disc","orbit_saw","cryo_sprayer"]
  g.build.items={"power_coil":1,"cooling_fan":1,"iron_plate":1,"running_boots":1,"moss_patch":1,"lens":1,"capacitor":1,"gear":1}
  g._recompute()
 if number==5:g._buy(0,g.shop_generation)
 if number==6:g.reserved_offer.price+=1;g._refresh_shop(g.shop_generation)
 if number==7:g._on_intent("inventory",{})
 else:g._render_shop()
 root.title="MossCircuit v28 CONTROLLED QA - "+mode+" case "+str(number)
 print(JSON.stringify({"fixture_case":number,"mode":mode,"coins":g.build.coins,"offers":g.shop_offers,"reserved":g.reserved_offer,"weapons":g.build.weapons,"items":g.build.items}))
func _process(_dt:float)->bool:
 if not is_instance_valid(g):return false
 for key in range(KEY_F1,KEY_F12+1):
  var down:=Input.is_key_pressed(key)
  if down and not keys.get(key,false):
   if key==KEY_F10:root.size=Vector2i(960,540)
   elif key==KEY_F11:root.size=Vector2i(1280,720)
   elif key==KEY_F12:mode="rooms" if mode=="arena" else "arena";scene_case(index)
   elif key<=KEY_F7:scene_case(key-KEY_F1+1)
   print(JSON.stringify({"mode":mode,"case":index,"window_size":[root.size.x,root.size.y]}))
  keys[key]=down
 g._update_hud()
 return false
