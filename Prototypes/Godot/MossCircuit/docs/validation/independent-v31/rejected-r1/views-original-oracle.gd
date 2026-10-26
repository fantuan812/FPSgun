extends SceneTree
## Controlled actual UI hierarchy/callback/focus tests; optional output, no hardware claim.
var g
var checks:=0
var failures:Array=[]
const IDS=["rivet","scatter","rail"]
const NAMES=["Rivet Starter","Scatter Starter","Rail Starter"]
const COINS=[35,23,17]
const WEAPONS=["rivet_gun","scrap_shotgun","rail_lance"]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var out:Array=[n]
 for c in n.get_children():out.append_array(nodes(c))
 return out
func buttons(prefix:String)->Array:return nodes(g.ui.modal).filter(func(n):return n is Button and n.text.begins_with(prefix))
func texts()->String:
 var a:Array=[]
 for n in nodes(g.ui.modal):
  if n is Label or n is Button:a.append(n.text)
 return "\n".join(a)
func scroll_of(n:Node)->ScrollContainer:
 var p:Node=n.get_parent()
 while p!=null and not p is ScrollContainer:p=p.get_parent()
 return p as ScrollContainer
func authority()->Dictionary:
 return {"state":g.state,"build":g.build.duplicate(true),"stats":g.stats.duplicate(true),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"origin":g.run.starting_loadout_id,"selected":g.selected_loadout_id,"title_generation":g.title_generation,"seed":g.run_seed,"clocks":g.weapon_clocks.duplicate(),"shop_generation":g.shop_generation,"choice_generation":g.choice_generation}
