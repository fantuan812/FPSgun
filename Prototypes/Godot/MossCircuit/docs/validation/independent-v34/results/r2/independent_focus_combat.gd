extends SceneTree
## Independent controlled actual acquisition/hit/snapshot checks; not ordinary gameplay.
const Runtime=preload("res://scripts/gameplay/combat_runtime.gd")
const Rules=preload("res://scripts/rules.gd")
const IDS=["rivet_gun","scrap_shotgun","rail_lance","orbit_saw","return_disc","shock_mortar","cryo_sprayer","bankshot_driver"]
const RANGE={"rivet_gun":500.0,"scrap_shotgun":300.0,"rail_lance":650.0,"orbit_saw":105.0,"return_disc":330.0,"shock_mortar":500.0,"cryo_sprayer":190.0,"bankshot_driver":900.0}
var g
var checks:=0
var failures:Array=[]
var hits:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func close(a:float,b:float,label:String)->void:ck(absf(a-b)<.0001,label+" got="+str(a)+" expected="+str(b))
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
    if str(k)!="sprite":d[k]=clean(v[k])
   return d
  TYPE_OBJECT:return "<object>"
  _:return v
func capture(kind:String,data:Dictionary)->bool:
 if kind=="hit":hits.append(data.duplicate(true))
 return g._effect_event(kind,data)
func setup(mode:String,ids:Array,items:Dictionary={})->void:
 g._title();g._select_mode(mode);g._start_run(3402)
 g.build.weapons=ids.duplicate();g.build.items=items.duplicate(true);g._recompute()
 g.weapon_clocks=[]
 for _id in ids:g.weapon_clocks.append(999.0)
 g.elapsed=10.0;g.spawn_clock=999;g.hurt_clock=0;g.player_pos=Vector2(g.config.arena.width*.5,g.config.arena.height*.5)
 g.hero.position=g.player_pos;g.combat_frame.area=g.config.arena;g.weapon_combat.effect_event=capture;hits.clear()
 ck(g.combat.focus_enemy_id==0,"fresh setup AUTO")
func spawn(offset:Vector2,kind:String="crawler")->Dictionary:
 var e:Dictionary=g._spawn_kind(kind,g.player_pos+offset);e.hp=1000.0;e.max_hp=1000.0;e.anim_hp=1000.0;e.speed=0.0;e.cooldown_left=999.0
 return e
func advance(dt:float)->void:
 for b in g.bullets:
  if b.get("behavior","")=="field_bankshot":g.weapon_combat.advance_bankshot(b,dt)
  elif b.weapon=="return_disc":g.weapon_combat.advance_disc(b,dt)
  else:g.weapon_combat.advance_bullet(b,dt)
func fire(id:String,slot:int=0)->void:g._fire_weapon(id,slot)
func aimed(id:String,target:Vector2,label:String)->void:
 if id=="shock_mortar":ck(g.pending_blasts.size()==1 and g.pending_blasts[0].pos==target,label+" actual mortar fixed center")
 elif id=="cryo_sprayer":
  var cones:Array=g.effect_visuals.filter(func(v):return v.kind=="cryo_cone")
  ck(cones.size()==1,label+" actual cone")
  if not cones.is_empty():ck(cones[0].direction.is_equal_approx((target-g.player_pos).normalized()),label+" cone oriented to target")
 elif id=="orbit_saw":
  ck(g.weapon_rig.last_shot.pose.direction.x>.9,label+" Orbit direction unchanged")
 else:
  ck(not g.bullets.is_empty(),label+" actual launch")
  if g.bullets.is_empty():return
  var pose:Dictionary=g.weapon_rig.last_shot.pose;var delta:Vector2=target-pose.muzzle
  ck(delta.normalized().dot(pose.direction)>.9999,label+" actual launched pose aims at target")
  if id!="scrap_shotgun":ck(g.bullets[0].velocity.normalized().dot(pose.direction)>.9999,label+" stored launch direction")
func snapshot_flight(mode:String,id:String,change:bool)->Dictionary:
 setup(mode,[id],{"bounce_guide":1} if id=="bankshot_driver" else {})
 var first:Dictionary=spawn(Vector2(110,0));var second:Dictionary=spawn(Vector2(0,150))
 g.combat.focus_enemy_id=first.id;fire(id)
 var before:Variant=clean({"bullets":g.bullets,"blasts":g.pending_blasts})
 if change:g.combat.focus_enemy_id=second.id
 ck(before==clean({"bullets":g.bullets,"blasts":g.pending_blasts}),"focus field cannot mutate live shots "+id)
 if id=="shock_mortar":g._update_mortars(.6)
 else:
  for _i in range(5):advance(.08)
 return clean({"bullets":g.bullets,"blasts":g.pending_blasts,"hp":[first.hp,second.hp],"hits":hits})
