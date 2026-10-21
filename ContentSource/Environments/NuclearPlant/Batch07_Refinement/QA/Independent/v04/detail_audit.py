import bpy,json,pathlib,math,sys,numpy as np
from mathutils import Vector
R=pathlib.Path('/workspace/shared/NuclearPlant_Cumulative_Final/NuclearPlant/Batch07_Refinement');O=pathlib.Path('/workspace/shared/Batch07_Independent_QA/v04');C=json.loads((R/'Config/design_v04.json').read_text());sys.path.insert(0,str(R/'Scripts'));from analytic_geometry import meshpart
out={'module_vertex_comparison':{},'front_and_east_support':[],'road_materials':[],'component_gap_checks':[]}
for mid,m in C['modules'].items():
 bpy.ops.wm.open_mainfile(filepath=str(R/'Assets'/f'{mid}.blend'));o=bpy.data.objects[mid];v=np.array([v.co[:] for v in o.data.vertices]);expected=np.concatenate([meshpart(p)[0] for p in m['parts']]);out['module_vertex_comparison'][mid]={'vertex_count':len(v),'expected_vertex_count':len(expected),'maximum_vertex_difference_m':float(np.abs(v-expected).max()) if v.shape==expected.shape else None,'parts':len(m['parts'])}
bpy.ops.wm.open_mainfile(filepath=str(R/'site_refined.blend'))
def bounds(o):
 vs=[o.matrix_world@Vector(v) for v in o.bound_box];return {'name':o.name,'lo':[min(v[i] for v in vs) for i in range(3)],'hi':[max(v[i] for v in vs) for i in range(3)]}
for o in bpy.context.scene.objects:
 if o.name.startswith(('End wall panel','Side concrete panel','B07_VENT_CASSETTE')):out['front_and_east_support'].append(bounds(o))
 if o.name.startswith(('B06 road','East road','West road','South road','North road','Protected pedestrian hardstand')) and o.type=='MESH':out['road_materials'].append({'name':o.name,**bounds(o),'materials':[m.name if m else None for m in o.data.materials],'polygon_material_indices':sorted(set(p.material_index for p in o.data.polygons))})
(O/'detail_audit.json').write_text(json.dumps(out,indent=2));print(json.dumps(out['module_vertex_comparison'],indent=2));print('DETAIL_DONE')
