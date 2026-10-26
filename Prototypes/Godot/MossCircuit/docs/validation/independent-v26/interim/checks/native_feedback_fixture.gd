extends SceneTree
const Motor=preload("res://scripts/gameplay/character_motor.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Layout=preload("res://scripts/gameplay/field_layout.gd")
var g
var caption:Label
var mode:="arena"
var index:=1
var held:Dictionary={}
func _initialize()->void:call_deferred("ready_fixture")
func ready_fixture()->void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0:mode=args[0]
 root.title="MossCircuit v26 controlled QA"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var layer=CanvasLayer.new();layer.layer=90;root.add_child(layer)
 caption=Label.new();caption.position=Vector2(22,215);caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",4);layer.add_child(caption)
 scene_case(1)
func sync()->void:
 g.hero.position=g.player_pos.round();g._sync_weapon_rig();g.camera.position=Layout.camera_position(g.player_pos,g.config.arena);g._update_hud();g._sync_telegraphs();g.queue_redraw()
func scene_case(number:int)->void:
 index=number;g.settings.reduced_flashes=false;g.vfx.reduced_flashes=false;g.vfx.refresh_style();g._title();g._select_mode(mode);g._start_run(826)
 g.build.items={"feedback_diode":1,"pulse_boots":1};g.build.coins=200;g._recompute();g.combat_frame.area=g.config.arena
 g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.elapsed=10
 for i in range(g.weapon_clocks.size()):g.weapon_clocks[i]=999
 g.state="playing"
 var e:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(220,35));e.speed=0;e.cooldown_left=999;e.hp=100;e.max_hp=100;e.anim_hp=100
 if number in [3,4,5,6,7]:
  var accepted=Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0)
  if accepted:g._effect_event("dash",{"pos":g.player_pos,"angle":0.0})
 if number in [4,5,6,7]:
  g.enemy_bullets.append({"owner":e.id,"pos":g.player_pos-Vector2(5,0),"velocity":Vector2(1000,0),"life":1.0,"damage":17.0})
  Runtime.step(g.combat_frame,.01)
 if number in [5,6]:
  var boss:Dictionary=g._spawn_kind("boss_warden",g.player_pos+Vector2(-145,20));boss.speed=0;boss.cooldown_left=0;boss.attack_index=1
  Runtime.step(g.combat_frame,0)
 if number==6:g.settings.reduced_flashes=true;g.vfx.reduced_flashes=true;g.vfx.refresh_style()
 if number==7:g.effect_visuals.clear();g.vfx.clear()
 if number==1:
  g.state="shop";g.build.items={};g._recompute();g.shop_offers=[{"id":"feedback_diode","sold":false},{"id":"pulse_boots","sold":false}];g.shop_generation+=1;g._render_shop()
 elif number==2:g.state="inventory";g._present_inventory()
 elif number in [8,9]:
  if number==8:
   g.stats.dash_time=.16;g.effects.feedback_armed=false
  else:
   Motor.step(g.combat,g.config.arena,Vector2.RIGHT,true,0);g._effect_event("dash",{"pos":g.player_pos,"angle":0.0})
  g.state="inventory";g._present_inventory()
 caption.text="CONTROLLED QA · "+mode+" · case "+str(number)+" · F1 shop / F2 build / F3 armed / F4 contact / F5 tell / F6 reduced / F7 spent / F8–9 status"
 if number in [1,2,8,9]:caption.position.y=6
 else:caption.position.y=220
 print(JSON.stringify({"case":number,"mode":mode,"owner_hp":e.hp,"armed":g.effects.feedback_armed,"status":g._view().mechanics.get("feedback_status","not owned"),"reduced":g.settings.reduced_flashes}))
 sync()
func _process(_dt:float)->bool:
 if not is_instance_valid(g):return false
 for k in range(KEY_F1,KEY_F12+1):
  var down=Input.is_key_pressed(k)
  if down and not held.get(k,false):
   if k==KEY_F10:root.size=Vector2i(960,540)
   elif k==KEY_F11:root.size=Vector2i(1280,720)
   elif k==KEY_F12:mode="rooms" if mode=="arena" else "arena";scene_case(index)
   else:scene_case(k-KEY_F1+1)
   print(JSON.stringify({"window_size":[root.size.x,root.size.y],"mode":mode}))
  held[k]=down
 return false
