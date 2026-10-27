extends SceneTree
# Independent runtime phase/HP-path oracle. C3 late-event injection is explicitly NOT a production proc.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
const Support=preload("res://scripts/gameplay/enemy_support.gd")
class InjectedLateDamage:
 extends "res://scripts/effects.gd"
 var trigger_kind:String=""
 var victim_id:int=-1
 var injected_count:int=0
 func process(event:Dictionary,context:Dictionary)->Array:
  var commands:Array=super.process(event,context)
  if str(event.kind)==trigger_kind and injected_count==0:
   injected_count+=1
   commands.append({"kind":"chain","targets":[victim_id],"damage":1000.,"pos":context.pos})
  return commands
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func setup(mode:String,items:Dictionary={},weapons:Array=["rivet_gun"])->Array:
 g._title();g._select_mode(mode);g._start_run(3801)
 g.build.weapons=weapons.duplicate(true);g.build.items=items.duplicate(true);g._recompute();g.effects.reset(g.build.items);g.effect_runtime.engine=g.effects
 g.elapsed=10.;g.spawn_clock=999.;g.weapon_clocks.fill(999.);g.player_pos=Vector2(500,350);g.hero.position=g.player_pos;g.stats.hp=100.;g.stats.dash_time=0.;g.hurt_clock=0.;g.combat_frame.area=g.config.arena
 var source:Dictionary=g._spawn_kind("stitch_drone",Vector2(580,350));var target:Dictionary=g._spawn_kind("crawler",Vector2(580,440))
 source.speed=0.;target.speed=0.;target.hp=50.;target.max_hp=100.;target.anim_hp=50.
 return [source,target]
func arm(source:Dictionary,target:Dictionary,left:float=0.0)->void:
 source.ai_state="warning";source.support_target_id=target.id;source.support_start_hp=source.hp;source.support_due=false;source.warning_left=left;source.support_target_pos=target.pos;source.support_channel_token=RefCounted.new();source.support_cancel_pending={}
func shot(point:Vector2,damage:float=1.0,weapon:String="rivet_gun")->Dictionary:
 return {"pos":point,"velocity":Vector2.ZERO,"life":1.,"damage":damage,"pierce":0,"hit":[],"weapon":weapon,"returning":false}
func emit_hit(target:Dictionary,damage:float=10.,weapon:String="rivet_gun")->void:
 g.effect_runtime.emit_event("hit",{"target":target.id,"pos":target.pos,"damage":damage,"weapon":weapon})
