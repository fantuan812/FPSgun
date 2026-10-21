"""Read-only static sampled clearance, not swept-capsule / UE navigation."""
import bpy, json, math, pathlib
from mathutils import Vector
P=pathlib.Path(__file__).resolve().parent
C=json.loads((P.parent/'layout.json').read_text()); S=bpy.context.scene; D=bpy.context.evaluated_depsgraph_get()
R={'source':bpy.data.filepath,'proxy':{'height':2.10,'radius':.50,'official_mesh_measured':False},'limits':'Discrete vertical and horizontal rays; not capsule sweep, UE navigation or combat validation. Display proxy objects ignored.','routes':{},'cameras':{},'dependencies':[x.filepath for x in bpy.data.libraries]}
def ray(p,v,dist):
 p=Vector(p);v=Vector(v).normalized()
 for _ in range(30):
  h,l,n,f,o,m=S.ray_cast(D,p,v,distance=dist)
  if not h:return None
  if 'proxy' not in o.name.lower() and not any('Proxy' in c.name for c in o.users_collection):return (l,o.name)
  used=(l-p).length+.001;p=l+v*.001;dist-=used
  if dist<=0:return None
 return None
def route(name,poly):
 bad=[];total=0
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);delta=b-a;length=delta.length;v=delta.normalized();n=Vector((-v.y,v.x,0)).normalized();steps=max(1,math.ceil(length/.5))
  for i in range(steps+1):
   q=a+delta*i/steps
   for off in [-.5,0,.5]:
    p=q+n*off;total+=1;floor=ray(p+Vector((0,0,.10)),(0,0,-1),.30)
    if not floor:bad.append({'type':'no_support','at':list(p)});continue
    z=floor[0].z
    if abs(z-p.z)>.12:bad.append({'type':'floor_step','at':list(p),'floor_z':z,'object':floor[1]})
    hit=ray((p.x,p.y,z+.06),(0,0,1),2.04)
    if hit:bad.append({'type':'head_or_solid','at':list(p),'height':hit[0].z-z,'object':hit[1]})
   # Parallel horizontal centre/edge lines catch railings and vertical wall faces.
   if i<steps:
    for off in [-.5,0,.5]:
     for h in [.5,1.0,1.65,2.05]:
      p=q+n*off+Vector((0,0,h));hit=ray(p,v,length/steps)
      if hit:bad.append({'type':'forward_barrier','at':list(p),'object':hit[1]})
  # Every node is intentionally included: overlaps are fine and misses not silently merged.
 R['routes'][name]={'samples':total,'issues':bad}
import os,sys
if os.environ.get('QA_BVH')=='1':
 sys.path.insert(0,str(P));from static_bvh import build_world_bvh
 ray,R['geometry_cache']=build_world_bvh()
paths={'outer_loop':[(*v,-.005) for v in C['roads']['outer_loop']], 'inner_west':[(*v,-.005) for v in C['roads']['inner_completion']], 'core_front':[(0,-30,0),(0,-10,0)],'core_rear':[(2,9,0),(2,26,0)],'retained_inner':[(0,-30,0),(34,-30,0),(34,26,0),(2,26,0)],'elevated':C['elevated_connection']['path']}
for i,p in enumerate(C['roads']['links']):paths['link_'+str(i)]=[(*v,-.005) for v in p]
for n,p in C.get('pedestrian_routes',{}).items():
 paths['pedestrian_'+n]=[(*v,6 if n=='upper_link' else 0) for v in p]
for n,p in paths.items():route(n,p)
# Wider proxy test of a previously limited original ring: reported separately, not promised route.
route('existing_core_ring_limitation',[(6.4*math.cos(a*math.pi/180),6.4*math.sin(a*math.pi/180),4.512) for a in range(0,361,3)])
for o in S.objects:
 if o.type!='CAMERA':continue
 p=o.matrix_world.translation;h=ray(p,(0,0,-1),3)
 f=ray(p,o.matrix_world.to_quaternion()@Vector((0,0,-1)),.5)
 R['cameras'][o.name]={'position':list(p),'support':None if not h else h[1],'relative_eye_height':None if not h else p.z-h[0].z,'forward_0p5m_block':None if not f else f[1]}
for name,item in R['routes'].items():
 item['scope']='legacy_core_limitation' if name=='existing_core_ring_limitation' else ('superseded_straight_axis_not_promised_clear' if name in {'inner_west','retained_inner','elevated'} else 'current_tested_route')
(P/os.environ.get('QA_REPORT','clearance_report.json')).write_text(json.dumps(R,indent=2))
print(json.dumps({n:{'samples':v['samples'],'issues':len(v['issues'])} for n,v in R['routes'].items()},indent=2))
