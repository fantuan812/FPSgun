extends SceneTree
# Independent contract oracle; expected booleans and numeric amounts are not obtained from brace().
const Defense=preload("res://scripts/gameplay/primary_defense.gd")
const AI=preload("res://scripts/enemy_ai.gd")
const OLD_ROSTER_SHA="f7a0ebd9273c2627f657a1a66099b2a56028ee5ec5e4acc719730bd7c080d31c"
var checks:=0
var failures:Array=[]
func ck(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func eq(actual:float,expected:float,label:String)->void:ck(is_equal_approx(actual,expected),label+" actual="+str(actual)+" expected="+str(expected))
func host(pos:Vector2=Vector2.ZERO)->Dictionary:
 return {"id":71,"kind":"charger","behavior":"charge","boss":false,"hp":42.0,"scale":1.2,"pos":pos,"aim":Vector2.RIGHT,"ai_state":"warning","attack":"charge","brace_degrees":120.0,"brace_multiplier":.5}
func entry(config:Dictionary,id:String)->Dictionary:
 for e in config.enemies:
  if e.id==id:return e
 return {}
func _initialize()->void:
 var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
 ck(AI.validate(config).is_empty(),"authored encounters validate")
 ck(config.enemies.map(func(e):return e.id)==["crawler","charger","spitter","flanker","brood_keeper","boss_warden","boss_core"],"exact seven IDs and ordering")
 var charger:Dictionary=entry(config,"charger")
 ck(charger.get("brace_degrees")==120 and charger.get("brace_multiplier")==.5,"frozen authored120/.5")
 var masked:Dictionary=config.duplicate(true);var old:Dictionary=entry(masked,"charger")
 old.erase("brace_degrees");old.erase("brace_multiplier")
 old.description="Locks direction, warns, then charges in a straight line."
 old.tell="Orange line marks the locked dash route for 0.65 s."
 old.dodge="Step sideways; warning and recovery are contact-safe."
 for key in ["behavior","description","tell","dodge","pulse_inner_radius","pulse_outer_radius","pulse_warning"]:entry(masked,"brood_keeper").erase(key)
 ck(JSON.stringify(masked).sha256_text()==OLD_ROSTER_SHA,"exact old roster/waves outside reviewed five charger and historical seven Brood fields")
 for e in config.enemies:
  if e.id!="charger":ck(not e.has("brace_degrees") and not e.has("brace_multiplier"),"no other host opt-in "+e.id)
 for field in ["brace_degrees","brace_multiplier"]:
  for bad_value in [null,true,false,"120",[],{},0,-1,NAN,INF,-INF]:
   var bad:Dictionary=charger.duplicate(true);bad[field]=bad_value
   ck(not Defense.validate_entry(bad).is_empty(),"reject malformed "+field+" type"+str(typeof(bad_value))+" "+str(bad_value))
   var whole:Dictionary=config.duplicate(true);entry(whole,"charger")[field]=bad_value
   ck(not AI.validate(whole).is_empty(),"startup rejects "+field+" "+str(bad_value))
  var missing:Dictionary=charger.duplicate(true);missing.erase(field)
  ck(not Defense.validate_entry(missing).is_empty(),"reject unpaired "+field)
 for degrees in [180,181,360]:
  var bad:Dictionary=charger.duplicate(true);bad.brace_degrees=degrees;ck(not Defense.validate_entry(bad).is_empty(),"reject excessive degrees "+str(degrees))
 for factor in [1,1.01,2]:
  var bad:Dictionary=charger.duplicate(true);bad.brace_multiplier=factor;ck(not Defense.validate_entry(bad).is_empty(),"reject non-reduction "+str(factor))
 for mutation in [{"id":"crawler"},{"behavior":"chase"},{"boss":true}]:
  var bad:Dictionary=charger.duplicate(true);bad.merge(mutation,true);ck(not Defense.validate_entry(bad).is_empty(),"reject unauthorized host "+str(mutation))
 var absent:Dictionary=charger.duplicate(true);absent.erase("brace_degrees");absent.erase("brace_multiplier")
 ck(Defense.validate_entry(absent).is_empty(),"absent pair retains legacy data")
 for numeric in [{"brace_degrees":120,"brace_multiplier":.5},{"brace_degrees":120.0,"brace_multiplier":.5}]:
  var good:Dictionary=charger.duplicate(true);good.merge(numeric,true);ck(Defense.validate_entry(good).is_empty(),"valid numeric JSON representation")
 for center in [Vector2(640,360),Vector2(480,270)]:
  for rotation in range(8):
   var e:Dictionary=host(center);var facing:=Vector2.from_angle(rotation*PI/4);e.aim=facing*7
   for degrees in [-180.0,-90.0,-60.01,-60.0,-30.0,0.0,30.0,60.0,60.01,90.0,180.0]:
    var toward:=facing.rotated(deg_to_rad(degrees));var origin:Vector2=center+toward*100
    var before:Dictionary=e.duplicate(true);var expected:float=7.5 if absf(degrees)<=60 else 15.0
    eq(Defense.resolve(e,15,origin,toward*11),expected,"8-way inclusive front "+str(center)+" r"+str(rotation)+" a"+str(degrees))
    ck(e==before,"pure resolve leaves target unchanged")
   for radius in [0.0,19.199,19.19995,19.2,19.201]:
    var source:Vector2=center+facing*radius
    var expected:float=15.0 if radius<19.1999 else 7.5
    eq(Defense.resolve(e,15,source,facing),expected,"strict interior/strip "+str(center)+" r"+str(rotation)+" d"+str(radius))
   var view:Dictionary=Defense.brace(e)
   ck(not view.is_empty(),"active brace exposed")
   if not view.is_empty():
    ck(view.direction.is_equal_approx(facing),"authoritative 2D aim normalized")
    eq(view.half_angle,PI/3,"half angle radians")
    eq(view.collision_radius,19.2,"old collision radius")
    eq(view.visual_radius,38.4,"visual indicator twice collision radius only")
    eq(view.multiplier,.5,"active factor")
    view.multiplier=.125;view.direction=Vector2.DOWN
    ck(e.brace_multiplier==.5 and e.aim.is_equal_approx(facing*7),"brace view detached")
 # Geometry and host invalidation are full fallback, never a new event or exception.
 for mutation in [{"hp":0},{"hp":-2},{"kind":"crawler"},{"kind":"boss_warden"},{"boss":true},{"behavior":"ranged"},{"ai_state":"move"},{"ai_state":"charging"},{"ai_state":"recover"},{"attack":"ring"},{"aim":Vector2.ZERO},{"aim":Vector2(INF,0)},{"aim":Vector2(NAN,1)},{"pos":Vector2(INF,0)},{"scale":0},{"scale":-1},{"scale":INF},{"brace_degrees":0},{"brace_degrees":180},{"brace_multiplier":1},{"brace_multiplier":NAN}]:
  var e:Dictionary=host();e.merge(mutation,true)
  ck(Defense.brace(e).is_empty(),"invalid/inactive cue hidden "+str(mutation))
  eq(Defense.resolve(e,15,Vector2(100,0),Vector2.RIGHT),15,"inactive full damage "+str(mutation))
 for direction in [Vector2.ZERO,Vector2(.0000005,0),Vector2(.000001,0),Vector2(INF,1),Vector2(NAN,0)]:
  eq(Defense.resolve(host(),15,Vector2(100,0),direction),15,"invalid/tiny direction full "+str(direction))
 eq(Defense.resolve(host(),15,Vector2(100,0),Vector2(.000002,0)),7.5,"above direction threshold normalized")
 for p in [Vector2(INF,0),Vector2(NAN,0)]:eq(Defense.resolve(host(),15,p,Vector2.RIGHT),15,"invalid source full")
 # Exactly construct representable strict-interior threshold rather than assuming decimal Vector2 is exact.
 var e:Dictionary=host();e.scale=(16.0+.0001)/16.0
 eq(Defense.resolve(e,15,Vector2(16,0),Vector2.RIGHT),7.5,"strict threshold equality remains directional")
 for nominal in [0.0,.5,7.25,15.0,30.0,1000.0]:eq(Defense.resolve(host(),nominal,Vector2(100,0),Vector2.RIGHT),nominal*.5,"fraction/nominal overkill no round or HP clamp")
 var result:Dictionary={"checks":checks,"failures":failures,"scope":"Independent fixed contract geometry/data oracle; no real combat/native/balance claim"}
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  ")+"\n")
 print(JSON.stringify(result));quit(0 if failures.is_empty() else 1)
