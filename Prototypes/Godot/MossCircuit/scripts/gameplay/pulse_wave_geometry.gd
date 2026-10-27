extends RefCounted
## Pure, bounded moving-annulus query. Inputs are the actual stored Vector2 components.
const SPACE_EPS:float=0.000001
const TIME_EPS:float=0.000000001
const COEFFICIENT_EPS:float=0.000000000001
const DISCRIMINANT_EPS:float=0.000000001

static func _miss()->Dictionary:return {"hit":false,"time":0.0}

static func _inside(t:float,x:float,y:float,vx:float,vy:float,ri:float,rv:float,pad:float)->bool:
	var px:float=x+vx*t
	var py:float=y+vy*t
	var radius:float=ri+rv*t
	var squared:float=px*px+py*py
	var outer:float=radius+pad
	var inner:float=radius-pad
	if not is_finite(squared) or not is_finite(outer*outer) or not is_finite(inner*inner):return false
	return squared<=outer*outer+SPACE_EPS and (inner<=0.0 or squared+SPACE_EPS>=inner*inner)

static func _roots(a:float,b:float,c:float)->Array:
	if absf(a)<=COEFFICIENT_EPS:
		if absf(b)<=COEFFICIENT_EPS:return []
		return [-c/b]
	var discriminant:float=b*b-4.0*a*c
	if not is_finite(discriminant) or discriminant < -DISCRIMINANT_EPS:return []
	var root:float=sqrt(maxf(0.0,discriminant))
	# Stable quadratic solution avoids cancellation when b dominates.
	var q:float=-0.5*(b+(root if b>=0.0 else -root))
	if absf(q)<=COEFFICIENT_EPS:return [-b/(2.0*a)]
	return [q/a,c/q]

static func first_contact(center:Vector2,p0:Vector2,p1:Vector2,frame_dt:float,t_start:float,t_end:float,r_start:float,r_end:float,half_width:float,enemy_radius:float)->Dictionary:
	if not center.is_finite() or not p0.is_finite() or not p1.is_finite():return _miss()
	for value in [frame_dt,t_start,t_end,r_start,r_end,half_width,enemy_radius]:
		if not is_finite(value) or value<0.0:return _miss()
	if t_start>t_end or t_end>frame_dt:return _miss()
	if t_start==t_end and r_start!=r_end:return _miss()
	# Cast each component before subtraction; never use Vector2.dot/difference here.
	var x:float=float(p0.x)-float(center.x)
	var y:float=float(p0.y)-float(center.y)
	var vx:float=(float(p1.x)-float(p0.x))/frame_dt if frame_dt>0.0 else 0.0
	var vy:float=(float(p1.y)-float(p0.y))/frame_dt if frame_dt>0.0 else 0.0
	var rv:float=(r_end-r_start)/(t_end-t_start) if t_end>t_start else 0.0
	var ri:float=r_start-rv*t_start
	var pad:float=half_width+enemy_radius
	for value in [x,y,vx,vy,rv,ri,pad]:
		if not is_finite(value):return _miss()
	if t_start==t_end:return {"hit":_inside(t_start,x,y,vx,vy,ri,rv,pad),"time":t_start if _inside(t_start,x,y,vx,vy,ri,rv,pad) else 0.0}
	var points:Array=[t_start,t_end]
	var a:float=vx*vx+vy*vy-rv*rv
	for sign_value in [-1.0,1.0]:
		var offset:float=ri+sign_value*pad
		var b:float=2.0*(x*vx+y*vy-offset*rv)
		var c:float=x*x+y*y-offset*offset
		if not is_finite(a) or not is_finite(b) or not is_finite(c) or not is_finite(b*b-4.0*a*c):return _miss()
		for root in _roots(a,b,c):
			if is_finite(root) and root>=t_start-TIME_EPS and root<=t_end+TIME_EPS:points.append(clampf(root,t_start,t_end))
	if rv!=0.0:
		var zero:float=(pad-ri)/rv
		if is_finite(zero) and zero>=t_start-TIME_EPS and zero<=t_end+TIME_EPS:points.append(clampf(zero,t_start,t_end))
	points.sort()
	var unique:Array=[]
	for t in points:
		if unique.is_empty() or t-float(unique[-1])>TIME_EPS:unique.append(t)
	for i in range(unique.size()):
		var left:float=unique[i]
		if _inside(left,x,y,vx,vy,ri,rv,pad):return {"hit":true,"time":left}
		if i+1>=unique.size():continue
		var right:float=unique[i+1]
		var middle:float=(left+right)*0.5
		if not _inside(middle,x,y,vx,vy,ri,rv,pad):continue
		# Numeric fallback only: first validated point, never the classification midpoint.
		var high:float=middle
		for iteration in range(64):
			if high-left<=TIME_EPS:break
			var candidate:float=(left+high)*0.5
			if _inside(candidate,x,y,vx,vy,ri,rv,pad):high=candidate
			else:left=candidate
		return {"hit":true,"time":high}
	return _miss()
