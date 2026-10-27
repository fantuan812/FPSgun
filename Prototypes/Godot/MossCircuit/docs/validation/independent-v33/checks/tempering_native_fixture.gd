extends SceneTree
## EXTERNAL CONTROLLED layout fixture, never shipped or ordinary acquisition evidence.
const Rules=preload("res://scripts/rules.gd")
var g
var mode_id:="arena"
var large:=false
var index:=0
class Driver extends Node:
 var next:Callable
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
   next.call();get_viewport().set_input_as_handled()
func nodes(n:Node)->Array:
 var a:Array=[n]
 for c in n.get_children():a.append_array(nodes(c))
 return a
func buttons(prefix:String)->Array:return nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with(prefix))
func scroll_of(n:Node)->ScrollContainer:
 var p:Node=n.get_parent()
 while p!=null and not p is ScrollContainer:p=p.get_parent()
 return p as ScrollContainer
func _initialize()->void:call_deferred("boot")
func boot()->void:
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():mode_id=args[0]
 large=args.size()>1 and args[1]=="large"
 root.title="Moss v33 CONTROLLED temper QA"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var d:=Driver.new();d.next=advance;root.add_child(d)
 await process_frame;await process_frame
 root.size=Vector2i(1280,720) if large else Vector2i(960,540)
 await process_frame;show_case()
func advance()->void:index=(index+1)%6;show_case()
func show_case()->void:
 g._title();g._select_mode(mode_id);g._start_run(3304);g.set_process(false)
 var ids:Array=[["rivet_gun","rivet_gun"],["rail_lance","rail_lance","rail_lance"],["scrap_shotgun","scrap_shotgun","scrap_shotgun"],["rail_lance","rivet_gun","rail_lance","rivet_gun"],["rivet_gun","rivet_gun","rivet_gun","rivet_gun"],["return_disc","rail_lance","return_disc","orbit_saw"]][index]
 g.build.weapons=ids.duplicate()
 if index==3:g.build.weapon_temper=[1,0,0,0]
 g._recompute();g.build.coins=137;g.weapon_clocks=[]
 for i in range(ids.size()):g.weapon_clocks.append(.17+float(i)*.19)
 g._open_shop()
 # Exact real catalog offers, deliberately supplied fixture stock, not seeded acquisition.
 g.shop_offers=[]
 for id in ["cryo_sprayer","power_coil","return_disc","fracture_coil"]:
  var e:Dictionary=Rules.catalog_entry(g.catalog,id).duplicate(true);e.sold=false;g.shop_offers.append(e)
 g._reserve_offer(0,g.shop_generation)
 if index==4:
  g._temper_weapon(0,1,g.shop_generation,"rivet_gun","rivet_gun");g._temper_weapon(2,1,g.shop_generation,"rivet_gun","rivet_gun")
 elif index==5:g._temper_weapon(2,0,g.shop_generation,"return_disc","return_disc")
 if index>=4:g.state="inventory";g.ui.show_inventory(g._view())
 else:g._render_shop()
 await process_frame;await process_frame;await process_frame
 if index<=2:
  var targets:Array=buttons("TEMPER / CONSUME SLOT ")
  if not targets.is_empty():
   var scroll:ScrollContainer=scroll_of(targets[0]);scroll.ensure_control_visible(targets[0])
 elif index==3:
  var replacement:Array=nodes(g.ui.modal).filter(func(n):return n is OptionButton)
  if not replacement.is_empty():scroll_of(replacement[0]).ensure_control_visible(replacement[0])
 await process_frame;await process_frame
 print(JSON.stringify({"fixture":"CONTROLLED temper layout","mode":mode_id,"case":index+1,"size":[root.size.x,root.size.y],"weapons":g.build.weapons,"tiers":g.build.get("weapon_temper",[]),"scope":"N advances; all setup is external injection, not ordinary gameplay"}))