func guide_trace(mode:String,marked_far:bool)->Dictionary:
 setup(mode,["bankshot_driver"],{"bounce_guide":1})
 # Same actual launch toward the nearby left field boundary, then two valid guide candidates.
 g.player_pos=Vector2(90,300);g.hero.position=g.player_pos
 var launch:Dictionary=spawn(Vector2(-60,0));var nearest:Dictionary=spawn(Vector2(30,-90));var farther:Dictionary=spawn(Vector2(230,100))
 g.combat.focus_enemy_id=launch.id;fire("bankshot_driver")
 ck(g.bullets.size()==1,"actual guide launch")
 if g.bullets.is_empty():return {}
 var b:Dictionary=g.bullets[0]
 launch.hp=0 # Both runs remove launch target before the same first-boundary event.
 g.combat.focus_enemy_id=farther.id if marked_far else 0
 advance(.25)
 ck(b.reflections==1 and b.guide_checked and b.guided_once,"actual first boundary guide occurred")
 var boundary:Array=g.effect_visuals.filter(func(v):return v.kind=="bankshot_contact")
 ck(boundary.size()==1 and boundary[0].guided,"actual guided cue exists")
 if not boundary.is_empty():ck(boundary[0].direction.dot((nearest.pos-boundary[0].pos).normalized())>.9999,"Guide uses nearest recipient, not world focus")
 return clean({"bullet":b,"boundary":boundary,"hp":[nearest.hp,farther.hp],"hits":hits})
