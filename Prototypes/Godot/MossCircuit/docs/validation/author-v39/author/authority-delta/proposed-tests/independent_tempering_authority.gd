extends SceneTree
## Controlled independent expected-state oracle; optional output after --.
const Rules=preload("res://scripts/rules.gd")
const Temper=preload("res://scripts/gameplay/weapon_tempering.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func eq(a:float,b:float,label:String)->void:ck(absf(a-b)<.00001,label+" got="+str(a)+" expected="+str(b))
func clean(v:Variant)->Variant:
 if v is Object:return {"instance_id":v.get_instance_id()} if is_instance_valid(v) else {"freed":true}
 if v is Array:
  var a:Array=[]
  for x in v:a.append(clean(x))
  return a
 if v is Dictionary:
  var d:Dictionary={}
  for k in v:d[k]=clean(v[k])
  return d
 return v
func props(obj:Object)->Dictionary:
 var d:Dictionary={}
 for p in obj.get_script().get_script_property_list():d[p.name]=clean(obj.get(p.name))
 return d
func snap()->Dictionary:
 return {"run":props(g.run),"world":props(g.combat),"effects":props(g.effects),"sequence":g.effect_runtime.sequence,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state],"rig":{"slots":clean(g.weapon_rig.slots),"generation":g.weapon_rig.generation,"clock":g.weapon_rig.visible_clock,"last":g.weapon_rig.last_shot.duplicate(true),"discs":clean(g.weapon_rig.disc_sprites),"mortars":g.weapon_rig.mortar_marks.duplicate(true)}}
func same(a:Variant,b:Variant)->bool:return var_to_bytes(a)==var_to_bytes(b)
func new_entities_empty(world:Dictionary)->bool:
 return world.get("pulse_beams") is Array and world.pulse_beams.is_empty() and world.get("seismic_waves") is Array and world.seismic_waves.is_empty() and world.get("new_weapon_motion") is Dictionary and world.new_weapon_motion.is_empty()
func setup(mode:String,ids:Array=["rivet_gun","rivet_gun"],tiers:Variant=null)->void:
 g._title();g._select_mode(mode);g._start_run(3301)
 g.build.weapons=ids.duplicate();g.build.items={"power_coil":1,"arc_relay":1,"kill_cell":1,"mirror_shell":1,"echo_chamber":1,"phase_capacitor":1,"feedback_diode":1,"dash_resin":1,"pulse_boots":1}
 if tiers!=null:g.build.weapon_temper=tiers.duplicate(true) if tiers is Array or tiers is Dictionary else tiers
 g._recompute();g.weapon_clocks=[]
 for i in range(ids.size()):g.weapon_clocks.append([-.17,.0,.63,1.27][i])
 g.build.coins=137;g.build.coin_fraction=.3;g.build.revision=7;g._open_shop();g._sync_weapon_rig()
 g._reserve_offer(0,g.shop_generation)
 g.stats.hp=41.0;g.stats.dash_time=.04;g.stats.dash_cooldown=1.7;g.hurt_clock=.27
 g.effects.cooldowns={"arc_relay":12.7,"echo_chamber":18.2};g.effects.echo_hits=3;g.effects.phase_charge=1;g.effects.chain_charges=2;g.effects.feedback_armed=true;g.effects.shield_spent=true;g.effects.shield=0
 g.hazards=[{"kind":"trail","pos":Vector2(20,20),"life":1.3,"radius":70.0,"slow":true}];g.pickups=[{"source":"normal","pos":Vector2(50,60),"xp":2,"coins":1}]
 for i in range(g.weapon_rig.slots.size()):g.weapon_rig.slots[i].age=.01+float(i)*.07;g.weapon_rig.slots[i].aim=Vector2.from_angle(.3+float(i)*.2)
 g.weapon_rig.visible_clock=3.7;g.weapon_rig.last_shot={"slot":0,"id":ids[0],"generation":g.weapon_rig.generation,"historical":true}
func reject(slot:Variant,donor:Variant,gen:Variant,id:Variant,other:Variant,label:String)->void:
 var before:=snap();ck(not g._temper_weapon(slot,donor,gen,id,other),label+" false");ck(same(snap(),before),label+" byte-atomic")
