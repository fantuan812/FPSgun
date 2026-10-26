extends Node
# External controlled text-layout fixture; not shipping progression or main scene.
var game
var mode_id:="arena"
var scenario:=1
func _ready()->void:
 DisplayServer.window_set_title("CONTROLLED MODIFIER COPY QA")
 game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false);show_case()
func show_case()->void:
 game._title();game._select_mode(mode_id);game._start_run(433)
 game.build.weapons=["cryo_sprayer","rivet_gun"];game.build.items={"power_coil":1,"fracture_coil":1};game.build.coins=1000;game._recompute()
 if scenario in [1,2,3]:
  var id:String=["power_coil","cryo_sprayer","fracture_coil"][scenario-1]
  game._open_shop();game.shop_offers=[{"id":id,"sold":false,"weight_multiplier":1.0,"bias_reasons":[]}];game._render_shop()
 elif scenario==4:game._on_intent("inventory",{})
 elif scenario==5:
  game.upgrade_pending=1;game._show_upgrades();game.choices=[game.config.upgrades.filter(func(u):return u.id=="haste")[0],game.config.upgrades.filter(func(u):return u.id=="damage")[0],game.config.upgrades.filter(func(u):return u.id=="pierce")[0]];game.ui.show_upgrade(game.choices,game.choice_generation)
 elif scenario==6:
  game.build.weapons=["cryo_sprayer","cryo_sprayer"];game._recompute();game._on_intent("inventory",{})
 print(JSON.stringify({"fixture":"controlled modifier copy","mode":mode_id,"case":scenario,"native_size":str(get_window().size),"scope":"injected UI setup; not ordinary play"}))
func _input(event:InputEvent)->void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6:scenario=int(event.keycode-KEY_0);show_case()
  KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";show_case()
  KEY_F6:get_window().size=Vector2i(960,540);get_window().position=Vector2i(30,80)
  KEY_F7:get_window().size=Vector2i(1280,720);get_window().position=Vector2i(30,80)
