extends Node
# Explicit external controlled UI fixture. Not ordinary acquisition/play or shipped source.
var game
var index:=2
var mode_id:="arena"
var modified:=true
var shop:=false
var full:=false
var ids:Array=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
func _ready()->void:
 DisplayServer.window_set_title("CONTROLLED WEAPON READOUT QA")
 game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false);show_case()
func show_case()->void:
 game._title();game._select_mode(mode_id);game._start_run(24924)
 game.build.weapons=[ids[index],"rivet_gun","rail_lance","bankshot_driver"] if full else [ids[index]]
 game.build.items={"power_coil":2,"cooling_fan":1,"lens":1,"capacitor":2,"gear":2,"pellet_pouch":2} if modified else {}
 game.build.coins=1000;game.build.revision+=1;game._recompute();game.elapsed=10;game.spawn_clock=999
 if shop:
  game._open_shop();game.shop_offers=[{"id":ids[index],"sold":false,"weight_multiplier":1.0,"bias_reasons":[]},{"id":"power_coil","sold":false,"weight_multiplier":1.0,"bias_reasons":[]}];game._render_shop()
 else:game._on_intent("inventory",{})
 call_deferred("record")
func record()->void:
 await get_tree().process_frame
 var v:Dictionary=game._view();var rows:Array=[]
 for w in v.weapons:rows.append({"id":w.id,"slot":w.slot,"readout":w.get("weapon_readout",{})})
 print(JSON.stringify({"scope":"controlled injected UI setup; not ordinary play","mode":mode_id,"size":str(get_window().size),"case":index+1,"modified":modified,"shop":shop,"full":full,"state":game.state,"coins":game.build.coins,"weapons":rows,"items":game.build.items}))
func _process(_dt:float)->void:game._update_hud()
func _input(event:InputEvent)->void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_Q:get_tree().quit()
  KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8:index=int(event.keycode-KEY_1);show_case()
  KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";show_case()
  KEY_M:modified=not modified;show_case()
  KEY_B:shop=not shop;show_case()
  KEY_F:full=not full;show_case()
  KEY_L:call_deferred("record")
  KEY_F6:get_window().size=Vector2i(960,540);get_window().position=Vector2i(30,80);call_deferred("record")
  KEY_F7:get_window().size=Vector2i(1280,720);get_window().position=Vector2i(30,80);call_deferred("record")
