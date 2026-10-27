extends SceneTree
## EXTERNAL controlled stock/build/geometry. Not ordinary acquisition or full gameplay.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Reel=preload("res://scripts/gameplay/scavenger_reel.gd")
const Rules=preload("res://scripts/rules.gd")
const Teardown=preload("<QA_ROOT>/native-support/audio_teardown.gd")
var g
var index:=0
var ready_case:=false
var supplied:=false
var previous:=""
var steps:=0
class Driver extends Node:
 var next:Callable
 var step:Callable
 var tick:Callable
 var close:Callable
 func _input(event:InputEvent)->void:
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_N:next.call();get_viewport().set_input_as_handled()
   elif event.keycode==KEY_H:step.call();get_viewport().set_input_as_handled()
   elif event.keycode==KEY_F9:close.call();get_viewport().set_input_as_handled()
 func _process(_dt:float)->void:tick.call()
func _initialize()->void:call_deferred("boot")
func boot()->void:
 root.title="Moss v36 CONTROLLED Reel / buy+deploy / H step N next F9 close"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var driver:=Driver.new();driver.next=advance;driver.step=step_once;driver.tick=tick;driver.close=finish;root.add_child(driver)
 await process_frame;show_case()
func advance()->void:
 if ready_case and index<3:index+=1;show_case()
func show_case()->void:
 ready_case=false;supplied=false;previous="";steps=0
 var mode:String="arena" if index%2==0 else "rooms"
 root.size=Vector2i(960,540) if index<2 else Vector2i(1280,720)
 await process_frame;await process_frame
 g._title();g._select_mode(mode);g._start_run(3606);g.set_process(false);g.build.weapons=["return_disc"];g.build.items={};g._recompute();g.weapon_clocks=[999.];g.spawn_clock=999.;g.build.coins=100
 g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g._sync_weapon_rig();g._open_shop()
 var stock:Dictionary=Rules.catalog_entry(g.catalog,"scavenger_reel").duplicate(true);stock.sold=false;g.shop_offers=[stock];g._render_shop()
 await process_frame;await process_frame;ready_case=true;tick()
 print(JSON.stringify({"fixture":"Controlled Return Disc ownership/100scrap/supplied Reel offer; no ordinary acquisition","case":index+1,"mode":mode,"window":[root.size.x,root.size.y],"action":"Use actual UI buy then deploy. H advances controlled .25s only when playing; N next bounded case; F9 external close."}))
func provide_geometry()->void:
 supplied=true;g.stats.pickup_radius=0.;g.stats.bullet_speed=100.;g.elapsed=10.;g.combat_frame.area=g.config.arena;g.pickups=[]
 for row in [[Vector2(100,0),"normal"],[Vector2(70,0),"energy"],[Vector2(40,0),"normal"],[Vector2(90,12),"medical"]]:
  g.pickups.append({"pos":g.player_pos+row[0],"xp":0 if row[1]=="medical" else 1,"coins":0 if row[1]=="medical" else 1,"heal":8. if row[1]=="medical" else 0.,"source":row[1]})
 g.bullets=[{"pos":g.player_pos+Vector2(125,0),"velocity":Vector2.LEFT*100,"life":2.,"damage":1.,"pierce":99,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.,"scavenger":Reel.snapshot(g.build,g.catalog)}]
 print(JSON.stringify({"controlled_geometry_supplied":true,"case":index+1,"quota":g.bullets[0].scavenger.remaining,"pickup_sources":["normal","energy","normal","medical"],"scope":"Synthetic visible returning disc/positions use actual launch-profile snapshot; actual Runtime pickup authority on H, not ordinary flight."}))
func step_once()->void:
 if not ready_case or not supplied or g.state!="playing" or steps>=3:return
 Runtime.step(g.combat_frame,.25);steps+=1;tick()
 print(JSON.stringify({"controlled_runtime_step":steps,"case":index+1,"dt":.25,"xp":g.xp,"coins":g.build.coins,"remaining":g.bullets[0].scavenger.remaining if not g.bullets.is_empty() else null,"floor_sources":g.pickups.map(func(p):return p.get("source","normal"))}))
func tick()->void:
 if not ready_case or not is_instance_valid(g):return
 if not supplied and g.state=="playing" and g.build.items.get("scavenger_reel",0)==1:provide_geometry()
 g._update_hud();g.queue_redraw()
 var state:Dictionary={"case":index+1,"mode":g.mode.id,"state":g.state,"coins":g.build.coins,"xp":g.xp,"items":g.build.items,"settings":g.settings,"steps":steps,"quota":g.bullets[0].scavenger.remaining if supplied and not g.bullets.is_empty() else null,"floor":g.pickups.size()}
 var current:=JSON.stringify(state)
 if current!=previous:print(JSON.stringify({"observed":state}));previous=current
func finish()->void:
 ready_case=false;print(JSON.stringify({"fixture_terminal":true,"case":index+1,"steps":steps,"state":g.state}))
 var observer=Teardown.new();observer.prepare([g]);g.queue_free();await process_frame;await observer.finish(self);quit(0)
