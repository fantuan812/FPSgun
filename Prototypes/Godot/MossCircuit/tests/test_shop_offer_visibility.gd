extends SceneTree
var passed:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	if value:passed+=1
	else:failures.append(label)
func _initialize()->void:call_deferred("run")
func buttons(node:Node)->Array:
	var found:Array=[]
	if node is Button:found.append(node)
	for child in node.get_children():found.append_array(buttons(child))
	return found
func run()->void:
	root.size=Vector2i(960,540)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);game.set_process(false)
	# Historical38-card suite; actual43-icon/new5 UI is separate.
	var legacy_input:Dictionary=preload("res://tests/support/v39_legacy_inputs.gd").install(game)
	if not legacy_input.pass:push_error(str(legacy_input.errors));quit(1);return
	game._start_run(1717)
	game.build.coins=999;game._open_shop()
	for entry in game.catalog.weapons+game.catalog.items:
		var view:Dictionary=game._view()
		var offer:Dictionary=entry.duplicate(true)
		offer.merge({"index":0,"sold":false,"can_buy":true,"weight_multiplier":2.0,"bias_reasons":["Existing build shares this tag"]})
		view.offers=[offer]
		game.ui.show_shop(view)
		await process_frame;await process_frame
		var buy:Button
		for button in buttons(game.ui.modal):
			if button.text.begins_with("BUY"):buy=button;break
		check(buy!=null,"purchase action exists "+entry.id)
		if buy==null:continue
		var scroll:Node=buy.get_parent()
		while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
		scroll.scroll_vertical=0
		await process_frame
		var action_rect:Rect2=buy.get_global_rect()
		var viewport_rect:Rect2=scroll.get_global_rect()
		check(action_rect.position.y>=viewport_rect.position.y and action_rect.end.y<=viewport_rect.end.y,"first purchase visible at initial scroll "+entry.id)
		var disclosure:Button
		for button in buttons(game.ui.modal):
			if button.text=="SHOW DRAW DETAILS":disclosure=button;break
		check(disclosure!=null,"draw explanation remains keyboard-accessible "+entry.id)
		if disclosure:
			var generation:int=game.shop_generation
			var coins:int=game.build.coins
			disclosure.button_pressed=true
			await process_frame
			check(disclosure.text=="HIDE DRAW DETAILS","explanation expands with clear affordance "+entry.id)
			disclosure.button_pressed=false
			await process_frame
			check(game.shop_generation==generation and game.build.coins==coins,"read-only disclosure never rerolls or purchases "+entry.id)
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free();await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"shop_offer_visibility_passed":passed,"failures":failures,"scope":"all32 catalog first-offer purchase rectangles and disclosure lifecycle at960x540; GUI separate"}))
	quit(0 if failures.is_empty() else 1)
