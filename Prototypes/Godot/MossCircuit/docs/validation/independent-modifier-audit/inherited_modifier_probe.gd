extends SceneTree
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
var g
var checks:=0
var failures:Array=[]
var observed:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func near(a:float,b:float)->bool:return absf(a-b)<.001
func _initialize()->void:call_deferred("run")
func setup(mode:String,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(433);g.build.items=items;g._recompute();g.elapsed=10;g.combat_frame.area=g.config.arena;g.weapon_clocks[0]=999
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 for mode in ["arena","rooms"]:
  setup(mode);g.upgrade_pending=1;g._show_upgrades();g.choices=[g.config.upgrades.filter(func(u):return u.id=="haste")[0]];var description:String=g.choices[0].description;g._take_upgrade(0,g.choice_generation)
  var e:Dictionary=g._spawn_kind("crawler",g.player_pos+Vector2(100,0));e.hp=500;e.anim_hp=500;g.weapon_clocks[0]=0;Runtime.step(g.combat_frame,0.0)
  check(g.build.levels.haste==1 and near(g.weapon_clocks[0],.4/1.15),mode+" actual Rapid rate15");check(not near(g.weapon_clocks[0],.4*.85),mode+" not advertised interval15");var clock:float=g.weapon_clocks[0]
  setup(mode,{"power_coil":1,"echo_chamber":1});e=g._spawn_kind("crawler",g.player_pos+Vector2(100,0));e.hp=500;e.anim_hp=500
  g.effects.echo_hits=4;g._fire_weapon("rivet_gun",0)
  for b in g.bullets:g._advance_bullet(b,.4)
  check(near(e.hp,500-17.25-12),mode+" PowerRivet17.25 fixedEcho12")
  observed.append({"mode":mode,"rapid_description":description,"rapid_actual_clock":clock,"rapid_advertised_clock":.4*.85,"powered_primary":17.25,"fixed_echo":500-e.hp-17.25})
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"observed":observed,"scope":"controlled actual runtime chooser/scheduledRivet and primaryfireEcho; historical wording attribution"};print(JSON.stringify(result));var args:=OS.get_cmdline_user_args();if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 quit(0 if failures.is_empty() else 1)
