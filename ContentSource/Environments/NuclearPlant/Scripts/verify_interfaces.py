import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for e in json.loads((R/'manifest.json').read_text())['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(p/'model.blend'));cols=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('UCX_')];visual=bpy.data.objects[sp['asset_id']];checks=[]
 for sc in sp['connection_sockets']:
  pos=Vector(sc['position_m']);n=Vector(sc['outward_normal']);t=Vector((-n.y,n.x,0));plane=[];hits=[]
  for o in cols:
   for v in o.data.vertices:
    co=o.matrix_world@v.co
    if abs((co-pos).dot(n))<1e-5 and abs(co.z-pos.z)<1e-5:plane.append((co-pos).dot(t))
  width=max(plane)-min(plane) if plane else 0
  for offset in [-.8,-.4,0,.4,.8]:
   target=pos-n*.001+t*offset;start=target+Vector((0,0,6));found=[]
   for o in cols:
    ok,loc,norm,idx=o.ray_cast(start,Vector((0,0,-1)),distance=12)
    if ok:found.append((loc.z,o.name))
   z,name=max(found) if found else (-999,'NO_HIT');expected=.5*target.x if sp['builder']=='stairs' else pos.z;hits.append({'offset_m':offset,'hit_z_m':z,'expected_z_m':expected,'error_m':abs(z-expected),'collision_mesh':name})
  # The evaluated actual visual mesh reaches the interface plane at each end.
  nearest=min(abs((v.co-pos).dot(n)) for v in visual.data.vertices)
  checks.append({'socket':sc['id'],'actual_collision_top_edge_width_m':width,'actual_visual_plane_error_m':nearest,'walk_surface_ray_tests':hits,'status':'PASS' if abs(width-2)<1e-5 and nearest<1e-5 and max(h['error_m'] for h in hits)<.001 else 'FAIL'})
 me=visual.data;uvchecks={}
 for uv in me.uv_layers:
  nonfinite=sum(not math.isfinite(a) for v in uv.data for a in v.uv);zero=0
  for poly in me.polygons:
   v=[uv.data[i].uv for i in poly.loop_indices];area=abs(sum(v[i].x*v[(i+1)%len(v)].y-v[(i+1)%len(v)].x*v[i].y for i in range(len(v)))/2)
   if area<1e-14:zero+=1
  uvchecks[uv.name]={'nonfinite_values':nonfinite,'zero_area_triangles':zero,'status':'PASS' if nonfinite==0 and zero==0 else 'FAIL'}
 report={'asset_id':sp['asset_id'],'sockets':checks,'uv_integrity':uvchecks,'status':'PASS' if all(x['status']=='PASS' for x in checks+list(uvchecks.values())) else 'FAIL'};reports.append(report);(p/'interface_validation.json').write_text(json.dumps(report,indent=2));print('INTERFACE_CHECK',sp['asset_id'],report['status'],flush=True)
(R/'Validation/interface_validation.json').write_text(json.dumps(reports,indent=2))
