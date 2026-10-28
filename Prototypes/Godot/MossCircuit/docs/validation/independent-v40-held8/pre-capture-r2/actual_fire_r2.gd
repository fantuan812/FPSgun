extends SceneTree
# External bounded actual controller fire gate. Never modify production source.
const Rules=preload("res://scripts/rules.gd")
const Rig=preload("res://scripts/weapon_rig.gd")
const Teardown=preload("evidence-workspace/moss-held8-integration-review/tests/support/audio_teardown.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
var checks:int=0
var failures:Array=[]
var records:Array=[]
var g
func ck(value:bool,label:String)->void:
 checks+=1
 if not value:failures.append(label)
func same(a,b)->bool:return var_to_bytes(a)==var_to_bytes(b)
func states()->Array:return [g.rng.state,g.loot_rng.state,g.shop_rng.state]
func run_one(id:String,mode:String,slot:int,left:bool,geometry:Dictionary,coincident:bool=false)->Dictionary:
 # Fully restart both golden and candidate sides. Never fire twice into changed animation state.
 g._title();g._select_mode(mode);g._start_run(83017);g.set_process(false)
 g.build.weapons=[id,id,id,id];g.build.weapon_temper=[0,0,0,0];g.build.items={};g._recompute();g.spawn_clock=999;g.weapon_clocks=[999.0,999.0,999.0,999.0]
 g.weapon_rig.geometry[id]=geometry.duplicate(true)
 g.hero.flip_h=left
 var weapon:Dictionary=Rules.catalog_entry(g.catalog,id)
 var reach:float=Rules.weapon_reach(weapon,g.stats)
 var delta:Vector2=Vector2(-1.0 if left else 1.0,0.12).normalized()*minf(reach*0.45,120.0)
 var target:Vector2=g.player_pos if coincident else g.player_pos+delta
 var enemy:Dictionary=g._spawn_kind("crawler",target);enemy.hp=1000;enemy.max_hp=1000;enemy.speed=0
 var rng_before:Array=states()
 g._fire_weapon(id,slot)
 var shot:Dictionary=g.weapon_rig.last_shot.duplicate(true)
 if shot.is_empty():return {"missing_shot":true}
 var pose:Dictionary=shot.pose
 var sprite:Sprite2D=g.weapon_rig.slots[slot].sprite
 var size:=Vector2(geometry.region[2],geometry.region[3])
 var grip:=Vector2(geometry.grip[0],geometry.grip[1])*size
 var tip:=Vector2(geometry.muzzle[0],geometry.muzzle[1])*size
 var sprite_grip:Vector2=sprite.to_global(grip+sprite.offset)
 var sprite_tip:Vector2=sprite.to_global(tip+sprite.offset)
 var bullets:Array=g.bullets.duplicate(true)
 var blasts:Array=g.pending_blasts.duplicate(true)
 var cones:Array=g.combat.effect_visuals.filter(func(v):return v.kind=="cryo_cone").duplicate(true)
 var flashes:Array=g.flashes.duplicate(true)
 var behavior_ok:bool=false
 if id=="shock_mortar":behavior_ok=bullets.is_empty() and blasts.size()==1 and blasts[0].visual_origin==pose.muzzle and blasts[0].pos==target and blasts[0].radius==85.0 and blasts[0].delay==0.6
 elif id=="orbit_saw":behavior_ok=bullets.is_empty() and enemy.hp<1000 and not flashes.is_empty() and flashes[-1].pos==g.player_pos and flashes[-1].radius==reach
 elif id=="cryo_sprayer":behavior_ok=bullets.is_empty() and cones.size()==1 and cones[0].pos==g.player_pos and cones[0].radius==reach and enemy.hp<1000
 elif id=="bankshot_driver":behavior_ok=bullets.size()==1 and bullets[0].pos==pose.muzzle and bullets[0].launch_budget==reach and bullets[0].velocity.normalized().distance_to(pose.direction)<0.00001 and (not coincident or pose.direction==Vector2.RIGHT)
 else:
  behavior_ok=bullets.size()==Rules.weapon_projectiles(weapon,g.stats)
  for i in range(bullets.size()):
   var b:Dictionary=bullets[i]
   var angle:float=(float(i)/maxf(1,bullets.size()-1)-0.5)*float(weapon.spread) if bullets.size()>1 else 0.0
   var direction:Vector2=pose.direction.rotated(angle)
   var travel:float=Rig.range_distance(g.player_pos,pose.muzzle,direction,reach)
   behavior_ok=behavior_ok and b.pos==pose.muzzle and b.launch_start==pose.mount and b.launch_end==pose.muzzle and b.velocity==direction*g.stats.bullet_speed and b.outbound_left==travel/g.stats.bullet_speed
 var flash_ok:bool=true
 if id not in ["orbit_saw","cryo_sprayer","return_disc"]:
  var active:Array=g.vfx.active.filter(func(v):return v.id=="muzzle_flash")
  flash_ok=active.size()==1 and active[0].pos==pose.muzzle.round() and active[0].options.angle==pose.direction.angle()
 var before_recoil:Dictionary=g._launch_pose(id,slot,target)
 g.weapon_rig.advance(0.06);g._sync_weapon_rig()
 var recoil_ok:bool=same(before_recoil,g._launch_pose(id,slot,target))
 var disc_ok:bool=true
 if id=="return_disc":
  disc_ok=g.weapon_rig.slots[slot].hidden
  for other in range(4):
   if other!=slot:disc_ok=disc_ok and not g.weapon_rig.slots[other].hidden
  for bullet in g.bullets:bullet.life=-1
  g._sync_weapon_rig();disc_ok=disc_ok and not g.weapon_rig.slots[slot].hidden
 return {"pose":pose,"bullets":bullets,"blasts":blasts,"cones":cones,"flashes":flashes,"target_hp":enemy.hp,"rng_before":rng_before,"rng_after":states(),"grip_ok":sprite_grip.distance_to(pose.mount)<0.001,"tip_ok":sprite_tip.distance_to(pose.muzzle)<0.001,"behavior_ok":behavior_ok,"flash_ok":flash_ok,"recoil_ok":recoil_ok,"disc_ok":disc_ok}
func compare_case(id:String,mode:String,slot:int,left:bool,golden:Dictionary,actual:Dictionary,coincident:bool=false)->void:
 var a:Dictionary=run_one(id,mode,slot,left,golden,coincident)
 var b:Dictionary=run_one(id,mode,slot,left,actual,coincident)
 var label:String=id+"/"+mode+"/"+str(slot)+"/"+str(left)+"/coincident="+str(coincident)
 ck(not a.has("missing_shot") and not b.has("missing_shot"),"actual fire observed "+label)
 if a.has("missing_shot") or b.has("missing_shot"):return
 ck(same(a,b),"all actual launch observations byte-equal "+label)
 ck(b.grip_ok and b.tip_ok,"real sprite grip/tip transform "+label)
 ck(b.behavior_ok,"behavior-specific actual origin/direction/budget "+label)
 ck(b.flash_ok,"real muzzle flash where applicable "+label)
 ck(b.recoil_ok,"recoil leaves logical launch unchanged "+label)
 ck(b.disc_ok,"disc owning-slot hide and recovery "+label)
 ck(b.rng_before==b.rng_after,"art launch consumes no gameplay RNG "+label)
 records.append({"id":id,"mode":mode,"slot":slot,"left":left,"coincident":coincident,"pose":var_to_str(b.pose),"bullet_count":b.bullets.size(),"blast_count":b.blasts.size(),"cone_count":b.cones.size(),"target_hp":b.target_hp})
func pre_capture_authority()->PackedByteArray:
 var foes:Array=[]
 for value in g.enemies:
  var copy:Dictionary=value.duplicate(true)
  copy.erase("sprite")
  foes.append(copy)
 return var_to_bytes({"build":g.build,"stats":g.stats,"elapsed":g.elapsed,"state":g.state,"clocks":g.weapon_clocks,"player":g.player_pos,"focus":g.combat.focus_enemy_id,"enemies":foes,"bullets":g.bullets,"blasts":g.pending_blasts,"pickups":g.pickups,"hazards":g.hazards,"B":g.effect_runtime.build_items.debug_snapshot(),"rng":g.rng.state,"loot_rng":g.loot_rng.state,"shop_rng":g.shop_rng.state})
func byte_hash(value:PackedByteArray)->String:
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(value);return hash.finish().hex_encode()
func _initialize()->void:call_deferred("run")
func run()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1:quit(2);return
 var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 var actual:Dictionary=g.weapon_rig.geometry.duplicate(true)
 for mode in ["arena","rooms"]:
  for id in IDS:
   for slot in range(4):
    for left in [false,true]:compare_case(id,mode,slot,left,old.weapons[id],actual[id])
  for slot in range(4):compare_case("bankshot_driver",mode,slot,false,old.weapons.bankshot_driver,actual.bankshot_driver,true)
 g.weapon_rig.geometry=actual
 ck(records.size()==136,"128regular+8literalbankcoincident cases")
 # Explicit fixture-only drain of historical queued nodes before capture exists.
 var before_authority:PackedByteArray=pre_capture_authority()
 var before_records:PackedByteArray=var_to_bytes(records)
 var before_live:bool=is_instance_valid(g) and not g.is_queued_for_deletion() and not g.is_processing()
 var pre_capture_start:int=Time.get_ticks_usec()
 await process_frame
 var after_authority:PackedByteArray=pre_capture_authority()
 var after_records:PackedByteArray=var_to_bytes(records)
 var after_live:bool=is_instance_valid(g) and not g.is_queued_for_deletion() and not g.is_processing()
 var guard:Dictionary={"before_current_owner_live_main_disabled":before_live,"after_current_owner_live_main_disabled":after_live,"capture_not_constructed_yet":true,"authority_before":byte_hash(before_authority),"authority_after":byte_hash(after_authority),"records_before":byte_hash(before_records),"records_after":byte_hash(after_records),"records_count":records.size(),"elapsed_us":Time.get_ticks_usec()-pre_capture_start}
 guard["pass"]=before_live and after_live and before_authority==after_authority and before_records==after_records and records.size()==136
 print("HELD_PRE_CAPTURE_GUARD "+JSON.stringify(guard))
 if not guard["pass"]:
  push_error("Held fixture pre-capture frame changed selected gameplay or records")
  quit(2);return
 var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"records":records,"scope":"136paired actual main._fire_weapon cases; controlled runtime, no native visual acceptance"}))
 quit(0 if failures.is_empty() else 1)
