extends Node
# External controlled presentation fixture; not the shipping main scene or ordinary acquisition.
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var game
var caption:Label
var mode_id:="arena"
var scenario:=3
var facing:=-1.0
func _ready()->void:
 DisplayServer.window_set_title("CONTROLLED BANKSHOT QA")
 game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false)
 var overlay:=CanvasLayer.new();overlay.layer=40;add_child(overlay)
 caption=Label.new();caption.position=Vector2(310,435);caption.size=Vector2(635,75);caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_color",Color.WHITE);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",3);overlay.add_child(caption)
 show_case()
func foe(pos:Vector2,hp:float=500,kind:String="crawler")->Dictionary:
 var e:Dictionary=game._spawn_kind(kind,pos);e.hp=hp;e.max_hp=hp;e.anim_hp=hp;e.speed=0;e.cooldown_left=999;e.sprite.position=e.pos;return e
func show_case()->void:
 game._title();game._select_mode(mode_id);game._start_run(27423)
 game.build.weapons=["bankshot_driver","rivet_gun"];game.build.items={"bounce_guide":1} if scenario in [1,2,6,7] else {};game.build.coins=1000;game._recompute();game.elapsed=10;game.stats.hp=10000;game.stats.max_hp=10000;game.spawn_clock=999
 for i in range(game.weapon_clocks.size()):game.weapon_clocks[i]=999.0
 var w:float=game.config.arena.width
 game.player_pos=Vector2(150 if facing<0 else w-150,300);game.hero.position=game.player_pos;game.hero.flip_h=facing<0
 game.camera.position=FieldLayout.camera_position(game.player_pos,game.config.arena);game.camera.force_update_scroll();game.combat_frame.area=game.config.arena
 if scenario==1:
  game._open_shop();game.shop_offers=[{"id":"bankshot_driver","sold":false,"weight_multiplier":1.0,"bias_reasons":[]},{"id":"bounce_guide","sold":false,"weight_multiplier":3.85,"bias_reasons":["Missing partner: Bankshot Driver"]}];game._render_shop()
 elif scenario==2:game._on_intent("inventory",{})
 else:
  foe(game.player_pos+Vector2(80*facing,0),18 if scenario==6 else 500)
  if scenario==6:foe(game.player_pos+Vector2(60*facing,65))
  if scenario==7:
   var boss:Dictionary=foe(game.player_pos+Vector2(-120*facing,55),1000,"boss_warden");boss.ai_state="warning";boss.attack="blast";boss.target=boss.pos;boss.warning_left=.5
  game._fire_weapon("bankshot_driver",0)
  if not game.bullets.is_empty():
   var b:Dictionary=game.bullets[0]
   var distance:float=b.x/absf(b.dx) if facing<0 else (w-b.x)/absf(b.dx)
   if scenario==4:game.weapon_combat.advance_bankshot(b,distance*.7/b.speed)
   elif scenario in [5,6,7]:game.weapon_combat.advance_bankshot(b,(distance+20)/b.speed)
   Runtime.step(game.combat_frame,0);game.actor_anim.advance(.06);game.vfx.advance(.06)
 game._sync_weapon_rig();game._update_hud();game._sync_telegraphs();game.queue_redraw();update_caption();call_deferred("record")
func update_caption()->void:
 caption.visible=not game.ui.modal_visible()
 caption.text="CONTROLLED Bankshot QA | "+mode_id+" | case "+str(scenario)+" | injected setup\n1 shop / 2 inventory / 3 armed / 4 spent / 5 reflection / 6 guide / 7 enemy tell\nF mirror | O mode | R reduced flashes | N step 0.04 s | F6 960 / F7 1280"
func record()->void:
 await get_tree().process_frame
 var shots:Array=[]
 for b in game.bullets:shots.append({"x":b.x,"y":b.y,"dx":b.dx,"dy":b.dy,"armed":b.leg_hits.size()<b.leg_quota,"reflections":b.reflections,"guided":b.guided_once,"hits":b.total_hits,"life":b.life})
 print(JSON.stringify({"fixture":"controlled Bankshot","mode":mode_id,"case":scenario,"facing":facing,"native_size":str(get_window().size),"shots":shots,"reduced_flashes":game.settings.reduced_flashes,"scope":"injected setup with actual shared fire/advance; not ordinary play"}))
func _process(_dt:float)->void:
 if is_instance_valid(game):game._update_hud();update_caption()
func _input(event:InputEvent)->void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_Q:get_tree().quit()
  KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7:scenario=int(event.keycode-KEY_0);show_case()
  KEY_F:facing*=-1;show_case()
  KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";show_case()
  KEY_R:game.settings.reduced_flashes=not game.settings.reduced_flashes;game.queue_redraw();call_deferred("record")
  KEY_F6:get_window().size=Vector2i(960,540);get_window().position=Vector2i(30,80);call_deferred("record")
  KEY_F7:get_window().size=Vector2i(1280,720);get_window().position=Vector2i(30,80);call_deferred("record")
  KEY_N:
   for b in game.bullets:game.weapon_combat.advance_bankshot(b,.04)
   game.combat_frame.procs.advance_hazards(.04);game.vfx.advance(.04);game.actor_anim.advance(.04);game._sync_weapon_rig();game._update_hud();game.queue_redraw();call_deferred("record")
