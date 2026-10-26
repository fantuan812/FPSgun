extends SceneTree
## Explicitly controlled fixture state; user actions are native keyboard/mouse.
const Rules=preload("res://scripts/rules.gd")
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var g
var mode:="arena"
var index:=1
var keys:Dictionary={}
func _initialize()->void:call_deferred("start")
func start()->void:
 root.size=Vector2i(960,540)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.ui.intent.connect(observe)
 scene_case(1)
func observe(action:String,payload:Dictionary)->void:
 print(JSON.stringify({"fixture":"controlled state, actual native UI input","action":action,"payload":payload,"mode":mode,"state":g.state,"coins":g.build.coins,"weapons":g.build.weapons,"clocks":g.weapon_clocks,"generation":g.shop_generation,"revision":g.build.revision,"held":g.reserved_offer}))
func scene_case(n:int)->void:
 index=n;g._title();g._select_mode(mode);g._start_run(128)
 g.build.weapons=["rivet_gun","rail_lance"]
 if n==2:g.build.weapons=["cryo_sprayer","cryo_sprayer","orbit_saw","return_disc"]
 if n==3:g.build.weapons=["bankshot_driver","shock_mortar"]
 g.build.items={"fracture_coil":1} if n==2 else {}
 g.build.coins=137;g._recompute();g.weapon_clocks=[]
 for i in range(g.build.weapons.size()):g.weapon_clocks.append([.11,.32,.6,.9][i])
 g._open_shop();g.shop_offers=[]
 for id in ["power_coil","rail_lance","cryo_sprayer"]:
  var pool:Array=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id==id)
  if not pool.is_empty():var offer:Dictionary=pool[0].duplicate(true);offer.sold=false;g.shop_offers.append(offer)
 if n==4:g.shop_offers=[]
 if n==3:
  g.state="playing";var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(120,0));e.hp=1000;e.max_hp=1000;e.speed=0
  g._fire_weapon("bankshot_driver",0);g._fire_weapon("shock_mortar",1);g.state="shop"
 g._render_shop();g._sync_weapon_rig()
 root.title="MossCircuit v30 CONTROLLED QA / "+mode+" / case "+str(n)
 print(JSON.stringify({"fixture_case":n,"mode":mode,"state":g.state,"weapons":g.build.weapons,"clocks":g.weapon_clocks,"coins":g.build.coins,"shots":g.bullets.size(),"pending_mortar":g.pending_blasts.size()}))
func _process(_dt:float)->bool:
 if not is_instance_valid(g):return false
 for key in range(KEY_F1,KEY_F12+1):
  var down:=Input.is_key_pressed(key)
  if down and not keys.get(key,false):
   if key==KEY_F10:root.size=Vector2i(960,540)
   elif key==KEY_F11:root.size=Vector2i(1280,720)
   elif key==KEY_F12:mode="rooms" if mode=="arena" else "arena";scene_case(index)
   elif key==KEY_F7:g.hero.flip_h=not g.hero.flip_h
   elif key==KEY_F6:
    g.state="inventory";g.ui.show_inventory(g._view())
   elif key<=KEY_F4:scene_case(key-KEY_F1+1)
   print(JSON.stringify({"fixture_key":key,"mode":mode,"case":index,"window_size":[root.size.x,root.size.y],"facing_left":g.hero.flip_h}))
  keys[key]=down
 g.hero.position=g.player_pos.round();g._sync_weapon_rig();g._update_hud()
 g.camera.position=FieldLayout.camera_position(g.player_pos,g.config.arena)
 return false
