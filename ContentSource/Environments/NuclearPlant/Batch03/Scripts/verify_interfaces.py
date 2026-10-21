import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for e in json.loads((R/'manifest.json').read_text())['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(p/'model.blend'));o=bpy.data.objects[sp['asset_id']];checks=[]
 def ray(start,direction,distance):
  ok,loc,n,idx=o.ray_cast(Vector(start),Vector(direction),distance=distance);return list(loc) if ok else None
 for sc in sp['connection_sockets']:
  p0=Vector(sc['position_m']);n=Vector(sc['outward_normal']);u=n.cross(Vector((0,0,1))).normalized();v=n.cross(u).normalized()
  for offset in [Vector((0,0,0)),u*.1,-u*.1,v*.1,-v*.1]:
   hit=ray(p0+n*.05+offset,-n,.23);checks.append({'test':'visual open port short bore ray','socket':sc['id'],'offset_m':list(offset),'hit':hit,'status':'PASS' if hit is None else 'FAIL'})
  for a in [math.pi/8,5*math.pi/8,9*math.pi/8,13*math.pi/8]:
   start=p0+n*.05+(u*math.cos(a)+v*math.sin(a))*.30;hit=ray(start,-n,.10);err=abs((Vector(hit)-p0).dot(n)) if hit else 999;checks.append({'test':'actual annular mating face plane','socket':sc['id'],'plane_error_m':err,'status':'PASS' if err<1e-5 else 'FAIL'})
 kind=sp['builder'];extra=[]
 if kind=='pipe_tee':
  for z in [-.23,-.20,-.15,0,.15,.20,.23]:
   hit=ray((1,-1,z),(0,1,0),1);checks.append({'test':'tee opposite exterior wall remains closed','sample_z':z,'hit':hit,'status':'PASS' if hit is not None and hit[1]<-.1 else 'FAIL'})
 if kind=='pipe':extra=[((-0.1,0,0),(1,0,0),4.2)]
 if kind=='pipe_tee':extra=[((-.1,0,0),(1,0,0),2.2),((1,0,0),(0,1,0),1.1)]
 if kind=='valve':extra=[((-.1,0,0),(1,0,0),1.2)]
 if kind=='pump':extra=[((-.1,0,1),(1,0,0),1.55),((1.5,-.1,1),(0,1,0),1.2)]
 for start,direction,distance in extra:
  hit=ray(start,direction,distance);checks.append({'test':'communicating visual bore centerline','start':start,'direction':direction,'length_m':distance,'hit':hit,'status':'PASS' if hit is None else 'FAIL'})
 if kind=='elbow':
  for degrees in [-75,-45,-15]:
   a=math.radians(degrees);c=Vector((math.cos(a),1+math.sin(a),0));d=Vector((0,0,1));hit=ray(c,d,.4);err=abs(hit[2]-.21) if hit else 999;checks.append({'test':'curved bore radial clearance sample','angle_degrees':degrees,'radius_error_m':err,'status':'PASS' if err<.004 else 'FAIL'})
 uvchecks={};me=o.data
 for uv in me.uv_layers:
  nf=sum(not math.isfinite(a) for d in uv.data for a in d.uv);zero=0
  for f in me.polygons:
   vv=[uv.data[i].uv for i in f.loop_indices];area=abs(sum(vv[i].x*vv[(i+1)%len(vv)].y-vv[(i+1)%len(vv)].x*vv[i].y for i in range(len(vv)))/2);zero+=area<1e-14
  uvchecks[uv.name]={'nonfinite_values':nf,'zero_area_triangles':zero,'status':'PASS' if not nf and not zero else 'FAIL'}
 report={'asset_id':sp['asset_id'],'tests':checks,'uv_integrity':uvchecks,'status':'PASS' if all(c['status']=='PASS' for c in checks+list(uvchecks.values())) else 'FAIL','note':'Visual bore tests do not mean the simplified convex gameplay collision is hollow. No hydraulic simulation.'};(p/'interface_validation.json').write_text(json.dumps(report,indent=2));reports.append(report);print('INTERFACE_CHECK',sp['asset_id'],report['status'],flush=True)
(R/'Validation/interface_validation.json').write_text(json.dumps(reports,indent=2))
