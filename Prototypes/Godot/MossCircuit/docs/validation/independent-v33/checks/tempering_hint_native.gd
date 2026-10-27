extends SceneTree
## External CONTROLLED exact-pack presentation fixture; not an ordinary acquisition.
var g
var index:=0
class Driver extends Node:
 var next:Callable
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
   next.call();get_viewport().set_input_as_handled()
func nodes(n:Node)->Array:
 var result:Array=[n]
 for child in n.get_children():result.append_array(nodes(child))
 return result
func _initialize()->void:call_deferred("boot")
func boot()->void:
 root.title="Moss v33 R2 CONTROLLED exact-pack hint"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var d:=Driver.new();d.next=advance;root.add_child(d)
 await process_frame;show_case()
func advance()->void:index=(index+1)%4;show_case()
func show_case()->void:
 var mode:String="arena" if index%2==0 else "rooms"
 root.size=Vector2i(960,540) if index<2 else Vector2i(1280,720)
 await process_frame;await process_frame
 g._title();g._select_mode(mode);g._start_run(433);g.set_process(false)
 g.build.weapons=["rivet_gun","rivet_gun"];g._recompute();g.weapon_clocks=[.23,.37];g.build.coins=42
 g._open_shop();var ok:bool=g._temper_weapon(0,1,g.shop_generation,"rivet_gun","rivet_gun")
 await process_frame;await process_frame
 for label in nodes(g.ui.modal):
  if label is Label and label.text=="TEMPERED / maximum tier. Cannot be fused again.":
   var p:Node=label.get_parent()
   while p!=null and not p is ScrollContainer:p=p.get_parent()
   if p is ScrollContainer:p.ensure_control_visible(label)
 await process_frame;await process_frame
 print(JSON.stringify({"fixture":"CONTROLLED exact-pack hint; injected setup then actual fusion","case":index+1,"mode":mode,"size":[root.size.x,root.size.y],"fused":ok,"reason":g._weapon_temper_view(0).reason,"weapons":g.build.weapons,"tiers":g.build.get("weapon_temper",[]),"clock":g.weapon_clocks,"scrap":g.build.coins}))
