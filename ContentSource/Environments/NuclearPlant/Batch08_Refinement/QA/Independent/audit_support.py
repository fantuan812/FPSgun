import os,bpy,json,pathlib,math,hashlib,itertools
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path('/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement');O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA'));O.mkdir(parents=True,exist_ok=True);D=json.loads((R/os.environ.get('B08_DESIGN','Config/design.json')).read_text());bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));dg=bpy.context.evaluated_depsgraph_get()
def bb(o):
 v=[o.matrix_world@Vector(x) for x in o.bound_box];return [[min(x[i] for x in v) for i in range(3)],[max(x[i] for x in v) for i in range(3)]]
vv=[];ff=[];owners=[];new=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('B08')];bounds={o.name:bb(o) for o in new}
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.name.startswith('B08') or 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
 ev=o.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();n=len(vv);vv.extend(o.matrix_world@v.co for v in me.vertices);ff.extend(tuple(n+i for i in t.vertices) for t in me.loop_triangles);owners.extend([o.name]*len(me.loop_triangles));ev.to_mesh_clear()
tree=BVHTree.FromPolygons(vv,ff,all_triangles=True);out={'scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'method':'9 underside footprint witnesses per edge/flush, 3 foot witnesses per terminal; supporting new bedding bbox must bridge down to actual old surface. New low bedding is separately checked. This is static support, not a capsule or physical simulation.','support_samples':[],'unsupported':[],'front_wall_contacts':[]}
for ob in new:
 mid=ob.get('module_id','');lo,hi=bounds[ob.name];points=[]
 if mid in ['B08_SERVICE_EDGE','B08_SERVICE_EDGE_FLUSH']:
  xx=[-1.85,0,1.85];yy=[-.43,0,.43] if mid=='B08_SERVICE_EDGE' else [-.24,0,.24]
  points=[ob.matrix_world@Vector((x,y,0)) for x,y in itertools.product(xx,yy)]
 elif mid=='B08_WALL_TERMINAL':points=[ob.matrix_world@Vector((x,-.07,0)) for x in [-.4,0,.4]]
 elif hi[2]<=.06 and lo[2]<-.001:points=[Vector((lo[0]+(hi[0]-lo[0])*x,lo[1]+(hi[1]-lo[1])*y,lo[2])) for x,y in itertools.product([.1,.5,.9],[.1,.5,.9])]
 for q in points:
  start=Vector((q.x,q.y,max(.08,hi[2]+.01 if hi[2]<.1 else .08)));loc,n,idx,dist=tree.ray_cast(start,Vector((0,0,-1)),.5);h=None if idx is None else {'object':owners[idx],'z':loc.z};basez=lo[2];bridge=[]
  if h and basez>h['z']+.005:
   for name,(a,b) in bounds.items():
    if name!=ob.name and b[2]<=.08 and a[2]<=h['z']+.005 and b[2]>=basez-.005 and a[0]-.001<=q.x<=b[0]+.001 and a[1]-.001<=q.y<=b[1]+.001:bridge.append(name)
  ok=h is not None and (basez<=h['z']+.005 or bool(bridge));rec={'object':ob.name,'xy':[q.x,q.y],'base_z':basez,'old_surface':h,'bridge_objects':bridge,'supported':ok};out['support_samples'].append(rec)
  if not ok:out['unsupported'].append(rec)
 if mid=='B08_WALL_TERMINAL':
  for x,z in itertools.product([-.6,0,.6],[.25,1.2,2.1]):
   p=ob.matrix_world@Vector((x,-.5,z));d=ob.matrix_world.to_3x3()@Vector((0,1,0));loc,n,idx,dist=tree.ray_cast(p,d,.8);out['front_wall_contacts'].append({'object':ob.name,'local_xz':[x,z],'hit':None if idx is None else {'object':owners[idx],'point':list(loc),'distance':dist},'expected_backface_distance':.66,'error_m':None if idx is None else dist-.66})
(O/'support_audit.json').write_text(json.dumps(out,indent=2));print('SUPPORT_DONE',len(out['support_samples']),'unsupported',len(out['unsupported']),flush=True)
