extends SceneTree
# New candidate proof, not reuse of old21504 receipt. Actual current main/socket path.
const Rig=preload("res://scripts/weapon_rig.gd")
const Rules=preload("res://scripts/rules.gd")
const Teardown=preload("evidence-workspace/moss-held8-integration-review/tests/support/audio_teardown.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
const FIELDS=["region","grip","muzzle","projectile_anchor","reference_width","visible_length"]
var checks:int=0
var failures:Array=[]
var poses:int=0
var ranges:int=0
func ck(value:bool,label:String)->void:
 checks+=1
 if not value:failures.append(label)
func same(a,b)->bool:return var_to_bytes(a)==var_to_bytes(b)
func _initialize()->void:call_deferred("run")
func run()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1:quit(2);return
 var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for id in IDS:
  var golden:Dictionary=before.weapons[id]
  var actual:Dictionary=g.weapon_rig.geometry[id].duplicate(true)
  for field in FIELDS:ck(same(golden[field],actual[field]),id+" exact loaded geometry "+field)
  g._start_run(83);g.build.weapons=[id,id,id,id];g.build.items={};g._recompute();g.spawn_clock=999;g.weapon_clocks=[999.0,999.0,999.0,999.0]
  var weapon:Dictionary=Rules.catalog_entry(g.catalog,id)
  var reach:float=Rules.weapon_reach(weapon,g.stats)
  var spread:float=float(weapon.get("spread",0.0))
  for center in [Vector2(320.25,240.5),Vector2(-12.5,-9.25)]:
   g.player_pos=center
   for slot in range(4):
    for facing in [false,true]:
     g.hero.flip_h=facing
     # Obtain mount from real WeaponPresentation + ActorDirector socket; no fake socket.
     g.weapon_rig.geometry[id]=actual
     var initial:Dictionary=g._launch_pose(id,slot,center+Vector2.RIGHT*100.0)
     var mount:Vector2=initial.mount
     for angle in [0.0,PI/2.0,PI,-PI/2.0]:
      for distance in [0.0,0.001,reach]:
       var target:Vector2=mount+Vector2.from_angle(angle)*distance
       for fallback in [Vector2.RIGHT,Vector2.LEFT,Vector2.ZERO]:
        g.weapon_rig.slots[slot].aim=fallback
        g.weapon_rig.geometry[id]=actual
        var candidate:Dictionary=g._launch_pose(id,slot,target)
        g.weapon_rig.geometry[id]=golden
        var prior:Dictionary=g._launch_pose(id,slot,target)
        g.weapon_rig.geometry[id]=actual
        poses+=1
        ck(same(prior,candidate),id+" actual socket pose bytes "+str(poses))
        ck(candidate.muzzle.is_finite() and candidate.direction.is_finite(),id+" finite pose "+str(poses))
        for pellet in [-spread/2.0,0.0,spread/2.0]:
         var a:float=Rig.range_distance(center,prior.muzzle,prior.direction.rotated(pellet),reach)
         var b:float=Rig.range_distance(center,candidate.muzzle,candidate.direction.rotated(pellet),reach)
         ranges+=1;ck(same(a,b),id+" range bytes "+str(ranges))
  g.weapon_rig.geometry[id]=actual
 ck(poses==4608,"exact4608actual socket poses")
 ck(ranges==13824,"exact13824range budgets")
 var teardown=Teardown.new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"checks":checks,"failures":failures,"poses":poses,"ranges":ranges,"scope":"new target actual main._launch_pose/socket/Rig finite golden comparison; not actual projectile/fire/native proof"}))
 quit(0 if failures.is_empty() else 1)
