extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Layout=preload("res://scripts/gameplay/field_layout.gd")
var g
var caption:Label
var mode:="arena"
var index:=1
var held:Dictionary={}
func _initialize()->void:call_deferred("ready_fixture")
func ready_fixture()->void:
 root.title="MossCircuit v27 controlled annulus QA"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var layer=CanvasLayer.new();layer.layer=90;root.add_child(layer)
 caption=Label.new();caption.position=Vector2(18,6);caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",4);layer.add_child(caption)
 scene_case(1)
func sync()->void:
 g.hero.position=g.player_pos.round();g._sync_weapon_rig();g.camera.position=Layout.camera_position(g.player_pos,g.config.arena);g._update_hud();g._sync_telegraphs();g.queue_redraw()
func keeper(pos:Vector2)->Dictionary:
 var e:Dictionary=g._spawn_kind("brood_keeper",pos);e.speed=0;e.cooldown_left=0;e.hp=1000;e.max_hp=1000;e.anim_hp=1000;return e
func scene_case(number:int)->void:
 index=number;g.settings.reduced_flashes=false;g.vfx.reduced_flashes=false;g.vfx.refresh_style()
 g._title();g._select_mode(mode);g._start_run(2701);g.elapsed=10;g.stats.hp=100;g.stats.max_hp=100
 g.build.items={"pulse_boots":1};g._recompute();g.combat_frame.area=g.config.arena;g.weapon_clocks=[999.0];g.spawn_clock=999
 var center:=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.player_pos=center+Vector2(35,0)
 var e:Dictionary=keeper(center)
 if number in [2,4]:g.player_pos=center+Vector2(120,0)
 if number==3:g.player_pos=center+Vector2(200,0)
 if number in [6,8]:
  e.pos=center-Vector2(110,0);keeper(center+Vector2(110,0));g.player_pos=center+Vector2(0,30)
 Runtime.step(g.combat_frame,0)
 if number==4:e.warning_left=0;Runtime.step(g.combat_frame,0)
 if number==5:
  g.player_pos=center+Vector2(100,0);g._effect_event("dash",{"pos":g.player_pos,"angle":0.0});Runtime.step(g.combat_frame,0);g.player_pos=center+Vector2(35,0)
 if number==7:
  var ram:Dictionary=g._spawn_kind("charger",center+Vector2(-220,-100));ram.speed=0;ram.cooldown_left=0
  var core:Dictionary=g._spawn_kind("boss_core",center+Vector2(180,100));core.speed=0;core.cooldown_left=0
  Runtime.step(g.combat_frame,0)
 if number==8:g.settings.reduced_flashes=true;g.vfx.reduced_flashes=true;g.vfx.refresh_style()
 if number==9:g._title();g._on_intent("guide",{})
 caption.text="CONTROLLED QA · "+mode+" · case"+str(number)+" · F1 hole / F2 band / F3 outer / F4 impact / F5 pushed / F6 overlap / F7 tells / F8 reduced / F9 guide"
 caption.position.y=6 if number==9 else 220
 print(JSON.stringify({"case":number,"mode":mode,"hp":g.stats.hp,"keeper_pos":[e.pos.x,e.pos.y],"locked_center":[e.pulse_center.x,e.pulse_center.y],"reduced":g.settings.reduced_flashes}))
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