func _initialize()->void:call_deferred("run")
func run()->void:
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);g.set_process(false)
 ck(g.catalog.weapons.map(func(w):return w.id)==IDS,"exact eight weapons retained in catalog order")
 for mode in ["arena","rooms"]:
  for id in IDS:
   for status in ["live","dead","removed","out-of-range"]:
    setup(mode,[id]);var near:Dictionary=spawn(Vector2(55,0));var far:Dictionary=spawn(Vector2(0,80 if id=="orbit_saw" else 150))
    g.combat.focus_enemy_id=far.id
    if status=="dead":far.hp=0
    elif status=="removed":g.enemies.erase(far)
    elif status=="out-of-range":far.pos=g.player_pos+Vector2(0,float(RANGE[id])+1.0)
    var clocks:Variant=g.weapon_clocks.duplicate();var seq:int=g.effect_sequence
    fire(id);aimed(id,far.pos if status=="live" and id!="orbit_saw" else near.pos,mode+" "+id+" "+status)
    ck(g.weapon_clocks==clocks,"direct firing retains old scheduler ownership "+id)
    if id=="orbit_saw":
     close(near.hp,980.0,"Orbit near radial unaffected")
     if status=="live":close(far.hp,980.0,"Orbit focused actor no special bonus")
    elif id=="cryo_sprayer":
     if status=="live":close(near.hp,1000,"Cryo focus changes orientation away from near")
     else:close(near.hp,991,"Cryo fallback actual hit")
    if status=="out-of-range":ck(g.combat.focus_enemy_id==far.id,"living out of range remains marked")
   # Exact old AUTO ties: first array entry vs distance/ID-sorted special weapons.
   setup(mode,[id]);var high:Dictionary=spawn(Vector2(0,80));var low:Dictionary=spawn(Vector2(80,0));high.id=20;low.id=10
   fire(id);aimed(id,low.pos if id in ["cryo_sprayer","bankshot_driver"] else high.pos,mode+" AUTO tie "+id)
   # Mark overrides tie preference without changing the actor array.
   setup(mode,[id]);high=spawn(Vector2(0,80));low=spawn(Vector2(80,0));high.id=20;low.id=10;g.combat.focus_enemy_id=high.id
   fire(id);aimed(id,high.pos,mode+" marked tie "+id);ck(g.enemies[0].id==20 and g.enemies[1].id==10,"no enemy reorder "+id)
  # Range decisions use the old exact comparison, with current bonus and no shared maximum.
  for id in IDS:
   if id=="orbit_saw":continue
   for bonus in [0.0,.25]:
    for extra in [-.01,0.0,.00005,.01]:
     setup(mode,[id]);g.stats.range_bonus=bonus
     var near:Dictionary=spawn(Vector2(0,50));var far:Dictionary=spawn(Vector2(float(RANGE[id])*(1+bonus)+extra,0));g.combat.focus_enemy_id=far.id
     # Compute from the actual Vector2 value; float32 representability is explicit.
     var distance:float=far.pos.distance_to(g.player_pos);var bound:float=float(RANGE[id])*(1+bonus)+(0.0001 if id in ["cryo_sprayer","bankshot_driver"] else 0.0)
     fire(id);aimed(id,far.pos if distance<=bound else near.pos,mode+" range "+id+" "+str(bonus)+" "+str(extra))
  # Cryo focused far target must not become first in primary victim iteration.
  setup(mode,["cryo_sprayer"]);var far:Dictionary=spawn(Vector2(120,0));var near:Dictionary=spawn(Vector2(60,0));var tied:Dictionary=spawn(Vector2(60,0));far.id=30;near.id=20;tied.id=10;g.combat.focus_enemy_id=30
  fire("cryo_sprayer");ck(hits.map(func(h):return h.target)==[10,20,30],"Cryo keeps distance/ID victim order, not chosen-first")
  # Earlier immediate kill invalidates focus before later slot in SAME shared step.
  setup(mode,["orbit_saw","shock_mortar"]);near=spawn(Vector2(60,0));far=spawn(Vector2(0,80));far.hp=1.0;g.combat.focus_enemy_id=far.id;g.weapon_clocks=[0.0,0.0]
  Runtime.step(g.combat_frame,0.0);ck(g.pending_blasts.size()==1 and g.pending_blasts[0].pos==near.pos,"same-step dead focus fallback before death cleanup");ck(g.combat.focus_enemy_id==0,"dead focus pruned by shared step")
  for id in ["rivet_gun","scrap_shotgun","rail_lance","return_disc","shock_mortar","bankshot_driver"]:
   ck(snapshot_flight(mode,id,false)==snapshot_flight(mode,id,true),"already launched fields/hits unaffected by later focus "+id)
  ck(guide_trace(mode,false)==guide_trace(mode,true),"Bounce Guide autonomous despite live marked alternative")
  # Idle override only eligible directional copies; no timer/generation/last-shot reset.
  setup(mode,["cryo_sprayer","rail_lance","orbit_saw","bankshot_driver"])
  near=spawn(Vector2(60,0));far=spawn(Vector2(0,500));g._sync_weapon_rig()
  for i in range(4):g.weapon_rig.slots[i].age=.2+float(i)*.1
  var saved:Dictionary={"clock":g.weapon_rig.visible_clock,"generation":g.weapon_rig.generation,"last":g.weapon_rig.last_shot.duplicate(true),"ages":g.weapon_rig.slots.map(func(s):return s.age)}
  g.combat.focus_enemy_id=far.id;g._sync_weapon_rig()
  for i in range(4):
   var target:Vector2=far.pos if i in [1,3] else near.pos
   var pose:Dictionary=g.weapon_rig.slots[i].pose
   ck((target-pose.muzzle).normalized().dot(pose.direction)>.9999,"idle per-copy range eligibility slot"+str(i))
  ck(saved=={"clock":g.weapon_rig.visible_clock,"generation":g.weapon_rig.generation,"last":g.weapon_rig.last_shot.duplicate(true),"ages":g.weapon_rig.slots.map(func(s):return s.age)},"focus idle update preserves rig chronology")
  # Primary tier and brace still apply to selected target; derived Arc uses its old nearest target.
  setup(mode,["rivet_gun"],{"arc_relay":1});g.build.weapon_temper=[1]
  near=spawn(Vector2(0,40));far=spawn(Vector2(100,0),"charger");var adjacent:Dictionary=spawn(Vector2(100,50),"charger")
  far.ai_state="warning";far.attack="charge";far.aim=Vector2.LEFT;far.warning_left=999
  adjacent.ai_state="warning";adjacent.attack="charge";adjacent.aim=Vector2.LEFT;adjacent.warning_left=999
  g.combat.focus_enemy_id=far.id;fire("rivet_gun");advance(.3)
  close(far.hp,988,"focused tempered24 guarded primary12");close(adjacent.hp,995.2,"Arc uses old closest recipient and reduced initiating4.8");close(near.hp,1000,"near distractor not new Arc focus recipient")
  ck(hits.size()==1 and hits[0].target==far.id and hits[0].damage==12,"one primary event unchanged")
  # A physically intervening unmarked enemy still intercepts a selected farther shot.
  setup(mode,["rivet_gun"]);near=spawn(Vector2(70,0));far=spawn(Vector2(140,0));g.combat.focus_enemy_id=far.id;fire("rivet_gun");advance(.4)
  close(near.hp,985,"ordinary interceptor actual hit");close(far.hp,1000,"priority does not grant piercing");ck(hits.size()==1 and hits[0].target==near.id,"intercept attribution unchanged")
  await process_frame
 g.queue_free();await process_frame
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Controlled actual eight-path acquisition/range/tie, same-step death, snapshot, tier/brace/Arc/interception. No ordinary play, balance or platform certification."}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
