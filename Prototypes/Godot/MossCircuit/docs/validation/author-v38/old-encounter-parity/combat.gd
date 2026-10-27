extends SceneTree
## Independent new-catalog fixed-old-combat control. Derived from preserved old projection; no shop phase.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
var g
var cases:Array=[]
var failures:Array=[]
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
    if k!="sprite":d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<presentation-object>"
  _:return v
func snap()->Dictionary:
 return clean({"state":g.state,"build":g.build,"stats":g.stats,"wave":g.wave,"elapsed":g.elapsed,"level":g.level,"xp":g.xp,"pending":g.upgrade_pending,"shop_pending":g.shop_pending,"choice_generation":g.choice_generation,"choices":g.choices,"shop_generation":g.shop_generation,"offers":g.shop_offers,"reserved":g.reserved_offer,"message":g.shop_message,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"clocks":g.weapon_clocks,"bullets":g.bullets,"pending_blasts":g.pending_blasts,"enemies":g.enemies,"enemy_bullets":g.enemy_bullets,"hazards":g.hazards,"pickups":g.pickups,"effects":{"epoch":g.effects.epoch,"sequence":g.effects.last_sequence,"runtime_sequence":g.effect_runtime.sequence,"active":g.effects.active,"cooldowns":g.effects.cooldowns,"shield":g.effects.shield,"feedback":g.effects.feedback_armed,"echo":g.effects.echo_hits,"phase":g.effects.phase_charge}})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 # Exact held v37 encounter/Rooms injection, before any mode construction/run.
 var old_encounters:String=FileAccess.get_file_as_string("evidence-workspace/moss-v38-parity/encounters.json")
 var old_rooms:String=FileAccess.get_file_as_string("evidence-workspace/moss-v38-parity/room_encounters.json")
 if old_encounters.sha256_text()!="853bb3699bb05c2ed1eb7d1c8dc3e51844428c233ffa3127ac035a2762a3f356" or old_rooms.sha256_text()!="4a0067faa08241d91042505d72b3a027956ef27571710d74d8559462ac2c5131":
  failures.append("held encounter bytes changed")
 var current:Dictionary=preload("res://tests/support/v38_encounter_projection.gd").project(FileAccess.get_file_as_string("res://data/encounters.json"),FileAccess.get_file_as_string("res://data/room_encounters.json"))
 if not current.get("pass",false) or current.encounter_bytes!=old_encounters or current.room_bytes!=old_rooms:failures.append("candidate additions not exactly declared")
 var shared_encounters:Dictionary=g.encounters
 var shared_rooms:Dictionary=g.room_profile
 g.encounters.clear();g.encounters.merge(JSON.parse_string(old_encounters),true)
 g.room_profile.clear();g.room_profile.merge(JSON.parse_string(old_rooms),true)
 if shared_encounters!=JSON.parse_string(old_encounters) or shared_rooms!=JSON.parse_string(old_rooms):failures.append("actual shared authority injection failed")
 var loadouts:Array=[["rivet_gun","rail_lance"],["orbit_saw","cryo_sprayer"],["scrap_shotgun","return_disc"],["shock_mortar","bankshot_driver"]]
 for mode in ["arena","rooms"]:
  for seed_value in [17,128,433]:
   for route in range(loadouts.size()):
    g._title();g._select_mode(mode);g._start_run(seed_value)
    g.build.weapons=loadouts[route].duplicate();g.build.items={"power_coil":1,"fracture_coil":1,"pulse_boots":1,"feedback_diode":1}
    g.build.coins=137;g.build.coin_fraction=.3;g._recompute();g.weapon_clocks=[.0,.17]
    g.elapsed=10;g.spawn_clock=999;g.combat_frame.area=g.config.arena
    var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(90,0));e.hp=1000;e.max_hp=1000;e.anim_hp=1000;e.speed=0;e.cooldown_left=999
    var ranged:Dictionary=g._spawn_kind("spitter",g.player_pos+Vector2(-180,25));ranged.hp=1000;ranged.max_hp=1000;ranged.anim_hp=1000;ranged.speed=0;ranged.cooldown_left=.1
    var steps:Array=[{"label":"prepared combat","state":snap()}]
    for tick in range(20):
     g.elapsed+=.05;Runtime.step(g.combat_frame,.05)
     if tick in [0,5,12,19]:steps.append({"label":"combat "+str(tick),"state":snap()})
    for state in steps:
     if state.state.bullets.any(func(b):return b.has("scavenger")):failures.append("no-module acquired scavenger metadata")
    cases.append({"mode":mode,"seed":seed_value,"route":route,"steps":steps})
    await process_frame
 var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 var result:Dictionary={"scope":"24 fixed old combat setups with unmodified current catalog and no Scavenger Reel. No shop phase or offer-ID parity claim; exact declared old combat/events/RNG projection.","cases":cases,"failures":failures}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify({"cases":cases.size(),"failures":failures,"case_sha256":JSON.stringify(cases).sha256_text()}))
 quit(0 if failures.is_empty() else 1)
