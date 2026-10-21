import os,bpy,pathlib,json,math,sys,itertools,gc,hashlib
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path('/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement');O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA'));O.mkdir(parents=True,exist_ok=True);D=json.loads((R/os.environ.get('B08_DESIGN','Config/design.json')).read_text());bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));scene=bpy.context.scene;dg=bpy.context.evaluated_depsgraph_get()
def bb(o):
 v=[o.matrix_world@Vector(x) for x in o.bound_box];return [min(x[i] for x in v) for i in range(3)],[max(x[i] for x in v) for i in range(3)]
def touch(a,b,eps=1e-5):return all(a[0][i]<=b[1][i]+eps and b[0][i]<=a[1][i]+eps for i in range(3))
cache={}
def tree(o):
 if o.name not in cache:
  ev=o.evaluated_get(dg);me=ev.to_mesh();v=[o.matrix_world@x.co for x in me.vertices];f=[tuple(p.vertices) for p in me.polygons];cache[o.name]=BVHTree.FromPolygons(v,f);ev.to_mesh_clear()
 return cache[o.name]
mods=[o for o in scene.objects if o.name.startswith('B08') and o.type in {'MESH','FONT'}];old=[o for o in scene.objects if not o.name.startswith('B08') and o.type=='MESH'];bounds={o.name:bb(o) for o in mods+old};out={'scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'new_objects_checked':len(mods),'module_context':[],'module_module':[],'door_candidates':[],'wall_contact':[],'foot_support':[]}
for group,pairs in [('module_context',itertools.product(mods,old)),('module_module',itertools.combinations(mods,2))]:
 for a,b in pairs:
  if touch(bounds[a.name],bounds[b.name]):
   x=tree(a).overlap(tree(b));out[group].append({'a':a.name,'b':b.name,'surface_triangle_pairs':len(x),'bounds_a':bounds[a.name],'bounds_b':bounds[b.name]})
 print('INTERSECTION_PHASE',group,len(out[group]),flush=True)
# All moving main entry door envelope; no B08 element may be here.
protected=[D['protected_door']['min'],D['protected_door']['max']]
out['door_candidates']=[{'name':o.name,'bounds':bounds[o.name]} for o in mods if touch(bounds[o.name],protected)]
# Existing-only BVH for actual rear wall and foot contact tests.
v=[];f=[];owner=[]
for o in old:
 if 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
 ev=o.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();n=len(v);v.extend(o.matrix_world@x.co for x in me.vertices);f.extend(tuple(n+i for i in t.vertices) for t in me.loop_triangles);owner.extend([o.name]*len(me.loop_triangles));ev.to_mesh_clear()
oldtree=BVHTree.FromPolygons(v,f,all_triangles=True);del v,f;cache.clear();gc.collect()
def ray(p,d,reach):
 loc,n,idx,dist=oldtree.ray_cast(Vector(p),Vector(d).normalized(),reach);return None if idx is None else {'object':owner[idx],'point':list(loc),'distance':dist}
for ob in mods:
 if ob.get('module_id')=='B08_WALL_TERMINAL':
  for x,z in itertools.product([-.6,0,.6],[.25,1.2,2.2]):
   q=ob.matrix_world@Vector((x,.15,z));direction=ob.matrix_world.to_3x3()@Vector((0,1,0));h=ray(q,direction,.08);out['wall_contact'].append({'object':ob.name,'local_xz':[x,z],'expected_distance':.01,'hit':h,'gap_after_nominal_backface':h['distance']-.01 if h else None})
  q=ob.matrix_world@Vector((0,-.07,.1));h=ray(q,[0,0,-1],.3);out['foot_support'].append({'object':ob.name,'hit':h,'nominal_base_to_support_m':.1-h['distance'] if h else None})
 if ob.get('module_id')=='B08_SERVICE_EDGE':
  q=ob.matrix_world@Vector((0,0,.1));h=ray(q,[0,0,-1],.3);out['foot_support'].append({'object':ob.name,'hit':h,'nominal_base_to_support_m':.1-h['distance'] if h else None})
(O/'intersections.json').write_text(json.dumps(out,indent=2));print('B08_INTERSECTIONS_DONE',len(out['module_context']),len(out['module_module']),len(out['door_candidates']),flush=True)
