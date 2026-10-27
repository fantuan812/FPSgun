extends SceneTree
## EXTERNAL CONTROLLED exact-pack setup. Mouse marks use the unmodified game input path.
## F9 only exits this external test harness normally; it is not a shipped game control.
const Field=preload("res://scripts/gameplay/field_layout.gd")
var g
var index:=0
var ready_case:=false
var previous:=""
var named:Dictionary={}
class Driver extends Node:
 var next:Callable
 var tick:Callable
 var observe:Callable
 var close:Callable
 var relocate:Callable
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
   close.call();get_viewport().set_input_as_handled()
  elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
   relocate.call();get_viewport().set_input_as_handled()
  elif event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
   next.call();get_viewport().set_input_as_handled()
  elif event is InputEventMouseButton:observe.call(event)
 func _process(_dt:float)->void:tick.call()
func _initialize()->void:call_deferred("boot")
func boot()->void:
 root.title="Moss v34 CONTROLLED focus / N next case"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var d:=Driver.new();d.next=advance;d.tick=tick;d.observe=observe;d.relocate=relocate;d.close=close_fixture;root.add_child(d)
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():index=clampi(int(args[0]),0,7)
 await process_frame;show_case()
func close_fixture()->void:quit(0)
func advance()->void:
 if ready_case:index=(index+1)%8;show_case()
func observe(event:InputEventMouseButton)->void:
 if not ready_case:return
 print(JSON.stringify({"input":"actual native delivered mouse","case":index+1,"button":event.button_index,"pressed":event.pressed,"viewport":[event.position.x,event.position.y],"prior_state":g.state,"prior_focus":g.combat.focus_enemy_id}))
func spawn(id:String,offset:Vector2,label:String)->Dictionary:
 var e:Dictionary=g._spawn_kind(id,g.player_pos+offset);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0;e.cooldown_left=999;named[label]=e.id;return e
func show_case()->void:
 ready_case=false;named.clear();previous=""
 var mode:String="arena" if index%2==0 else "rooms"
 root.size=([Vector2i(960,540),Vector2i(1280,720),Vector2i(1180,812)][index/2] if index<6 else (Vector2i(960,540) if index==6 else Vector2i(1180,812)))
 await process_frame;await process_frame
 g._title();g._select_mode(mode);g._start_run(3404);g.set_process(false)
 g.build.weapons=["cryo_sprayer","rail_lance","orbit_saw","bankshot_driver"];g.build.weapon_temper=[0,1,0,0];g._recompute();g.weapon_clocks=[999.0,999.0,999.0,999.0];g.spawn_clock=999
 g.player_pos=Vector2(80,g.config.arena.height-80) if index%2 else Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.hero.position=g.player_pos;g.camera.position=Field.camera_position(g.player_pos,g.config.arena);g.camera.force_update_scroll()
 if index%2:
  spawn("crawler",Vector2(60,-40),"near")
  spawn("spitter",Vector2(210,-100),"far")
  var ram:Dictionary=spawn("charger",Vector2(360,-180),"brace");ram.ai_state="warning";ram.attack="charge";ram.aim=(g.player_pos-ram.pos).normalized();ram.warning_left=.6
  spawn("boss_warden",Vector2(560,-120),"boss")
 else:
  spawn("crawler",Vector2(-70,60),"near")
  spawn("spitter",Vector2(210,50),"far")
  var ram:Dictionary=spawn("charger",Vector2(50,180),"brace");ram.ai_state="warning";ram.attack="charge";ram.aim=(g.player_pos-ram.pos).normalized();ram.warning_left=.6
  spawn("boss_warden",Vector2(270,-60),"boss")
 if index>=6:
  for e in g.enemies:
   if e.id==named.far:e.pos=g.make_canvas_position_local(Vector2(955,320))
 for e in g.enemies:e.sprite.position=e.pos;g.actor_anim.observe_enemy(e,"move",g.player_pos)
 g.settings.reduced_flashes=index>=4;g.actor_anim.reduced_flashes=g.settings.reduced_flashes;g.vfx.reduced_flashes=g.settings.reduced_flashes
 g._sync_weapon_rig();g._update_hud();g._sync_telegraphs();g.queue_redraw()
 await process_frame;await process_frame;await process_frame
 ready_case=true;tick()
 var actors:Array=[]
 for e in g.enemies:
  var p:Vector2=g.get_global_transform_with_canvas()*e.pos
  actors.append({"id":e.id,"name":e.name,"world":[e.pos.x,e.pos.y],"viewport":[p.x,p.y]})
 print(JSON.stringify({"fixture":"EXTERNAL CONTROLLED; no automatic combat/no ordinary state","case":index+1,"mode":mode,"window":[root.size.x,root.size.y],"viewport":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],"camera_edge":index%2==1,"reduced":g.settings.reduced_flashes,"actors":actors,"named":named,"N":"next injected case"}))
func relocate()->void:
 if not ready_case or index<6:return
 for e in g.enemies:
  if e.id==g.combat.focus_enemy_id:
   e.pos=(Vector2(e.pos.x,40) if index%2 else e.pos+Vector2(120,0)).clamp(Vector2(20,20),Vector2(g.config.arena.width-20,g.config.arena.height-20));e.sprite.position=e.pos
   print(JSON.stringify({"fixture_action":"F8 external controlled actor relocation, not gameplay movement","case":index+1,"id":e.id,"world":str(e.pos),"viewport":str(g.get_global_transform_with_canvas()*e.pos)}))
func tick()->void:
 if not ready_case or not is_instance_valid(g):return
 g._sync_weapon_rig();g._update_hud();g._sync_telegraphs();g.queue_redraw()
 var stamp:String=JSON.stringify({"case":index+1,"state":g.state,"focus":g._focus_view(),"stored_id":g.combat.focus_enemy_id,"objective":g.mode_status.objective.text})
 if stamp!=previous:print(stamp);previous=stamp
