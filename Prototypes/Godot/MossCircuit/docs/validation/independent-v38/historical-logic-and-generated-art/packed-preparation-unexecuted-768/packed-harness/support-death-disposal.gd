extends SceneTree
# C3 requires death to clear ephemeral channel identity even when old death loop removes actor before B.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var checks:=0
var failures:Array=[]
var observations:Array=[]
var g
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  g._title();g._select_mode(mode);g._start_run(3810);g.elapsed=10.;g.spawn_clock=999.;g.weapon_clocks.fill(999.);g.combat_frame.area=g.config.arena;g.player_pos=Vector2(500,350);g.hero.position=g.player_pos
  var s:Dictionary=g._spawn_kind("stitch_drone",Vector2(580,350));var t:Dictionary=g._spawn_kind("crawler",Vector2(580,440));s.speed=0.;t.speed=0.;t.hp=50.;t.max_hp=100.;t.anim_hp=50.;s.cooldown_left=0.
  Runtime.step(g.combat_frame,0.)
  ck(s.ai_state=="warning" and s.support_channel_token is RefCounted,"real acquisition before lethal "+mode)
  g.bullets=[{"pos":s.pos,"velocity":Vector2.ZERO,"life":2.,"damage":1000.,"pierce":0,"hit":[],"weapon":"rivet_gun","returning":false}]
  Runtime.step(g.combat_frame,1.2)
  ck(s.hp<=0 and not g.enemies.has(s) and t.hp==50.,"actual lethal collision removes source without heal "+mode)
  ck(s.support_channel_token==null and s.support_target_id==-1 and s.support_start_hp==0. and not s.support_due and s.support_cancel_pending.is_empty(),"removed dead source ephemeral identity disposed "+mode)
  ck(g.effect_visuals.filter(func(v):return str(v.kind).begins_with("support_")).is_empty(),"death emits no repair/cancel burst "+mode)
  observations.append({"mode":mode,"source_removed":not g.enemies.has(s),"source_hp":s.hp,"target_hp":t.hp,"token_present":s.support_channel_token!=null,"target_id":s.support_target_id,"witness":s.support_start_hp,"due":s.support_due,"pending":s.support_cancel_pending})
 var cleanup=preload("<WORKSPACE>/moss-v38-qa/packed-harness/audio_teardown.gd").new();cleanup.prepare([g]);g.queue_free();await process_frame;await cleanup.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Two-mode actual late projectile source death and retained dictionary disposal. Separate supplemental C3 post-first static gap, original126/104/369/38 results unchanged."}))
 quit(0 if failures.is_empty() else 1)
