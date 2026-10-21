"""Static sight evidence only; cover usability requires plan and image review."""
import bpy,json,math,pathlib
from mathutils import Vector
P=pathlib.Path(__file__).resolve().parent;C=json.loads((P.parent/'layout.json').read_text());S=bpy.context.scene;D=bpy.context.evaluated_depsgraph_get()
R={'source':bpy.data.filepath,'method':'2m path intervals, 1.65m eye height, 24 horizontal rays up to20m. Hits are raw geometry, not automatically solid usable cover. No weapon, enemy, UE or combat safety simulation.','paths':{}}
def cast(p,v):
 h,l,n,f,o,m=S.ray_cast(D,p,v,distance=20)
 return None if not h else {'distance':round((l-p).length,3),'object':o.name}
import os,sys
if os.environ.get('QA_BVH')=='1':
 sys.path.insert(0,str(P));from static_bvh import build_world_bvh
 fast_ray,R['geometry_cache']=build_world_bvh()
 def cast(p,v):
  result=fast_ray(p,v,20)
  return None if not result else {'distance':round((result[0]-p).length,3),'object':result[1]}
for name,poly in C.get('pedestrian_routes',{}).items():
 samples=[];z=7.65 if name=='upper_link' else 1.65;chain=0
 for segment,(a,b) in enumerate(zip(poly,poly[1:])):
  a,b=Vector((*a,z)),Vector((*b,z));length=(b-a).length;num=max(1,math.ceil(length/2));forward=(b-a).normalized()
  for i in range(num):
   p=a+(b-a)*i/num
   sample={'segment':segment,'station':round(chain+i*length/num,2),'point':list(p),'forward':cast(p,forward),'back':cast(p,-forward),'directions':{}}
   for angle in range(0,360,15):sample['directions'][str(angle)]=cast(p,Vector((math.cos(math.radians(angle)),math.sin(math.radians(angle)),0)))
   samples.append(sample)
  chain+=length
 R['paths'][name]={'length':chain,'samples':samples}
(P/os.environ.get('QA_EXPOSURE_REPORT','exposure_rays.json')).write_text(json.dumps(R,indent=2));print('Wrote',P/'exposure_rays.json')
