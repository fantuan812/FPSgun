import bpy,json,pathlib,math
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for e in json.loads((R/'manifest.json').read_text())['assets']:
 p=R/e['path'];sp=json.loads((p/'spec.json').read_text());bpy.ops.wm.open_mainfile(filepath=str(p/'model.blend'));o=bpy.data.objects[sp['asset_id']];checks=[]
 if sp['builder']=='bay_wall':
  obstructed=[]
  for x in [1.01,2,4,6,6.99]:
   for z in [.01,1.5,2.99]:
    if o.ray_cast(Vector((x,-.5,z)),Vector((0,1,0)),distance=1)[0]:obstructed.append([x,z])
  checks.append({'test':'actual 6 x 3 m aperture ray grid','obstructions':obstructed,'status':'PASS' if not obstructed else 'FAIL'})
 elif sp['builder']=='rack':
  hits=[]
  for z in [.25,1.5,2.75]:
   ok,loc,_,_=o.ray_cast(Vector((2,0,z+.02)),Vector((0,0,-1)),distance=.1);hits.append({'expected':z,'actual':loc.z if ok else None,'pass':ok and abs(loc.z-z)<1e-5})
  checks.append({'test':'three actual shelf deck heights','hits':hits,'status':'PASS' if all(h['pass'] for h in hits) else 'FAIL'})
 uvok=all(math.isfinite(c) for layer in o.data.uv_layers for item in layer.data for c in item.uv)
 checks.append({'test':'finite UV coordinates','status':'PASS' if uvok else 'FAIL'})
 checks.append({'test':'identity pivot rotation scale','status':'PASS' if o.location.length<1e-6 and max(abs(v) for v in o.rotation_euler)<1e-6 and max(abs(v-1) for v in o.scale)<1e-6 else 'FAIL'})
 report={'asset_id':e['asset_id'],'status':'PASS' if all(c['status']=='PASS' for c in checks) else 'FAIL','checks':checks};(p/'interface_validation.json').write_text(json.dumps(report,indent=2));reports.append(report)
(R/'Validation/interface_validation.json').write_text(json.dumps(reports,indent=2));print('INTERFACES',[(r['asset_id'],r['status']) for r in reports])
