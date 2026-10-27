"""Independent decimal boundary partition reference; no Godot/target imports.
Reference uses represented float32 Vector2 inputs and Decimal(90) scalars.
Physical equality is resolved at high precision; target tolerance policy has a
separate adversarial group, not a claim of exact real-valued collision physics.
"""
from decimal import Decimal as D,localcontext
import math,struct,json,pathlib,itertools
P=pathlib.Path(__file__).parent
f32=lambda x:struct.unpack('f',struct.pack('f',x))[0]
def dec(x):return D.from_float(float(x))
def roots(a,b,c):
 if a==0:return [] if b==0 else [-c/b]
 z=b*b-4*a*c
 if z<0:return []
 q=z.sqrt();return [(-b-q)/(2*a),(-b+q)/(2*a)]
def reference(c):
 # p0,p1 are normal segment endpoints across full dt, range clipped by [lo,hi].
 with localcontext() as ctx:
  ctx.prec=90
  dt=dec(c['dt']);lo=dec(c.get('lo',0));hi=dec(c.get('hi',c['dt']));r0=dec(c['r0']);r1=dec(c['r1']);rad=dec(c.get('scale',1))*16+12
  p=[dec(f32(v))-dec(f32(z)) for v,z in zip(c['p0'],c.get('center',[0,0]))]
  end=[dec(f32(v))-dec(f32(z)) for v,z in zip(c['p1'],c.get('center',[0,0]))]
  if dt==0:
   d=p[0]*p[0]+p[1]*p[1];hit=max(D(0),r0-rad)**2<=d<=(r0+rad)**2
   return {'hit':hit,'time':'0' if hit else None}
  v=[(end[i]-p[i])/dt for i in range(2)];vr=(r1-r0)/dt
  def inside(t):
   d=sum((p[i]+v[i]*t)**2 for i in range(2));rr=r0+vr*t
   return max(D(0),rr-rad)**2-D('1e-70')<=d<=(rr+rad)**2+D('1e-70')
  candidates=[lo,hi]
  for sign in [-1,1]:
   base=r0+sign*rad
   a=sum(x*x for x in v)-vr*vr;b=2*(sum(p[i]*v[i] for i in range(2))-base*vr);cc=sum(x*x for x in p)-base*base
   candidates += [t for t in roots(a,b,cc) if lo<=t<=hi]
  if vr!=0:
   z=(rad-r0)/vr
   if lo<=z<=hi:candidates.append(z)
  candidates=sorted(set(candidates))
  for i,t in enumerate(candidates):
   if inside(t):return {'hit':True,'time':str(t)}
   if i+1<len(candidates) and inside((t+candidates[i+1])/2):
    # Analytic partition boundary; residual only at 90-digit rounding.
    return {'hit':True,'time':str(t)}
  return {'hit':False,'time':None}
def hand(name,p0,p1,r0,r1,dt,expected,time=None,**kw):return dict(name=name,p0=p0,p1=p1,r0=r0,r1=r1,dt=dt,expected_hit=expected,expected_time=time,**kw)
H=[hand('stationary100_out',[100,0],[100,0],24,180,.6,True,48/260),hand('center_initial_band',[0,0],[0,0],24,180,.6,True,0),hand('stationary_center_hole',[0,0],[0,0],60,100,1,False),hand('inner_exit_earliest',[0,0],[200,0],60,60,1,True,.16),hand('fast_two_crossings',[-200,0],[200,0],60,60,1,True,.28),hand('outer_tangent',[-100,88],[100,88],60,60,1,True,.5),hand('outside_tangent',[-100,89],[100,89],60,60,1,False),hand('inner_boundary',[32,0],[32,0],60,60,1,True,0),hand('inside_hole',[31,0],[31,0],60,60,1,False),hand('zero_scale_boundary',[48,0],[48,0],60,60,1,True,0,scale=0),hand('zero_duration_outer',[88,0],[88,0],60,60,0,True,0),hand('zero_duration_hole',[0,0],[0,0],60,60,0,False),hand('wave_dies_before_segment_contact',[-200,0],[200,0],60,60,1,False,lo=0,hi=.2),hand('wave_alive_contact_clipped',[-200,0],[200,0],60,60,1,True,.28,lo=.2,hi=.3),hand('inward_stationary100',[100,0],[100,0],180,24,.45,True,52/(156/.45)),hand('translated_represented',[1000000100,1000000000],[1000000100,1000000000],24,180,.6,True,(128-28-24)/260,center=[1000000000,1000000000])]
cases=H[:]
for distance,delta,rr,scale in itertools.product([0,24,32,60,88,100,208],[-200,0,200],[24,60,180],[.5,1,2]):
 cases.append(dict(name=f'matrix_{len(cases)}',p0=[distance,13],p1=[distance+delta,-13],r0=rr,r1=180 if rr!=180 else 24,dt=.6,scale=scale))
# Explicit discontinuity controls: never interpolate a push across the ring.
DROPS=[{'name':'normal_stationary_inside_hole_push_to_outside','normal':[0,0,0,0],'final':[200,0],'r':60,'expected_hit':False,'reason':'No sweep fromnormalend tofinal; finaloutside'}, {'name':'postpush_endpoint_only','normal':[0,0,0,0],'final':[60,0],'r':60,'expected_hit_if_alive_at_dt':True,'expected_hit_if_expired_before_dt':False}, {'name':'newborn_at_final_band','has_normal_segment':False,'final':[60,0],'expected_hits':1}, {'name':'turnpoint_two_closed_legs','target':[180,0],'alive_after_outward':True,'expected_legs':[0,1],'expected_damage_default':[22,11]}, {'name':'turnpoint_outward_kills','target_hp':20,'expected_legs':[0],'expected_final_hp':-2}]
if __name__=='__main__':
 out=[]
 for c in cases:
  result=reference(c)
  if 'expected_hit'in c:
   assert result['hit']==c['expected_hit'],c['name']
   if c.get('expected_time')is not None:assert abs(float(result['time'])-c['expected_time'])<1e-10,(c['name'],result)
  out.append(dict(input=c,reference=result))
 (P/'GEOMETRY_CASES.json').write_text(json.dumps({'method':'Independent Decimal90 boundary partition on actualfloat32 endpoint inputs','cases':out,'discontinuity_hand_cases':DROPS},indent=2)+'\n');print(json.dumps({'pass':True,'geometry_cases':len(out),'hand_cases':len(H),'discontinuity_cases':len(DROPS),'target_imports':0}))
