extends SceneTree
var passed:=0
var failures:Array=[]
var intent_count:=0
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	game.ui.intent.connect(func(_action,_payload):intent_count+=1)
	for mode_id in ["arena","rooms"]:
		game._title();game._select_mode(mode_id);game._start_run(874205)
		for viewport_size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1000,750)]:
			root.size=viewport_size
			await process_frame;await process_frame
			game._update_hud()
			var context:String=mode_id+" "+str(viewport_size)
			var hud_style:StyleBoxFlat=game.ui.hud.get_theme_stylebox("panel")
			check(hud_style.bg_color.a<=.08+.0001,"main panel not an opaque mask "+context)
			check(hud_style.border_color.a<=.25+.0001,"main border translucent "+context)
			check(game.ui.modal.get_theme_stylebox("panel").bg_color.a==1.0,"modal styling unchanged "+context)
			for bar in [game.ui.hp,game.ui.xp]:
				check(bar.get_theme_stylebox("fill").bg_color.a<=.55+.0001,"main bars translucent "+context)
				check(bar.mouse_filter==Control.MOUSE_FILTER_IGNORE,"passive bar ignores mouse "+context)
			for label in [game.ui.hud_title,game.ui.hud_detail,game.ui.hud_action]:
				check(label.get_theme_constant("outline_size")>=3,"combat text contrast outline "+context)
			for count in [1,2]:
				var bosses:Array=[{"name":"Scrap Warden","phase":2,"hp":434,"max_hp":950,"hint":"warning: blast"}]
				if count==2:bosses.append({"name":"Moss Core","phase":3,"hp":1200,"max_hp":2000,"hint":"warning: summon"})
				var before:String=JSON.stringify(bosses)
				game.ui.update_bosses(bosses)
				await process_frame;await process_frame
				var rect:Rect2=game.ui.boss_panel.get_global_rect()
				check(game.ui.boss_panel.get_theme_stylebox("panel") is StyleBoxEmpty,"no bottom full-rectangle fill "+context)
				check(rect.size.y<=50 if count==1 else rect.size.y<=88,"compact boss height "+context+" "+str(count)+" "+str(rect))
				check(rect.end.y<=root.get_visible_rect().size.y,"boss within bottom edge "+context)
				check(game.ui.boss_widgets.size()==count,"all live boss rows retained "+context)
				check(JSON.stringify(bosses)==before,"presentation never mutates boss snapshots "+context)
				for i in count:
					var widgets:Dictionary=game.ui.boss_widgets[i]
					check(widgets.bar.size.y<=4.01,"boss HP line at most four logical pixels "+context)
					check(is_equal_approx(widgets.bar.value,float(bosses[i].hp)),"exact HP value "+context)
					check(widgets.title.text.contains(bosses[i].name) and widgets.title.text.contains("PHASE "+str(bosses[i].phase)),"name and phase retained "+context)
					check(widgets.hint.text==bosses[i].hint,"exact attack hint "+context)
					check(widgets.title.get_global_rect().end.x<=widgets.hint.get_global_rect().position.x,"boss text does not overlap "+context)
					check(widgets.hint.get_global_rect().end.x<=rect.end.x,"hint in panel "+context)
					check(widgets.title.get_theme_constant("outline_size")>=3,"boss outlined text "+context)
			game.ui.update_bosses([])
			check(not game.ui.boss_panel.visible and game.ui.boss_widgets.is_empty(),"stale boss rows clear "+context)
			game.ui.show_pause();await process_frame
			check(game.ui.modal_visible() and game.ui.current_screen=="pause","pause modal still visible "+context)
			game.ui.hide_modal();await process_frame
			check(not game.ui.modal_visible(),"pause dismisses "+context)
	check(intent_count==0,"read-only display updates do not emit gameplay intents")
	game.queue_free();await process_frame
	print(JSON.stringify({"combat_hud_readability_passed":passed,"failures":failures,"scope":"headless layout/style/read-only checks; native-window readability is separate"}))
	quit(0 if failures.is_empty() else 1)
