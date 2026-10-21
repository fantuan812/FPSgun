import os,bpy,pathlib,json,math,hashlib,itertools
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path('/workspace/shared/NuclearPlant_Batch08_Work/NuclearPlant/Batch08_Refinement');O=pathlib.Path(os.environ.get('B08_QA_OUTPUT','/workspace/shared/Batch08_Independent_QA'));D=json.loads((R/os.environ.get('B08_DESIGN','Config/design_v03.json')).read_text());bpy.ops.wm.open_mainfile(filepath=str(R/D['source']));dg=bpy.context.evaluated_depsgraph_get();v=[];f=[];owners=[]
# Existing ground surfaces only, avoiding a tall wall's underside when a boundary lies on its footprint.
for o in bpy.context.scene.objects:
 if o.type!='MESH' or 'proxy' in o.name.lower() or any('Proxy' in c.name for c in o.users_collection):continue
 bb=[o.matrix_world@Vector(q) for q in o.bound_box]
 if max(q.z for q in bb)>.08:continue
 ev=o.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();n=len(v);v.extend(o.matrix_world@p.co for p in me.vertices);f.extend(tuple(n+i for i in t.vertices) for t in me.loop_triangles);owners.extend([o.name]*len(me.loop_triangles));ev.to_mesh_clear()
base=BVHTree.FromPolygons(v,f,all_triangles=True)
def ground(x,y):
 q,n,i,d=base.ray_cast(Vector((x,y,.1)),Vector((0,0,-1)),.6);return None if i is None else {'z':q.z,'object':owners[i]}
bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'));dg=bpy.context.evaluated_depsgraph_get();out={'scene_sha256':hashlib.sha256((R/'site_refined.blend').read_bytes()).hexdigest(),'baseline_sha256':hashlib.sha256((R/D['source']).read_bytes()).hexdigest(),'limit_m':.03,'definition':'Actual top minus old local ground, not world-Z. All evaluated cover mesh vertices plus 21x3 cover-surface witnesses and known ground-transition +/-1mm witnesses. New bedding never changes old ground.','covers':[]}
for o in bpy.context.scene.objects:
 if o.type!='MESH' or not o.name.startswith('B08') or 'FLUSH' not in str(o.get('module_id','')):continue
 ev=o.evaluated_get(dg);me=ev.to_mesh();me.calc_loop_triangles();vs=[o.matrix_world@p.co for p in me.vertices];fs=[tuple(t.vertices) for t in me.loop_triangles];cover=BVHTree.FromPolygons(vs,fs,all_triangles=True);lo=[min(q[i] for q in vs) for i in range(3)];hi=[max(q[i] for q in vs) for i in range(3)];ev.to_mesh_clear();samples=[]
 for q in vs:samples.append(('vertex',q.x,q.y,q.z))
 longaxis=0 if hi[0]-lo[0]>hi[1]-lo[1] else 1;other=1-longaxis
 xx=[]
 for k,j in itertools.product(range(21),[.1,.5,.9]):
  xy=[0,0];xy[longaxis]=lo[longaxis]+(hi[longaxis]-lo[longaxis])*(.005+.99*k/20);xy[other]=lo[other]+(hi[other]-lo[other])*j;xx.append(xy)
 for axis,bound in [(0,46),(0,48),(1,-38),(1,-8)]:
  if lo[axis]-.002<=bound<=hi[axis]+.002:
   for delta,j in itertools.product([-.001,.001],[.1,.5,.9]):
    xy=[0,0];xy[axis]=bound+delta;xy[1-axis]=lo[1-axis]+(hi[1-axis]-lo[1-axis])*j
    if all(lo[i]-.0001<=xy[i]<=hi[i]+.0001 for i in range(2)):xx.append(xy)
 for x,y in xx:
  q,n,i,d=cover.ray_cast(Vector((x,y,.2)),Vector((0,0,-1)),.6)
  if i is not None:samples.append(('surface',x,y,q.z))
 maximum=-100;worst=None;violations=[];groundnames=set()
 for typ,x,y,z in samples:
  g=ground(x,y)
  if g is None:violations.append({'type':typ,'xy':[x,y],'reason':'no old ground'});continue
  groundnames.add(g['object']);rel=z-g['z'];row={'type':typ,'xyz':[x,y,z],'ground':g,'relative_height_m':rel}
  if rel>maximum:maximum=rel;worst=row
  if rel>.0301:violations.append(row)
 out['covers'].append({'object':o.name,'bounds':[lo,hi],'samples':len(samples),'maximum_relative_height_m':maximum,'worst':worst,'violations_count':len(violations),'violation_examples':violations[:12],'ground_objects':sorted(groundnames)})
O.mkdir(parents=True,exist_ok=True);(O/'crossing_heights.json').write_text(json.dumps(out,indent=2));print('CROSSING_HEIGHTS',json.dumps([{k:c[k] for k in ['object','maximum_relative_height_m','violations_count']} for c in out['covers']]),flush=True)
