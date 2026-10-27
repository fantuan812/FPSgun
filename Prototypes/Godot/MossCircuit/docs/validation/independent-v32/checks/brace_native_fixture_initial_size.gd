extends SceneTree
# External controlled native-presentation fixture; never shipped or called ordinary play.
const Field=preload("res://scripts/gameplay/field_layout.gd")
var g
var mode_id:="arena"
var index:=0
var caption:Label
var actor_id:=-1
class Driver extends Node:
 var next:Callable
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
   next.call();get_viewport().set_input_as_handled()
func _initialize()->void:call_deferred("boot")
func boot()->void:
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():mode_id=args[0]
 root.title="Moss v32 CONTROLLED brace QA"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var layer:=CanvasLayer.new();layer.layer=90;root.add_child(layer)
 caption=Label.new();caption.position=Vector2(180,490);caption.size=Vector2(600,42);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",14);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",5);layer.add_child(caption)
 var driver:=Driver.new();driver.next=advance;root.add_child(driver)
 show_case()
func advance()->void:
 index=(index+1)%12;show_case()
func enemy(kind:String,pos:Vector2,aim:Vector2)->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,pos);e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.ai_state="warning";e.attack="charge";e.aim=aim;e.warning_left=.45;e.cooldown_left=999;e.target=pos
 e.sprite.position=e.pos.round();g.actor_anim.observe_enemy(e,"move",g.player_pos)
 return e
func show_case()->void:
 g._title();g._select_mode(mode_id);g._start_run(3201);g.set_process(false)
 g.weapon_clocks=[999.0];g.spawn_clock=999;g.elapsed=10;g.combat_frame.area=g.config.arena
 g.settings.reduced_flashes=index==9;g.actor_anim.reduced_flashes=g.settings.reduced_flashes;g.vfx.reduced_flashes=g.settings.reduced_flashes
 var center:=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 var directions:Array=[Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2.from_angle(deg_to_rad(-88)),Vector2(1,-1).normalized(),Vector2.LEFT,Vector2.LEFT,Vector2.UP,Vector2.UP,Vector2.RIGHT,Vector2.RIGHT]
 var aim:Vector2=directions[index]
 g.player_pos=center+aim*105
 var e:Dictionary=enemy("charger",center,aim);actor_id=e.id
 var labels:Array=["RIGHT / FRONT", "LEFT / FRONT", "UP / 2D AIM", "DOWN / 2D AIM", "NEAR VERTICAL / HORN NOT AUTHORITY", "DIAGONAL", "HURT DURING WARNING", "HURT RETURN TO WARNING", "ORANGE OVERLAP", "REDUCED FLASHES", "CHARGING / BRACE OPEN", "ENEMY GUIDE"]
 if index==6 or index==7:
  g.actor_anim.trigger(e.id,"hurt");g.actor_anim.advance(.08 if index==6 else .3)
 if index==8 or index==9:
  var second:Dictionary=enemy("charger",center+Vector2(-110,-65),Vector2(1,.35).normalized());second.warning_left=.35
  var warden:Dictionary=enemy("boss_warden",center+Vector2(115,45),Vector2.LEFT)
  warden.attack="blast";warden.target=warden.pos;g.actor_anim.observe_enemy(warden,"move",g.player_pos)
 if index==10:
  e.ai_state="charging";e.charge_left=.4;g.actor_anim.observe_enemy(e,"warning",g.player_pos)
 g.hero.position=g.player_pos.round();g.camera.position=Field.camera_position(g.player_pos,g.config.arena)
 g._sync_weapon_rig();g._update_hud();g._sync_telegraphs();g.queue_redraw()
 if index==11:g._on_intent("pause",{});g._on_intent("codex",{})
 caption.text="CONTROLLED FIXTURE / "+mode_id.to_upper()+" / "+str(index+1)+": "+labels[index]+"\nN = next; caption is not shipped game UI"
 print(JSON.stringify({"fixture":"controlled brace native","mode":mode_id,"case":index+1,"name":labels[index],"reduced":g.settings.reduced_flashes,"actor":actor_id}))
