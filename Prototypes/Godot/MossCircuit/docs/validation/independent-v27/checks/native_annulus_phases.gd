extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Layout=preload("res://scripts/gameplay/field_layout.gd")
var g
var caption:Label
var mode:="arena"
var index:=1
var held:Dictionary={}
var mirrored:=false
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
func step(dt:float)->void:
 g.actor_anim.advance(dt);g.elapsed+=dt;Runtime.step(g.combat_frame,dt)
func scene_case(number:int)->void:
 index=number;g._title();g._select_mode(mode);g._start_run(2701)
 g.elapsed=10;g.stats.hp=100;g.stats.max_hp=100;g.combat_frame.area=g.config.arena;g.weapon_clocks=[999.0];g.spawn_clock=999
 var center:=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.player_pos=center+Vector2(-200 if mirrored else 200,0)
 var e:Dictionary=keeper(center)
 if number==9:e.attack_index=1
 step(0)
 if number==2:step(.4)
 if number in [3,4,5]:step(.6)
 if number in [4,5]:
  g.actor_anim.trigger(e.id,"hurt");g.actor_anim.advance(.1 if number==4 else .4)
 if number in [6,7,8]:step(1)
 if number==7:step(.35)
 if number==8:step(.7)
 if number==9:step(.35)
 var actor:Dictionary=g.actor_anim.actors[e.id]
 caption.text="CONTROLLED stepped pose · "+mode+" · case"+str(number)+" · "+str(e.attack)+" / "+str(e.ai_state)+" · not ordinary play"
 caption.position.y=510
 print(JSON.stringify({"case":number,"mode":mode,"mirrored":mirrored,"attack":e.attack,"ai_state":e.ai_state,"warning_left":e.warning_left,"recover_left":e.recover_left,"actor_state":actor.state,"phase_progress":actor.phase_progress,"hp":g.stats.hp}))
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
 var m=Input.is_key_pressed(KEY_M)
 if m and not held.get(KEY_M,false):mirrored=not mirrored;scene_case(index)
 held[KEY_M]=m
 # UI layout is deferred; keep the ordinary read-only HUD placement refresh even
 # though this fixture deliberately disables gameplay simulation.
 g._update_hud()
 return false
