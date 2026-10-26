extends Node
# Controlled presentation-only HUD fixture; never shipped as the main scene.
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var game
var caption:Label
var mode_id:String="arena"
var scenario:int=1
var variant:String=""
func _ready()->void:
	variant=ProjectSettings.globalize_path("res://").trim_suffix("/").get_file()
	DisplayServer.window_set_title("CONTROLLED HUD QA — "+variant)
	game=load("res://scenes/main.tscn").instantiate()
	add_child(game);game.set_process(false)
	var overlay:=CanvasLayer.new();overlay.layer=40;add_child(overlay)
	caption=Label.new();caption.position=Vector2(18,244);caption.size=Vector2(920,55)
	caption.add_theme_font_size_override("font_size",12)
	caption.add_theme_color_override("font_color",Color.WHITE)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",3)
	overlay.add_child(caption)
	reset_case()
func enemy(kind:String,pos:Vector2,attack:String)->Dictionary:
	var e:Dictionary=game._spawn_kind(kind,pos)
	e.sprite.position=pos.round();e.ai_state="warning";e.attack=attack
	e.hp=e.max_hp*.42;e.phase=2;e.target=Vector2(game.player_pos.x,game.config.arena.height-110)
	e.aim=(game.player_pos-pos).normalized();e.warning_left=.4
	return e
func reset_case()->void:
	game._title();game._select_mode(mode_id);game._start_run(2020)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	var area:Dictionary=game.config.arena
	game.player_pos=Vector2(area.width*.5,24 if scenario==4 else area.height-24)
	game.hero.position=game.player_pos.round()
	game.camera.position=FieldLayout.camera_position(game.player_pos,area)
	game.camera.force_update_scroll()
	match scenario:
		1:enemy("boss_warden",Vector2(game.player_pos.x+220,area.height-180),"blast")
		2:enemy("boss_core",Vector2(game.player_pos.x+200,area.height-120),"ring")
		3:
			enemy("boss_warden",Vector2(game.player_pos.x-220,area.height-180),"blast")
			var core:Dictionary=enemy("boss_core",Vector2(game.player_pos.x+200,area.height-120),"ring")
			core.hp=core.max_hp*.82;core.phase=1
		4:enemy("boss_warden",game.player_pos+Vector2(180,40),"charge")
	game._sync_weapon_rig();game._update_hud();game._sync_telegraphs();game.queue_redraw()
	update_caption()
	call_deferred("record")
func update_caption()->void:
	caption.text="CONTROLLED HUD QA | "+variant+" | "+mode_id+" | case "+str(scenario)+" | frozen presentation; not ordinary play\n1 lower Warden / 2 lower Core / 3 two bosses / 4 upper charge | O mode | F6 960x540 / F7 1280x720 / F8 1000x750\nP pause / B shop / R restore | native "+str(get_window().size)+" | logical "+str(get_viewport().get_visible_rect().size)
func record()->void:
	await get_tree().process_frame
	update_caption()
	print(JSON.stringify({"fixture":"hud-occlusion","variant":variant,"mode":mode_id,"case":scenario,"native_size":str(get_window().size),"logical_size":str(get_viewport().get_visible_rect().size),"player":str(game.player_pos),"camera":str(game.camera.position),"hud_rect":str(game.ui.hud.get_global_rect()),"boss_rect":str(game.ui.boss_panel.get_global_rect()),"markers":str(game.telegraphs.markers),"state":game.state}))
func resize_to(value:Vector2i)->void:
	get_window().size=value
	get_window().position=Vector2i(30,80)
	call_deferred("record")
func _process(_delta:float)->void:
	if is_instance_valid(game):game._update_hud()
func _input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1,KEY_2,KEY_3,KEY_4:scenario=int(event.keycode-KEY_0);reset_case()
		KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";reset_case()
		KEY_R:reset_case()
		KEY_F6:resize_to(Vector2i(960,540))
		KEY_F7:resize_to(Vector2i(1280,720))
		KEY_F8:resize_to(Vector2i(1000,750))
		KEY_P:game._on_intent("pause",{});update_caption();call_deferred("record")
		KEY_B:game._open_shop();update_caption();call_deferred("record")
