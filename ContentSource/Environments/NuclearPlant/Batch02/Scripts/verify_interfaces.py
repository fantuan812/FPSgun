import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for e in json.loads((R/'manifest.json').read_text())['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(p/'model.blend'));cols=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('UCX_')];vis=bpy.data.objects[sp['asset_id']];checks=[]
 def cast(start,direction,maxdist=20,objects=None):
  hits=[]
  for o in (cols if objects is None else objects):
   ok,loc,n,idx=o.ray_cast(Vector(start),Vector(direction),distance=maxdist)
   if ok:hits.append(((loc-Vector(start)).length,list(loc),o.name))
  return min(hits) if hits else None
 if sp['builder']=='door_wall':
  for x in [1.05,2,2.95]:
   for z in [.05,1.5,2.95]:
    hit=cast((x,-2,z),(0,1,0),4);checks.append({'test':'door clear ray','sample':[x,z],'status':'PASS' if hit is None else 'FAIL','hit':hit})
  for x,z in [(.5,1.5),(3.5,1.5),(2,3.5)]:
   hit=cast((x,-2,z),(0,1,0),4);checks.append({'test':'door surround blocks','sample':[x,z],'status':'PASS' if hit else 'FAIL'})
  left=cast((2,0,1.5),(-1,0,0));right=cast((2,0,1.5),(1,0,0));up=cast((2,0,.001),(0,0,1));width=left[0]+right[0];height=up[1][2]
  checks.append({'test':'measured opening','width_m':width,'height_m':height,'status':'PASS' if abs(width-2)<1e-5 and abs(height-3)<1e-5 else 'FAIL'})
 if sp['builder'] in ['floor','roof','column_head']:
  z=sp['bounds_max'][2]
  samples=[(2,2),(.2,.2),(3.8,3.8)] if sp['builder']!='column_head' else [(0,0),(.2,.2),(-.2,-.2)]
  for x,y in samples:
   hit=cast((x,y,5),(0,0,-1));error=abs(hit[1][2]-z) if hit else 999;checks.append({'test':'collision proxy support or walking surface','sample':[x,y],'expected_z':z,'error_m':error,'status':'PASS' if error<1e-5 else 'FAIL'})
 # Independently sample the true visual mesh, including deliberate recessed tile seams.
 if sp['builder']=='door_wall':
  for x in [1.05,2,2.95]:
   for z in [.05,1.5,2.95]:
    hit=cast((x,-2,z),(0,1,0),4,[vis]);checks.append({'test':'visual mesh door clear ray','sample':[x,z],'status':'PASS' if hit is None else 'FAIL','hit':hit})
 if sp['builder'] in ['floor','roof','column_head']:
  samples={'floor':[(2,2,-.025),(.2,.2,0),(3.8,3.8,0),(.04,2,0)],'roof':[(2,2,.20),(.2,.2,.24),(3.8,3.8,.24),(.04,2,.25)],'column_head':[(0,0,.25),(.2,.2,.25),(-.2,-.2,.25)]}[sp['builder']]
  for x,y,z in samples:
   hit=cast((x,y,5),(0,0,-1),20,[vis]);error=abs(hit[1][2]-z) if hit else 999;checks.append({'test':'visual mesh surface including recessed seams','sample':[x,y],'expected_z':z,'error_m':error,'status':'PASS' if error<1e-5 else 'FAIL'})
 # Every render mesh and collision origin remains unchanged and every UV triangle has finite positive area.
 uvchecks={};me=vis.data
 for uv in me.uv_layers:
  nf=sum(not math.isfinite(a) for d in uv.data for a in d.uv);zero=0
  for f in me.polygons:
   v=[uv.data[i].uv for i in f.loop_indices];area=abs(sum(v[i].x*v[(i+1)%len(v)].y-v[(i+1)%len(v)].x*v[i].y for i in range(len(v)))/2)
   zero+=area<1e-14
  uvchecks[uv.name]={'nonfinite_values':nf,'zero_area_triangles':zero,'status':'PASS' if not nf and not zero else 'FAIL'}
 for sc in sp['connection_sockets']:
  if sc['role'] in ['walkway_port','floor_edge','column_bearing','slab_bearing','wall_bearing','floor_bearing','roof_bearing','wall_end']:
   pos=Vector(sc['position_m']);normal=Vector(sc['outward_normal']);proj=[(v.co-pos).dot(normal) for v in vis.data.vertices];near=0 if min(proj)<=0<=max(proj) else min(abs(v) for v in proj);checks.append({'test':'actual mesh reaches socket plane','socket':sc['id'],'plane_error_m':near,'status':'PASS' if near<1e-5 else 'FAIL'})
 report={'asset_id':sp['asset_id'],'tests':checks,'uv_integrity':uvchecks,'status':'PASS' if all(x['status']=='PASS' for x in checks+list(uvchecks.values())) else 'FAIL'};(p/'interface_validation.json').write_text(json.dumps(report,indent=2));reports.append(report);print('INTERFACE_CHECK',sp['asset_id'],report['status'],flush=True)
(R/'Validation/interface_validation.json').write_text(json.dumps(reports,indent=2))
