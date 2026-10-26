extends Node
# Controlled injected ownership/shop setup, never ordinary acquisition or shipped source.
var game
var mode_id:="arena"
var index:=2
var shop:=false
var profiles:Array=[[["rivet_gun"],{}],[["rail_lance"],{"capacitor":1}],[["rail_lance","orbit_saw","scrap_shotgun"],{"capacitor":2,"gear":2,"pellet_pouch":2}],[["rail_lance","rail_lance","rail_lance","rail_lance"],{}],[["rivet_gun"],{"capacitor":3,"gear":3}],[["rail_lance","rail_lance","rivet_gun","scrap_shotgun"],{"capacitor":1}]]
func _ready()->void:
 DisplayServer.window_set_title("CONTROLLED TAG PROGRESS QA")
 game=load("res://scenes/main.tscn").instantiate();add_child(game);game.set_process(false);show_case()
func nodes(n:Node)->Array:
 var out:Array=[n]
 for c in n.get_children():out.append_array(nodes(c))
 return out
func show_case()->void:
 game._title();game._select_mode(mode_id);game._start_run(25025)
 game.build.weapons=profiles[index][0].duplicate();game.build.items=profiles[index][1].duplicate();game.build.coins=1000;game.build.revision+=1;game._recompute();game.elapsed=10;game.spawn_clock=999
 if shop:
  game._open_shop();game.shop_offers=[{"id":"rivet_gun" if index==5 else "capacitor","sold":false,"weight_multiplier":1.0,"bias_reasons":[]}];game._render_shop()
 else:game._on_intent("inventory",{})
 call_deferred("record")
func tag_scroll()->void:
 await get_tree().process_frame;await get_tree().process_frame
 for n in nodes(game.ui.modal):
  if n is Label and n.text=="TAG SYNERGY PROGRESS":
   var p:Node=n.get_parent()
   while p!=null and not p is ScrollContainer:p=p.get_parent()
   if p is ScrollContainer:p.scroll_vertical+=int(n.global_position.y-p.global_position.y);p.grab_focus()
 call_deferred("record")
func record()->void:
 await get_tree().process_frame
 var view:Dictionary=game._view();var scrolls:Array=[]
 for n in nodes(game.ui.modal):
  if n is ScrollContainer:scrolls.append({"offset":n.scroll_vertical,"rect":str(n.get_global_rect())})
 print(JSON.stringify({"scope":"controlled injected ownership/setup; native UI inputs only thereafter","case":index+1,"mode":mode_id,"size":str(get_window().size),"screen":game.ui.current_screen,"state":game.state,"coins":game.build.coins,"weapons":game.build.weapons,"items":game.build.items,"rows":view.tag_synergy_status,"scrolls":scrolls}))
func _process(_dt:float)->void:game._update_hud()
func _input(event:InputEvent)->void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_Q:get_tree().quit()
  KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6:index=int(event.keycode-KEY_1);show_case()
  KEY_O:mode_id="rooms" if mode_id=="arena" else "arena";show_case()
  KEY_B:shop=not shop;show_case()
  KEY_T:call_deferred("tag_scroll")
  KEY_L:call_deferred("record")
  KEY_F6:get_window().size=Vector2i(960,540);get_window().position=Vector2i(30,80);call_deferred("record")
  KEY_F7:get_window().size=Vector2i(1280,720);get_window().position=Vector2i(30,80);call_deferred("record")
