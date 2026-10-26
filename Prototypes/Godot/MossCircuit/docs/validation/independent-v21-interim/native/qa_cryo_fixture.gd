extends Node
# Controlled native presentation fixture; not the shipping main scene.
const FieldLayout=preload("res://scripts/gameplay/field_layout.gd")
var game
var caption:Label
var mode_id:String="arena"
var facing:float=1.0
var scenario:int=1
var running:=false
func _ready()->void:
	DisplayServer.window_set_title("CONTROLLED v21 CRYO QA")
	game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false)
	var overlay:=CanvasLayer.new();overlay.layer=40;add_child(overlay)
	caption=Label.new();caption.position=Vector2(18,470);caption.size=Vector2(920,55);caption.add_theme_font_size_override("font_size",12);caption.add_theme_color_override("font_color",Color.WHITE);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",3);overlay.add_child(caption)
	reset_case()
func reset_case()->void:
	running=false;game.set_process(false);game._title();game._select_mode(mode_id);game._start_run(874205)
	game.build.weapons=["cryo_sprayer","rivet_gun"] if scenario!=6 else ["cryo_sprayer","cryo_sprayer"]
	game.build.items={"fracture_coil":1};game.build.coins=1000;game._recompute();game.elapsed=10.0;game.stats.hp=10000;game.stats.max_hp=10000;game.spawn_clock=999.0
	for i in range(game.weapon_clocks.size()):game.weapon_clocks[i]=999.0
	game.hero.position=game.player_pos;game.hero.flip_h=facing<0;game.camera.position=FieldLayout.camera_position(game.player_pos,game.config.arena);game.camera.force_update_scroll()
	if scenario==4:
		var boss:Dictionary=game._spawn_kind("boss_warden",game.player_pos+Vector2(150*facing,0));boss.hp=950;boss.max_hp=950;boss.sprite.position=boss.pos;boss.ai_state="warning";boss.attack="blast";boss.target=boss.pos;boss.warning_left=.5
	else:
		for offset in [Vector2(90,0),Vector2(150,-55),Vector2(150,55),Vector2(-120,0)]:
			var e:Dictionary=game._spawn_kind("crawler",game.player_pos+Vector2(offset.x*facing,offset.y));e.hp=500;e.max_hp=500;e.sprite.position=e.pos
	if scenario in [2,3,4]:game._fire_weapon("cryo_sprayer",0)
	if scenario==3:
		var e:Dictionary=game.enemies[0];game._hit_segment({"hit":[],"damage":15.0,"pierce":0,"life":1.0,"weapon":"rivet_gun"},e.pos,e.pos);game.vfx.advance(.08)
	game._sync_weapon_rig();game._update_hud();game._sync_telegraphs();game.queue_redraw();update_caption();call_deferred("record")
	if scenario==5:
		game._open_shop();game.shop_offers=[{"id":"cryo_sprayer","sold":false,"weight_multiplier":1.85,"bias_reasons":["Shared tag: control"]},{"id":"fracture_coil","sold":false,"weight_multiplier":1.35,"bias_reasons":["Shared tag: control"]}];game._render_shop()
	if scenario==6:game._on_intent("inventory",{})
func update_caption()->void:
	caption.visible=not game.ui.modal_visible()
	caption.text="CONTROLLED v21 QA | "+mode_id+" | case "+str(scenario)+" | injected setup; not ordinary run\n1 neutral / 2 chill / 3 shatter / 4 boss / 5 shop / 6 Cryo-only inactive | F mirror | O mode | T live controlled\nF6 960x540 / F7 1280x720 | I inventory | native "+str(get_window().size)
func record()->void:
	await get_tree().process_frame
	var targets:Array=[]
	for e in game.enemies:targets.append({"id":e.id,"kind":e.kind,"hp":e.hp,"pos":str(e.pos),"chill_until":e.get("chill_until",0),"source":e.last_source})
	print(JSON.stringify({"fixture":"controlled-cryo","mode":mode_id,"case":scenario,"facing":facing,"native_size":str(get_window().size),"targets":targets,"effect_visuals":str(game.effect_visuals)}))
func _process(_dt:float)->void:
	if is_instance_valid(game):game._update_hud();update_caption()
func _input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6:scenario=int(event.keycode-KEY_0);reset_case()
		KEY_F:facing*=-1;reset_case()
		KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";reset_case()
		KEY_F6:get_window().size=Vector2i(960,540);get_window().position=Vector2i(30,80);call_deferred("record")
		KEY_F7:get_window().size=Vector2i(1280,720);get_window().position=Vector2i(30,80);call_deferred("record")
		KEY_T:
			running=not running
			if running:
				for i in range(game.weapon_clocks.size()):game.weapon_clocks[i]=0.0
			game.set_process(running)
