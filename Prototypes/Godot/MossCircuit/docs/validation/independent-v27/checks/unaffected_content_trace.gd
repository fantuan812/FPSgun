extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Motor=preload("res://scripts/gameplay/character_motor.gd")
var g
var traces:Array=[]
var samples:Array=[]
var shops:Array=[]
var failures:Array=[]
var profiles:Array=[
 {"weapons":["rivet_gun","rail_lance"],"items":{"mirror_shell":1,"thorn_crown":1,"feedback_diode":1,"iron_plate":2,"running_boots":1,"moss_patch":1}},
 {"weapons":["scrap_shotgun","shock_mortar"],"items":{"dash_resin":1,"pulse_boots":1,"phase_capacitor":1,"blast_fuse":1,"gravity_anchor":1,"scrap_mine":1,"blood_valve":1,"kill_cell":1}},
 {"weapons":["cryo_sprayer","rivet_gun","orbit_saw"],"items":{"fracture_coil":1,"arc_relay":1,"kill_cell":1,"power_coil":2,"cooling_fan":1,"lens":1,"capacitor":1,"gear":1}},
 {"weapons":["bankshot_driver","return_disc","scrap_shotgun"],"items":{"bounce_guide":1,"echo_chamber":1,"return_spool":1,"pellet_pouch":1,"salvage_magnet":1,"lucky_chip":1,"recycler":1}}]
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
    if k not in ["sprite"]:d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<presentation-object>"
  _:return v
func projection()->Dictionary:
 return clean({"state":g.state,"time":g.elapsed,"kills":g.kills,"stats":g.stats,"player":g.player_pos,"hurt_clock":g.hurt_clock,"build":g.build,"enemies":g.enemies,"bullets":g.bullets,"enemy_bullets":g.enemy_bullets,"pickups":g.pickups,"hazards":g.hazards,"pending_blasts":g.pending_blasts,"weapon_clocks":g.weapon_clocks,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"old_effect_state":{"epoch":g.effects.epoch,"last_sequence":g.effects.last_sequence,"runtime_sequence":g.effect_runtime.sequence,"active":g.effects.active,"cooldowns":g.effects.cooldowns,"shield":g.effects.shield,"shield_spent":g.effects.shield_spent,"echo_hits":g.effects.echo_hits,"phase_charge":g.effects.phase_charge,"medic_damage":g.effects.medic_damage,"chain_charges":g.effects.chain_charges,"feedback_armed":g.effects.feedback_armed,"feedback_damage":g.effects.feedback_damage}})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var filtered:Dictionary=g.catalog.duplicate(true)
 
 
 
 for pi in range(profiles.size()):
  var b:Dictionary=Rules.new_build(filtered);b.weapons=profiles[pi].weapons.duplicate();b.items=profiles[pi].items.duplicate()
  var draws:Array=[]
  for seed_value in range(200):
   var random:=RandomNumberGenerator.new();random.seed=seed_value
   draws.append({"seed":seed_value,"offers":Rules.draw_shop(b,filtered,random),"state":random.state})
  shops.append({"profile":pi,"affinity":Rules.shop_affinity(b,filtered),"pool":Rules.weighted_pool(b,filtered),"draws":draws})
 for mode in ["arena","rooms"]:
  for pi in range(profiles.size()):
   g._title();g._select_mode(mode);g._start_run(26025)
   g.build.weapons=profiles[pi].weapons.duplicate();g.build.items=profiles[pi].items.duplicate();g.build.revision+=1;g._recompute()
   g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.elapsed=10;g.spawn_clock=999
   g.stats.max_hp=10000;g.stats.hp=10000;g.combat_frame.area=g.config.arena
   var s:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(150,0));s.hp=1000;s.max_hp=1000;s.anim_hp=1000;s.cooldown_left=0
   g._spawn_kind("crawler",g.player_pos+Vector2(-90,45))
   g._spawn_kind("charger",g.player_pos+Vector2(0,-150))
   var f:Dictionary=g._spawn_kind("flanker",g.player_pos+Vector2(-150,75));f.hp=10000;f.max_hp=10000;f.anim_hp=10000
   if pi==2:
    var w:Dictionary=g._spawn_kind("boss_warden",g.player_pos+Vector2(120,-100));w.hp=10000;w.max_hp=30000;w.anim_hp=10000;w.cooldown_left=0
   if pi==3:
    var core:Dictionary=g._spawn_kind("boss_core",g.player_pos+Vector2(120,120));core.hp=10000;core.max_hp=30000;core.anim_hp=10000;core.cooldown_left=0
   var hashes:Array=[];var dash_frames:=0;var max_enemy_bullets:=0;var hp_start:float=g.stats.hp
   for step in range(400):
    var dt:=.05;g.elapsed+=dt;g.wave_time+=dt
    g.weapon_rig.advance(dt);g.actor_anim.advance(dt);g.vfx.advance(dt)
    var direction:=Vector2.RIGHT if step%80<40 else Vector2.LEFT
    var origin:Vector2=g.player_pos
    if Motor.step(g.combat,g.config.arena,direction,step in [0,130],dt):g._effect_event("dash",{"pos":origin,"angle":direction.angle()})
    if g.stats.dash_time>0:dash_frames+=1
    if step in [0,1,20,21] and s.hp>0:
     g.enemy_bullets.append({"pos":g.player_pos,"velocity":Vector2.ZERO,"life":1.0,"damage":8.0,"owner":s.id})
    Runtime.step(g.combat_frame,dt)
    max_enemy_bullets=maxi(max_enemy_bullets,g.enemy_bullets.size())
    if step==60:
     g._on_intent("pause",{});g._process(.5);g._on_intent("resume",{})
    var p:Dictionary=projection();hashes.append(JSON.stringify(p).sha256_text())
    if step in [0,1,20,21,60,130,399]:samples.append({"mode":mode,"profile":pi,"step":step,"state":p})
   if dash_frames==0:failures.append(mode+str(pi)+" no dash frames")
   traces.append({"mode":mode,"profile":pi,"hashes":hashes,"dash_frames":dash_frames,"max_enemy_bullets":max_enemy_bullets,"hp_delta":hp_start-g.stats.hp})
   await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"scope":"controlled finite accepted-v26-schema authority/event/RNG trace and unchanged full v26 shop; includes Feedback, all 8 weapons, non-Broodkeeper actors and both bosses. No Broodkeeper because its new attack behavior intentionally changes. Controlled diagnostic builds include over-cap combinations to observe hook ordering, not legal-build acquisition evidence; excludes rendering object identity","steps":3200,"old_pool_draws":800,"traces":traces,"samples":samples,"shops":shops,"failures":failures}
 var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"steps":3200,"old_pool_draws":800,"failures":failures,"trace_sha256":JSON.stringify(traces).sha256_text(),"shop_sha256":JSON.stringify(shops).sha256_text()}));quit(0 if failures.is_empty() else 1)
