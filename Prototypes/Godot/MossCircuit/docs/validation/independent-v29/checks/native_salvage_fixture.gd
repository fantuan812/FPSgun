extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var g
var mode:="arena"
var index:=1
var keys:Dictionary={}
func _initialize()->void:call_deferred("ready_fixture")
func ready_fixture()->void:
 root.size=Vector2i(960,540)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.ui.intent.connect(observe)
 scene_case(1)
func observe(action:String,payload:Dictionary)->void:
 print(JSON.stringify({"fixture":"controlled state; actual native UI inputs","action":action,"payload":payload,"state":g.state,"coins":g.build.coins,"pending":g.upgrade_pending,"generation":g.choice_generation,"levels":g.build.levels,"held":g.reserved_offer}))
func scene_case(n:int)->void:
 index=n;g._title();g._select_mode(mode);g._start_run(128);g.build.coins=32;g.build.coin_fraction=.3
 if n in [2,3]:
  g._open_shop()
  var offer:Dictionary=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id=="rail_lance")[0].duplicate(true)
  offer.sold=false;g.shop_offers=[offer];g._reserve_offer(0,g.shop_generation);g._leave_shop(g.shop_generation)
 if n==5:g.build.coins=123456789
 g.upgrade_pending=3 if n==2 else 1;g.shop_pending=n in [2,3];g._show_upgrades()
 g.choices=[]
 for id in ["damage","health","pierce"]:g.choices.append(g.config.upgrades.filter(func(e):return e.id==id)[0].duplicate(true))
 if n==4:g.ui.show_upgrade(g.choices,g.choice_generation)
 else:g.ui.show_upgrade(g.choices,g.choice_generation,g._upgrade_salvage_view())
 root.title="MossCircuit v29 CONTROLLED QA - "+mode+" case "+str(n)
 print(JSON.stringify({"fixture_case":n,"mode":mode,"coins":g.build.coins,"pending":g.upgrade_pending,"choices":g.choices,"held":g.reserved_offer}))
func _process(_dt:float)->bool:
 if not is_instance_valid(g):return false
 for key in range(KEY_F1,KEY_F12+1):
  var down:=Input.is_key_pressed(key)
  if down and not keys.get(key,false):
   if key==KEY_F10:root.size=Vector2i(960,540)
   elif key==KEY_F11:root.size=Vector2i(1280,720)
   elif key==KEY_F12:mode="rooms" if mode=="arena" else "arena";scene_case(index)
   elif key<=KEY_F5:scene_case(key-KEY_F1+1)
   print(JSON.stringify({"mode":mode,"case":index,"window_size":[root.size.x,root.size.y]}))
  keys[key]=down
 g.hero.position=g.player_pos.round()
 g._sync_weapon_rig()
 g._update_hud()
 return false
