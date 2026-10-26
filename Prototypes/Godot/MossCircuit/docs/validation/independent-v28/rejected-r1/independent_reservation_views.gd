extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var g
var checks:=0
var failures:Array=[]
var samples:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func descendants(node:Node)->Array:
 var result:Array=[node]
 for child in node.get_children():result.append_array(descendants(child))
 return result
func button(prefix:String)->Button:
 for n in descendants(g.ui.modal):
  if n is Button and n.text.begins_with(prefix):return n
 return null
func all_text()->String:
 var texts:Array=[]
 for n in descendants(g.ui.modal):
  if n is Label or n is Button:texts.append(n.text)
 return "\n".join(texts)
func rectangle_check(purchase:Button,reserve:Button,label:String)->void:
 ck(purchase!=null and reserve!=null,label+" both actions exist")
 if purchase==null or reserve==null:return
 var scroller:Node=purchase.get_parent()
 while scroller!=null and not scroller is ScrollContainer:scroller=scroller.get_parent()
 ck(scroller!=null,label+" actions are in offer scroll pane")
 if scroller==null:return
 var viewport:Rect2=scroller.get_global_rect()
 var p:Rect2=purchase.get_global_rect();var r:Rect2=reserve.get_global_rect()
 ck(p.position.y>=viewport.position.y and p.end.y<=viewport.end.y,label+" first BUY/REPLACE initially visible")
 ck(r.position.y>=viewport.position.y and r.end.y<=viewport.end.y,label+" first reserve/release initially visible")
 ck(p.position.x>=viewport.position.x and r.end.x<=viewport.end.x,label+" both horizontal bounds fit")
 ck(is_equal_approx(p.position.y,r.position.y) and minf(p.size.y,r.size.y)>=32,label+" same-height reachable action row")
func setup(mode:String,id:String)->void:
 g._title();g._select_mode(mode);g._start_run(28001);g.build.coins=0;g._open_shop()
 var offer:Dictionary=Rules.weighted_pool(g.build,g.catalog).filter(func(e):return e.id==id)[0].duplicate(true)
 offer.sold=false;g.shop_offers=[offer];g._render_shop()
func accept_event(pressed:bool)->void:
 var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A;event.pressed=pressed;event.device=0
 ck(InputMap.event_is_action(event,"ui_accept"),"default joypad A mapping recognized as ui_accept")
 root.push_input(event)
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var expected_ids:Array=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
 ck(g.catalog.weapons.map(func(e):return e.id)==expected_ids,"exact eight weapon IDs and order")
 ck(g.catalog.items.size()==29,"exact 29-module catalog count")
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for entry in g.catalog.weapons+g.catalog.items:
    setup(mode,entry.id)
    await process_frame;await process_frame
    var label:String=mode+" "+str(size)+" "+entry.id
    var buy:Button=button("BUY");var reserve:Button=button("RESERVE")
    rectangle_check(buy,reserve,label+" unheld")
    ck(buy.disabled and not reserve.disabled,label+" unfunded reserve enabled independently of purchase")
    ck(reserve.focus_mode==Control.FOCUS_ALL,label+" keyboard focus enabled")
    var view:Dictionary=g._view()
    ck(view.offers[0].can_reserve and not view.offers[0].reserved and view.reserved_offer.is_empty(),label+" no false ownership/hold state")
    var stale:Callable=reserve.get_signal_connection_list("pressed")[0].callable
    reserve.emit_signal("pressed")
    await process_frame;await process_frame
    buy=button("BUY");var release:Button=button("RELEASE")
    rectangle_check(buy,release,label+" held")
    ck(not release.disabled and buy.disabled,label+" release remains enabled without funds")
    var text:String=all_text()
    ck(text.contains("[RESERVED]") and text.contains("NOT OWNED") and text.contains("three fresh"),label+" reserved cost/ownership disclosure")
    ck(text.contains("ORIGINAL DRAW / RETAINED") and text.contains("not a new draw or current chance"),label+" historic metadata not current probability")
    var held:Dictionary=g.reserved_offer.duplicate(true);var gen:int=g.shop_generation
    stale.call()
    ck(g.shop_generation==gen and g.reserved_offer==held,label+" detached old UI callback rejected")
    view=g._view();view.reserved_offer.name="mutated view";view.offers[0].bias_reasons.append("mutated view")
    ck(g.reserved_offer==held,label+" view data detached from reservation")
    release.emit_signal("pressed")
    ck(g.reserved_offer.is_empty() and g.build.coins==0,label+" actual release signal keeps funds unchanged")
    await process_frame
   # Full-slot layout must retain select/REPLACE and reservation on the same first card.
   setup(mode,"rail_lance");g.build.weapons=["rivet_gun","return_disc","orbit_saw","cryo_sprayer"];g.build.coins=100;g._recompute();g._reserve_offer(0,g.shop_generation)
   await process_frame;await process_frame
   rectangle_check(button("REPLACE"),button("RELEASE"),mode+str(size)+" full-slot")
   var options:Array=descendants(g.ui.modal).filter(func(n):return n is OptionButton)
   ck(options.size()==1 and options[0].item_count==4,"all four replacement targets remain available")
   var text:String=all_text();ck(text.contains("no refund"),"replacement loss disclosed")
   # Synthetic controller-mapped UI events, not a physical controller or game movement claim.
   setup(mode,"rail_lance");await process_frame;await process_frame
   var reserve:Button=button("RESERVE");reserve.grab_focus()
   var before:Array=[g.build.coins,g.build.revision,g.shop_rng.state]
   var gen:int=g.shop_generation
   accept_event(true);await process_frame;accept_event(false);await process_frame;await process_frame
   ck(not g.reserved_offer.is_empty() and g.shop_generation==gen+1,"default ui_accept reserves focused card")
   var release:Button=button("RELEASE")
   if release!=null:
    release.grab_focus();accept_event(true);await process_frame;accept_event(false);await process_frame;await process_frame
    ck(g.reserved_offer.is_empty() and g.shop_generation==gen+2,"default ui_accept releases focused card")
   else:ck(false,"release button after synthetic ui_accept")
   ck(before==[g.build.coins,g.build.revision,g.shop_rng.state],"mapped UI toggles preserve coins/revision/RNG")
   samples.append({"mode":mode,"window":[size.x,size.y],"entries":g.catalog.weapons.size()+g.catalog.items.size(),"mapped_event":"synthetic InputEventJoypadButton A through Viewport.push_input"})
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"layouts":samples,"scope":"Actual UI hierarchy geometry, button callbacks and synthetic default controller-mapped UI accept in both modes/two sizes. This is not native pixel review, physical controller gameplay or ordinary acquisition."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
