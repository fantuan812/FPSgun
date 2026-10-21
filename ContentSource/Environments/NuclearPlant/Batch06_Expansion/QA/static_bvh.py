"""Read-only evaluated world-space triangle BVH for repeated static rays.
Includes MESH/CURVE/FONT/SURFACE geometry and render-hidden structures; excludes
explicit display proxies. It is not a UE collision representation.
"""
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

def build_world_bvh():
 d=bpy.context.evaluated_depsgraph_get(); verts=[]; faces=[]; owners=[]
 for ob in bpy.context.scene.objects:
  if ob.type not in {'MESH','CURVE','FONT','SURFACE','META'}:continue
  if 'proxy' in ob.name.lower() or any('Proxy' in c.name for c in ob.users_collection):continue
  e=ob.evaluated_get(d);me=e.to_mesh()
  if not me:continue
  me.calc_loop_triangles();base=len(verts);mw=ob.matrix_world
  verts.extend(mw@v.co for v in me.vertices)
  faces.extend(tuple(base+i for i in tri.vertices) for tri in me.loop_triangles)
  owners.extend([ob.name]*len(me.loop_triangles));e.to_mesh_clear()
 tree=BVHTree.FromPolygons(verts,faces,all_triangles=True,epsilon=0.0)
 def ray(p,v,dist):
  loc,normal,idx,distance=tree.ray_cast(Vector(p),Vector(v).normalized(),dist)
  return None if idx is None else (loc,owners[idx])
 return ray,{'vertices':len(verts),'triangles':len(faces),'excludes':'Explicit display proxies only','method':'Evaluated world geometry BVH, not engine collision'}