func apply_path(name:String,source:Dictionary,target:Dictionary)->void:
 match name:
  "orbit":g.weapon_combat.fire("orbit_saw",0,g.config.arena)
  "cone":g.weapon_combat.fire("cryo_sprayer",0,g.config.arena)
  "segment":g.weapon_combat.hit_segment(shot(source.pos),source.pos,source.pos)
  "bankshot":g.weapon_combat._bankshot_hit(source,{"damage":1.,"pos":source.pos,"dx":1.,"dy":0.,"weapon":"bankshot_driver"})
  "feedback":
   g.stats.dash_time=.3;g.effects.feedback_armed=true
   g.effect_runtime.emit_event("projectile_contact",{"owner":source.id,"source":"hostile_projectile","depth":0})
  "fracture":
   source.chill_until=11.;source.chill_weapon="cryo_sprayer";source.chill_speed=.65;emit_hit(source)
  "chain":emit_hit(target)
  "echo":g.effects.echo_hits=4;emit_hit(source)
  "phase":g.effects.phase_charge=1;emit_hit(source)
  "thorns":g.effect_runtime.emit_event("hurt",{"amount":1.,"pos":g.player_pos})
  "mine":
   g.effect_runtime.emit_event("pickup",{"source":"normal","pos":source.pos});g.effect_runtime.advance_hazards(.3)
  "scorch":
   g.effect_runtime.emit_event("mortar",{"pos":source.pos});g.effect_runtime.advance_hazards(0.)
  "trail":
   g.effect_runtime.emit_event("dash",{"pos":source.pos});g.effect_runtime.advance_hazards(0.)
  "mortar":
   g.pending_blasts=[{"pos":source.pos,"delay":0.,"damage":1.,"radius":20.,"weapon":"shock_mortar"}];g.effect_runtime.advance_mortars(0.)
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var paths:Array=[
  ["orbit",{},["orbit_saw"]],["cone",{},["cryo_sprayer"]],["segment",{},["rivet_gun"]],["bankshot",{},["rivet_gun"]],
  ["feedback",{"feedback_diode":1},["rivet_gun"]],["fracture",{"fracture_coil":1},["rivet_gun"]],["chain",{"arc_relay":1},["rivet_gun"]],
  ["echo",{"echo_chamber":1},["rivet_gun"]],["phase",{"phase_capacitor":1},["rivet_gun"]],["thorns",{"thorn_crown":1},["rivet_gun"]],
  ["mine",{"scrap_mine":1},["rivet_gun"]],["scorch",{"blast_fuse":1},["rivet_gun"]],["trail",{"dash_resin":1},["rivet_gun"]],["mortar",{},["rivet_gun"]]]
 for mode in ["arena","rooms"]:
  for spec in paths:
   var pair:Array=setup(mode,spec[1],spec[2]);var s:Dictionary=pair[0];var t:Dictionary=pair[1];arm(s,t)
   var hp:float=s.hp;apply_path(spec[0],s,t)
   ck(s.hp>0 and s.hp<hp,"actual existing HP write "+mode+"/"+spec[0])
   var before:float=t.hp;Runtime.step(g.combat_frame,0.)
   ck(t.hp==before and s.ai_state=="recover" and s.support_channel_token==null,"real runtime cancels ongoing channel after "+spec[0])
   observations.append({"class":"existing_damage_path","mode":mode,"path":spec[0],"source_loss":hp-s.hp,"target_unchanged_by_support":t.hp==before})
  # Exact full-runtime phase placement: early primary vs late projectiles.
  var pair:Array=setup(mode,{},["orbit_saw"]);var s:Dictionary=pair[0];var t:Dictionary=pair[1]
  s.cooldown_left=0.;g.weapon_clocks[0]=0.;Runtime.step(g.combat_frame,0.)
  ck(s.hp<34 and s.ai_state=="warning" and s.support_start_hp==s.hp,"early primary before acquisition is new snapshot")
  ck(t.hp==50 and s.warning_left==1.2,"same-step acquisition neither retroactive cancel nor immediateheal")
  pair=setup(mode);s=pair[0];t=pair[1];arm(s,t);g.bullets=[shot(s.pos,1.)];Runtime.step(g.combat_frame,0.)
  ck(s.hp==33 and t.hp==50 and s.ai_state=="recover","due source late projectile hit beatsrepair")
  pair=setup(mode);s=pair[0];t=pair[1];arm(s,t);g.bullets=[shot(t.pos,1000.)];Runtime.step(g.combat_frame,0.)
  ck(t.hp<=0 and not g.enemies.has(t),"due target primarydeath neverresurrects")
  pair=setup(mode,{"feedback_diode":1});s=pair[0];t=pair[1];arm(s,t);g.stats.dash_time=.3;g.effects.feedback_armed=true
  g.enemy_bullets=[{"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.,"damage":1.,"owner":s.id}];Runtime.step(g.combat_frame,0.)
  ck(s.hp<34 and t.hp==50 and s.ai_state=="recover","actual hostile contact feedback afterA beats dueheal")
  pair=setup(mode);s=pair[0];t=pair[1];arm(s,t);g.bullets=[shot(s.pos,0.)];Runtime.step(g.combat_frame,0.)
  ck(s.hp==34 and t.hp==60,"zero resolved primary doesnot interrupt")
  pair=setup(mode);s=pair[0];t=pair[1];arm(s,t);s.chill_until=12.;s.chill_weapon="cryo_sprayer";s.chill_speed=.65;Runtime.step(g.combat_frame,0.)
  ck(t.hp==60,"chill-only doesnot interrupt")
  ck(t.anim_hp==60,"lateheal synchronizes next hurt baseline")
  g.bullets=[shot(t.pos,1.)];Runtime.step(g.combat_frame,0.)
  ck(t.hp==59 and t.anim_hp==59,"next small hit retains exact updated HP baseline")
  # No natural kill/pickup immediate damage exists. Explicit test-engine fault injection only.
  for event_kind in ["kill","pickup"]:
   for victim_source in [false,true]:
    pair=setup(mode);s=pair[0];t=pair[1];arm(s,t)
    var injected:=InjectedLateDamage.new();injected.configure(g.catalog);injected.reset({});injected.trigger_kind=event_kind;injected.victim_id=s.id if victim_source else t.id;g.effect_runtime.engine=injected
    if event_kind=="kill":
     var trigger:Dictionary=g._spawn_kind("crawler",Vector2(100,100));trigger.hp=0.;g.enemies=[trigger,s,t]
    else:g.pickups=[{"pos":g.player_pos,"xp":0,"coins":0,"source":"normal"}]
    Runtime.step(g.combat_frame,0.)
    var victim:Dictionary=s if victim_source else t
    ck(injected.injected_count==1 and victim.hp<=0,"fault-injected real "+event_kind+" event executes actual EffectRuntime lethalwrite")
    ck(g.enemies.has(victim),"late dead remains without second olddeathflush")
    ck(t.hp==50 if victim_source else t.hp<=0,"late fault-injecteddeath cannotbe healed")
    observations.append({"class":"fault_injected_late_event_NOT_existing_module","mode":mode,"event":event_kind,"victim":"source" if victim_source else "target","injections":injected.injected_count,"dead_present":g.enemies.has(victim)})
    g.effect_runtime.engine=g.effects
  pair=setup(mode);s=pair[0];t=pair[1];arm(s,t,1.2)
  var before:Dictionary=s.duplicate(true);g.state="paused";Runtime.step(g.combat_frame,0.)
  ck(s==before and t.hp==50,"directpaused support state frozen")
  g.state="dead";Runtime.step(g.combat_frame,0.)
  ck(t.hp==50 and s.support_channel_token==null,"directterminal clears support withoutheal")
  g._title();ck(g.enemies.is_empty(),"title removes allactor channel identities")
 var teardown=preload("<WORKSPACE>/moss-v38-qa/packed-harness/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Two modes; actual existing14 HP-source paths plus separately labelled test-engine late-event fault injections. No physical audio/native acquisition claim."}))
 quit(0 if failures.is_empty() else 1)
