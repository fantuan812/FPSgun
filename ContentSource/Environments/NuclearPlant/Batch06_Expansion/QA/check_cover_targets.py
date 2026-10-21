"""Directed rays to nearby named solid AABBs supplement angular sampling.
Targets are standing-height opaque masses, not rails/vegetation. Nearest surface
is not proof of a physically reachable hiding pose or bullet resistance.
"""
import bpy,json,pathlib,sys,math
from mathutils import Vector
P=pathlib.Path(__file__).resolve().parent;sys.path.insert(0,str(P))
from static_bvh import build_world_bvh
ray,cache=build_world_bvh();C=json.loads((P.parent/'layout.json').read_text())
TOKENS=['b06_screen / 0','b06_service_bank / 0','b06_utility_shelter /','b06_p_hall side','b06_p_hall north','b06_p_front wall','open sliding leaf','external service wing','end wall panel','side concrete panel','m east red band','m north wall','m south wall','m west wall','portal_boundary_closure','reuse_sm_npp_wall_solid']
def solid(n):return any(t in n.lower() for t in TOKENS)
cover=[]
for o in bpy.context.scene.objects:
 if not solid(o.name):continue
 v=[o.matrix_world@Vector(c) for c in o.bound_box];lo=Vector(tuple(min(p[i] for p in v) for i in range(3)));hi=Vector(tuple(max(p[i] for p in v) for i in range(3)))
 cover.append((o.name,lo,hi))
R={'method':'Directed horizontal rays at1.65m to nearest points on named solid mass AABBs; maximum12m. Not reachability, bullet resistance or combat safety.','paths':{},'geometry_cache':cache}
for name,path in C['pedestrian_routes'].items():
 z=7.65 if name=='upper_link' else 1.65
 samples=[];station=0
 for a,b in zip(path,path[1:]):
  a,b=Vector((*a,z)),Vector((*b,z));length=(b-a).length;steps=max(1,math.ceil(length/2))
  for i in range(steps):
   p=a+(b-a)*i/steps;best=None
   for obj,lo,hi in cover:
    if not lo.z<=z<hi.z-.1:continue
    target=Vector((min(max(p.x,lo.x+.01),hi.x-.01),min(max(p.y,lo.y+.01),hi.y-.01),z));dist=(target-p).length
    if dist>12 or dist<.001:continue
    hit=ray(p,target-p,dist+.02)
    if hit and solid(hit[1]) and (best is None or (hit[0]-p).length<best['distance']):best={'object':hit[1],'distance':round((hit[0]-p).length,3),'point':list(hit[0])}
   samples.append({'station':round(station+i*length/steps,3),'point':list(p),'nearby_solid':best})
  station+=length
 R['paths'][name]={'length':station,'samples':samples,'missing_within12m':sum(s['nearby_solid'] is None for s in samples)}
(P/'cover_target_report.json').write_text(json.dumps(R,indent=2));print({n:v['missing_within12m'] for n,v in R['paths'].items()})
