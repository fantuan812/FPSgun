extends SceneTree
## EXTERNAL CONTROLLED native settings fixture. No ordinary acquisition/audio-listening claim.
var g
var index:=0
var ready_case:=false
var previous:=""
var hit_count:=0
class Driver extends Node:
 var next:Callable
 var hit:Callable
 var tick:Callable
 var close:Callable
 var focus:Callable
 func _notification(what:int)->void:
  if what in [MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN,MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT] and focus.is_valid():focus.call(what)
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_N:next.call();get_viewport().set_input_as_handled()
   elif event.keycode==KEY_H:hit.call();get_viewport().set_input_as_handled()
   elif event.keycode==KEY_F9:close.call();get_viewport().set_input_as_handled()
 func _process(_dt:float)->void:tick.call()
func _initialize()->void:call_deferred("boot")
func boot()->void:
 root.title="Moss v35 CONTROLLED feedback settings / N next H hit F9 close"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g.feedback_audio.cue_requested.connect(func(cue:String,accepted:bool):print(JSON.stringify({"resolved_cue":cue,"accepted":accepted,"case":index+1,"state":g.state,"hp":g.stats.hp,"shield":g.effects.shield,"driver":g.feedback_audio.status()})))
 var d:=Driver.new();d.next=advance;d.hit=hit;d.tick=tick;d.close=finish;d.focus=focus_event;root.add_child(d)
 await process_frame;show_case()
func advance()->void:
 if ready_case and index<3:index+=1;show_case()
func hit()->void:
 if not ready_case or g.state!="playing":return
 # Explicit controlled collision surrogate; real shared _hurt authority, not ordinary enemy contact.
 g.hurt_clock=0;hit_count+=1;g._hurt(11);g._update_hud()
 print(JSON.stringify({"fixture_hit":hit_count,"case":index+1,"controlled_reset_hurt_clock":true,"hp":g.stats.hp,"shield":g.effects.shield}))
func show_case()->void:
 ready_case=false;previous="";hit_count=0
 var mode:String="arena" if index%2==0 else "rooms"
 root.size=Vector2i(960,540) if index<2 else Vector2i(1280,720)
 await process_frame;await process_frame
 g._title();g._select_mode(mode);g._start_run(3504);g.set_process(false);g.build.items={"mirror_shell":1};g._recompute();g.effects.reset(g.build.items);g.weapon_clocks=[999.];g.spawn_clock=999
 g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g._sync_weapon_rig();g._update_hud()
 if index==0:g._title()
 await process_frame;await process_frame;await process_frame
 ready_case=true;tick()
 print(JSON.stringify({"fixture":"EXTERNAL CONTROLLED exact source; Mirror ownership/HP/timers supplied, not ordinary; no physical listening","case":index+1,"mode":mode,"window":[root.size.x,root.size.y],"state":g.state,"settings":g.settings,"N":"next controlled case","H":"reset hurt clock and actual _hurt(11), playing only","F9":"clean external fixture exit"}))
func voice_state()->Dictionary:
 var result:Dictionary={}
 if is_instance_valid(g):
  for cue in g.feedback_audio.players:result[cue]=g.feedback_audio.players[cue].playing
 return result
func focus_event(what:int)->void:
 if ready_case and is_instance_valid(g):print(JSON.stringify({"external_focus_notification":what,"case":index+1,"state":g.state,"playing":voice_state(),"ticks_us":Time.get_ticks_usec()}))
func tick()->void:
 if not ready_case or not is_instance_valid(g):return
 g._update_hud();g.queue_redraw()
 var stamp:String=JSON.stringify({"case":index+1,"state":g.state,"hp":g.stats.hp,"shield":g.effects.shield,"settings":g.settings,"feedback_audio":g.feedback_audio.status(),"playing":voice_state()})
 if stamp!=previous:print(JSON.stringify({"observed":JSON.parse_string(stamp),"ticks_us":Time.get_ticks_usec()}));previous=stamp
func finish()->void:
 print(JSON.stringify({"fixture_terminal":true,"case":index+1,"state":g.state,"settings":g.settings}));g.queue_free();await process_frame;await create_timer(.25).timeout;quit(0)
