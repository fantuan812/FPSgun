extends SceneTree
const Rules=preload("res://scripts/rules.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var a:Array=[n]
 for child in n.get_children():a.append_array(nodes(child))
 return a
func buttons(prefix:String)->Array:
 return nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with(prefix))
func texts()->String:
 var a:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:a.append(n.text)
 return "\n".join(a)
func authority()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"pending":g.upgrade_pending,"generation":g.choice_generation,"held":g.reserved_offer.duplicate(true),"choices":g.choices.duplicate(true)}
func setup(mode:String,ids:Array,coins:int)->void:
 g._title();g._select_mode(mode);g._start_run(29001);g.build.coins=coins
 g.upgrade_pending=2;g.shop_pending=false;g._show_upgrades()
 g.choices=[]
 for id in ids:g.choices.append(g.config.upgrades.filter(func(e):return e.id==id)[0].duplicate(true))
 g.ui.show_upgrade(g.choices,g.choice_generation,g._upgrade_salvage_view())
func accept(pressed:bool)->void:
 var e:=InputEventAction.new();e.action="ui_accept";e.pressed=pressed;root.push_input(e)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var ids:Array=["damage","speed","haste","health","magnet","pierce"]
 ck(g.config.upgrades.map(func(e):return e.id)==ids,"exact six upgrade IDs/order; no seventh entry")
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for a in range(4):
    for b in range(a+1,5):
     for c in range(b+1,6):
      setup(mode,[ids[a],ids[b],ids[c]],32)
      var before:=authority();await process_frame;await process_frame
      var ordinary:Array=buttons("SELECT");var alternatives:Array=buttons("SALVAGE THIS UPGRADE")
      ck(ordinary.size()==3 and alternatives.size()==1,"three ordinary and separate salvage "+mode+str(size))
      if ordinary.size()!=3 or alternatives.size()!=1:continue
      var salvage:Button=alternatives[0];var first:Button=ordinary[0];var last:Button=ordinary[2]
      ck(root.gui_get_focus_owner()==first,"ordinary first SELECT initial focus")
      ck(salvage.focus_mode==Control.FOCUS_ALL and not salvage.disabled,"salvage keyboard focus enabled")
      var rect:Rect2=salvage.get_global_rect();var viewport:=Rect2(Vector2.ZERO,Vector2(size))
      ck(viewport.encloses(rect) and rect.size.y>=32,"salvage action inside viewport")
      var scroll:Node=first.get_parent()
      while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
      ck(scroll!=null,"ordinary cards remain scrollable")
      if scroll!=null:
       ck(scroll.get_global_rect().encloses(first.get_global_rect()),"first SELECT initially visible")
       ck(rect.position.y>=scroll.get_global_rect().end.y,"salvage outside/below ordinary scroll")
       scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await process_frame;await process_frame
       ck(scroll.get_global_rect().encloses(last.get_global_rect()),"last ordinary SELECT reachable by scrolling")
      var text:String=texts()
      ck(text.contains("Forfeit this permanent stat choice") and text.contains("Keep earned level / XP") and text.contains("+10 SCRAP"),"sacrifice/amount/earned-level disclosure")
      ck(text.contains("CURRENT SCRAP: 32") and text.contains("later normal shop, if reached"),"budget and no-guaranteed-shop disclosure")
      ck(authority()==before,"render/focus/scroll read-only")
   setup(mode,ids.slice(0,3),32);await process_frame;await process_frame
   var salvage:Button=buttons("SALVAGE THIS UPGRADE")[0]
   var old_callback:Callable=salvage.get_signal_connection_list("pressed")[0].callable
   salvage.grab_focus();accept(true);await process_frame;accept(false);await process_frame;await process_frame
   ck(g.build.coins==42 and g.upgrade_pending==1 and g.state=="upgrade","synthetic ui_accept actual salvage callback")
   var before:=authority();old_callback.call();ck(authority()==before,"stale old button cannot resolve next page")
   ck(root.gui_get_focus_owner()==buttons("SELECT")[0],"next page defaults to ordinary SELECT")
   # Legacy two-argument API remains a three-stat-only presentation.
   g.ui.show_upgrade(g.choices,g.choice_generation);await process_frame;await process_frame
   ck(buttons("SELECT").size()==3 and buttons("SALVAGE THIS UPGRADE").is_empty(),"legacy optional context retained")
   ck(authority()==before,"legacy render read-only")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var r:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled UI hierarchy/geometry,20 three-of-six combinations per mode/size, actual button callback and synthetic ui_accept. Native pixels/keyboard/mouse and ordinary acquisition remain separate. No physical controller claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(r,"  ")+"\n")
 print(JSON.stringify(r));quit(0 if failures.is_empty() else 1)
