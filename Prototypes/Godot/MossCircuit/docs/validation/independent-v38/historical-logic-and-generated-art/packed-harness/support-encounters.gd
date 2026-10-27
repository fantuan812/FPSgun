extends SceneTree
# Exact held v37 data projection and original RNG sequence control, not all-seed balance proof.
const Arena=preload("res://scripts/modes/arena_mode.gd")
const Room=preload("res://scripts/modes/room_mode.gd")
const EnemyAI=preload("res://scripts/enemy_ai.gd")
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func expected_request(pool:Array,random:RandomNumberGenerator)->Dictionary:
 var pos:Vector2=g.player_pos+Vector2.from_angle(random.randf_range(0,TAU))*random.randf_range(330,440)
 pos=pos.clamp(Vector2(20,20),Vector2(g.config.arena.width-20,g.config.arena.height-20))
 if pos.distance_to(g.player_pos)<180 or pool.is_empty():return {}
 return {"kind":pool[random.randi_range(0,pool.size()-1)],"pos":pos}
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false);g._select_mode("arena");g._start_run(3802);g.spawn_clock=999;g.weapon_clocks.fill(999.)
 var old:Dictionary=JSON.parse_string(OLD_ENCOUNTERS);var old_rooms:Dictionary=JSON.parse_string(OLD_ROOMS)
 var now:Dictionary=g.encounters.duplicate(true);var rooms:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_encounters.json"))
 ck(now.enemies.size()==8 and now.enemies[-1].id=="stitch_drone","exact one appended eighth enemy")
 var drone:Dictionary=now.enemies.pop_back()
 ck(drone.behavior=="support_repair" and drone.boss==false,"new support identity")
 for spec in [["hp",34],["speed",30],["damage",6],["xp",7],["scale",1],["desired_distance",210],["support_radius",150],["support_channel",1.2],["support_cooldown",5],["support_retry",1],["support_heal",10],["support_max_alive",1]]:
  ck(drone.get(spec[0])==spec[1],"hand-declared shipped parameter "+spec[0])
 ck(now.waves[3].pool[-1]=="stitch_drone" and now.waves[3].pool.size()==old.waves[3].pool.size()+1,"onlywave4 appended support")
 now.waves[3].pool.pop_back();ck(now==old,"entire old encounter projection exact")
 ck(rooms.stages.size()==3 and rooms.stages[0]==old_rooms.stages[0],"entry untouched")
 for stage in [1,2]:
  ck(rooms.stages[stage].enemies.size()==5 and rooms.stages[stage].enemies[-1]=={"kind":"stitch_drone","at":[.5,.18]},"exact fifth room entry "+str(stage))
  rooms.stages[stage].enemies.pop_back()
 ck(rooms==old_rooms,"entire old room projection exact")
 ck(EnemyAI.validate(g.encounters).is_empty(),"new actual encounter schema valid")
 var arena:=Arena.new();g.wave=4;g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 for config_case in ["old","new_no_source","new_live_source","new_dead_source","new_saturated_only_support"]:
  var config_data:Dictionary=old.duplicate(true) if config_case=="old" else g.encounters.duplicate(true)
  var expected_pool:Array=config_data.waves[3].pool.duplicate()
  g._title();g._select_mode("arena");g._start_run(3802);g.wave=4;g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5);g.spawn_clock=999;g.weapon_clocks.fill(999.)
  if config_case in ["new_live_source","new_dead_source","new_saturated_only_support"]:
   var spawned:Dictionary=g._spawn_kind("stitch_drone",g.player_pos+Vector2(70,0))
   if config_case=="new_dead_source":spawned.hp=0.
  if config_case=="new_saturated_only_support":config_data.waves[3].pool=["stitch_drone"];expected_pool=[]
  elif config_case=="new_live_source":expected_pool.erase("stitch_drone")
  for seed_value in range(1,33):
   var actual_rng:=RandomNumberGenerator.new();actual_rng.seed=seed_value;var reference_rng:=RandomNumberGenerator.new();reference_rng.seed=seed_value
   var expected:Dictionary=expected_request(expected_pool,reference_rng)
   var actual:Dictionary=arena.regular_request(g.run,g.combat,g.config,config_data,actual_rng)
   ck(actual==expected,"actual spawn versus held original draw order / "+config_case+"/"+str(seed_value))
   ck(actual_rng.state==reference_rng.state,"no extra RNG draw / "+config_case+"/"+str(seed_value))
 g._title();g._select_mode("arena");g._start_run(3802)
 # Room policy is the actual current class; acknowledge only successful spawns, fifth actor gates completion.
 var current_rooms:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_encounters.json"))
 for stage in [2,3]:
  var mode:=Room.new(current_rooms);mode.begin_stage(stage);g.wave=stage
  var random:=RandomNumberGenerator.new();random.seed=44;var before_state:int=random.state
  for index in range(5):
   var request:Dictionary=mode.regular_request(g.run,g.combat,g.config,g.encounters,random)
   ck(request.plan_index==index,"room exact finite request index")
   if index==4:ck(request.kind=="stitch_drone","fifth actual request is support")
   mode.acknowledge(request,{})
   ck(mode.planned_index==index,"failed spawn doesnot consume finite quota")
   mode.acknowledge(request,{"id":100+index})
  ck(mode.planned_index==5 and mode.planned_count==5 and random.state==before_state,"actual room fifth quota complete without RNG")
  var live:Dictionary=g._spawn_kind("stitch_drone",Vector2(200,200));mode.advance_clear(10.,g.combat)
  ck(not mode.can_end(g.run,g.combat,g.encounters),"remaining support prevents room clear")
  live.sprite.queue_free();g.enemies.clear();mode.advance_clear(.6,g.combat)
  ck(mode.can_end(g.run,g.combat,g.encounters),"all five gone permits exact clear delay")
 var teardown=preload("<WORKSPACE>/moss-v38-qa/packed-harness/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Heldv37 data projection, finite32seed draw controls in5poolstates and actualRoom5quota policy; old6/24 combat parity separately executed."}))
 quit(0 if failures.is_empty() else 1)

