"""Read-only static geometry QA. Not engine collision, navmesh or combat certification."""
import bpy,json,pathlib,sys,math,hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path(__file__).resolve().parent.parent;C=json.loads((R/'Config'/('design_v04.json' if (R/'Config/design_v04.json').exists() else 'design_v03.json' if (R/'Config/design_v03.json').exists() else ('design_v02.json' if (R/'Config/design_v02.json').exists() else 'design.json'))).read_text());L=json.loads((R.parent/'Batch06_Expansion'/'layout.json').read_text())
def tree_for(new_only=False,exclude_open=False):
 verts=[];faces=[];owners=[];d=bpy.context.evaluated_depsgraph_get()
 for o in bpy.context.scene.objects:
  if o.type not in {'MESH','CURVE','FONT'}:continue
  if exclude_open and o.get('module_id')=='B07_PIPE_RACK':continue
  if 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
  if new_only and not any(c.name.startswith('B07_') for c in o.users_collection):continue
  e=o.evaluated_get(d);me=e.to_mesh();me.calc_loop_triangles();base=len(verts);verts.extend(o.matrix_world@v.co for v in me.vertices);faces.extend(tuple(base+i for i in t.vertices) for t in me.loop_triangles);owners.extend([o.name]*len(me.loop_triangles));e.to_mesh_clear()
 t=BVHTree.FromPolygons(verts,faces,all_triangles=True)
 def ray(p,v,dist):
  q,n,idx,d=t.ray_cast(Vector(p),Vector(v).normalized(),dist);return None if idx is None else (q,owners[idx],d)
 return ray,{'vertices':len(verts),'triangles':len(faces)}
paths={n:[(*p,6 if n=='upper_link' else 0) for p in poly] for n,poly in L['pedestrian_routes'].items()}
paths['core_front']=[(0,-26,0),(0,-10,0)];paths['core_rear']=[(2,10,0),(2,26,0)]
# Deliberately limited set: ground routes and apron witnesses at retained shed front.
witnesses=[]
for n,poly in paths.items():
 if n=='upper_link':continue
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);length=(b-a).length
  for i in range(max(1,int(length/3))):
   p=a+(b-a)*i/max(1,int(length/3));witnesses.append((n,tuple(p+Vector((0,0,1.65)))))
for x,y in C['replace_shelter_centers']:
 for dx in [-4,0,4]:witnesses.append(('yard_apron',(x+dx,y-4.85,1.65)))
def visibility(ray,elevated=False):
 result=[]
 for name,p in witnesses:
  distances=[]
  for i in range(16):
   a=i*2*math.pi/16;v=(math.cos(a),math.sin(a),.16 if elevated else 0);h=ray(p,v,40);distances.append(round(h[2],4) if h else 40)
  result.append({'route':name,'point':p,'distance_m':distances,'blocked_within_12m':sum(d<12 for d in distances)})
 return result
bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));s=bpy.context.scene
newray,ng=tree_for(True);routes={}
for n,poly in paths.items():
 issues=[];samples=0
 for a,b in zip(poly,poly[1:]):
  a,b=Vector(a),Vector(b);delta=b-a;steps=max(1,math.ceil(delta.length/.35));v=delta.normalized();normal=Vector((-v.y,v.x,0))
  for i in range(steps+1):
   q=a+delta*i/steps
   for off in [-1,-.5,0,.5,1]:
    p=q+normal*off;hit=newray(p+Vector((0,0,.06)),(0,0,1),2.04);samples+=1
    if hit:issues.append({'at':list(p),'object':hit[1],'kind':'new vertical interference'})
   if i<steps:
    for off in [-1,0,1]:
     for z in [.25,1.0,1.65,2.1]:
      hit=newray(q+normal*off+Vector((0,0,z)),v,delta.length/steps)
      if hit:issues.append({'at':list(q),'object':hit[1],'kind':'new horizontal interference'})
 routes[n]={'width_sampled_m':2,'height_m':2.1,'sample_count':samples,'new_geometry_issues':issues}
ray,geom=tree_for();after=visibility(ray);after_high=visibility(ray,True)
camera_qa={}
for name in ['core_entry','pump_eye','logistics_eye']:
 o=bpy.data.objects[name];p=o.location;h=ray(p,(0,0,-1),3);f=ray(p,o.rotation_euler.to_quaternion()@Vector((0,0,-1)),.5);camera_qa[name]={'z':p.z,'support':None if h is None else h[1],'eye_above_support':None if h is None else p.z-h[0].z,'first_0p5m_block':None if f is None else f[1]}
coverray,_=tree_for(exclude_open=True);after_solid=visibility(coverray);after_high_solid=visibility(coverray,True)
external=[x.filepath for x in bpy.data.libraries]
bpy.ops.wm.open_mainfile(filepath=str(R/C['source']));ray,bgeom=tree_for();before=visibility(ray);before_high=visibility(ray,True)
def compare(b,a):
 out=[]
 for old,new in zip(b,a):
  loss=[i for i,(x,y) in enumerate(zip(old['distance_m'],new['distance_m'])) if x<12 and y>=12]
  gain=[i for i,(x,y) in enumerate(zip(old['distance_m'],new['distance_m'])) if x>=12 and y<12]
  if loss or gain:out.append({'route':new['route'],'point':new['point'],'lost_near_occlusion_directions':loss,'gained_near_occlusion_directions':gain})
 return {'rays':len(b)*16,'before_near_occluded':sum(x['blocked_within_12m'] for x in b),'after_near_occluded':sum(x['blocked_within_12m'] for x in a),'changed_witnesses':out}
report={'scope':'New-geometry interference only across unchanged baseline route centrelines; 2m width and 2.10m height sampled. Not whole-scene capsule sweep.','route_tests':routes,'cameras':camera_qa,'linked_libraries':external,'new_geometry':ng,'full_scene_geometry':geom,'line_of_sight':{'ground':compare(before,after),'rising_9degree':compare(before_high,after_high),'ground_excluding_open_rack':compare(before,after_solid),'rising_9degree_excluding_open_rack':compare(before_high,after_high_solid),'limits':'16 rays per witness, near occlusion at 12m, 40m reach. Not bullet collision, combat cover or visibility from all enemy positions. Roof / high wall removal can change elevated exposure.'},'baseline_sha256':hashlib.sha256((R/C['source']).read_bytes()).hexdigest(),'ue_runtime_tested':False,'official_manny_mesh_tested':False}
(R/'QA'/'static_geometry.json').write_text(json.dumps(report,indent=2));print('B07_QA',json.dumps({'route_new_issues':{n:len(v['new_geometry_issues']) for n,v in routes.items()},'cameras':camera_qa,'occlusion':{k:report['line_of_sight'][k] for k in ['ground','rising_9degree']}}))