func accept(value:bool)->void:
 var e:=InputEventAction.new();e.action="ui_accept";e.pressed=value;root.push_input(e)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size;g._title();g._select_mode(mode)
   for k in range(IDS.size()):
    g._title()
    if g.selected_loadout_id!=IDS[k]:g._select_starting_loadout(IDS[k],g.title_generation)
    g._on_intent("seed_changed",{"seed":128+k});g._present_title();await process_frame;await process_frame
    var before:=authority();var start:Array=buttons("START ");var chosen:Array=buttons("SELECTED");var choices:Array=buttons("CHOOSE ")
    ck(start.size()==1 and chosen.size()==1 and choices.size()==2,"three selectable cards/one start "+mode+str(size)+IDS[k])
    if start.size()!=1 or chosen.size()!=1 or choices.size()!=2:continue
    ck(start[0].text=="START "+NAMES[k].to_upper()+" / "+str(COINS[k])+" SCRAP","persistent start summary exact kit/coins")
    ck(not start[0].disabled and root.gui_get_focus_owner()==start[0],"default focus remains start")
    ck(scroll_of(start[0])==null and g.ui.body.get_global_rect().encloses(start[0].get_global_rect()),"start summary/action outside scroll fully visible")
    ck(chosen[0].disabled and choices.all(func(b):return not b.disabled),"selected is disabled no-op; alternatives enabled")
    var txt:String=texts()
    ck(txt.contains(NAMES[k]+" / SELECTED") and txt.contains("Same hero, base HP and movement") and txt.contains("no modules") and txt.contains("shop affinity"),"explicit non-color selection and honest scope")
    for i in range(IDS.size()):
     ck(txt.contains(NAMES[i]) and txt.contains(str(COINS[i])+" STARTING SCRAP"),"all authored kit rows exposed in hierarchy")
    ck(txt.contains("per pellet contact") and txt.contains("Not every pellet will hit") and txt.contains("BASE WEAPON STATS"),"shared truthful pellet/base readout")
    var icons:Array=nodes(g.ui.modal).filter(func(n):return n is TextureRect and n.texture!=null)
    ck(icons.size()==3,"exact three existing icon textures")
    for b in choices+chosen:
     var sc:ScrollContainer=scroll_of(b);ck(sc!=null,"each choice in scroll content")
     if sc!=null:
      sc.ensure_control_visible(b);await process_frame;await process_frame
      ck(sc.get_global_rect().encloses(b.get_global_rect()),"whole choice button reachable at native layout size")
      ck(b.size.y>=32 and b.size.x>=100,"usable choice target")
    ck(authority()==before,"render/focus/scroll does not mutate authority")
    # Readouts are disclosure-only, and cannot change kit or start a run.
    var details:Array=buttons("SHOW BASE WEAPON DETAILS");ck(details.size()==3,"one existing disclosure per kit")
    if not details.is_empty():
     details[0].emit_signal("pressed");await process_frame;ck(authority()==before,"detail expansion read-only")
    # Real focused button + synthetic action, then stale captured callbacks.
    var target:int=(k+1)%3
    var wanted:Array=buttons("CHOOSE "+NAMES[target].to_upper());ck(wanted.size()==1,"requested alternate choice exists")
    if wanted.size()!=1:continue
    var old_start:Callable=start[0].get_signal_connection_list("pressed")[0].callable
    var old_choice:Callable=wanted[0].get_signal_connection_list("pressed")[0].callable
    var edits:Array=nodes(g.ui.modal).filter(func(n):return n is LineEdit)
    ck(edits.size()==1,"one seed draft field")
    if edits.size()==1:edits[0].text="8765";edits[0].emit_signal("text_changed","8765")
    wanted[0].grab_focus();accept(true);await process_frame;accept(false);await process_frame;await process_frame
    ck(g.selected_loadout_id==IDS[target] and g.run_seed==8765 and g.state=="title","synthetic action uses real selection and retains seed")
    ck(g.title_generation==before.title_generation+1,"selection advances exactly one title generation")
    var stable:=authority();old_start.call();old_choice.call();ck(authority()==stable,"stale old start/select callbacks cannot start/reset")
    ck(root.gui_get_focus_owner()==buttons("START ")[0],"rerender default focus still start")
    # Real fresh START callback, with detached origin separate from current gear.
    buttons("START ")[0].emit_signal("pressed");await process_frame;await process_frame
    ck(g.state=="playing" and g.build.weapons==[WEAPONS[target]] and g.build.coins==COINS[target] and g.run_seed==8765,"fresh visible START initializes chosen kit")
    g._on_intent("inventory",{});await process_frame;await process_frame
    ck(texts().contains("STARTED WITH: "+NAMES[target]) and texts().contains("origin only, not current equipment"),"read-only origin in inventory")
    ck(buttons("CHOOSE ").is_empty() and buttons("SELECTED").is_empty(),"no midrun kit selector")
    g.build.weapons=["bankshot_driver"];g._recompute();g._present_inventory();await process_frame;await process_frame
    ck(texts().contains("STARTED WITH: "+NAMES[target]) and texts().contains("Bankshot Driver [SLOT 1]"),"origin not rewritten to changed gear")
    g._finish(true);await process_frame;await process_frame
    ck(texts().contains("STARTED WITH: "+NAMES[target]) and buttons("CHOOSE ").is_empty(),"result origin visible and read-only")
   # Explicit legacy two-argument UI path emits unchanged Rivet start intent.
   g._title();g.selected_loadout_id="rail";g.ui.show_title(123,mode);await process_frame;await process_frame
   ck(buttons("CHOOSE ").is_empty() and buttons("START RUN").size()==1,"legacy two-argument title unchanged")
   buttons("START RUN")[0].emit_signal("pressed");await process_frame
   ck(g.build.weapons==["rivet_gun"] and g.build.coins==35 and g.run.starting_loadout_id=="rivet","legacy UI start remains old default")
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"Controlled actual title UI layout, all3 choices/both modes/960x540 and1280x720, native-size rectangles, signal callbacks and syntheticui_accept, default focus, stale callbacks, seed retention and read-only origin. Native pixels/mouse/keyboard and ordinary exported starts remain separate; no physical-controller claim.","checks":checks,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
