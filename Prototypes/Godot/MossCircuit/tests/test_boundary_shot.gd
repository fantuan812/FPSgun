extends SceneTree
const Shot=preload("res://scripts/gameplay/boundary_shot.gd")
var checks:=0
var failures:Array=[]
var hits:Array=[]
var events:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label)
func hit(enemy:Dictionary,b:Dictionary)->void:
 hits.append(enemy.id);enemy.hp-=b.damage
func event(data:Dictionary)->void:events.append(data)
func foe(id:int,pos:Vector2,hp:float=1000.0)->Dictionary:return {"id":id,"pos":pos,"hp":hp,"scale":1.0}
func fresh(pos:Vector2,dir:Vector2,area:Dictionary,budget:float=900.0,pierce:int=0,guide:bool=false)->Dictionary:
 hits.clear();events.clear();return Shot.spawn(pos,dir,area,18.0,470.0,budget,pierce,guide)
func _initialize()->void:call_deferred("run")
func run()->void:
 for area in [{"width":1440,"height":960},{"width":960,"height":640}]:
  var b:Dictionary=fresh(Vector2(100,100),Vector2.LEFT,area)
  check(is_equal_approx(b.life,900.0/470.0),"snapshot TTL")
  var enemies:Array=[foe(1,Vector2(50,100)),foe(2,Vector2(20,100))]
  Shot.advance(b,1.0,enemies,hit,event)
  check(hits==[1,2],"one quota per leg, reflection re-arms")
  check(b.reflections==1 and b.leg_hits==[2],"separate reflection and new leg hit set")
  check(is_equal_approx(b.travelled,470.0) and is_equal_approx(b.distance_left,430.0),"finite total path never resets")
  check(is_equal_approx(b.life,(900.0-470.0)/470.0),"TTL and path decrease together")
  b=fresh(Vector2(0,100),Vector2.LEFT,area);enemies=[foe(3,Vector2(8,100))]
  var original:String=JSON.stringify(b);Shot.advance(b,0,enemies,hit,event)
  check(JSON.stringify(b)==original and hits.is_empty() and events.is_empty(),"zero dt inert")
  Shot.advance(b,.1,enemies,hit,event)
  check(b.reflections==1 and hits==[3],"initial outward contact before first ever overlap hit")
  b=fresh(Vector2(100,100),Vector2(-1,-1),area)
  Shot.advance(b,.5,[],hit,event)
  check(b.reflections==1 and events.size()==1 and b.dx>0 and b.dy>0,"corner combined")
  b=fresh(Vector2(-10,-15),Vector2.ZERO,area)
  check(b.pos==Vector2.ZERO and b.dx==1 and b.dy==0,"clamped origin and zero aim fallback")
  b=fresh(Vector2(100,100),Vector2.LEFT,area,100)
  Shot.advance(b,1000,[],hit,event)
  check(b.life==0 and b.end_reason=="path_budget" and b.reflections==0,"budget equality grants no free reflection")
  b=fresh(Vector2(10,100),Vector2.LEFT,area,5000)
  Shot.advance(b,1000,[],hit,event)
  check(b.reflections==2 and b.end_reason=="third_boundary" and events.size()==3,"third boundary absorbs, no fourth leg")
  b=fresh(Vector2(100,100),Vector2.LEFT,area,900,0,true)
  enemies=[foe(4,Vector2(50,50)),foe(5,Vector2(50,150))]
  Shot.advance(b,.3,enemies,hit,event)
  check(b.guide_checked and b.guided_once and b.dx>0 and b.dy<0,"first guide distance tie chooses ID")
  b=fresh(Vector2(100,100),Vector2.LEFT,area,900,5)
  enemies=[]
  for i in range(8):enemies.append(foe(i+10,Vector2(90-i*9,100)))
  Shot.advance(b,.19,enemies,hit,event)
  check(hits.size()==6 and b.leg_hits.size()==6,"quota cap6")
  # First hit overlaps reflection point: no instantaneous duplicate on the reflected leg.
  b=fresh(Vector2(70,100),Vector2.LEFT,area)
  enemies=[foe(50,Vector2(8,100))]
  Shot.advance(b,.3,enemies,hit,event)
  check(hits==[50] and enemies[0].hp==982,"overlap carry prevents immediate double hit")
  # Static geometry partitioning, with poses and callback behavior held fixed.
  var whole:Dictionary=fresh(Vector2(100,100),Vector2(-1,-.25),area)
  Shot.advance(whole,1.5,[],Callable(),Callable())
  var parts:Dictionary=fresh(Vector2(100,100),Vector2(-1,-.25),area)
  for i in range(150):Shot.advance(parts,.01,[],Callable(),Callable())
  check(whole.pos.distance_to(parts.pos)<.001 and absf(whole.distance_left-parts.distance_left)<.001 and whole.reflections==parts.reflections,"frozen geometry partition parity")
 var endpoint:Dictionary=fresh(Vector2(860,320),Vector2.RIGHT,{"width":960,"height":640},1260)
 Shot.advance(endpoint,100.0/470.0,[],hit,event)
 Shot.advance(endpoint,960.0/470.0,[],hit,event)
 check(endpoint.reflections==2 and endpoint.x==0 and endpoint.dx>0,"floating exact endpoint reflects within spatial tolerance")
 check(absf(endpoint.travelled-1060)<.000001 and absf(endpoint.distance_left-200)<.000001,"endpoint snap grants no extra budget")
 var spent:Dictionary=fresh(Vector2(860,320),Vector2.RIGHT,{"width":960,"height":640},1060)
 Shot.advance(spent,100.0/470.0,[],hit,event);Shot.advance(spent,960.0/470.0,[],hit,event)
 check(spent.life==0 and spent.reflections==1 and spent.end_reason=="path_budget","tolerant endpoint still cannot reflect on exhausted budget")
 check(Shot.spawn(Vector2.ZERO,Vector2.RIGHT,{"width":0,"height":10},18,470,900,0,false).is_empty(),"invalid field rejected")
 check(Shot.spawn(Vector2.ZERO,Vector2.RIGHT,{"width":960,"height":640},18,0,900,0,false).is_empty(),"zero speed rejected")
 print(JSON.stringify({"boundary_shot_checks":checks,"failures":failures,"scope":"initial pure geometry tests only; runtime/art/native not integrated"}))
 quit(0 if failures.is_empty() else 1)
