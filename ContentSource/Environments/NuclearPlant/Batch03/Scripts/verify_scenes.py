import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];reports=[]
for name in ['pump_zone.blend','site_with_pump_zone.blend']:
 bpy.ops.wm.open_mainfile(filepath=str(R/'Region'/name));s=bpy.context.scene;names={o.name for o in s.objects};others=['01_REACTOR','02_TURBINE','03_CONTROL','05_COOLING','06_TRANSFORMER','07_SERVICE','08_INTAKE'];libs=len(bpy.data.libraries);images=[i.filepath for i in bpy.data.images if i.filepath and not i.packed_file];present=[n for n in others if n in names];ok=libs==0 and not images and '04_PUMP' not in names and ('site_' not in name or len(present)==7)
 south_violations=[]
 for ob in s.objects:
  if ob.type!='MESH' or 'asset_id' not in ob or 'Floor_4x4' in ob['asset_id']:continue
  vv=[ob.matrix_world@v.co for v in ob.data.vertices];lo=[min(v[a] for v in vv) for a in range(3)];hi=[max(v[a] for v in vv) for a in range(3)]
  if hi[0]>.50001 and lo[0]<23.99999 and hi[1]>-27.99999 and lo[1]<-25.50001 and hi[2]>.05 and lo[2]<2.5:south_violations.append(ob.name)
 ok=ok and not south_violations
 ground_check=None
 if 'site_' in name:
  g=bpy.data.objects['SITE_224x192'];inv=g.matrix_world.inverted();hit,loc,normal,index=g.ray_cast(inv@Vector((8,-16,1)),Vector((0,0,-1)),distance=3);world=g.matrix_world@loc;ground_check={'ground_top_under_zone_m':world.z,'expected_max_m':-.25,'status':'PASS' if hit and world.z<=-.25 else 'FAIL'};ok=ok and ground_check['status']=='PASS'
 reports.append({'scene':name,'status':'PASS' if ok else 'FAIL','south_crossroute_clearance':{'width_m':2.5,'violations':south_violations,'status':'PASS' if not south_violations else 'FAIL'},'ground_recess':ground_check,'external_blend_libraries':libs,'external_images':images,'old_pump_placeholder_present':'04_PUMP' in names,'other_graybox_zone_objects':present,'module_instances':sum('asset_id' in o for o in s.objects),'camera_type':s.camera.data.type})
(R/'Validation/scene_integrity.json').write_text(json.dumps(reports,indent=2));print(json.dumps(reports,indent=2))