const OLD_ENCOUNTERS = """{
  "enemies": [
    {
      "id": "crawler",
      "name": "Scrap Crawler",
      "behavior": "chase",
      "hp": 22,
      "speed": 53,
      "damage": 9,
      "xp": 4,
      "scale": 1,
      "color": "ffffff",
      "boss": false,
      "cooldown": 1,
      "warning": 0.65,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Direct pursuit; contact damage.",
      "tell": "No ranged attack.",
      "dodge": "Keep moving and create distance."
    },
    {
      "id": "charger",
      "name": "Amber Ram",
      "behavior": "charge",
      "hp": 42,
      "speed": 36,
      "damage": 15,
      "xp": 7,
      "scale": 1.2,
      "color": "e9b660",
      "boss": false,
      "cooldown": 3.2,
      "warning": 0.65,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "brace_degrees": 120.0,
      "brace_multiplier": 0.5,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Locks a route and braces its front while warning, then charges.",
      "tell": "Pale front arc halves incoming primary damage during the 0.65 s warning; orange marks the charge route.",
      "dodge": "Flank or wait: side/rear, charge and recovery take full damage. Warning and recovery remain contact-safe."
    },
    {
      "id": "spitter",
      "name": "Violet Spitter",
      "behavior": "ranged",
      "hp": 30,
      "speed": 46,
      "damage": 8,
      "xp": 6,
      "scale": 0.95,
      "color": "be9ae6",
      "boss": false,
      "cooldown": 2,
      "warning": 0.65,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Maintains 230 px distance and fires aimed projectiles.",
      "tell": "Orange ring marks its 0.65 s firing preparation.",
      "dodge": "Strafe after its aim locks; pink bullets can be dodged."
    },
    {
      "id": "flanker",
      "name": "Knifeleg Flanker",
      "behavior": "flank",
      "hp": 26,
      "speed": 72,
      "damage": 8,
      "xp": 6,
      "scale": 0.9,
      "color": "90d7e0",
      "boss": false,
      "cooldown": 1,
      "warning": 0.65,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Weaves sideways while approaching rather than taking a direct line.",
      "tell": "Alternating lateral path; no ranged attack.",
      "dodge": "Avoid retreating into its side path."
    },
    {
      "id": "brood_keeper",
      "name": "Moss Broodkeeper",
      "behavior": "brood_cycle",
      "hp": 75,
      "speed": 22,
      "damage": 11,
      "xp": 12,
      "scale": 1.35,
      "color": "90bd74",
      "boss": false,
      "cooldown": 6,
      "warning": 0.65,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Alternates a hollow ground pulse first, then its existing summon. At most 3 living children.",
      "tell": "Pulse: two orange edges mark a fixed 70\u2013180 px band for 1.0 s. Summon: the old small ring for 0.65 s.",
      "dodge": "Enter the inner pocket or leave the outer circle; both orange edges hurt. Other enemies still hit. Leave its body before recovery ends.",
      "pulse_inner_radius": 70,
      "pulse_outer_radius": 180,
      "pulse_warning": 1.0
    },
    {
      "id": "boss_warden",
      "name": "Scrap Warden",
      "behavior": "warden",
      "hp": 950,
      "speed": 35,
      "damage": 18,
      "xp": 60,
      "scale": 2.6,
      "color": "e9bd74",
      "boss": true,
      "cooldown": 3,
      "warning": 0.85,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Wave 3 boss: alternates a locked charge and targeted ground blast. Below half HP it moves and attacks faster.",
      "tell": "0.85 s line or ground circle. Warning/recovery have no contact damage.",
      "dodge": "Dodge sideways from line; leave the marked circle before detonation."
    },
    {
      "id": "boss_core",
      "name": "Spore Reactor",
      "behavior": "core",
      "hp": 1600,
      "speed": 25,
      "damage": 15,
      "xp": 100,
      "scale": 2.9,
      "color": "9de0c4",
      "boss": true,
      "cooldown": 3.4,
      "warning": 0.85,
      "projectile_speed": 145,
      "charge_speed": 310,
      "charge_duration": 0.6,
      "desired_distance": 230,
      "summon_limit": 3,
      "phase_threshold": 0.5,
      "phase_speed": 1.25,
      "description": "Wave 6 boss: maintains distance and fires ring volleys. Below half HP, 12-shot rings alternate with summons.",
      "tell": "0.85 s orange ring before each release.",
      "dodge": "Use gaps in the slow ring; dash is briefly invulnerable. Clear summons."
    }
  ],
  "waves": [
    {
      "number": 1,
      "pool": [
        "crawler"
      ],
      "boss": ""
    },
    {
      "number": 2,
      "pool": [
        "crawler",
        "charger",
        "spitter"
      ],
      "boss": ""
    },
    {
      "number": 3,
      "pool": [
        "crawler",
        "flanker"
      ],
      "boss": "boss_warden"
    },
    {
      "number": 4,
      "pool": [
        "charger",
        "spitter",
        "flanker"
      ],
      "boss": ""
    },
    {
      "number": 5,
      "pool": [
        "spitter",
        "flanker",
        "brood_keeper"
      ],
      "boss": ""
    },
    {
      "number": 6,
      "pool": [
        "crawler",
        "spitter",
        "brood_keeper"
      ],
      "boss": "boss_core"
    }
  ]
}
"""

const OLD_ROOMS = """{
  "id":"rooms","name":"ROOM ENCOUNTERS · PROTOTYPE",
  "field":{"width":960,"height":640,"tile_size":80},
  "spawn_interval":0.3,"clear_delay":0.6,
  "reward":{"coins":24,"heal":15,"upgrades":1},
  "stages":[
    {"name":"ENTRY","enemies":[{"kind":"crawler","at":[0.18,0.22]},{"kind":"crawler","at":[0.82,0.22]},{"kind":"flanker","at":[0.8,0.8]}]},
    {"name":"CROSSFIRE","enemies":[{"kind":"spitter","at":[0.16,0.2]},{"kind":"charger","at":[0.82,0.8]},{"kind":"crawler","at":[0.18,0.8]},{"kind":"flanker","at":[0.82,0.22]}]},
    {"name":"BROOD","enemies":[{"kind":"brood_keeper","at":[0.18,0.2]},{"kind":"charger","at":[0.82,0.2]},{"kind":"spitter","at":[0.82,0.8]},{"kind":"crawler","at":[0.18,0.8]}]}
  ]
}
"""
