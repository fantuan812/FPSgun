extends SceneTree
## Synthetic actual GUI dispatch/read-only presentation checks; native captures separate.
var g
var checks:=0
var failures:Array=[]
var samples:Array=[]
var events:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func all_nodes(n:Node)->Array:
 var a:Array=[n]
 for c in n.get_children():a.append_array(all_nodes(c))
 return a
func button(text:String)->BaseButton:
 for n in all_nodes(g.ui.root):
  if n is BaseButton and n.is_visible_in_tree() and n.text==text:return n
 return null
func text_all()->String:
 var s:String=""
 for n in all_nodes(g.ui.modal):
  if n is Label or n is Button:s+=n.text+"\n"
 return s
func center(c:Control)->Vector2:return c.get_global_transform_with_canvas()*(c.size*.5)
func click(c:Control)->void:
 var p:Vector2=center(c)
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=p;e.global_position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;root.push_input(e,true)
func reveal(c:Control)->void:
 var parent:Node=c.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(c)
  parent=parent.get_parent()
func gameplay()->String:return JSON.stringify({"build":g.build,"stats":g.stats,"state":g.state,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"epoch":g.effects.epoch,"sequence":g.effect_sequence,"clock":g.weapon_clocks})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.feedback_audio.cue_requested.connect(func(cue:String,accepted:bool):events.append([cue,accepted]))
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720)]:
   root.size=size;await process_frame;await process_frame
   for source in ["title","paused"]:
    g._title();g._select_mode(mode);g._start_run(3503);g.set_process(false);g.weapon_clocks=[999.];g.settings.reduced_flashes=false;g.vfx.reduced_flashes=false;g.actor_anim.reduced_flashes=false;g.settings.mute_feedback_sounds=false;g.feedback_audio.set_muted(false);events.clear()
    if source=="title":g._title()
    else:g._on_intent("pause",{})
    await process_frame;await process_frame
    var open:BaseButton=button("PRESENTATION SETTINGS");ck(open!=null,"renamed actual entry "+source+mode+str(size))
    if open==null:continue
    click(open);await process_frame;await process_frame
    ck(g.state=="settings" and g.settings_return==source,"GUI enters correct settings return context")
    var reduce:BaseButton=button("REDUCE DECORATIVE FLASHES");var mute:BaseButton=button("MUTE PLAYER FEEDBACK SOUNDS");var back:BaseButton=button("BACK")
    ck(reduce is CheckButton and mute is CheckButton and back!=null,"two distinct checkbox controls and BACK")
    ck(reduce.has_focus() and not reduce.button_pressed and not mute.button_pressed,"legacy initial focus preserved, new mute off")
    ck(g.ui.body.size.x<=g.ui.modal.size.x and g.ui.body.size.y<=g.ui.modal.size.y,"settings outer body fits viewport")
    ck(root.get_visible_rect().has_point(center(back)),"persistent BACK within viewport")
    var text:String=text_all()
    ck(text.contains("PRESENTATION SETTINGS") and text.contains("Only HP-loss and Mirror Shell block cues. Session only; no music."),"scope explicit")
    ck(text.contains("not saved to disk") and text.contains("ANIMATION COVERAGE"),"old persistence/coverage disclosure retained")
    ck(text.contains("Audio backend: Dummy") and text.contains("no physical device output"),"actual Dummy disclosure")
    var before:String=gameplay();reveal(mute);await process_frame;await process_frame
    ck(root.get_visible_rect().has_point(center(mute)),"mute reachable by actual scroll at full text size")
    click(mute);await process_frame;await process_frame
    ck(g.settings.mute_feedback_sounds and g.feedback_audio.muted and button("MUTE PLAYER FEEDBACK SOUNDS").button_pressed,"actual mouse GUI changes session mute")
    ck(gameplay()==before and events.is_empty(),"toggle has no gameplay effect or sound")
    # Synthetic ui_accept on the actual focused checkbox, not physical-controller certification.
    mute=button("MUTE PLAYER FEEDBACK SOUNDS");reveal(mute);mute.grab_focus();await process_frame
    var action:=InputEventAction.new();action.action="ui_accept";action.pressed=true;root.push_input(action,true)
    var release:=InputEventAction.new();release.action="ui_accept";release.pressed=false;root.push_input(release,true)
    await process_frame;await process_frame
    ck(not g.settings.mute_feedback_sounds and not g.feedback_audio.muted,"ui_accept actual focused mute control")
    ck(gameplay()==before and events.is_empty(),"unmute no replay/gameplay mutation")
    reduce=button("REDUCE DECORATIVE FLASHES");reveal(reduce);await process_frame;await process_frame;click(reduce);await process_frame;await process_frame
    ck(g.settings.reduced_flashes and g.vfx.reduced_flashes and g.actor_anim.reduced_flashes and not g.settings.mute_feedback_sounds,"legacy reduce flash actual control independent")
    var saved:Resource=g.feedback_audio.players.shield_block.stream;g.feedback_audio.install_stream("shield_block",null);before=gameplay();g.ui.show_settings(g._view());await process_frame;await process_frame
    ck(text_all().contains("Unavailable cues: shield_block. Gameplay remains active."),"single missing resource honestly named")
    ck(gameplay()==before and events.is_empty(),"status render neither repairs nor requests")
    ck(g.feedback_audio.players.shield_block.stream==null,"view cannot repair missing stream")
    g.feedback_audio.install_stream("shield_block",saved);g.ui.show_settings(g._view());await process_frame;await process_frame
    ck(not text_all().contains("Unavailable cues:"),"valid streams no false warning")
    samples.append({"mode":mode,"size":[size.x,size.y],"source":source,"mute_rect":str(button("MUTE PLAYER FEEDBACK SOUNDS").get_global_rect()),"back_rect":str(button("BACK").get_global_rect()),"backend":g.feedback_audio.status()})
    click(button("BACK"));await process_frame;await process_frame
    ck(g.state==source,"BACK correct actual route "+source)
    ck(events.is_empty(),"navigation never sound")
 var audio_teardown = preload("evidence-workspace/moss-v39-B-qa/packed-harness/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"samples":samples,"scope":"Actual GUI controls with synthetic mouse/ui_accept, title and paused routes, both modes at 960/1280. Not native hardware mouse, controller, WM focus, physical listening or audio mix proof."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
