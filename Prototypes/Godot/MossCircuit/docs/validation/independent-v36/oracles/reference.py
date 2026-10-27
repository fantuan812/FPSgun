"""Independent pre-implementation oracle. Not production code or target acceptance.
Geometry uses dot products against closed segments; phase model keys physical pickup identity by index.
"""
from math import isfinite, hypot
from copy import deepcopy

def numeric(x):return type(x) in (int,float) and isfinite(x)
def profile(row):
 if type(row) is not dict:return {}
 radius=row.get('return_pickup_radius');quota=row.get('return_pickup_limit');sources=row.get('pickup_sources')
 if not numeric(radius) or not 0<radius<=64:return {}
 if not numeric(quota) or not 1<=quota<=8 or quota!=int(quota):return {}
 if not numeric(row.get('max_stack')) or row['max_stack']!=1:return {}
 if type(sources) is not list or len(sources)!=2 or any(type(s) is not str for s in sources) or set(sources)!={'normal','energy'}:return {}
 return {'radius':float(radius),'maximum':int(quota),'sources':sources.copy()}
def snapshot(row):
 p=profile(row)
 return dict(p,remaining=p['maximum']) if p else {}
def segment_inside(a,b,p,r):
 if not numeric(r) or not 0<r<=64:return False
 if any(len(v)!=2 or any(not numeric(x) for x in v) for v in (a,b,p)):return False
 vx,vy=b[0]-a[0],b[1]-a[1];wx,wy=p[0]-a[0],p[1]-a[1];length=vx*vx+vy*vy
 if length==0:return False
 dot=wx*vx+wy*vy
 if dot<=0:return wx*wx+wy*wy<r*r
 if dot>=length:return (p[0]-b[0])**2+(p[1]-b[1])**2<r*r
 # Avoid sqrt and projection division; algebraically equivalent squared distance.
 return (wx*wx+wy*wy)*length-dot*dot<r*r*length
def valid_snapshot(s):
 return type(s) is dict and numeric(s.get('radius')) and 0<s['radius']<=64 and type(s.get('maximum')) is int and 1<=s['maximum']<=8 and type(s.get('remaining')) is int and 0<=s['remaining']<=s['maximum'] and type(s.get('sources')) is list and len(s['sources'])==2 and all(type(x) is str for x in s['sources']) and set(s['sources'])=={'normal','energy'}
def eligible(sweep,pickup):
 s=sweep['disc'].get('scavenger');source=pickup.get('source','normal')
 return valid_snapshot(s) and s['remaining']>0 and type(source) is str and source in s['sources'] and segment_inside(sweep['start'],sweep['end'],pickup['pos'],s['radius'])
def return_piece(pos,player,speed,life,dt,returning,outbound_left):
 # Independent finite paper integrator, no enemy collisions; test last-hit retirement separately in target.
 remaining=min(dt,max(0,life));x,y=pos
 if remaining<=0:return []
 if not returning:
  outward=min(remaining,max(0,outbound_left));x+=speed*outward;life-=outward;remaining-=outward;outbound_left-=outward
  returning=outbound_left<=.000001
 if not returning or remaining<=0 or life<=0:return []
 dx,dy=player[0]-x,player[1]-y;dist=hypot(dx,dy)
 if dist<14:return []
 time=min(remaining,life,dist/speed);end=(x+dx/dist*speed*time,y+dy/dist*speed*time)
 return [] if end==(x,y) else [((x,y),end)]
def pickup_phase(pickups,sweeps,player=(0.,0.),pickup_radius=0.,dt=0.,append_on_event=None):
 # sweeps already in existing descending original bullet-index order.
 items=deepcopy(pickups);events=[];original_count=len(items)
 for i in range(original_count-1,-1,-1):
  p=items[i];dx,dy=player[0]-p['pos'][0],player[1]-p['pos'][1];before=hypot(dx,dy)
  if before<pickup_radius and before>0:
   factor=min(1,dt*260/before);p['pos']=(p['pos'][0]+dx*factor,p['pos'][1]+dy*factor)
  winner='player' if before<14 else None
  if winner is None:
   for sweep in sweeps:
    if eligible(sweep,p):sweep['disc']['scavenger']['remaining']-=1;winner=sweep['disc']['id'];break
  if winner is not None:
   events.append({'identity':p['identity'],'winner':winner,'pos':p['pos'],'source':p.get('source','normal')});items.pop(i)
   if append_on_event is not None:items.append(deepcopy(append_on_event))
 return items,events
