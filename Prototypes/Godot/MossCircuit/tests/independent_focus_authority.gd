extends SceneTree
## Independent picking, input-guard and lifecycle expectations. Controlled source fixture.
const Focus=preload("res://scripts/gameplay/combat_focus.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func clean(v:Variant)->Variant:
 match typeof(v):
  TYPE_VECTOR2:return [v.x,v.y]
  TYPE_COLOR:return [v.r,v.g,v.b,v.a]
  TYPE_ARRAY:
   var a:Array=[]
   for x in v:a.append(clean(x))
   return a
  TYPE_DICTIONARY:
   var d:Dictionary={}
   for k in v:
    if str(k)!="sprite":d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<object>"
  TYPE_CALLABLE:return "<callable>"
  _:return v
func properties(o:Object)->Dictionary:
 var d:Dictionary={}
 for p in o.get_property_list():
  if (int(p.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE)!=0:d[p.name]=o.get(p.name)
 return clean(d)
func snap(ignore_focus:bool=false)->Dictionary:
 var world:Dictionary=properties(g.combat)
 if ignore_focus:world.erase("focus_enemy_id")
 return {"world":world,"session":properties(g.run),"effects":properties(g.effects),"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"choice_generation":g.choice_generation,"shop_generation":g.shop_generation,"effect_sequence":g.effect_sequence,"rig":clean({"slots":g.weapon_rig.slots,"clock":g.weapon_rig.visible_clock,"generation":g.weapon_rig.generation,"last":g.weapon_rig.last_shot}),"actor":properties(g.actor_anim),"vfx":properties(g.vfx)}
func enemy(id:Variant=1,pos:Variant=Vector2.ZERO,hp:Variant=10.0,scale_value:Variant=1.0)->Dictionary:return {"id":id,"pos":pos,"hp":hp,"scale":scale_value}
func vp(point:Vector2)->Vector2:return g.get_global_transform_with_canvas()*point
func setup(mode:String)->Dictionary:
 g._title();g._select_mode(mode);g._start_run(3401);g.spawn_clock=999;g.elapsed=10;g.weapon_clocks=[999.0];g.hurt_clock=0
 g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g.combat_frame.area=g.config.arena
 var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(80,50));e.hp=1000.0;e.anim_hp=1000.0;e.max_hp=1000.0;e.speed=0.0;e.cooldown_left=999.0
 g._sync_weapon_rig();g._update_hud();return e
func _initialize()->void:call_deferred("run")
func run()->void:
 # Pure disk arithmetic and strict schema; data not borrowed from production helper output.
 for scale_value in [.25,1.0,2.0,3.5]:
  var radius:float=16.0*scale_value+8.0;var e:Dictionary=enemy(7,Vector2.ZERO,10,scale_value)
  ck(Focus.pick([e],Vector2.ZERO)==7,"center picks scale"+str(scale_value))
  for axis in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
   ck(Focus.pick([e],axis*radius)==7,"closed exact axis edge")
   ck(Focus.pick([e],axis*(radius+.001))==0,"axis outside")
  for i in range(8):
   var direction:=Vector2.from_angle(float(i)*TAU/8)
   ck(Focus.pick([e],direction*(radius-.002))==7,"rotated inside")
   ck(Focus.pick([e],direction*(radius+.002))==0,"rotated outside")
 var a:Dictionary=enemy(9,Vector2(-5,0));var b:Dictionary=enemy(3,Vector2(5,0))
 ck(Focus.pick([a,b],Vector2.ZERO)==3 and Focus.pick([b,a],Vector2.ZERO)==3,"exact equal-distance lower ID independent of order")
 ck(Focus.pick([a,b],Vector2(-.001,0))==9,"no approximate distance tie merging")
 for id in [0,-1,1.0,true,"1",null,[],{}]:ck(Focus.pick([enemy(id)],Vector2.ZERO)==0,"reject actual ID type/bounds "+str(id))
 for hp in [0,-1,NAN,INF,-INF,true,"10",null,[],{}]:ck(Focus.pick([enemy(1,Vector2.ZERO,hp)],Vector2.ZERO)==0,"reject HP "+str(hp))
 for scale_value in [0,-1,NAN,INF,-INF,true,"1",null,[],{},1.0e200]:ck(Focus.pick([enemy(1,Vector2.ZERO,10,scale_value)],Vector2.ZERO)==0,"reject scale/overflow "+str(scale_value))
 for pos in [null,[],{},"0,0",0,Vector2(INF,0),Vector2(NAN,0),Vector2(1.0e30,0)]:ck(Focus.pick([enemy(1,pos)],Vector2.ZERO)==0,"reject malformed/overflow position "+str(pos))
 for point in [null,[],{},"0,0",0,true,Vector2(INF,0),Vector2(NAN,0)]:ck(Focus.pick([enemy()],point)==-1,"invalid point distinct from empty "+str(point))
 for bad in [null,[],"enemy",false,0,{}]:ck(Focus.pick([bad],Vector2.ZERO)==0,"invalid entry ignored")
 var original:Array=[a.duplicate(true),b.duplicate(true)];var old:Variant=original.duplicate(true)
 for _i in range(4):Focus.pick(original,Vector2.ZERO);Focus.find(original,3)
 ck(original==old,"pure helper no repair/reorder/mutation")
 for id in [0,-1,true,3.0,"3",null]:ck(Focus.find(original,id).is_empty(),"lookup strict ID guard")
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  var e:Dictionary=setup(mode);await process_frame;g.camera.force_update_scroll();g._update_hud()
  ck(g.combat.focus_enemy_id==0,"new run AUTO "+mode)
  var before:Dictionary=snap(true);ck(g._focus_click(vp(e.pos)),"valid controller mark "+mode);ck(g.combat.focus_enemy_id==e.id,"marked actual current ID");ck(snap(true)==before,"mark changes only focus authority")
  var stable:Dictionary=snap();ck(not g._focus_click(vp(e.pos)),"same ID idempotent false");ck(snap()==stable,"same ID entire authority unchanged")
  var detached:Dictionary=g._focus_view();detached.id=99999;detached.name="MUTATED";ck(snap()==stable,"focus view is detached")
  for blocked_state in ["title","shop","paused","inventory","upgrade","settings","codex","room_clear","dead","won","transition"]:
   g.state=blocked_state;stable=snap();ck(not g._focus_click(vp(e.pos)),"nonplaying guard "+blocked_state);ck(snap()==stable,"nonplaying rejection atomic "+blocked_state)
  g.state="playing";stable=snap();ck(not g._start_run(1,"invalid-kit"),"invalid start remains rejected");ck(snap()==stable,"invalid start does not clear valid focus")
  var valid:Vector2=vp(e.pos)
  for bad in [null,[],{},true,"x",0,Vector2(NAN,0),Vector2(INF,0),Vector2(-1,200),Vector2(200,-1),Vector2(100000,200)]:
   stable=snap();ck(not g._focus_click(bad),"bad viewport request rejected");ck(snap()==stable,"bad viewport atomic")
  var visible:Rect2=root.get_visible_rect()
  for point in [Vector2(visible.end.x,visible.size.y*.7),Vector2(visible.size.x*.5,visible.end.y)]:
   stable=snap();ck(not g._focus_click(point) and snap()==stable,"exact viewport right/bottom excluded")
  # Force a legal invertible camera outside the field only as a controlled coordinate fixture.
  var old_camera:Vector2=g.camera.position;g.camera.position=Vector2.ZERO;g.camera.force_update_scroll()
  stable=snap();ck(not g._focus_click(Vector2(visible.size.x*.25,visible.size.y*.75)) and snap()==stable,"visible viewport but negative world X rejected")
  g.camera.position=old_camera;g.camera.force_update_scroll()
  var old_transform:Transform2D=g.transform;g.scale=Vector2.ZERO;stable=snap();ck(not g._focus_click(valid),"singular canvas rejected");ck(snap()==stable,"singular canvas authority unchanged");g.transform=old_transform
  # Visible text/panels reject before they can become valid-empty clears.
  for control in [g.ui.hud,g.mode_status.objective]:
   var p:Vector2=control.get_global_transform_with_canvas()*(control.size*.5);stable=snap();ck(not g._focus_click(p),"visible UI region blocks selection");ck(snap()==stable,"HUD/text blocked request atomic")
  if mode=="rooms":
   var p:Vector2=g.mode_status.badge.get_global_transform_with_canvas()*Vector2(20,20);stable=snap();ck(not g._focus_click(p),"visible badge blocks");ck(snap()==stable,"badge no clear")
  var empty:Vector2=vp(g.player_pos+Vector2(-90,70));before=snap(true);ck(g._focus_click(empty),"valid empty clears");ck(g.combat.focus_enemy_id==0 and snap(true)==before,"clear only focus authority");stable=snap();ck(not g._focus_click(empty) and snap()==stable,"already AUTO idempotent")
  # Dead views display inactive without repairing authority; Runtime owns actual pruning.
  g.combat.focus_enemy_id=e.id;e.hp=0;stable=snap();ck(not g._focus_view().active and g._focus_status_text()=="","dead read-only view inactive");g._view();ck(snap()==stable,"read-only views never prune or mutate")
  Runtime.step(g.combat_frame,0.0);ck(g.combat.focus_enemy_id==0,"shared step prunes dead focus")
  e=setup(mode);g.combat.focus_enemy_id=e.id;g.enemies.erase(e);stable=snap();ck(not g._focus_view().active,"removed view inactive");ck(snap()==stable,"removed view pure");Runtime.step(g.combat_frame,0.0);ck(g.combat.focus_enemy_id==0,"shared step prunes removed focus")
  # Offscreen/out-of-range is still living; no automatic target reassignment.
  e=setup(mode);g.combat.focus_enemy_id=e.id;e.pos=g.player_pos+Vector2(10000,10000);g._focus_view();ck(g.combat.focus_enemy_id==e.id and g._focus_view().eligible==0,"living beyond all ranges persists")
  # Real modal transitions may retain their OLD effects.invalidate behavior; only focus retention claimed.
  e=setup(mode);g.combat.focus_enemy_id=e.id;g._on_intent("pause",{});ck(g.state=="paused" and g.combat.focus_enemy_id==e.id,"pause retains")
  for action in ["settings","codex"]:
   g._on_intent(action,{});stable=snap();ck(not g._focus_click(vp(e.pos)),"modal input rejected "+action);ck(snap()==stable,"modal click atomic");g._on_intent("close_"+action,{});ck(g.combat.focus_enemy_id==e.id and g.state=="paused","modal return retains "+action)
  g._on_intent("inventory",{});stable=snap();ck(not g._focus_click(vp(e.pos)) and snap()==stable,"inventory input rejected/pure");g._on_intent("close_inventory",{});g._on_intent("resume",{});ck(g.combat.focus_enemy_id==e.id and g.state=="playing","resume retains")
  g._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT);ck(g.state=="paused" and g.combat.focus_enemy_id==e.id,"application focus loss pauses/retains");stable=snap();ck(not g._focus_click(vp(e.pos)) and snap()==stable,"window-focus click cannot resume/select");g._on_intent("resume",{})
  g.upgrade_pending=1;g._show_upgrades();ck(g.state=="upgrade" and g.combat.focus_enemy_id==e.id,"upgrade retains");stable=snap();ck(not g._focus_click(vp(e.pos)) and snap()==stable,"upgrade click ignored");g._take_upgrade(0,g.choice_generation);ck(g.combat.focus_enemy_id==e.id,"resolved mid-encounter upgrade retains")
  # Independent per-copy count: four owned but one radial, short range fallback.
  g.build.weapons=["cryo_sprayer","rail_lance","orbit_saw","rail_lance"];g._recompute();e.pos=g.player_pos+Vector2(400,0)
  var view:Dictionary=g._focus_view();ck(view.active and view.eligible==2 and view.directional==3,"copy count excludes radial/short but counts duplicates");g.weapon_clocks=[999.0,999.0,999.0,999.0];ck(g._focus_view()==view,"count not cooldown readiness")
  g.build.weapons=["orbit_saw"];g._recompute();ck(g._focus_status_text().contains("radial aim unchanged"),"radial-only honest cue")
  for outcome in [false,true]:
   e=setup(mode);g.combat.focus_enemy_id=e.id;g._finish(outcome);ck(g.combat.focus_enemy_id==0,"terminal clears "+str(outcome))
   g._on_intent("retry" if not outcome else "new_seed",{});ck(g.combat.focus_enemy_id==0 and g.next_enemy_id==0,"retry/newseed cannot inherit reused IDs")
  e=setup(mode);g.combat.focus_enemy_id=e.id;g._title();ck(g.combat.focus_enemy_id==0,"title clears")
  e=setup(mode);g.combat.focus_enemy_id=e.id;g._start_run(99,"rail");ck(g.combat.focus_enemy_id==0,"direct new run clears")
  e=setup(mode);g.combat.focus_enemy_id=e.id;g._begin_room_clear();ck(g.combat.focus_enemy_id==0,"room-clear entry clears")
  e=setup(mode);g.combat.focus_enemy_id=e.id;g.wave_time=999;g.wave=1;g.enemies.clear()
  if mode=="rooms":g.mode.planned_index=g.mode.planned_count;g.mode.clear_elapsed=g.mode.profile.clear_delay
  g._complete_wave();ck(g.combat.focus_enemy_id==0 and g.wave==2,"actual successful settlement clears")
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled picking/schema/overflow, atomic main handlers and explicit focus lifecycle/read-only views. Native dispatch/coordinate proof is separate; no ordinary play or balance claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
