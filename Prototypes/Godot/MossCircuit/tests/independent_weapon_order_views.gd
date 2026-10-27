extends SceneTree
## Actual UI structure/geometry and existing action dispatch. No hardware-controller claim.
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var a:Array=[n]
 for c in n.get_children():a.append_array(nodes(c))
 return a
func buttons(prefix:String)->Array:return nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with(prefix))
func texts()->String:
 var a:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:a.append(n.text)
 return "\n".join(a)
func authority()->Dictionary:
 return {"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"generation":g.shop_generation,"held":g.reserved_offer.duplicate(true),"offers":g.shop_offers.duplicate(true),"clocks":g.weapon_clocks.duplicate(),"effects":[g.effects.epoch,g.effects.last_sequence,g.effect_runtime.sequence,g.effects.echo_hits,g.effects.phase_charge,g.effects.feedback_armed]}
func setup(mode:String,ids:Array)->void:
 g._title();g._select_mode(mode);g._start_run(30001)
 g.build.weapons=ids.duplicate();g._recompute();g.build.coins=137
 g.weapon_clocks=[]
 for i in range(ids.size()):g.weapon_clocks.append(.13+float(i)*.17)
 g._open_shop();g._sync_weapon_rig()
func scroll_of(node:Node)->ScrollContainer:
 var p:Node=node.get_parent()
 while p!=null and not p is ScrollContainer:p=p.get_parent()
 return p as ScrollContainer
func accept(value:bool)->void:
 var event:=InputEventAction.new();event.action="ui_accept";event.pressed=value;root.push_input(event)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var profiles:Array=[["rivet_gun"],["rivet_gun","rail_lance"],["cryo_sprayer","orbit_saw","return_disc"],["shock_mortar","scrap_shotgun","bankshot_driver","rivet_gun"],["cryo_sprayer","cryo_sprayer","orbit_saw","orbit_saw"]]
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size
   for ids in profiles:
    setup(mode,ids);var before:=authority();await process_frame;await process_frame
    var earlier:Array=buttons("MOVE EARLIER");var later:Array=buttons("MOVE LATER")
    ck(earlier.size()==ids.size() and later.size()==ids.size(),"one adjacent action pair per owned copy "+mode+str(size))
    if earlier.size()!=ids.size() or later.size()!=ids.size():continue
    ck(not root.gui_get_focus_owner() in earlier and not root.gui_get_focus_owner() in later,"moves never initial/default focus")
    var text:String=texts()
    ck(text.contains("FREE ORDER") and text.contains("cooldown follows each copy") and text.contains("SLOT 1 is the hand mount"),"free/copy-time/mount guidance")
    ck(text.contains("not guaranteed earlier impact or more damage") and text.contains("does not reset or synchronize"),"truthful conditional ordering disclosure")
    for i in range(ids.size()):
     ck(text.contains("[SLOT "+str(i+1)+"]"),"one-based copy identity")
     ck(earlier[i].disabled==(i==0 or ids.size()<2) and later[i].disabled==(i==ids.size()-1 or ids.size()<2),"only eligible adjacent direction enabled")
     ck(earlier[i].focus_mode==Control.FOCUS_ALL and later[i].focus_mode==Control.FOCUS_ALL,"existing keyboard navigation")
     var bag:ScrollContainer=scroll_of(earlier[i]);ck(bag!=null,"owned actions in scrollable bag")
     if bag!=null:
      bag.ensure_control_visible(earlier[i]);await process_frame;await process_frame
      ck(bag.get_global_rect().encloses(earlier[i].get_global_rect()) and bag.get_global_rect().encloses(later[i].get_global_rect()),"both full action rectangles reachable")
      ck(earlier[i].size.y>=32 and earlier[i].size.x>=100 and later[i].size.x>=100,"usable paired target size")
    # Preserve document order: grouping BUY ahead of REPLACE misidentifies later offers.
    var purchase:Array=nodes(g.ui.modal).filter(func(n):return n is Button and (n.text.begins_with("BUY") or n.text.begins_with("REPLACE")))
    ck(not purchase.is_empty(),"purchase/replacement remains present")
    if not purchase.is_empty():
     var offers:ScrollContainer=scroll_of(purchase[0]);ck(offers!=null and offers.get_global_rect().encloses(purchase[0].get_global_rect()),"first purchase/replacement initially visible")
    ck(authority()==before,"render/scroll/focus observations read-only")
   setup(mode,["rivet_gun","rail_lance"]);await process_frame;await process_frame
   var move:Button=buttons("MOVE LATER")[0];var stale:Callable=move.get_signal_connection_list("pressed")[0].callable
   var before:=authority();move.grab_focus();accept(true);await process_frame;accept(false);await process_frame;await process_frame
   ck(g.build.weapons==["rail_lance","rivet_gun"] and g.weapon_clocks==[before.clocks[1],before.clocks[0]],"synthetic ui_accept dispatches real copy swap")
   ck(g.shop_generation==before.generation+1 and g.build.coins==137,"action is one guarded free transaction")
   var stable:=authority();stale.call();ck(authority()==stable,"old captured button callback rejected")
   ck(not root.gui_get_focus_owner() in buttons("MOVE EARLIER")+buttons("MOVE LATER"),"post-render default not reorder")
   # A direct actual button signal reaches the same authority with fresh slot identity.
   buttons("MOVE EARLIER")[1].emit_signal("pressed");await process_frame;await process_frame
   ck(g.build.weapons==["rivet_gun","rail_lance"] and g.weapon_clocks==before.clocks,"fresh opposite UI callback restores copies")
   # Unsettled view disables, and read-only inventory cannot grant shop operations.
   g.bullets=[{"life":1.0,"weapon":"rivet_gun","slot":0}];g._render_shop();await process_frame;await process_frame
   ck(buttons("MOVE EARLIER").all(func(b):return b.disabled) and buttons("MOVE LATER").all(func(b):return b.disabled),"all controls disabled with flight state")
   ck(texts().contains("shots are still active"),"unavailable cause visible")
   g.bullets.clear();g.state="inventory";g.ui.show_inventory(g._view());await process_frame;await process_frame
   ck(buttons("MOVE EARLIER").is_empty() and buttons("MOVE LATER").is_empty(),"ordinary inventory is not editable")
   g.state="shop";g.shop_offers=[];g._render_shop();await process_frame;await process_frame
   ck(not root.gui_get_focus_owner() in buttons("MOVE EARLIER")+buttons("MOVE LATER"),"no default reorder even synthetic empty stock")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"scope":"Controlled actual UI hierarchy/rectangles, all8 weapon identities and repeated copies, 1–4 slots, both modes/960x540 and1280x720; real bound callbacks plus synthetic InputEventAction ui_accept. Native pixels/keyboard/mouse and ordinary acquisition are separate. No controller mapping/hardware claim.","checks":checks,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
