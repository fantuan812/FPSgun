extends SceneTree
## Explicit controlled frozen simulation; UI interaction is native keyboard/mouse.
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var g
var keys:Dictionary={}
func _initialize()->void:call_deferred("start")
func start()->void:
 root.size=Vector2i(960,540)
 root.title="MossCircuit v31 CONTROLLED QA / frozen simulation"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.ui.intent.connect(observe)
 print(JSON.stringify({"fixture":"initial actual title, simulation frozen","selected":g.selected_loadout_id,"state":g.state}))
func observe(action:String,payload:Dictionary)->void:
 print(JSON.stringify({"fixture":"controlled frozen simulation / actual UI input","action":action,"payload":payload,"mode":g.mode.id,"state":g.state,"coins":g.build.get("coins",0),"weapons":g.build.get("weapons",[]),"seed":g.run_seed,"selected":g.selected_loadout_id,"origin":g.run.starting_loadout_id,"title_generation":g.title_generation}))
func _process(_dt:float)->bool:
 if not is_instance_valid(g):return false
 for key in range(KEY_F1,KEY_F12+1):
  var down:=Input.is_key_pressed(key)
  if down and not keys.get(key,false):
   if key==KEY_F10:root.size=Vector2i(960,540)
   elif key==KEY_F11:root.size=Vector2i(1280,720)
   elif key==KEY_F1:g._title();g._select_mode("arena")
   elif key==KEY_F2:g._title();g._select_mode("rooms")
   elif key==KEY_F3:g.state="inventory";g._present_inventory()
   elif key==KEY_F4:g._finish(true)
   elif key==KEY_F5:g.build.weapons=["bankshot_driver"];g._recompute();g.state="inventory";g._present_inventory()
   print(JSON.stringify({"fixture_key":key,"mode":g.mode.id,"size":[root.size.x,root.size.y],"state":g.state}))
  keys[key]=down
 g.hero.position=g.player_pos.round();g._sync_weapon_rig();g._update_hud()
 g.camera.position=FieldLayout.camera_position(g.player_pos,g.config.arena)
 return false
