extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Flow=preload("res://scripts/gameplay/run_flow.gd")
class Policy extends RefCounted:
 var invalid:=false
 func can_end(_s,_w,_e)->bool:return true
 func resolution(_s,_w,_c)->Dictionary:return {"terminal":"bad" if invalid else false,"shop":false,"next_stage":2,"upgrades":0,"coins":0.,"heal":0.}
var g
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func snapshot()->Dictionary:return {"state":g.state,"xp":g.xp,"level":g.level,"pending":g.upgrade_pending,"coins":g.build.coins,"fraction":g.build.coin_fraction,"pickups":g.pickups.duplicate(true),"bullets":g.bullets.duplicate(true),"epoch":g.effects.epoch,"sequence":g.effect_sequence,"rng":[g.rng.state,g.loot_rng.state,g.shop_rng.state]}
func setup(mode:String)->void:
 g._title();g._select_mode(mode);g._start_run(3604);g.build.weapons=["return_disc"];g.build.items={"scavenger_reel":1};g._recompute();g.weapon_clocks=[999.];g.player_pos=Vector2(300,300);g.hero.position=g.player_pos;g.stats.pickup_radius=0.;g.stats.bullet_speed=100.;g.stats.coin_bonus=0.;g.build.coins=0;g.build.coin_fraction=0.;g.xp=0;g.spawn_clock=999.;g.combat_frame.area=g.config.arena
func shot()->Dictionary:return {"pos":Vector2(400,300),"velocity":Vector2.LEFT*100,"life":2.,"damage":1.,"pierce":99,"hit":[],"weapon":"return_disc","slot":0,"returning":true,"outbound_left":0.,"scavenger":{"radius":18.,"remaining":3,"maximum":3,"sources":["normal","energy"]}}
func floor_pickup()->Dictionary:return {"pos":Vector2(350,300),"xp":1,"coins":1}
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode);var d:Dictionary=shot();g.bullets=[d];g.pickups=[floor_pickup(),floor_pickup(),floor_pickup(),floor_pickup()]
  Runtime.step(g.combat_frame,.8);ck(g.xp==3 and g.build.coins==3 and g.pickups.size()==1,"three remote before settlement "+mode)
  var policy:=Policy.new();var outcome:String=Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)
  ck(outcome=="next" and g.xp==4 and g.build.coins==4,"settlement only remaining floor reward "+mode)
  ck(g.pickups.is_empty() and g.bullets.is_empty() and g.effect_visuals.is_empty(),"settlement clears persistent world, no sweep cargo "+mode)
  var stable:Dictionary=snapshot();ck(Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)=="ignored" and snapshot()==stable,"repeat transition cannot credit twice "+mode)
  setup(mode);d=shot();g.bullets=[d];g.pickups=[floor_pickup()];policy.invalid=true;stable=snapshot()
  ck(Flow.settle(g.combat,g.run,policy,g.config,g.effects,g.encounters)=="invalid" and snapshot()==stable,"malformed policy cannot mutate new metadata/world "+mode)
  for modal in ["pause","inventory"]:
   setup(mode);d=shot();g.bullets=[d];g.pickups=[floor_pickup()];g._on_intent(modal,{});stable=snapshot();g._process(.5)
   ck(snapshot()==stable,"supported modal does not advance or collect "+mode+modal)
   g._on_intent("resume" if modal=="pause" else "close_inventory",{});ck(d.scavenger.remaining==3 and g.xp==0,"resume no replay "+mode+modal)
  for terminal in [false,true]:
   setup(mode);d=shot();g.bullets=[d];g.pickups=[floor_pickup()];g._finish(terminal);var before_xp:int=g.xp;var quota:int=d.scavenger.remaining;g._process(.1)
   ck(g.xp==before_xp and d.scavenger.remaining==quota,"supported terminal update no remote reward "+mode+str(terminal))
   g._on_intent("retry",{});ck(g.bullets.is_empty() and g.pickups.is_empty() and g.xp==0 and not g.build.items.has("scavenger_reel"),"retry fresh world no retained module/cargo "+mode)
  setup(mode);d=shot();g.bullets=[d];g.pickups=[floor_pickup()];g._title();g._start_run(3605)
  ck(g.bullets.is_empty() and g.pickups.is_empty() and g.xp==0,"title/newrun cannot credit old floor "+mode)
 setup("rooms");var d:Dictionary=shot();g.bullets=[d];g.pickups=[floor_pickup()];g._begin_room_clear()
 ck(g.state=="room_clear" and g.bullets.is_empty() and g.pickups.size()==1 and g.xp==0,"room clear deletes discs but not floor cargo")
 var before:Dictionary=snapshot();g._enter_field(9123);ck(g.xp==before.xp and g.build.coins==before.coins,"field layout never awards separate rewards")
 var teardown=preload("<QA_ROOT>/final-gate/packed-harness/audio_teardown.gd").new();teardown.prepare([g]);g.queue_free();await process_frame;await teardown.finish(self)
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled shared settlement with policy stub and supported controller modal/terminal/reset/field seams; not ordinary progression or full mode policy coverage."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
