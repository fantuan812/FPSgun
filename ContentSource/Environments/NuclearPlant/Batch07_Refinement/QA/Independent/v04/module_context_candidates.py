import bpy,json,pathlib,itertools
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=pathlib.Path('/workspace/shared/NuclearPlant_Cumulative_Final/NuclearPlant/Batch07_Refinement');O=pathlib.Path('/workspace/shared/Batch07_Independent_QA/v04');bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'))
def bb(o):
 v=[o.matrix_world@Vector(v) for v in o.bound_box];return [min(v[i] for v in v) for i in range(3)],[max(v[i] for v in v) for i in range(3)]
def touch(a,b):return all(a[0][i]<b[1][i]-1e-5 and b[0][i]<a[1][i]-1e-5 for i in range(3))
cache={}
def tree(o):
 if o.name not in cache:
  me=o.data;vs=[o.matrix_world@v.co for v in me.vertices];faces=[tuple(p.vertices) for p in me.polygons];cache[o.name]=BVHTree.FromPolygons(vs,faces)
 return cache[o.name]
mods=[o for o in bpy.context.scene.objects if o.type=='MESH' and str(o.get('module_id','')).startswith('B07')];bbs={o.name:bb(o) for o in bpy.context.scene.objects if o.type=='MESH'};out=[]
for a,b in itertools.product(mods,[o for o in bpy.context.scene.objects if o.type=='MESH' and not str(o.get('module_id','')).startswith('B07')]):
 if touch(bbs[a.name],bbs[b.name]):
  ol=tree(a).overlap(tree(b))
  out.append({'a':a.name,'b':b.name,'triangle_pairs':len(ol),'a_bounds':bbs[a.name],'b_bounds':bbs[b.name]})
(O/'module_context_candidates.json').write_text(json.dumps({'scene':str(R/'site_refined.blend'),'module_count':len(mods),'intersections':out},indent=2));print('INTERSECTIONS',json.dumps(out),flush=True)
