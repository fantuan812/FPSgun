extends SceneTree
var passed := 0
var failures: Array = []
func check(v: bool, s: String) -> void:
	if v: passed += 1
	else: failures.append(s)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(960,540)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	await process_frame
	check(root.gui_get_focus_owner() != null,"title focus")
	game._start_run(10)
	for entry in game.catalog.weapons + game.catalog.items:
		var tex = game.ui.icon(entry.id)
		check(tex != null,"icon exists " + entry.id)
		if tex is AtlasTexture:
			check(tex.region.size.x > 0 and tex.region.size.y > 0 and tex.region.position.x >= 0 and tex.region.position.y >= 0 and tex.region.end.x <= tex.atlas.get_width() and tex.region.end.y <= tex.atlas.get_height(),"icon valid rect " + entry.id)
	game._open_shop()
	await process_frame
	await process_frame
	check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().is_visible_in_tree(),"shop focus visible")
	check(game.ui.modal.size.x <= 960 and game.ui.modal.size.y <= 540,"integrated shop logical viewport")
	var gen: int = game.shop_generation
	game._on_intent("inventory",{})
	check(game.state == "inventory","shop inventory open")
	check(not game._buy(0,gen),"shop purchase blocked in inventory")
	game._on_intent("close_inventory",{})
	check(game.state == "shop","inventory returns shop")
	game._leave_shop(game.shop_generation)
	game.upgrade_pending = 1
	game._show_upgrades()
	await process_frame
	await process_frame
	check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().is_visible_in_tree(),"upgrade focus visible")
	game._take_upgrade(0,game.choice_generation)
	check(root.gui_get_focus_owner() == null,"playing releases modal focus")
	var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
	audio_teardown.prepare([game])
	game.queue_free()
	await process_frame
	await audio_teardown.finish(self)
	print(JSON.stringify({"independent_ui_passed":passed,"failures":failures,"scope":"headless structure and resources, no visual window"}))
	quit(0 if failures.is_empty() else 1)
