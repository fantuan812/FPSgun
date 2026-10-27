extends SceneTree
# External controlled geometry and steps. Not ordinary encounter/acquisition.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Teardown=preload("<WORKSPACE>/moss-v38-svg-qa/native-support/audio_teardown.gd")
var g
var index:=0
var stage:=-1
var ready_case:=false
var source:Dictionary={}
var target:Dictionary={}
var failures:Array=[]
var observations:Array=[]
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
 func _process(dt:float)->void:tick.call(dt)
func ck(ok:bool,label:String)->void:
 if not ok:failures.append(str(index)+"/"+str(stage)+": "+label)
func _initialize()->void:call_deferred("boot")
func boot()->void:
 root.title="Moss v38 CONTROLLED support: H step (7) / N next (4 cases) / F9 close"
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var driver:=Driver.new();driver.next=next_case;driver.step=step_once;driver.tick=tick;driver.close=finish;root.add_child(driver)
 await process_frame;show_case()
func next_case()->void:
 if ready_case and stage==6 and index<3:index+=1;show_case()
func show_case()->void:
 ready_case=false;stage=-1
 root.size=Vector2i(960,540) if index<2 else Vector2i(1280,720)
 await process_frame;await process_frame
 reset_geometry();ready_case=true;tick(0.)
 print(JSON.stringify({"controlled_case":index+1,"mode":g.mode.id,"window":[root.size.x,root.size.y],"reduced_flashes":g.settings.reduced_flashes,"scope":"Externally supplied source/recipient positions/HP/zero movement/disabled autonomous weapons; H runs real Runtime and real damage collision, not normal gameplay."}))
func reset_geometry()->void:
 g._title();g._select_mode("arena" if index%2==0 else "rooms");g._start_run(3807);g.set_process(false)
 g.settings.reduced_flashes=index>=2
 g.build.weapons=["rivet_gun"];g.build.items={};g._recompute();g.weapon_clocks.fill(999.);g.spawn_clock=999.;g.elapsed=10.;g.combat_frame.area=g.config.arena
 g.player_pos=Vector2(500,350);g.hero.position=g.player_pos;g.camera.position=g.player_pos;g.camera.force_update_scroll();g._sync_weapon_rig()
 source=g._spawn_kind("stitch_drone",Vector2(580,350));target=g._spawn_kind("crawler",Vector2(580,440));source.speed=0.;target.speed=0.;source.cooldown_left=0.;target.hp=50.;target.max_hp=100.;target.anim_hp=50.
 g.combat.focus_enemy_id=target.id
func bullet(damage:float)->Dictionary:
 return {"pos":source.pos,"velocity":Vector2.ZERO,"life":1.,"damage":damage,"pierce":0,"hit":[],"weapon":"rivet_gun","returning":false}
func step_once()->void:
 if not ready_case or stage>=6:return
 stage+=1
 match stage:
  0:
   Runtime.step(g.combat_frame,0.)
   ck(source.ai_state=="warning" and source.warning_left==1.2 and target.hp==50.,"fresh acquisition")
  1:
   Runtime.step(g.combat_frame,.6)
   ck(source.ai_state=="warning" and target.hp==50.,"half warning no early heal")
  2:
   Runtime.step(g.combat_frame,.6)
   ck(target.hp==60. and target.anim_hp==60. and source.ai_state=="recover","real heal10 and anim baseline")
   ck(g.effect_visuals.filter(func(v):return v.kind=="support_complete").size()==1,"single success marker")
  3:
   reset_geometry();Runtime.step(g.combat_frame,0.);Runtime.step(g.combat_frame,.6)
   ck(source.ai_state=="warning" and target.hp==50.,"second controlled channel")
  4:
   g.bullets=[bullet(1.)];Runtime.step(g.combat_frame,0.)
   ck(source.hp==33. and target.hp==50. and source.ai_state=="recover","actual bullet loss1 interrupts")
   ck(g.effect_visuals.filter(func(v):return v.kind=="support_cancel").size()==1,"single broken tether marker")
  5:
   reset_geometry();Runtime.step(g.combat_frame,0.);Runtime.step(g.combat_frame,.6)
   ck(source.ai_state=="warning" and target.hp==50.,"third controlled channel")
  6:
   g.bullets=[bullet(1000.)];Runtime.step(g.combat_frame,.6)
   ck(source.hp<=0 and not g.enemies.has(source) and target.hp==50.,"actual lethal projectile beats due repair")
   ck(g.effect_visuals.filter(func(v):return v.kind in ["support_complete","support_cancel"]).is_empty(),"source death no support burst")
   ck(source.support_channel_token==null and source.support_target_id==-1 and source.support_start_hp==0. and not source.support_due,"removed source ephemeral identity cleared")
 tick(0.)
 var row:Dictionary={"case":index+1,"stage":stage,"mode":g.mode.id,"source_hp":source.hp,"source_state":source.ai_state,"source_present":g.enemies.has(source),"recipient_hp":target.hp,"recipient_anim_hp":target.anim_hp,"warning_left":source.warning_left,"token_present":source.get("support_channel_token")!=null,"markers":g.telegraphs.markers.map(func(m):return m.kind),"support_visuals":g.effect_visuals.filter(func(v):return str(v.kind).begins_with("support_")),"failures":failures.duplicate()}
 observations.append(row);print(JSON.stringify({"controlled_step":row}))
func tick(dt:float)->void:
 if not ready_case or not is_instance_valid(g):return
 # Only existing actor presentation progresses continuously. World/HP/timers advance on H alone.
 g.actor_anim.reduced_flashes=g.settings.reduced_flashes;g.actor_anim.advance(minf(dt,.05));g._sync_telegraphs();g._update_hud();g.queue_redraw()
func finish()->void:
 ready_case=false
 ck(index==3 and stage==6 and observations.size()==28,"all four cases and seven real steps completed")
 print(JSON.stringify({"fixture_terminal":true,"cases_completed":index+1,"observations":observations.size(),"failures":failures,"scope":"Controlled4 combinations: Arena/Rooms at960 and1280; reduced flashes at1280. Animation only continuously advances; actual Runtime steps only H. SVG asset-only rerun: historical original-art ordinary remains separately scoped; no new ordinary run."}))
 var cleanup=Teardown.new();cleanup.prepare([g]);source={};target={};g.queue_free();await process_frame;await cleanup.finish(self)
 quit(0 if failures.is_empty() else 1)
