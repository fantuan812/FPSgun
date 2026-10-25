extends Node
var game
var boss:Dictionary
var caption:Label
var auto:=false
var mirrored:=false
var mode_id:="arena"
func _ready()->void:
	game=load("res://scenes/main.tscn").instantiate()
	add_child(game);game.set_process(false)
	var overlay:=CanvasLayer.new();overlay.layer=30;add_child(overlay)
	caption=Label.new();caption.position=Vector2(20,430);caption.size=Vector2(920,100)
	caption.add_theme_font_size_override("font_size",12)
	caption.add_theme_color_override("font_color",Color("ffffff"))
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2)
	overlay.add_child(caption)
	reset(false,false)
func reset(flip:bool,blast:bool)->void:
	mirrored=flip;auto=false
	game._title();game._select_mode(mode_id);game._start_run(1616)
	game.spawn_clock=999;game.weapon_clocks=[999.0]
	game.stats.hp=10000;game.stats.max_hp=10000
	boss=game._spawn_kind("boss_warden",game.player_pos+Vector2(-280 if flip else 280,0))
	boss.hp=boss.max_hp*.9;boss.anim_hp=boss.hp;boss.cooldown_left=0
	boss.attack_index=1 if blast else 0
	game._process(.01)
	show_label()
func step(dt:float)->void:
	game._process(dt);show_label()
func show_label()->void:
	if boss.is_empty():return
	game.ui.boss_panel.hide()
	caption.text="CONTROLLED QA ONLY: HP boosted; ordinary spawns and player weapons disabled\n%s | AI %s | frame %s | flip_h %s | pose %s\nN: next AI phase  T: +0.1s  Enter: slow playback  R: left-facing  M: right-facing  B: blast  H: hurt"%["AUTO" if auto else "STEPPED",boss.ai_state,boss.sprite.frame,boss.sprite.flip_h,game.actor_anim.actors[boss.id].asset_id]
func _process(delta:float)->void:
	if auto:step(minf(.02,delta*.25))
func _input(event:InputEvent)->void:
	if not(event is InputEventKey) or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ENTER:auto=not auto;show_label()
		KEY_O:
			mode_id="rooms" if mode_id=="arena" else "arena"
			reset(false,false)
		KEY_X:
			game.player_pos=boss.pos+Vector2(200 if boss.aim.x<0 else -200,0)
			step(.01)
		KEY_R:reset(false,false)
		KEY_M:reset(true,false)
		KEY_B:reset(mirrored,true)
		KEY_T:
			for i in range(10):step(.01)
		KEY_N:
			var phase:String=boss.ai_state
			for i in range(2000):
				step(.01)
				if boss.ai_state!=phase:break
		KEY_H:game.actor_anim.trigger(boss.id,"hurt");show_label()
