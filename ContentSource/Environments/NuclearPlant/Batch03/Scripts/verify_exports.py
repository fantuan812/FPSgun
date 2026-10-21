import bpy,bmesh,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];manifest=json.loads((R/'manifest.json').read_text());reports=[]
for e in manifest['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());item={'asset_id':sp['asset_id'],'exports':{}}
 for ext in ['fbx','glb']:
  bpy.ops.wm.read_factory_settings(use_empty=True)
  if ext=='fbx':bpy.ops.import_scene.fbx(filepath=str(p/'export.fbx'))
  else:bpy.ops.import_scene.gltf(filepath=str(p/'export.glb'))
  obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.name.startswith('UCX_')]
  verts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
  mn=[min(v[a] for v in verts) for a in range(3)];mx=[max(v[a] for v in verts) for a in range(3)]
  err=max(abs(x-y) for x,y in zip(mn+mx,sp['bounds_min']+sp['bounds_max']))
  cols=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('UCX_')];bad=[]
  for c in cols:
   bm=bmesh.new();bm.from_mesh(c.data)
   if any(not ed.is_manifold for ed in bm.edges):bad.append(c.name+': open mesh')
   # Convexity: all vertices lie on or behind every outward face plane.
   for f in bm.faces:
    a=f.verts[0].co
    if max(f.normal.dot(v.co-a) for v in bm.verts)>1e-5:bad.append(c.name+': nonconvex');break
   bm.free()
  item['exports'][ext]={'status':'PASS' if err<1e-4 and not bad else 'FAIL','bounds_min_m':mn,'bounds_max_m':mx,'max_bounds_error_m':err,'visual_meshes':len(obs),'uv_layers':[u.name for u in obs[0].data.uv_layers],'collision_hulls':len(cols),'collision_errors':bad,'method':'Export file re-imported in fresh Blender 4.3.2 scene; world coordinates measured. This is not an Unreal Engine import test.'}
 item['status']='PASS' if all(x['status']=='PASS' for x in item['exports'].values()) else 'FAIL';reports.append(item)
 (p/'export_validation.json').write_text(json.dumps(item,indent=2));print('EXPORT_CHECK',e['asset_id'],item['status'],flush=True)
(R/'Validation/export_roundtrip.json').write_text(json.dumps(reports,indent=2))
