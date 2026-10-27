extends SceneTree
# Supplemental pre-target concrete projectile variants; shared HP seam covered separately.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
var g
var checks:=0
var failures:Array=[]
var observations:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func setup(mode:String,weapon:String)->Array:
 g._title();g._select_mode(mode);g._start_run(3803);g.build.weapons=[weapon];g._recompute();g.weapon_clocks.fill(999.);g.spawn_clock=999.;g.elapsed=10.;g.player_pos=Vector2(500,350);g.hero.position=g.player_pos;g.combat_frame.area=g.config.arena;g.hurt_clock=0.
 var s:Dictionary=g._spawn_kind("stitch_drone",Vector2(580,350));var t:Dictionary=g._spawn_kind("crawler",Vector2(580,440));s.speed=0.;t.speed=0.;t.hp=50.;t.max_hp=100.;t.anim_hp=50.
 s.ai_state="warning";s.support_target_id=t.id;s.support_start_hp=s.hp;s.support_due=false;s.warning_left=0.;s.support_target_pos=t.pos;s.support_channel_token=RefCounted.new();s.support_cancel_pending={}
 return [s,t]
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  for spec in [["rivet_gun",false],["scrap_shotgun",false],["rail_lance",false],["return_disc",false],["return_disc",true]]:
   var pair:Array=setup(mode,spec[0]);var s:Dictionary=pair[0];var t:Dictionary=pair[1]
   var b:Dictionary={"pos":s.pos,"launch_start":s.pos,"velocity":Vector2.RIGHT*470.,"life":1.,"damage":1.,"pierce":0,"hit":[],"weapon":spec[0],"returning":spec[1],"outbound_left":.5}
   g.bullets=[b];Runtime.step(g.combat_frame,0.)
   ck(s.hp==33. and t.hp==50.,"concrete late projectile damage1 interruptsdue "+str(spec)+"/"+mode)
   ck(s.ai_state=="recover" and s.support_channel_token==null,"actual projectile route cancels once")
   ck(b.hit.has(s.id),"actual collision records source ID")
   observations.append({"mode":mode,"weapon":spec[0],"returning":spec[1],"controlled_projectile_damage":1.,"source_hp":s.hp,"target_hp":t.hp})
  var pair:Array=setup(mode,"bankshot_driver");var s:Dictionary=pair[0];var t:Dictionary=pair[1]
  g.weapon_combat.fire_bankshot(Rules.catalog_entry(g.catalog,"bankshot_driver"),0,1.,g.config.arena)
  ck(g.bullets.size()==1 and g.bullets[0].behavior=="field_bankshot","actual bankshot spawn, not direct hit callback")
  Runtime.step(g.combat_frame,.3)
  ck(s.hp==33. and t.hp==50. and s.ai_state=="recover","actual bankshot trajectory latehit cancels dueheal")
  pair=setup(mode,"shock_mortar");s=pair[0];t=pair[1];s.hp=100.;s.max_hp=100.;s.anim_hp=100.;s.support_start_hp=100.
  g.weapon_combat.fire("shock_mortar",0,g.config.arena)
  ck(g.pending_blasts.size()==1,"actual mortar launch queued")
  Runtime.step(g.combat_frame,.6)
  ck(s.hp==64. and t.hp==50. and s.ai_state=="recover","actual mortar36 earlydue damage cancels ongoing channel")
  observations.append({"mode":mode,"weapon":"shock_mortar","controlled_source_hp":100.,"catalog_damage":36.,"source_after":s.hp,"target_after":t.hp})
 var teardown=preload("res://tests/support/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 print(JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Concrete bolt/pellet/rail/return-out/in controlled projectile damage1, actual bankshot trajectory and actual launched mortar36 in both modes. Not an ordinary acquisition or new numeric balance oracle."}))
 quit(0 if failures.is_empty() else 1)