func apply(slot:int,donor:int,label:String)->void:
 var before:=snap();var original_id:String=g.build.weapons[slot];var wanted:Dictionary=g.build.duplicate(true)
 if not wanted.has("weapon_temper"):
  wanted.weapon_temper=[]
  for _x in wanted.weapons:wanted.weapon_temper.append(0)
 wanted.weapon_temper[slot]=1;wanted.weapon_temper.remove_at(donor);wanted.weapons.remove_at(donor);wanted.revision+=1
 var clocks:Array=g.weapon_clocks.duplicate();clocks.remove_at(donor)
 var remaining:Array=before.rig.slots.duplicate(true);remaining.remove_at(donor)
 for i in range(remaining.size()):
  if remaining[i].slot!=i:remaining[i].slot=i;remaining[i].pose={}
 var donor_ref:WeakRef=weakref(g.weapon_rig.slots[donor].sprite)
 var generation:int=g.shop_generation
 ck(g._temper_weapon(slot,donor,generation,original_id,original_id),label+" accepted")
 var after:=snap();ck(same(g.build,wanted),label+" exact resulting build");ck(same(g.weapon_clocks,clocks),label+" clocks follow survivors");ck(same(after.rig.slots,remaining),label+" exact surviving rig records")
 ck(after.rig.generation==before.rig.generation and after.rig.clock==before.rig.clock and same(after.rig.last,before.rig.last),label+" rig history/clock preserved")
 ck(same(after.effects,before.effects) and after.sequence==before.sequence and same(after.rng,before.rng),label+" effects/sequence/RNG exact")
 ck(g.shop_generation==generation+1,label+" generation once")
 var run_before:Dictionary=before.run.duplicate(true);var run_after:Dictionary=after.run.duplicate(true)
 for key in ["build","shop_generation","shop_message"]:run_before.erase(key);run_after.erase(key)
 ck(same(run_before,run_after),label+" all other run authority exact")
 var world_before:Dictionary=before.world.duplicate(true);var world_after:Dictionary=after.world.duplicate(true)
 for key in ["stats","weapon_clocks"]:world_before.erase(key);world_after.erase(key)
 var epoch_advanced:bool=world_before.get("new_weapon_epoch") is int and world_after.get("new_weapon_epoch") is int and world_after.new_weapon_epoch==world_before.new_weapon_epoch+1
 world_after.new_weapon_epoch=world_before.new_weapon_epoch
 ck(epoch_advanced and new_entities_empty(world_before) and new_entities_empty(world_after) and same(world_before,world_after),label+" A epoch exactly +1; all other combat authority exact")
 var old_stats:Dictionary=before.world.stats.duplicate(true);var new_stats:Dictionary=after.world.stats.duplicate(true)
 for key in ["electric_bonus","melee_bonus","extra_pellets","synergies"]:old_stats.erase(key);new_stats.erase(key)
 ck(same(old_stats,new_stats),label+" no unrelated derived-stat change")
 eq(g.stats.hp,41,label+" HP unchanged");eq(g.stats.dash_time,.04,label+" dash unchanged");eq(g.stats.dash_cooldown,1.7,label+" dash cooldown unchanged")
 reject(slot,donor,generation,original_id,original_id,label+" stale callback")
 await process_frame
 ck(donor_ref.get_ref()==null,label+" donor sprite deferred freed")
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var profile:Dictionary={"max_tier":1,"primary_damage_multiplier":1.6};ck(Temper.validate_profile(profile).is_empty(),"valid profile");ck(Temper.validate_profile({"max_tier":1.0,"primary_damage_multiplier":1.6}).is_empty(),"integral JSON float max tier")
 for field in ["max_tier","primary_damage_multiplier"]:
  for bad in [null,true,false,"1",{},[],NAN,INF,-INF,-1,0,2,2.2]:
   var p:Dictionary=profile.duplicate();p[field]=bad;ck(not Temper.validate_profile(p).is_empty(),"invalid profile "+field+" "+str(bad))
 for p in [{"max_tier":1.5,"primary_damage_multiplier":1.6},{"max_tier":1,"primary_damage_multiplier":1.0},{"max_tier":1},{"primary_damage_multiplier":1.6}]:ck(not Temper.validate_profile(p).is_empty(),"missing or boundary profile")
 for v in [null,true,"x",[],1]:ck(not Temper.validate_profile(v).is_empty(),"profile wrong container")
 for id in IDS:
  var b:Dictionary={"weapons":[id,id],"items":{},"coins":19,"coin_fraction":.3,"revision":2};var before:Dictionary=b.duplicate(true)
  ck(Temper.metadata_error(b).is_empty() and Temper.tier_at(b,0,id)==0,"absent STANDARD "+id);ck(same(b,before),"no eager insertion "+id)
  b.weapon_temper=[1,0];ck(Temper.tier_at(b,0,id)==1 and Temper.tier_at(b,1,id)==0,"copy not type "+id);eq(Temper.multiplier(b,g.catalog,0,id),1.6,"factor "+id);eq(Temper.multiplier(b,g.catalog,1,id),1,"standard "+id)
  var alternate:Dictionary=g.catalog.duplicate(true);alternate.weapon_tempering.primary_damage_multiplier=1.25;eq(Temper.multiplier(b,alternate,0,id),1.25,"factor comes from validated profile")
  for slot in [-1,2,999]:eq(Temper.multiplier(b,g.catalog,slot,id),1,"invalid slot fallback")
  eq(Temper.multiplier(b,g.catalog,0,"unknown"),1,"mismatched ID fallback")
  for invalid in [null,true,{},"00",[0],[0,0,0],[0.0,0],[true,0],[-1,0],[2,0],[[0],0],[null,0]]:
   b.weapon_temper=invalid;var stable:Dictionary=b.duplicate(true);ck(not Temper.metadata_error(b).is_empty(),"malformed present "+str(invalid));eq(Temper.multiplier(b,g.catalog,0,id),1,"malformed no boost");ck(same(b,stable),"malformed not repaired")
 for mode in ["arena","rooms"]:
  setup(mode)
  for bad in [null,true,0.0,"0",{},[]]:
   reject(bad,1,g.shop_generation,"rivet_gun","rivet_gun","slot rawtype");reject(0,bad,g.shop_generation,"rivet_gun","rivet_gun","donor rawtype");reject(0,1,bad,"rivet_gun","rivet_gun","generation rawtype");reject(0,1,g.shop_generation,bad,"rivet_gun","id rawtype");reject(0,1,g.shop_generation,"rivet_gun",bad,"donor id rawtype")
  for pair in [[-1,1],[2,1],[0,0],[0,2]]:reject(pair[0],pair[1],g.shop_generation,"rivet_gun","rivet_gun","bounds")
  reject(0,1,g.shop_generation-1,"rivet_gun","rivet_gun","old gen");reject(0,1,g.shop_generation,"rail_lance","rivet_gun","wrong identity")
  for state in ["title","playing","paused","inventory","upgrade","dead","won"]:
   g.state=state;reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","wrong state "+state)
  g.state="shop"
  for bullet in [{"weapon":"rivet_gun"},{"weapon":"return_disc"},{"behavior":"field_bankshot"}]:
   g.bullets=[bullet];reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","outstanding flight");g.bullets=[]
  g.pending_blasts=[{"weapon":"shock_mortar"}];reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","pending mortar");g.pending_blasts=[]
  for bad in [[0],[0,INF],[0,NAN],[0,true],[0,".2"]]:
   var old:Array=g.weapon_clocks;g.weapon_clocks=bad;reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","invalid clocks");g.weapon_clocks=old
  for invalid in [null,[0.0,0],[2,0],[0],{}]:
   g.build.weapon_temper=invalid;reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","invalid metadata guard")
  g.build.erase("weapon_temper")
  g.weapon_rig.clear();reject(0,1,g.shop_generation-1,"rivet_gun","rivet_gun","lazy rig stale request does not sync")
  g._sync_weapon_rig()
  var old_id:String=g.build.weapons[1];g.build.weapons[1]="unknown";reject(0,1,g.shop_generation,"rivet_gun","unknown","unknown owned ID");g.build.weapons[1]=old_id
  g.build.weapons.append_array(["rivet_gun","rivet_gun","rivet_gun"]);g.weapon_clocks.append_array([0.0,0.0,0.0]);reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","over-cap five copies")
  setup(mode)
  await apply(0,1,mode+" retain-first")
  setup(mode,["rivet_gun","rail_lance","rivet_gun","orbit_saw"]);await apply(2,0,mode+" retain-later")
  setup(mode,["rivet_gun","rivet_gun","rivet_gun","rivet_gun"]);reject(0,2,g.shop_generation,"rivet_gun","rivet_gun","nonlowest donor");await apply(0,1,mode+" first pair");await apply(2,1,mode+" second pair");ck(g.build.weapon_temper==[1,1],"two tempered pairs")
  reject(0,1,g.shop_generation,"rivet_gun","rivet_gun","no tier ladder")
  for kind in ["rail_lance","orbit_saw","scrap_shotgun"]:
   setup(mode,[kind,kind,kind]);g.build.items={};g._recompute();g.stats.hp=41.0;g.stats.dash_time=.04;g.stats.dash_cooldown=1.7
   await apply(0,1,mode+" threshold "+kind)
   var s:Dictionary=g.stats;ck(s.synergies.is_empty(),"three to two loses threshold");eq(s.electric_bonus,0,"electric threshold absent");eq(s.melee_bonus,0,"melee threshold absent");ck(s.extra_pellets==0,"spread threshold absent")
 var audio_teardown = preload("res://tests/support/audio_teardown.gd").new()
 audio_teardown.prepare([g])
 g.queue_free();await process_frame
 await audio_teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Independent controlled pure config/metadata plus actual guarded shop authority, copy-clock/rig identity, threshold and lifetime checks; no ordinary/Windows/balance claim."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
