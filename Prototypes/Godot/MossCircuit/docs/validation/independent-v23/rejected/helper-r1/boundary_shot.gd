extends RefCounted
## Rectangular-field trajectory only. No mode, UI, RNG, damage ownership or arbitrary colliders.
const EPS:=0.0001
const DIR_EPS:=0.000000001
const MAX_REFLECTIONS:=2
const MAX_QUOTA:=6
const MAX_EVENTS_PER_ADVANCE:=24

static func spawn(origin:Vector2,direction:Vector2,area:Dictionary,damage:float,speed:float,budget:float,pierce_bonus:int,guide:bool,slot:int=0)->Dictionary:
 var width:float=float(area.get("width",0));var height:float=float(area.get("height",0))
 if not is_finite(width) or not is_finite(height) or width<=EPS or height<=EPS:return {}
 if not origin.is_finite() or not direction.is_finite() or not is_finite(damage) or not is_finite(speed) or not is_finite(budget):return {}
 if damage<=0 or speed<=0 or budget<=0:return {}
 var dx:float=direction.x;var dy:float=direction.y;var length:float=sqrt(dx*dx+dy*dy)
 if length<=DIR_EPS:dx=1.0;dy=0.0
 else:dx/=length;dy/=length
 # Scalar positions preserve sub-pixel accumulation across tiny dt at large field coordinates.
 var x:float=clampf(float(origin.x),0.0,width);var y:float=clampf(float(origin.y),0.0,height)
 return {"behavior":"field_bankshot","weapon":"bankshot_driver","slot":slot,"pos":Vector2(x,y),"velocity":Vector2(dx,dy)*speed,"x":x,"y":y,"dx":dx,"dy":dy,"field_width":width,"field_height":height,"speed":speed,"damage":damage,"life":budget/speed,"launch_life":budget/speed,"distance_left":budget,"launch_budget":budget,"travelled":0.0,"leg_quota":clampi(1+pierce_bonus,1,MAX_QUOTA),"leg_hits":[],"blocked_overlap":[],"reflections":0,"since_reflection":0.0,"guide":guide,"guide_checked":false,"guided_once":false,"total_hits":0,"end_reason":""}

static func _sync(b:Dictionary)->void:
 b.pos=Vector2(b.x,b.y);b.velocity=Vector2(b.dx,b.dy)*float(b.speed)

static func _expire(b:Dictionary,reason:String)->void:
 b.life=0.0;b.end_reason=reason

static func _radius(enemy:Dictionary)->float:
 return 16.0*float(enemy.get("scale",1.0))

static func _contains(b:Dictionary,enemy:Dictionary)->bool:
 var ox:float=float(enemy.pos.x)-float(b.x);var oy:float=float(enemy.pos.y)-float(b.y)
 var radius:float=_radius(enemy)+EPS
 return ox*ox+oy*oy<=radius*radius

static func _release_blocks(b:Dictionary,enemies:Array)->void:
 var kept:Array=[]
 for enemy in enemies:
  if enemy.hp>0 and enemy.id in b.blocked_overlap and _contains(b,enemy):kept.append(enemy.id)
 b.blocked_overlap=kept

static func _carry_at_reflection(b:Dictionary,enemies:Array)->void:
 var kept:Array=[]
 for enemy in enemies:
  if enemy.hp>0 and (enemy.id in b.leg_hits or enemy.id in b.blocked_overlap) and _contains(b,enemy):kept.append(enemy.id)
 b.blocked_overlap=kept;b.leg_hits.clear()

static func _boundary(b:Dictionary)->Dictionary:
 var tx:=INF;var ty:=INF;var nx:=0;var ny:=0
 if float(b.dx)>DIR_EPS:tx=maxf(0.0,(float(b.field_width)-float(b.x))/float(b.dx));nx=1
 elif float(b.dx)<-DIR_EPS:tx=maxf(0.0,-float(b.x)/float(b.dx));nx=-1
 if float(b.dy)>DIR_EPS:ty=maxf(0.0,(float(b.field_height)-float(b.y))/float(b.dy));ny=1
 elif float(b.dy)<-DIR_EPS:ty=maxf(0.0,-float(b.y)/float(b.dy));ny=-1
 var distance:float=minf(tx,ty)
 return {"distance":distance,"nx":nx if tx<=distance+EPS else 0,"ny":ny if ty<=distance+EPS else 0}

static func _contacts(b:Dictionary,enemies:Array,distance:float)->Array:
 var result:Array=[]
 for enemy in enemies:
  if enemy.hp<=0 or enemy.id in b.leg_hits or enemy.id in b.blocked_overlap:continue
  var ox:float=float(enemy.pos.x)-float(b.x);var oy:float=float(enemy.pos.y)-float(b.y)
  var radius:float=_radius(enemy);var projected:float=ox*float(b.dx)+oy*float(b.dy)
  var perpendicular_sq:float=maxf(0.0,ox*ox+oy*oy-projected*projected)
  if perpendicular_sq>pow(radius+EPS,2):continue
  var half_chord:float=sqrt(maxf(0.0,radius*radius-perpendicular_sq))
  if projected+half_chord < -EPS:continue
  var first:float=maxf(0.0,projected-half_chord)
  if first<=distance+EPS:result.append({"enemy":enemy,"distance":minf(distance,first)})
 # Strict ordering, not approximate-equality sorting (which can be non-transitive).
 result.sort_custom(func(a,c):return a.distance<c.distance or (a.distance==c.distance and int(a.enemy.id)<int(c.enemy.id)))
 return result

