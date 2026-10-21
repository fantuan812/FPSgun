import bpy,pathlib,json
from mathutils import Vector
R=pathlib.Path(__file__).resolve().parents[1];records=[]
for name in ['pump_service_connected.blend','site_with_pump_service.blend','pump_annex_double_height_option.blend','service_compact_comparison_only.blend','pump_annex_before_comparison_only.blend']:
 bpy.ops.wm.open_mainfile(filepath=str(R/'Region'/name));s=bpy.context.scene
 libs=[{'path':lib.filepath,'exists':pathlib.Path(bpy.path.abspath(lib.filepath)).is_file()} for lib in bpy.data.libraries]
 empty=[o.name for o in s.objects if o.type=='MESH' and len(o.data.vertices)==0]
 records.append({'scene':name,'libraries':libs,'empty_meshes':empty,'mesh_objects':sum(o.type=='MESH' for o in s.objects),'status':'PASS' if all(l['exists'] and l['path'].startswith('//../Geometry/') for l in libs) and not empty else 'FAIL'})
 if name in ['pump_service_connected.blend','site_with_pump_service.blend']:
  for camname,pos,target in [('EYE_1p65m_MATCHED_24mm',(-9,-52.5,1.65),(-11,-67,3.4)),('EYE_1p65m_CROSS_SPAN_24mm',(-23.5,-68.5,1.65),(1,-55,4))]:
   if camname not in bpy.data.objects:
    data=bpy.data.cameras.new(camname);o=bpy.data.objects.new(camname,data);s.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();data.lens=24;data.clip_start=.05
  for lib in bpy.data.libraries:lib.filepath='//../Geometry/'+pathlib.Path(lib.filepath).name
  bpy.ops.wm.save_as_mainfile(filepath=str(R/'Region'/name),relative_remap=False)
(R/'Validation/packaged_scene_libraries.json').write_text(json.dumps(records,indent=2));print(json.dumps(records,indent=2))
