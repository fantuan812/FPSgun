extends SceneTree
## Synthetic Viewport mouse dispatch through GUI + unhandled input, not physical-mouse proof.
const Field=preload("res://scripts/gameplay/field_layout.gd")
var g
var checks:=0
var failures:Array=[]
var samples:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func nodes(n:Node)->Array:
 var a:Array=[n]
 for c in n.get_children():a.append_array(nodes(c))
 return a
func button(prefix:String)->Button:
 for n in nodes(g.ui.root):
  if n is Button and n.is_visible_in_tree() and n.text.begins_with(prefix):return n
 return null
func center(c:Control)->Vector2:return c.get_global_transform_with_canvas()*(c.size*.5)
func vp(p:Vector2)->Vector2:return g.get_global_transform_with_canvas()*p
func mouse(point:Vector2,pressed:bool=true,which:MouseButton=MOUSE_BUTTON_LEFT)->void:
 var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=which;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed and which==MOUSE_BUTTON_LEFT else 0
 # true means viewport coordinates, avoiding a second embedder/stretch conversion.
 root.push_input(e,true)
func click(point:Vector2)->void:mouse(point,true);mouse(point,false)
func spawn(point:Vector2,kind:String="crawler")->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,point);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0;e.cooldown_left=999;return e
func prepare(mode:String,edge:bool)->void:
 g._title();g._select_mode(mode);g._start_run(3403);g.build.weapons=["cryo_sprayer","rail_lance","orbit_saw","rail_lance"];g._recompute();g.weapon_clocks=[999.0,999.0,999.0,999.0];g.spawn_clock=999
 g.player_pos=Vector2(80,g.config.arena.height-80) if edge else Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.hero.position=g.player_pos;g.camera.position=Field.camera_position(g.player_pos,g.config.arena);g.camera.force_update_scroll();g._sync_weapon_rig();g._update_hud()
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1180,812)]:
   root.size=size;await process_frame;await process_frame
   for edge in [false,true]:
    prepare(mode,edge);await process_frame;await process_frame;g.camera.force_update_scroll();g._update_hud()
    var visible:Rect2=root.get_visible_rect()
    # Place test actors in actual clear viewport coordinates; inverse checked independently below.
    var pa:=Vector2(visible.size.x*.56,visible.size.y*.61);var pb:=Vector2(visible.size.x*.76,visible.size.y*.75)
    var a:Dictionary=spawn(g.make_canvas_position_local(pa));var b:Dictionary=spawn(g.make_canvas_position_local(pb));g._update_hud()
    ck(vp(a.pos).distance_to(pa)<.001 and vp(b.pos).distance_to(pb)<.001,"current camera forward/inverse consistency")
    click(pa);ck(g.combat.focus_enemy_id==a.id,"GUI dispatch LMB selects current actor "+mode+str(size)+str(edge))
    var rngs:Array=[g.rng.state,g.loot_rng.state,g.shop_rng.state];var clocks:Array=g.weapon_clocks.duplicate();var revision:int=g.build.revision
    mouse(pb,false);ck(g.combat.focus_enemy_id==a.id,"release elsewhere cannot select")
    mouse(pb,true,MOUSE_BUTTON_RIGHT);mouse(pb,false,MOUSE_BUTTON_RIGHT);ck(g.combat.focus_enemy_id==a.id,"right button ignored")
    var drag:=InputEventMouseMotion.new();drag.position=pb;drag.global_position=pb;drag.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(drag,true);ck(g.combat.focus_enemy_id==a.id,"held drag not selection")
    click(pb);ck(g.combat.focus_enemy_id==b.id,"later actual dispatch changes mark")
    ck(rngs==[g.rng.state,g.loot_rng.state,g.shop_rng.state] and clocks==g.weapon_clocks and revision==g.build.revision,"mouse targeting no RNG/clock/build revision")
    # Explicit IGNORE-label guards: actor behind each visible rectangle must not be selected.
    for control in [g.ui.hud_title,g.ui.hud_detail,g.ui.hp,g.ui.xp,g.mode_status.objective]:
     var at:Vector2=center(control);a.pos=g.make_canvas_position_local(at);click(at);ck(g.combat.focus_enemy_id==b.id,"visible text/bar/objective doesn't leak "+control.get_class())
    if mode=="rooms":
     var at:Vector2=g.mode_status.badge.get_global_transform_with_canvas()*Vector2(20,20);a.pos=g.make_canvas_position_local(at);click(at);ck(g.combat.focus_enemy_id==b.id,"Rooms badge no passthrough")
    var boss:Dictionary=spawn(g.player_pos+Vector2(200,0),"boss_warden");g._update_hud();await process_frame;await process_frame
    ck(g.ui.boss_panel.is_visible_in_tree(),"actual boss rectangle visible")
    var at:Vector2=center(g.ui.boss_panel);a.pos=g.make_canvas_position_local(at);click(at);ck(g.combat.focus_enemy_id==b.id,"boss panel IGNORE cannot select behind")
    boss.hp=0;g._update_hud();await process_frame
    # Actual buttons consume input; modal closing release must not pass through.
    var build_button:Button=button("BUILD")
    ck(build_button!=null,"BUILD actual button exists")
    if build_button!=null:
     at=center(build_button);a.pos=g.make_canvas_position_local(at);click(at);await process_frame;await process_frame
     ck(g.state=="inventory" and g.combat.focus_enemy_id==b.id,"BUILD invokes inventory, not mark")
     var back:Button=button("BACK");ck(back!=null,"inventory BACK visible")
     if back!=null:click(center(back));await process_frame;await process_frame;ck(g.state=="playing" and g.combat.focus_enemy_id==b.id,"inventory closing click no selection leak")
    var pause_button:Button=button("PAUSE");ck(pause_button!=null,"PAUSE actual button exists")
    if pause_button!=null:
     click(center(pause_button));await process_frame;await process_frame;ck(g.state=="paused" and g.combat.focus_enemy_id==b.id,"PAUSE button retains focus")
     var resume:Button=button("RESUME");ck(resume!=null,"RESUME actual button exists")
     if resume!=null:
      at=center(resume);a.pos=g.make_canvas_position_local(at);click(at);await process_frame;await process_frame;ck(g.state=="playing" and g.combat.focus_enemy_id==b.id,"resume release cannot hit enemy behind modal")
    # Empty-space AUTO, then no-focus exact objective first line.
    a.pos=g.make_canvas_position_local(pa);b.pos=g.make_canvas_position_local(pb)
    var empty:=Vector2(visible.size.x*.44,visible.size.y*.78);click(empty);ck(g.combat.focus_enemy_id==0,"valid viewport empty clears")
    g._update_hud();var original:String=g.mode.objective(g.run,g.combat,g.config);ck(g.mode_status.objective.text==original,"AUTO objective exact old text")
    click(pb);g._update_hud();ck(g.mode_status.objective.text.begins_with(original+"\n"),"priority appends below original objective only")
    ck(g.mode_status.objective.text.contains("PRIORITY") and g.mode_status.objective.text.contains("AUTO"),"visible target/reset caption")
    ck(g.mode_status.objective.size.y==42,"existing objective region height preserved")
    # UI bounds do not transform by the gameplay camera; old HUD remains placed identically.
    ck(g.ui.hud.get_global_rect().position.x>=0 and g.ui.hud.get_global_rect().end.x<=visible.end.x+.1,"HUD within viewport width")
    samples.append({"mode":mode,"window":[size.x,size.y],"visible":[visible.size.x,visible.size.y],"edge":edge,"focus":g.combat.focus_enemy_id,"objective":g.mode_status.objective.text,"transform":str(g.get_global_transform_with_canvas())})
    await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"samples":samples,"scope":"Synthetic viewport-local mouse events dispatched through real GUI then unhandled input; actual controls/camera and both modes at three window sizes. Physical mouse and letterbox host coordinates require separate native proof."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