static func _guide_direction(b:Dictionary,enemies:Array,nx:int,ny:int)->Dictionary:
 var candidates:Array=[]
 for enemy in enemies:
  if enemy.hp<=0 or enemy.id in b.blocked_overlap:continue
  var x:float=enemy.pos.x;var y:float=enemy.pos.y
  if x<=EPS or y<=EPS or x>=float(b.field_width)-EPS or y>=float(b.field_height)-EPS:continue
  var dx:float=x-float(b.x);var dy:float=y-float(b.y);var distance_sq:float=dx*dx+dy*dy
  if distance_sq<=DIR_EPS*DIR_EPS or distance_sq>pow(float(b.distance_left)+EPS,2):continue
  var length:float=sqrt(distance_sq);dx/=length;dy/=length
  if (nx!=0 and dx*nx>=-DIR_EPS) or (ny!=0 and dy*ny>=-DIR_EPS):continue
  candidates.append({"dx":dx,"dy":dy,"distance_sq":distance_sq,"id":enemy.id})
 candidates.sort_custom(func(a,c):return a.distance_sq<c.distance_sq or (a.distance_sq==c.distance_sq and int(a.id)<int(c.id)))
 return candidates[0] if not candidates.is_empty() else {}

static func advance(b:Dictionary,dt:float,enemies:Array,hit:Callable,boundary_event:Callable)->void:
 if b.is_empty() or float(b.get("life",0))<=0:return
 if not is_finite(dt):_expire(b,"invalid_dt");return
 if dt<=0:return
 var remaining:float=minf(float(b.distance_left),minf(dt,float(b.life))*float(b.speed))
 if not is_finite(remaining) or remaining<0:_expire(b,"invalid_budget");return
 var events:=0;var segments:=0
 while remaining>0 and float(b.life)>0:
  segments+=1
  if segments>MAX_REFLECTIONS+2 or events>=MAX_EVENTS_PER_ADVANCE:_expire(b,"safety_ceiling");return
  _release_blocks(b,enemies)
  var wall:Dictionary=_boundary(b)
  var reaches:bool=float(wall.distance)<=remaining
  var distance:float=float(wall.distance) if reaches else remaining
  # Accumulated distance, not just this frame. Reject a second zero-progress corner event.
  if reaches and int(b.reflections)>0 and float(b.since_reflection)+distance<=EPS:
   _expire(b,"insufficient_boundary_progress");return
  # The initial outward t=0 contact has no damaging launch bridge/zero-length segment.
  if distance>0 and b.leg_hits.size()<int(b.leg_quota):
   for candidate in _contacts(b,enemies,distance):
    var enemy:Dictionary=candidate.enemy
    if enemy.hp<=0 or enemy.id in b.leg_hits or enemy.id in b.blocked_overlap:continue
    if b.leg_hits.size()>=int(b.leg_quota):break
    if events>=MAX_EVENTS_PER_ADVANCE or int(b.total_hits)>=MAX_QUOTA*(MAX_REFLECTIONS+1):_expire(b,"safety_ceiling");return
    b.leg_hits.append(enemy.id);b.total_hits+=1;events+=1
    if hit.is_valid():hit.call(enemy,b)
  b.x=float(b.x)+float(b.dx)*distance;b.y=float(b.y)+float(b.dy)*distance
  b.travelled=float(b.travelled)+distance;b.since_reflection=float(b.since_reflection)+distance
  b.distance_left=maxf(0.0,float(b.distance_left)-distance)
  b.life=maxf(0.0,float(b.life)-distance/float(b.speed));remaining=maxf(0.0,remaining-distance)
  if reaches:
   if int(wall.nx)!=0:b.x=0.0 if int(wall.nx)<0 else float(b.field_width)
   if int(wall.ny)!=0:b.y=0.0 if int(wall.ny)<0 else float(b.field_height)
  _sync(b);_release_blocks(b,enemies)
  if float(b.distance_left)<=EPS or float(b.life)<=0:
   b.distance_left=0.0;_expire(b,"path_budget");return
  if not reaches:return
  events+=1
  if int(b.reflections)>=MAX_REFLECTIONS:
   if boundary_event.is_valid():boundary_event.call({"pos":b.pos,"direction":Vector2(b.dx,b.dy),"reflected":false,"guided":false,"reflection":int(b.reflections),"kind":"absorbed"})
   _expire(b,"third_boundary");return
  _carry_at_reflection(b,enemies)
  b.reflections+=1;b.since_reflection=0.0
  var guided:=false
  var next_dx:float=-float(b.dx) if int(wall.nx)!=0 else float(b.dx)
  var next_dy:float=-float(b.dy) if int(wall.ny)!=0 else float(b.dy)
  if not bool(b.guide_checked):
   b.guide_checked=true
   if bool(b.guide):
    var target:Dictionary=_guide_direction(b,enemies,int(wall.nx),int(wall.ny))
    if not target.is_empty():next_dx=target.dx;next_dy=target.dy;guided=true;b.guided_once=true
  b.dx=next_dx;b.dy=next_dy;_sync(b)
  if boundary_event.is_valid():boundary_event.call({"pos":b.pos,"direction":Vector2(b.dx,b.dy),"reflected":true,"guided":guided,"reflection":int(b.reflections),"kind":"reflection"})
