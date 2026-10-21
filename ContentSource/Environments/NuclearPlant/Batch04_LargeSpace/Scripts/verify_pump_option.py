import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];p=R/'Validation/pump_annex_option.json';r=json.loads(p.read_text());bpy.ops.wm.open_mainfile(filepath=str(R/'Region/pump_annex_double_height_option.blend'));s=bpy.context.scene;dg=bpy.context.evaluated_depsgraph_get();roof=[]
# Mannequin is an inspection aid, excluded from room headroom measurements.
for o in s.objects:
 if 'HUMAN_' in o.name:o.hide_viewport=True
bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
for x in [-6,-4,-2]:
 for y in [-26,-22,-18,-14,-10]:
  ok,loc,n,f,o,m=s.ray_cast(dg,Vector((x,y,.3)),Vector((0,0,1)),distance=10);roof.append({'xy':[x,y],'first_overhead_m':loc.z if ok else None,'pass':ok and loc.z>=7.49})
libs=[l.filepath for l in bpy.data.libraries if not l.filepath.startswith('//') or not pathlib.Path(bpy.path.abspath(l.filepath)).is_file()]
floors=[o.name for o in s.objects if o.name.startswith('UpperFloor_')]
r['geometry_checks']={'headroom_samples':roof,'remaining_upper_floor_tiles':floors,'missing_or_absolute_libraries':libs,'guardrails_present':all(n in s.objects for n in ['OPTION_LandingRailWest','OPTION_LandingRailSouth'])};r['status']='PASS' if all(x['pass'] for x in roof) and len(floors)==1 and not libs and r['geometry_checks']['guardrails_present'] else 'FAIL';p.write_text(json.dumps(r,indent=2));print('PUMP_OPTION_CHECK',r['status'])
