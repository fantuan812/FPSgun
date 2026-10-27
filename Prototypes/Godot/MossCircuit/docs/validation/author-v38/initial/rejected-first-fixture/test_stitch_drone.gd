extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Support=preload("res://scripts/gameplay/enemy_support.gd")
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 g._start_run(3803);g.spawn_clock=999.;g.weapon_clocks.fill(999.)
 var source:Dictionary=g._spawn_kind("stitch_drone",Vector2(100,100))
 var target:Dictionary=g._spawn_kind("crawler",Vector2(150,100))
 source.speed=0.;target.speed=0.;source.cooldown_left=0.;target.hp=5.;target.anim_hp=5.
 ck(source.support_max_alive is int and source.support_max_alive==1,"JSON integral cap becomes actual int")
 ck(source.sprite.sprite_frames.get_frame_count("walk")==9,"authored nine-frame source sheet")
 for id in ["stitch_drone_channel","stitch_drone_hurt","stitch_drone_death"]:
  ck(g.actor_anim.assets.has(id) and g.actor_anim.assets[id].frames.get_frame_count("action")==9,"authored action present "+id)
 Runtime.step(g.combat_frame,0.)
 ck(source.ai_state=="warning" and source.warning_left==1.2,"post-movement acquisition owns fresh span")
 ck(source.support_target_id==target.id and source.support_channel_token is RefCounted,"identity-bound channel")
 g._sync_telegraphs()
 ck(g.telegraphs.markers.filter(func(m):return m.kind=="support_tether").size()==1,"one authoritative tether")
 Runtime.step(g.combat_frame,1.2)
 ck(target.hp==15. and target.anim_hp==15.,"actual runtime repairs ten and reconciles hurt baseline")
 ck(source.ai_state=="recover" and source.cooldown_left==5. and source.support_channel_token==null,"one completion resets lifecycle")
 ck(g.effect_visuals.filter(func(v):return v.kind=="support_complete").size()==1,"success visual is authority-derived")
 var hp:float=target.hp;Runtime.step(g.combat_frame,0.)
 ck(target.hp==hp,"no duplicate repair after completion")
 source.ai_state="move";source.cooldown_left=0.;Runtime.step(g.combat_frame,0.)
 source.hp-=1.;Runtime.step(g.combat_frame,0.)
 ck(source.ai_state=="recover" and target.hp==hp,"actual loss cancels without heal")
 ck(g.effect_visuals.filter(func(v):return v.kind=="support_cancel").size()==1,"one cancellation visual")
 g._sync_telegraphs();ck(g.telegraphs.markers.filter(func(m):return m.kind=="support_tether").is_empty(),"cancel drops live tether")
 source.ai_state="move";source.cooldown_left=0.;Runtime.step(g.combat_frame,0.)
 var before:Dictionary=source.duplicate(true);g.state="paused";Runtime.step(g.combat_frame,.2)
 ck(source==before,"paused direct step preserves channel")
 g.state="dead";Runtime.step(g.combat_frame,.2)
 ck(source.support_channel_token==null and target.hp==hp,"terminal direct step never repairs")
 g._sync_telegraphs();ck(g.telegraphs.markers.filter(func(m):return m.kind.begins_with("support_")).is_empty(),"terminal hides all support markers")
 var cleanup=preload("res://tests/support/audio_teardown.gd").new();cleanup.prepare([g]);g.queue_free();await process_frame;await cleanup.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Author smoke of actual support lifecycle and authored atlas presence; independent policy/path/native gates separate."}))
 quit(0 if failures.is_empty() else 1)
